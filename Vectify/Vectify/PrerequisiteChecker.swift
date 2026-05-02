import Foundation

struct JavaRuntimeInfo: Sendable {
    var isInstalled: Bool
    var javaHome: String?
    var versionLine: String?
    /// How the JVM was resolved (shown in Environment for troubleshooting).
    var detectionNote: String?
}

struct VdToolLocation: Sendable {
    /// Path to `bin/vd-tool` inside the app bundle, if vendored.
    var bundledLauncherPath: String?
    var isBundled: Bool { bundledLauncherPath != nil }
}

enum PrerequisiteChecker {
    /// Resolved `bin/vd-tool` path when the bundle contains `Vendor/vd-tool` with `lib/*.jar`.
    static func bundledVdToolLauncherPath() -> String? {
        let fm = FileManager.default
        let candidates: [URL] = [
            Bundle.main.url(forResource: "vd-tool", withExtension: nil, subdirectory: "Vendor/vd-tool/bin"),
            Bundle.main.resourceURL.map { $0.appendingPathComponent("Vendor/vd-tool/bin/vd-tool") },
        ].compactMap { $0 }

        for url in candidates {
            guard fm.fileExists(atPath: url.path) else { continue }
            guard vdToolLibFolderLooksValid(binURL: url) else { continue }
            return url.path
        }
        return nil
    }

    /// True when `lib` next to `bin` contains at least one `.jar` (vd-tool layout).
    private static func vdToolLibFolderLooksValid(binURL: URL) -> Bool {
        let libDir = binURL.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("lib")
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: libDir.path) else { return false }
        return names.contains { $0.hasSuffix(".jar") }
    }

    static func vdToolLocation() -> VdToolLocation {
        VdToolLocation(bundledLauncherPath: bundledVdToolLauncherPath())
    }

    /// Resolves a JDK/JRE usable by vd-tool (Java 8+). Tries `JAVA_HOME`, `/usr/libexec/java_home`,
    /// `/Library/Java/JavaVirtualMachines`, then `java -XshowSettings:properties` (covers many Homebrew installs).
    static func javaRuntime() -> JavaRuntimeInfo {
        if let info = javaFromExplicitJavaHome(ProcessInfo.processInfo.environment["JAVA_HOME"]) {
            return JavaRuntimeInfo(
                isInstalled: true,
                javaHome: info.home,
                versionLine: info.version,
                detectionNote: "Using JAVA_HOME from your environment."
            )
        }

        if let home = invokeJavaHome(arguments: []), let info = validateJavaHome(home) {
            return JavaRuntimeInfo(
                isInstalled: true,
                javaHome: info.home,
                versionLine: info.version,
                detectionNote: "Using macOS default JVM from /usr/libexec/java_home."
            )
        }

        for ver in ["25+", "22+", "21+", "17+", "11+", "1.8+"] {
            if let home = invokeJavaHome(arguments: ["-v", ver]), let info = validateJavaHome(home) {
                return JavaRuntimeInfo(
                    isInstalled: true,
                    javaHome: info.home,
                    versionLine: info.version,
                    detectionNote: "Using JVM matching /usr/libexec/java_home -v \(ver)."
                )
            }
        }

        for home in javaHomesFromLibraryInstalls() {
            if let info = validateJavaHome(home) {
                return JavaRuntimeInfo(
                    isInstalled: true,
                    javaHome: info.home,
                    versionLine: info.version,
                    detectionNote: "Using JDK under /Library/Java/JavaVirtualMachines."
                )
            }
        }

        if let home = javaHomeFromShowSettings(), let info = validateJavaHome(home) {
            return JavaRuntimeInfo(
                isInstalled: true,
                javaHome: info.home,
                versionLine: info.version,
                detectionNote: "Using java on PATH (/usr/bin/java -XshowSettings:properties)."
            )
        }

        return JavaRuntimeInfo(
            isInstalled: false,
            javaHome: nil,
            versionLine: nil,
            detectionNote: javaFailureHint()
        )
    }

    private static func javaFailureHint() -> String {
        "No JVM found. Install a JDK (Temurin 17+ recommended) so it appears under /Library/Java/JavaVirtualMachines, "
            + "or set JAVA_HOME to your JDK, or ensure /usr/libexec/java_home works in Terminal. "
            + "Java 8 through current LTS releases work with vd-tool."
    }

    private struct ValidatedJava: Sendable {
        let home: String
        let version: String?
    }

    private static func javaFromExplicitJavaHome(_ raw: String?) -> ValidatedJava? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let home = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return validateJavaHome(home)
    }

    private static func validateJavaHome(_ home: String) -> ValidatedJava? {
        let javaBin = URL(fileURLWithPath: home).appendingPathComponent("bin/java").path
        guard FileManager.default.isExecutableFile(atPath: javaBin) else { return nil }
        let version = javaVersionLine(javaHome: home)
        return ValidatedJava(home: home, version: version)
    }

    private static func invokeJavaHome(arguments: [String]) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/libexec/java_home")
        p.arguments = arguments
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        do {
            try p.run()
            p.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let out = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if p.terminationStatus == 0, !out.isEmpty { return out }
        } catch {
            return nil
        }
        return nil
    }

    private static func javaHomesFromLibraryInstalls() -> [String] {
        let base = URL(fileURLWithPath: "/Library/Java/JavaVirtualMachines")
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: base.path) else { return [] }
        return names.sorted(by: >).compactMap { name -> String? in
            let home = base.appendingPathComponent(name).appendingPathComponent("Contents/Home").path
            let javaBin = URL(fileURLWithPath: home).appendingPathComponent("bin/java").path
            return FileManager.default.isExecutableFile(atPath: javaBin) ? home : nil
        }
    }

    private static func javaHomeFromShowSettings() -> String? {
        let candidates = ["/usr/bin/java", "/opt/homebrew/opt/openjdk/bin/java", "/usr/local/opt/openjdk/bin/java"]
        for path in candidates {
            guard FileManager.default.isExecutableFile(atPath: path) else { continue }
            if let home = javaHomeFromShowSettings(javaPath: path) { return home }
        }
        if let whichJava = which(name: "java"), FileManager.default.isExecutableFile(atPath: whichJava) {
            return javaHomeFromShowSettings(javaPath: whichJava)
        }
        return nil
    }

    private static func javaHomeFromShowSettings(javaPath: String) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: javaPath)
        p.arguments = ["-XshowSettings:properties", "-version"]
        let errPipe = Pipe()
        p.standardError = errPipe
        p.standardOutput = FileHandle.nullDevice
        do {
            try p.run()
            p.waitUntilExit()
            let data = errPipe.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8) ?? ""
            guard let re = try? NSRegularExpression(pattern: #"java\.home\s*=\s*(.+)"#, options: []) else {
                return nil
            }
            let range = NSRange(text.startIndex..., in: text)
            guard let m = re.firstMatch(in: text, options: [], range: range), m.numberOfRanges > 1,
                  let r = Range(m.range(at: 1), in: text) else { return nil }
            return String(text[r]).trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    private static func javaVersionLine(javaHome: String) -> String? {
        let bin = URL(fileURLWithPath: javaHome).appendingPathComponent("bin/java").path
        guard FileManager.default.isExecutableFile(atPath: bin) else { return nil }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: bin)
        p.arguments = ["-version"]
        let err = Pipe()
        p.standardError = err
        p.standardOutput = Pipe()
        do {
            try p.run()
            p.waitUntilExit()
            let data = err.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?
                .split(separator: "\n")
                .first
                .map(String.init)
        } catch {
            return nil
        }
    }

    static func nodeAvailable() -> Bool {
        nodeExecutablePath() != nil
    }

    /// Resolved `node` binary path, if any (same logic as `nodeAvailable()`).
    /// GUI apps often inherit a minimal `PATH`; we check common install locations first, then `which` with a Homebrew-friendly `PATH` (same idea as `SvgoRunner`).
    static func nodeExecutablePath() -> String? {
        for path in ["/opt/homebrew/bin/node", "/usr/local/bin/node", "/usr/bin/node"] {
            if FileManager.default.isExecutableFile(atPath: path) { return path }
        }
        if FileManager.default.isExecutableFile(atPath: "/usr/bin/which") {
            if let found = which(name: "node") { return found }
        }
        return whichFallback("node")
    }

    private static func which(name: String) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        p.arguments = [name]
        var env = ProcessInfo.processInfo.environment
        let pathPrefix = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        env["PATH"] = pathPrefix + ":" + (env["PATH"] ?? "")
        p.environment = env
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        do {
            try p.run()
            p.waitUntilExit()
            guard p.terminationStatus == 0 else { return nil }
            let s = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (s?.isEmpty == false) ? s : nil
        } catch {
            return nil
        }
    }

    private static func whichFallback(_ name: String) -> String? {
        for root in ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"] {
            let path = "\(root)/\(name)"
            if FileManager.default.isExecutableFile(atPath: path) { return path }
        }
        return nil
    }

    static func diagnosticsText(java: JavaRuntimeInfo, vd: VdToolLocation, node: Bool) -> String {
        var lines: [String] = []
        lines.append("Java installed: \(java.isInstalled)")
        if let n = java.detectionNote { lines.append(n) }
        if let home = java.javaHome { lines.append("JAVA_HOME: \(home)") }
        if let v = java.versionLine { lines.append(v) }
        lines.append("vd-tool bundled: \(vd.isBundled)")
        if let p = vd.bundledLauncherPath { lines.append("vd-tool path: \(p)") }
        lines.append("Node.js (SVGO optional): \(node ? "found" : "not found — install only if you use SVGO")")
        return lines.joined(separator: "\n")
    }
}

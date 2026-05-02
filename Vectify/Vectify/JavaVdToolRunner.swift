import Foundation

enum JavaVdToolError: LocalizedError {
    case noBundledVdTool
    case javaMissing
    case cannotCreateOutputDir(String)
    case vdToolFailed(code: Int32, stderr: String)
    case missingOutput

    var errorDescription: String? {
        switch self {
        case .noBundledVdTool:
            return "Bundled vd-tool launcher not found in the app."
        case .javaMissing:
            return "Java was not detected. Install a JDK (Temurin 17+), set JAVA_HOME, or open Environment to see details."
        case .cannotCreateOutputDir(let m):
            return "Cannot create output directory: \(m)"
        case .vdToolFailed(let code, let stderr):
            return "vd-tool exited with \(code): \(stderr)"
        case .missingOutput:
            return "vd-tool did not produce the expected XML file."
        }
    }
}

enum JavaVdToolRunner {
    /// Runs bundled `bin/vd-tool` with `-c -in <svg> -out <dir>` (`out` must exist).
    static func convert(svg: URL, outputDirectory: URL) throws -> Data {
        guard let launcher = PrerequisiteChecker.bundledVdToolLauncherPath() else {
            throw JavaVdToolError.noBundledVdTool
        }
        let java = PrerequisiteChecker.javaRuntime()
        guard java.isInstalled, let javaHome = java.javaHome else {
            throw JavaVdToolError.javaMissing
        }
        do {
            try FileManager.default.createDirectory(
                at: outputDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            throw JavaVdToolError.cannotCreateOutputDir(error.localizedDescription)
        }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: launcher)
        p.arguments = [
            "-c",
            "-in", svg.path,
            "-out", outputDirectory.path,
        ]
        var env = ProcessInfo.processInfo.environment
        env["JAVA_HOME"] = javaHome
        let pathPrefix = "/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin"
        env["PATH"] = pathPrefix + ":" + (env["PATH"] ?? "")
        p.environment = env
        p.currentDirectoryURL = outputDirectory.deletingLastPathComponent()

        let errPipe = Pipe()
        p.standardError = errPipe
        p.standardOutput = FileHandle.nullDevice
        p.standardInput = FileHandle.nullDevice

        try p.run()
        p.waitUntilExit()

        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let errStr = String(data: errData, encoding: .utf8) ?? ""

        guard p.terminationStatus == 0 else {
            throw JavaVdToolError.vdToolFailed(code: p.terminationStatus, stderr: String(errStr.prefix(2000)))
        }

        let outFile = outputDirectory.appendingPathComponent(svg.deletingPathExtension().lastPathComponent + ".xml")
        guard FileManager.default.fileExists(atPath: outFile.path),
              let data = try? Data(contentsOf: outFile),
              data.contains(Data("<vector".utf8))
        else {
            throw JavaVdToolError.missingOutput
        }
        return data
    }
}

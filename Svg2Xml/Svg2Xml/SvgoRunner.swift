import Foundation

enum SvgoRunnerError: LocalizedError {
    case nodeMissing
    case failed(code: Int32, message: String)

    var errorDescription: String? {
        switch self {
        case .nodeMissing:
            return "Node.js / npx not found. Install Node or disable SVGO."
        case .failed(let code, let message):
            return "SVGO failed (\(code)): \(message)"
        }
    }
}

enum SvgoRunner {
    /// Runs `npx --yes svgo` on the given SVG path (mutates file in place, like the Python script).
    static func optimize(svg: URL, configFile: URL?, workingDirectory: URL) throws {
        guard PrerequisiteChecker.nodeAvailable() else { throw SvgoRunnerError.nodeMissing }
        var args = ["--yes", "svgo"]
        if let cfg = configFile, FileManager.default.fileExists(atPath: cfg.path) {
            args.append(contentsOf: ["--config", cfg.path])
        }
        args.append(svg.path)

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/npx")
        p.arguments = args
        p.currentDirectoryURL = workingDirectory
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:" + (env["PATH"] ?? "")
        p.environment = env
        let err = Pipe()
        let out = Pipe()
        p.standardError = err
        p.standardOutput = out
        try p.run()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else {
            let msg =
                String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw SvgoRunnerError.failed(code: p.terminationStatus, message: String(msg.prefix(800)))
        }
    }
}

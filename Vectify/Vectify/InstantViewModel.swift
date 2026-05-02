import AppKit
import Foundation
import Observation
import UniformTypeIdentifiers

enum InstantItemStatus: String, Sendable {
    case queued
    case converting
    case converted
    case failed
}

struct InstantSessionItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let sourceURL: URL
    let displayName: String
    var byteSize: Int64
    var status: InstantItemStatus
    var xmlData: Data?
    var errorMessage: String

    var suggestedXmlFileName: String {
        let stem = (displayName as NSString).deletingPathExtension.lowercased()
        return stem.isEmpty ? "vector.xml" : "\(stem).xml"
    }

    var sizeLabel: String {
        ByteCountFormatter.string(fromByteCount: byteSize, countStyle: .file)
    }
}

@MainActor
@Observable
final class InstantViewModel {
    var items: [InstantSessionItem] = []
    var logLines: [String] = []
    var applySvgo = false
    var isConverting = false
    var fileDropHover = false

    func logText() -> String {
        logLines.joined(separator: "\n")
    }

    func clearLog() {
        logLines = []
    }

    func clearSession() {
        items = []
        appendLog("[SYSTEM] Session cleared.")
    }

    func chooseSVGFiles() {
        let p = NSOpenPanel()
        p.canChooseFiles = true
        p.canChooseDirectories = false
        p.allowsMultipleSelection = true
        p.allowedContentTypes = [.svg]
        p.prompt = "Select SVG files"
        guard p.runModal() == .OK else { return }
        importURLs(p.urls)
    }

    func importURLs(_ urls: [URL]) {
        let svgURLs = urls.filter { $0.pathExtension.lowercased() == "svg" }
        guard !svgURLs.isEmpty else {
            appendLog("[INFO] No SVG files in selection.")
            return
        }
        for url in svgURLs {
            _ = url.startAccessingSecurityScopedResource()
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map(Int64.init) ?? 0
            items.append(
                InstantSessionItem(
                    id: UUID(),
                    sourceURL: url,
                    displayName: url.lastPathComponent,
                    byteSize: size,
                    status: .queued,
                    xmlData: nil,
                    errorMessage: ""
                )
            )
        }
        appendLog("[SYSTEM] Added \(svgURLs.count) SVG file(s) to session.")
        Task { await convertQueuedItems() }
    }

    func convertQueuedItems() async {
        let java = PrerequisiteChecker.javaRuntime()
        guard java.isInstalled, java.javaHome != nil else {
            appendLog("[ERROR] Java is not installed. Open Environment for setup help.")
            for i in items.indices where items[i].status == .queued || items[i].status == .converting {
                items[i].status = .failed
                items[i].errorMessage = "Java not available"
            }
            return
        }

        isConverting = true
        defer { isConverting = false }

        for index in items.indices {
            guard items[index].status != .converted else { continue }
            await convertItem(at: index)
        }
        appendLog("[INFO] Session batch finished.")
    }

    private func convertItem(at index: Int) async {
        guard items.indices.contains(index) else { return }
        let url = items[index].sourceURL
        let name = items[index].displayName
        items[index].status = .converting
        items[index].errorMessage = ""

        let scoped = url.startAccessingSecurityScopedResource()
        defer {
            if scoped { url.stopAccessingSecurityScopedResource() }
        }

        let (ok, reason) = SvgConversionHelpers.isValidSVG(at: url)
        guard ok else {
            items[index].status = .failed
            items[index].errorMessage = reason
            appendLog("[SKIP] \(name): \(reason)")
            return
        }

        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("vectify-instant-\(UUID().uuidString)", isDirectory: true)
        let stem = url.deletingPathExtension().lastPathComponent
        let stagedSVG = tmp.appendingPathComponent("\(stem).svg")
        let vdOut = tmp.appendingPathComponent("vdout", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: url, to: stagedSVG)
            if applySvgo {
                do {
                    let cfg = Bundle.main.url(forResource: "svgo-icons", withExtension: "config.mjs")
                    try SvgoRunner.optimize(
                        svg: stagedSVG,
                        configFile: cfg,
                        workingDirectory: tmp
                    )
                } catch {
                    appendLog("[WARN] SVGO failed for \(name): \(error.localizedDescription)")
                }
            }
            try FileManager.default.createDirectory(at: vdOut, withIntermediateDirectories: true)
            var raw = try JavaVdToolRunner.convert(svg: stagedSVG, outputDirectory: vdOut)
            raw = try VectorDrawablePostProcessor.finalizeVectorXML(data: raw)
            items[index].xmlData = raw
            items[index].status = .converted
            appendLog("[SUCCESS] \(name) → VectorDrawable XML (\(raw.count) bytes)")
        } catch {
            items[index].status = .failed
            items[index].errorMessage = error.localizedDescription
            items[index].xmlData = nil
            appendLog("[FAIL] \(name): \(error.localizedDescription)")
        }
        try? FileManager.default.removeItem(at: tmp)
    }

    func saveItemXML(_ item: InstantSessionItem) {
        guard let data = item.xmlData else { return }
        let p = NSSavePanel()
        p.allowedContentTypes = [.xml]
        p.canCreateDirectories = true
        p.nameFieldStringValue = item.suggestedXmlFileName
        guard p.runModal() == .OK, let dest = p.url else { return }
        do {
            try data.write(to: dest, options: .atomic)
            appendLog("[INFO] Saved \(item.displayName) → \(dest.path)")
        } catch {
            appendLog("[ERROR] Save failed: \(error.localizedDescription)")
        }
    }

    func downloadAllAsZip() {
        let converted = items.filter { $0.status == .converted && $0.xmlData != nil }
        guard !converted.isEmpty else {
            appendLog("[WARN] No converted files to zip.")
            return
        }
        let p = NSSavePanel()
        p.allowedContentTypes = [.zip]
        p.nameFieldStringValue = "Vectify-instant-drawables.zip"
        p.canCreateDirectories = true
        guard p.runModal() == .OK, let zipURL = p.url else { return }

        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("vectify-instant-zip-\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tmp) }

            var paths: [String] = []
            var usedNames: Set<String> = []
            for item in converted {
                guard let data = item.xmlData else { continue }
                let uniqueName = Self.uniqueXmlName(base: item.suggestedXmlFileName, used: &usedNames)
                let fileURL = tmp.appendingPathComponent(uniqueName)
                try data.write(to: fileURL, options: .atomic)
                paths.append(fileURL.path)
            }
            guard !paths.isEmpty else { return }

            if FileManager.default.fileExists(atPath: zipURL.path) {
                try FileManager.default.removeItem(at: zipURL)
            }

            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
            proc.arguments = ["-j", zipURL.path] + paths
            try proc.run()
            proc.waitUntilExit()
            guard proc.terminationStatus == 0 else {
                appendLog("[ERROR] zip exited with code \(proc.terminationStatus)")
                return
            }
            appendLog("[INFO] Wrote ZIP: \(zipURL.path) (\(converted.count) file(s))")
        } catch {
            appendLog("[ERROR] ZIP failed: \(error.localizedDescription)")
        }
    }

    func appendInfoLog(_ line: String) {
        appendLog("[INFO] \(line)")
    }

    private func appendLog(_ line: String) {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        logLines.append("[\(f.string(from: Date()))] \(line)")
    }

    /// Avoids overwriting when multiple session items map to the same `.xml` basename inside the ZIP staging folder.
    private static func uniqueXmlName(base: String, used: inout Set<String>) -> String {
        if !used.contains(base) {
            used.insert(base)
            return base
        }
        let stem = (base as NSString).deletingPathExtension
        var n = 2
        var candidate = "\(stem)_\(n).xml"
        while used.contains(candidate) {
            n += 1
            candidate = "\(stem)_\(n).xml"
        }
        used.insert(candidate)
        return candidate
    }
}

import AppKit
import Foundation
import Observation

enum ConversionStatus: String, Sendable {
    case queued
    case running
    case ok
    case failed
    case skipped
}

struct ConversionRowModel: Identifiable, Sendable {
    let id = UUID()
    var name: String
    var status: ConversionStatus
    var message: String
    var outputFileName: String?
}

@MainActor
@Observable
final class ConversionViewModel {
    var inputFolderURL: URL?
    var outputFolderURL: URL?
    var logLines: [String] = []
    var rows: [ConversionRowModel] = []
    var isConverting = false
    var applySvgo = false
    var overwrite = false

    var canConvert: Bool {
        guard let input = inputFolderURL, let output = outputFolderURL else { return false }
        guard !isConverting else { return false }
        let svgs = SvgConversionHelpers.listSVGFiles(in: input)
        return !svgs.isEmpty && FileManager.default.isWritableFile(atPath: output.path)
    }

    func appendLog(_ line: String) {
        logLines.append(line)
    }

    func clearLog() {
        logLines.removeAll()
    }

    func logText() -> String {
        logLines.joined(separator: "\n")
    }

    func refreshFileList() {
        guard let dir = inputFolderURL else {
            rows = []
            return
        }
        let files = SvgConversionHelpers.listSVGFiles(in: dir)
        rows = files.map {
            ConversionRowModel(name: $0.lastPathComponent, status: .queued, message: "", outputFileName: nil)
        }
    }

    func chooseInputFolder() {
        let p = NSOpenPanel()
        p.canChooseFiles = false
        p.canChooseDirectories = true
        p.allowsMultipleSelection = false
        p.prompt = "Choose Input Folder"
        guard p.runModal() == .OK, let url = p.url else { return }
        _ = url.startAccessingSecurityScopedResource()
        inputFolderURL = url
        appendLog("Input folder: \(url.path)")
        refreshFileList()
    }

    func chooseOutputFolder() {
        let p = NSOpenPanel()
        p.canChooseFiles = false
        p.canChooseDirectories = true
        p.allowsMultipleSelection = false
        p.prompt = "Choose Output Folder"
        guard p.runModal() == .OK, let url = p.url else { return }
        _ = url.startAccessingSecurityScopedResource()
        outputFolderURL = url
        appendLog("Output folder: \(url.path)")
    }

    func convertAll() async {
        guard let inputRoot = inputFolderURL, let drawableRoot = outputFolderURL else { return }
        isConverting = true
        defer { isConverting = false }

        let inScoped = inputRoot.startAccessingSecurityScopedResource()
        let outScoped = drawableRoot.startAccessingSecurityScopedResource()
        defer {
            if inScoped { inputRoot.stopAccessingSecurityScopedResource() }
            if outScoped { drawableRoot.stopAccessingSecurityScopedResource() }
        }

        let files = SvgConversionHelpers.listSVGFiles(in: inputRoot)
        for i in rows.indices {
            rows[i].status = .queued
            rows[i].message = ""
            rows[i].outputFileName = nil
        }

        var converted = 0
        var failed = 0
        var skipped = 0

        for svg in files {
            let name = svg.lastPathComponent
            guard let idx = rows.firstIndex(where: { $0.name == name }) else { continue }
            rows[idx].status = .running

            let stemLower = svg.deletingPathExtension().lastPathComponent.lowercased()
            let (outURL, allocErr, _) = DrawableNaming.allocateOutputXML(
                drawableDir: drawableRoot,
                stemLower: stemLower,
                force: overwrite
            )
            guard let outXML = outURL else {
                rows[idx].status = .failed
                rows[idx].message = allocErr
                failed += 1
                appendLog("failed: \(name) — \(allocErr)")
                continue
            }

            let (ok, reason) = SvgConversionHelpers.isValidSVG(at: svg)
            if !ok {
                rows[idx].status = .skipped
                rows[idx].message = reason
                skipped += 1
                appendLog("skipped (invalid): \(name) — \(reason)")
                continue
            }

            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("vectify-\(UUID().uuidString)", isDirectory: true)
            let stagedStem = outXML.deletingPathExtension().lastPathComponent
            let stagedSVG = tmp.appendingPathComponent("\(stagedStem).svg")
            let vdOut = tmp.appendingPathComponent("vdout", isDirectory: true)

            do {
                try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: svg, to: stagedSVG)
                if applySvgo {
                    do {
                        let cfg = Bundle.main.url(forResource: "svgo-icons", withExtension: "config.mjs")
                        try SvgoRunner.optimize(
                            svg: stagedSVG,
                            configFile: cfg,
                            workingDirectory: tmp
                        )
                    } catch {
                        appendLog("WARNING: SVGO failed for \(name): \(error.localizedDescription)")
                    }
                }
                try FileManager.default.createDirectory(at: vdOut, withIntermediateDirectories: true)
                var raw = try JavaVdToolRunner.convert(svg: stagedSVG, outputDirectory: vdOut)
                raw = try VectorDrawablePostProcessor.finalizeVectorXML(data: raw)
                try raw.write(to: outXML, options: .atomic)
                rows[idx].status = .ok
                rows[idx].message = ""
                rows[idx].outputFileName = outXML.lastPathComponent
                converted += 1
                appendLog("converted: \(name) → \(outXML.lastPathComponent)")
            } catch {
                rows[idx].status = .failed
                rows[idx].message = error.localizedDescription
                failed += 1
                appendLog("Conversion failed for \(name): \(error.localizedDescription)")
                try? FileManager.default.removeItem(at: outXML)
            }
            try? FileManager.default.removeItem(at: tmp)
        }

        appendLog(
            "Summary: found=\(files.count) converted=\(converted) failed=\(failed) skipped_invalid=\(skipped)"
        )
    }
}

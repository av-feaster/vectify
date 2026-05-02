import AppKit
import Foundation
import Observation

/// Menu target for the conversion-time status item (must be `NSObject` for `#selector`).
@MainActor
private final class ConversionMenuBarActions: NSObject {
    static let shared = ConversionMenuBarActions()

    private override init() {
        super.init()
    }

    @objc func showVectify(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        if let main = NSApp.mainWindow, main.isVisible {
            main.makeKeyAndOrderFront(nil)
            return
        }
        NSApp.windows.first(where: { $0.isVisible })?.makeKeyAndOrderFront(nil)
    }
}

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
    @ObservationIgnored private var conversionMenuBarStatusItem: NSStatusItem?

    var inputFolderURL: URL?
    var outputFolderURL: URL?
    var logLines: [String] = []
    var rows: [ConversionRowModel] = []
    var isConverting = false
    var applySvgo = false
    var overwrite = false

    /// Named workspaces persisted under Application Support.
    var savedProjects: [SavedConvertProject] = []
    var activeProjectID: UUID = UUID()

    var activeProjectName: String {
        savedProjects.first(where: { $0.id == activeProjectID })?.name ?? "Project"
    }

    var canConvert: Bool {
        guard let input = inputFolderURL, let output = outputFolderURL else { return false }
        guard !isConverting else { return false }
        let svgs = SvgConversionHelpers.listSVGFiles(in: input)
        return !svgs.isEmpty && FileManager.default.isWritableFile(atPath: output.path)
    }

    init() {
        bootstrapProjectsIfNeeded()
        applyActiveProjectToUI()
    }

    // MARK: - Projects

    private func bootstrapProjectsIfNeeded() {
        if let doc = ConvertProjectPersistence.load(), !doc.projects.isEmpty {
            savedProjects = doc.projects
            if let id = doc.activeProjectID, savedProjects.contains(where: { $0.id == id }) {
                activeProjectID = id
            } else {
                activeProjectID = savedProjects[0].id
            }
        } else {
            let id = UUID()
            savedProjects = [
                SavedConvertProject(
                    id: id,
                    name: "Default",
                    inputBookmark: nil,
                    outputBookmark: nil,
                    applySvgo: false,
                    overwrite: false,
                    logLines: []
                ),
            ]
            activeProjectID = id
            persistDocumentToDisk()
        }
    }

    func selectProject(id: UUID) {
        guard id != activeProjectID else { return }
        persistActiveProjectSnapshot()
        activeProjectID = id
        applyActiveProjectToUI()
        persistDocumentToDisk()
    }

    func createProject(name raw: String) {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        persistActiveProjectSnapshot()
        let id = UUID()
        let project = SavedConvertProject(
            id: id,
            name: name,
            inputBookmark: nil,
            outputBookmark: nil,
            applySvgo: false,
            overwrite: false,
            logLines: []
        )
        savedProjects.append(project)
        activeProjectID = id
        applyActiveProjectToUI()
        persistDocumentToDisk()
    }

    func renameActiveProject(to raw: String) {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty,
            let idx = savedProjects.firstIndex(where: { $0.id == activeProjectID })
        else { return }
        savedProjects[idx].name = name
        persistDocumentToDisk()
    }

    func persistActiveProjectSnapshot() {
        guard let idx = savedProjects.firstIndex(where: { $0.id == activeProjectID }) else { return }
        savedProjects[idx].inputBookmark = bookmarkData(for: inputFolderURL)
        savedProjects[idx].outputBookmark = bookmarkData(for: outputFolderURL)
        savedProjects[idx].applySvgo = applySvgo
        savedProjects[idx].overwrite = overwrite
        savedProjects[idx].logLines = logLines
        persistDocumentToDisk()
    }

    private func persistDocumentToDisk() {
        let doc = ConvertProjectsDocument(projects: savedProjects, activeProjectID: activeProjectID)
        try? ConvertProjectPersistence.save(doc)
    }

    private func bookmarkData(for url: URL?) -> Data? {
        guard let url else { return nil }
        return try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    private func resolveBookmark(_ data: Data?) -> URL? {
        guard let data else { return nil }
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return url
        } catch {
            return nil
        }
    }

    private func stopAccessingCurrentFolders() {
        if let u = inputFolderURL {
            u.stopAccessingSecurityScopedResource()
        }
        if let u = outputFolderURL {
            u.stopAccessingSecurityScopedResource()
        }
        inputFolderURL = nil
        outputFolderURL = nil
    }

    private func applyActiveProjectToUI() {
        stopAccessingCurrentFolders()
        rows = []
        guard let p = savedProjects.first(where: { $0.id == activeProjectID }) else { return }
        applySvgo = p.applySvgo
        overwrite = p.overwrite
        logLines = p.logLines
        if let u = resolveBookmark(p.inputBookmark) {
            _ = u.startAccessingSecurityScopedResource()
            inputFolderURL = u
        }
        if let u = resolveBookmark(p.outputBookmark) {
            _ = u.startAccessingSecurityScopedResource()
            outputFolderURL = u
        }
        refreshFileList()
    }

    // MARK: - Log & rows

    func appendLog(_ line: String) {
        logLines.append(line)
    }

    func clearLog() {
        logLines.removeAll()
        persistActiveProjectSnapshot()
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

    /// Adopt a folder from the open panel or drag-and-drop (caller should prefer security-scoped URLs when available).
    func adoptInputFolder(_ url: URL) {
        if let old = inputFolderURL, old.path != url.path {
            old.stopAccessingSecurityScopedResource()
        }
        _ = url.startAccessingSecurityScopedResource()
        inputFolderURL = url
        appendLog("Input folder: \(url.path)")
        refreshFileList()
        persistActiveProjectSnapshot()
    }

    func adoptOutputFolder(_ url: URL) {
        if let old = outputFolderURL, old.path != url.path {
            old.stopAccessingSecurityScopedResource()
        }
        _ = url.startAccessingSecurityScopedResource()
        outputFolderURL = url
        appendLog("Output folder: \(url.path)")
        persistActiveProjectSnapshot()
    }

    func chooseInputFolder() {
        let p = NSOpenPanel()
        p.canChooseFiles = false
        p.canChooseDirectories = true
        p.allowsMultipleSelection = false
        p.prompt = "Choose Input Folder"
        guard p.runModal() == .OK, let url = p.url else { return }
        adoptInputFolder(url)
    }

    func chooseOutputFolder() {
        let p = NSOpenPanel()
        p.canChooseFiles = false
        p.canChooseDirectories = true
        p.allowsMultipleSelection = false
        p.prompt = "Choose Output Folder"
        guard p.runModal() == .OK, let url = p.url else { return }
        adoptOutputFolder(url)
    }

    func convertAll() async {
        guard let inputRoot = inputFolderURL, let drawableRoot = outputFolderURL else { return }
        isConverting = true
        installConversionMenuBarStatusItem()
        defer {
            removeConversionMenuBarStatusItem()
            isConverting = false
        }

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
        persistActiveProjectSnapshot()
    }

    // MARK: - Menu bar (system status item while converting)

    private func installConversionMenuBarStatusItem() {
        guard conversionMenuBarStatusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = item.button else { return }

        let icon = (NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath).copy() as? NSImage) ?? NSImage()
        icon.size = NSSize(width: 18, height: 18)
        button.image = icon
        button.image?.isTemplate = false
        button.toolTip = "Vectify — Converting SVGs…"

        let menu = NSMenu()
        let showItem = NSMenuItem(
            title: "Show Vectify",
            action: #selector(ConversionMenuBarActions.showVectify),
            keyEquivalent: ""
        )
        showItem.target = ConversionMenuBarActions.shared
        menu.addItem(showItem)
        item.menu = menu

        conversionMenuBarStatusItem = item
    }

    private func removeConversionMenuBarStatusItem() {
        guard let item = conversionMenuBarStatusItem else { return }
        NSStatusBar.system.removeStatusItem(item)
        conversionMenuBarStatusItem = nil
    }

    // MARK: - vd-tool preview (`-d`, debug or `VectifyAppDelegate.showPreviewFlag` / env)

    func canOpenVdToolPreview(for row: ConversionRowModel) -> Bool {
        guard VdToolPreviewGate.isEnabled else { return false }
        guard row.status == .ok,
            let name = row.outputFileName,
            let outDir = outputFolderURL
        else { return false }
        let xml = outDir.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: xml.path)
    }

    /// Opens bundled vd-tool in display mode for the row’s output XML (blocking subprocess until the preview window closes).
    func openVdToolPreview(for row: ConversionRowModel) {
        guard VdToolPreviewGate.isEnabled else { return }
        guard let outDir = outputFolderURL,
            let outName = row.outputFileName
        else { return }
        let xml = outDir.appendingPathComponent(outName)
        guard FileManager.default.fileExists(atPath: xml.path) else {
            appendLog("vd-tool preview: missing \(outName)")
            return
        }

        let scoped = outDir.startAccessingSecurityScopedResource()
        Task {
            defer {
                if scoped {
                    outDir.stopAccessingSecurityScopedResource()
                }
            }
            do {
                try await Task.detached(priority: .userInitiated) {
                    try JavaVdToolRunner.displayVectorDrawable(at: xml)
                }.value
            } catch {
                appendLog("vd-tool preview failed: \(error.localizedDescription)")
            }
        }
    }
}

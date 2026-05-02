import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class RepairViewModel {
    var folderURL: URL?
    /// One row per `<vector>` XML in the selected folder (non-recursive).
    var rows: [VectorDrawablePostProcessor.DrawableRepairOutcome] = []
    var logLines: [String] = []
    var isRepairing = false

    /// After at least one **Repair All** finishes, sidebar metrics reflect the last run.
    private(set) var hasCompletedRepairRun = false
    /// Share of vector files that needed no change after last run (0...1). Honest UX: `unchanged / total`.
    private(set) var lastHealthOptimizedFraction: Double = 1
    private(set) var lastTotalVectorFiles: Int = 0
    /// Files written in the last repair run.
    private(set) var lastFixedCount: Int = 0

    var folderPathDisplay: String {
        folderURL?.path ?? ""
    }

    /// Health ring: `unchanged / total` after last repair (higher = more already optimal).
    var healthPercentDisplay: Int {
        guard lastTotalVectorFiles > 0 else { return 0 }
        return Int((lastHealthOptimizedFraction * 100).rounded(.toNearestOrAwayFromZero))
    }

    func logText() -> String {
        logLines.joined(separator: "\n")
    }

    func chooseFolder() {
        let p = NSOpenPanel()
        p.canChooseDirectories = true
        p.canChooseFiles = false
        p.prompt = "Folder containing VectorDrawable XML"
        guard p.runModal() == .OK, let url = p.url else { return }
        _ = url.startAccessingSecurityScopedResource()
        folderURL = url
        rescanFolder()
    }

    func rescanFolder() {
        guard let dir = folderURL else {
            rows = []
            lastTotalVectorFiles = 0
            lastFixedCount = 0
            lastHealthOptimizedFraction = 1
            hasCompletedRepairRun = false
            return
        }
        do {
            let names = try VectorDrawablePostProcessor.listVectorDrawableXMLFiles(in: dir)
            rows = names.map { name in
                VectorDrawablePostProcessor.DrawableRepairOutcome(
                    fileName: name,
                    status: .pending,
                    changelog: "—"
                )
            }
            lastTotalVectorFiles = rows.count
            hasCompletedRepairRun = false
            lastFixedCount = 0
            lastHealthOptimizedFraction = 1
            appendLog("Scanned \(rows.count) vector XML file(s) in folder.")
        } catch {
            rows = []
            appendLog("Scan failed: \(error.localizedDescription)")
            hasCompletedRepairRun = false
        }
    }

    func repairAll() async {
        guard let dir = folderURL else { return }
        isRepairing = true
        defer { isRepairing = false }

        let scoped = dir.startAccessingSecurityScopedResource()
        defer {
            if scoped { dir.stopAccessingSecurityScopedResource() }
        }

        appendLog("Starting repair…")
        do {
            let outcomes = try VectorDrawablePostProcessor.repairDrawablesDetailed(in: dir)
            rows = outcomes
            lastTotalVectorFiles = outcomes.count
            lastFixedCount = outcomes.filter { $0.status == .fixed }.count
            let unchanged = outcomes.filter { $0.status == .unchanged }.count
            if outcomes.isEmpty {
                lastHealthOptimizedFraction = 1
            } else {
                lastHealthOptimizedFraction = Double(unchanged) / Double(outcomes.count)
            }

            for o in outcomes {
                switch o.status {
                case .fixed:
                    appendLog("\(o.fileName): fixed — \(o.changelog)")
                case .unchanged:
                    appendLog("\(o.fileName): no changes needed.")
                case .failed:
                    appendLog("\(o.fileName): failed — \(o.changelog)")
                case .pending:
                    appendLog("\(o.fileName): pending")
                }
            }
            appendLog(
                "Summary: \(outcomes.count) file(s), \(lastFixedCount) updated, \(unchanged) unchanged, \(outcomes.filter { $0.status == .failed }.count) failed."
            )
            hasCompletedRepairRun = true
        } catch {
            appendLog("Repair failed: \(error.localizedDescription)")
            hasCompletedRepairRun = true
        }
    }

    func clearLog() {
        logLines = []
    }

    func revealInFinder() {
        guard let url = folderURL else { return }
        NSWorkspace.shared.open(url)
    }

    private func appendLog(_ line: String) {
        let ts = Self.logTimestamp()
        logLines.append("[\(ts)] \(line)")
    }

    private static func logTimestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: Date())
    }
}

import AppKit
import SwiftUI

/// Snapshot loaded once per appearance to avoid AttributeGraph cycles from
/// `@State` initializers + `onAppear` both mutating the same values in one update pass.
private struct EnvironmentDiagnosticsSnapshot: Sendable {
    let java: JavaRuntimeInfo
    let vd: VdToolLocation
    let node: Bool
}

struct EnvironmentDiagnosticsView: View {
    @State private var snapshot: EnvironmentDiagnosticsSnapshot?

    var body: some View {
        Group {
            if let snapshot {
                loadedContent(snapshot: snapshot)
            } else {
                ProgressView("Checking environment…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.canvas)
        .foregroundStyle(AppTheme.body)
        .task {
            let java = PrerequisiteChecker.javaRuntime()
            let vd = PrerequisiteChecker.vdToolLocation()
            let node = PrerequisiteChecker.nodeAvailable()
            snapshot = EnvironmentDiagnosticsSnapshot(java: java, vd: vd, node: node)
        }
    }

    @ViewBuilder
    private func loadedContent(snapshot: EnvironmentDiagnosticsSnapshot) -> some View {
        let java = snapshot.java
        let vd = snapshot.vd
        let node = snapshot.node

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Environment")
                    .font(.title2.weight(.semibold))
                Text("Distribution tier A: bundled vd-tool; you provide Java 8+. Optional SVGO needs Node when enabled.")
                    .font(.callout)
                    .foregroundStyle(AppTheme.secondary)

                GroupBox("Java") {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(java.isInstalled ? "Installed" : "Not found", systemImage: java.isInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(java.isInstalled ? AppTheme.success : AppTheme.error)
                        if let note = java.detectionNote {
                            Text(note)
                                .font(.callout)
                                .foregroundStyle(AppTheme.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if let v = java.versionLine { Text(v).font(.system(.body, design: .monospaced)) }
                        if let h = java.javaHome { Text(h).font(.system(.caption, design: .monospaced)).textSelection(.enabled) }
                    }
                }

                GroupBox("vd-tool (bundled)") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(vd.isBundled ? "Vendor layout OK (pin 4.0.2): bin/vd-tool + lib/*.jar" : "Bundled vd-tool missing or incomplete — run ./scripts/fetch-vd-tool.sh")
                            .foregroundStyle(vd.isBundled ? AppTheme.success : AppTheme.error)
                        if let p = vd.bundledLauncherPath {
                            Text(p).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                        }
                    }
                }

                GroupBox("Node (SVGO)") {
                    Text(node ? "node / npx available" : "Not detected on PATH (SVGO toggle will fail until Node is installed)")
                        .foregroundStyle(node ? AppTheme.success : AppTheme.secondary)
                }

                Button("Copy diagnostics") {
                    let t = PrerequisiteChecker.diagnosticsText(java: java, vd: vd, node: node)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(t, forType: .string)
                }
                .buttonStyle(.borderedProminent)

                Button("Install Java (Temurin)…") {
                    if let url = URL(string: "https://adoptium.net/temurin/releases/") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
            }
            .padding(24)
        }
    }
}

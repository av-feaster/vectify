import AppKit
import SwiftUI

struct RepairView: View {
    @State private var folderURL: URL?
    @State private var statusMessage = ""
    @State private var isRepairing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Repair drawable XML")
                .font(.title2.weight(.semibold))
            Text(
                "Runs the same post-processing as the Python `finalize_vector_xml_bytes` on each `<vector>` XML in the chosen folder (in place)."
            )
            .foregroundStyle(AppTheme.secondary)

            HStack {
                Button("Choose input folder…") {
                    let p = NSOpenPanel()
                    p.canChooseDirectories = true
                    p.canChooseFiles = false
                    p.prompt = "Folder containing vector XML"
                    if p.runModal() == .OK, let url = p.url {
                        _ = url.startAccessingSecurityScopedResource()
                        folderURL = url
                    }
                }
                if let u = folderURL {
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: u.path)
                    }
                }
            }

            if let path = folderURL?.path {
                Text(path)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }

            Button("Repair all") {
                guard let dir = folderURL else { return }
                isRepairing = true
                statusMessage = ""
                Task {
                    let scoped = dir.startAccessingSecurityScopedResource()
                    defer {
                        if scoped { dir.stopAccessingSecurityScopedResource() }
                    }
                    do {
                        let n = try VectorDrawablePostProcessor.repairDrawables(in: dir)
                        await MainActor.run {
                            statusMessage = "Repaired \(n) file(s)."
                            isRepairing = false
                        }
                    } catch {
                        await MainActor.run {
                            statusMessage = error.localizedDescription
                            isRepairing = false
                        }
                    }
                }
            }
            .disabled(folderURL == nil || isRepairing)

            Text(statusMessage)
                .foregroundStyle(statusMessage.contains("Repaired") ? AppTheme.success : AppTheme.error)

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.canvas)
        .foregroundStyle(AppTheme.body)
    }
}

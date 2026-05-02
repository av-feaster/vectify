import AppKit
import Observation
import SwiftUI
import UniformTypeIdentifiers

/// Instant convert workspace from `stitch_svg_vector_toolbox/instant_dark_mode/code.html`.
struct InstantView: View {
    @Bindable var model: InstantViewModel
    @Environment(\.presentToast) private var presentToast

    private var convertedCount: Int {
        model.items.filter { $0.status == .converted }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            instantTopBar

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    dropZoneSection

                    sessionSection

                    footerBento

                    activityLogSection
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.canvas)
        .foregroundStyle(AppTheme.body)
        .navigationTitle("Instant")
    }

    // MARK: - Top bar

    private var instantTopBar: some View {
        HStack(spacing: 12) {
            Text("Instant Convert")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(AppTheme.onSurface)

            Rectangle()
                .fill(AppTheme.borderHairline)
                .frame(width: 1, height: 16)

            Text("Local session")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.outline)
                .tracking(1.2)
                .textCase(.uppercase)

            Spacer()

            Toggle(isOn: $model.applySvgo) {
                Text("SVGO")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.navInactive)
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .tint(AppTheme.primaryContainer)
            .help("Optional Node-based SVG shrink before vd-tool")

            Button {
                presentToast("Coming soon")
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppTheme.navInactive)
                    .padding(6)
            }
            .buttonStyle(.plain)
            .help("Settings — shows a toast until preferences ship")
        }
        .padding(.horizontal, 24)
        .frame(height: 48)
        .background(topBarChrome)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.sidebarDivider)
                .frame(height: 1)
        }
    }

    private var topBarChrome: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Rectangle().fill(AppTheme.sidebarSurface.opacity(0.55))
        }
    }

    // MARK: - Drop zone

    private var dropZoneSection: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        AppTheme.primaryContainer.opacity(model.fileDropHover ? 0.55 : 0.22),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                    )

                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.primaryContainer.opacity(0.12))
                            .frame(width: 64, height: 64)
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(AppTheme.primaryContainer)
                            .symbolRenderingMode(.hierarchical)
                    }

                    Text("Drop SVGs here to convert instantly")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.onSurface)

                    Text("Fast, in-session conversion to Android VectorDrawable XML. Nothing is uploaded; output stays in memory until you save or export a ZIP.")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.outline)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)

                    Button {
                        model.chooseSVGFiles()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Select Files")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.onSurface)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AppTheme.borderSubtle, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.vertical, 36)
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .onDrop(of: [.fileURL], isTargeted: $model.fileDropHover) { providers in
                handleDrop(providers: providers)
            }
        }
    }

    // MARK: - Session

    private var sessionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                HStack(spacing: 10) {
                    Text("Current session")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.onSurface)
                    Text("\(model.items.count) files")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.outline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.06))
                        )
                }
                Spacer()
                HStack(spacing: 10) {
                    Button("Clear session") {
                        model.clearSession()
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.outline)
                    .buttonStyle(.plain)

                    Button {
                        model.downloadAllAsZip()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Download All (ZIP)")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(convertedCount > 0 ? AppTheme.onPrimaryContainer : Color(red: 0.42, green: 0.44, blue: 0.48))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(convertedCount > 0 ? AppTheme.primaryContainer : Color.white.opacity(0.05))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(convertedCount == 0 || model.isConverting)
                }
            }

            VStack(spacing: 0) {
                if model.items.isEmpty {
                    Text("No files in this session yet.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.navInactive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                } else {
                    ForEach(model.items) { item in
                        sessionRow(item)
                        if item.id != model.items.last?.id {
                            Divider()
                                .overlay(AppTheme.borderHairline)
                        }
                    }
                }
            }
            .background(AppTheme.surface.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppTheme.borderSubtle, lineWidth: 1)
            )
        }
    }

    private func sessionRow(_ item: InstantSessionItem) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.25))
                    .frame(width: 44, height: 44)
                Image(systemName: "square.stack.3d.up")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.outline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.onSurface)
                    .lineLimit(1)
                Text("\(item.sizeLabel) • \(item.status.rawValue.uppercased())")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(AppTheme.outline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            statusPill(for: item)

            if item.status == .converted && item.xmlData != nil {
                Button {
                    model.saveItemXML(item)
                } label: {
                    HStack(spacing: 4) {
                        Text("Download .xml")
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(AppTheme.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.02))
    }

    @ViewBuilder
    private func statusPill(for item: InstantSessionItem) -> some View {
        switch item.status {
        case .converted:
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: 6, height: 6)
                Text("Converted")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.green.opacity(0.9))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.green.opacity(0.12)))
        case .failed:
            HStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.error)
                    .frame(width: 6, height: 6)
                Text("Failed")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.error)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(AppTheme.error.opacity(0.12)))
        case .converting:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.85)
                Text("Converting")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.outline)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.06)))
        case .queued:
            HStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.outline.opacity(0.5))
                    .frame(width: 6, height: 6)
                Text("Queued")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.outline)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.06)))
        }
    }

    // MARK: - Footer bento

    private var footerBento: some View {
        HStack(alignment: .top, spacing: 14) {
            infoCard(
                symbol: "lock.shield",
                title: "Local privacy",
                body: "No cloud upload. vd-tool and optional SVGO run on your Mac; XML is held in memory until you export."
            )
            infoCard(
                symbol: "iphone",
                title: "Android optimized",
                body: "Output is VectorDrawable XML suitable for composeResources/drawable and the same post-processing as batch Convert."
            )
            infoCard(
                symbol: "cpu",
                title: "In-session engine",
                body: "Each file is converted in a temporary folder, finalized, then discarded—only results you save are written to disk."
            )
        }
    }

    private func infoCard(symbol: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.outline)
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.onSurface)
            Text(body)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(AppTheme.surface.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Activity log

    private var activityLogSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Activity")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.82, green: 0.84, blue: 0.88))
                Spacer()
                HStack(spacing: 0) {
                    Button("Clear") { model.clearLog() }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.outline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    Rectangle()
                        .fill(AppTheme.borderHairline)
                        .frame(width: 1, height: 12)
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(model.logText(), forType: .string)
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.outline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.2))

            ScrollView {
                Text(logBody)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(AppTheme.outline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(14)
            }
            .frame(minHeight: 100, maxHeight: 180)
            .background(Color.black.opacity(0.12))
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }

    private var logBody: String {
        let t = model.logText()
        if t.isEmpty {
            return "[SYSTEM] Ready — drop SVGs or use Select Files."
        }
        return t
    }

    // MARK: - Drop

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !providers.isEmpty else { return false }
        Task { @MainActor in
            var urls: [URL] = []
            for provider in providers where provider.canLoadObject(ofClass: URL.self) {
                let url: URL? = await withCheckedContinuation { continuation in
                    _ = provider.loadObject(ofClass: URL.self) { object, _ in
                        continuation.resume(returning: object as? URL)
                    }
                }
                if let url {
                    urls.append(url)
                }
            }
            let svgs = urls.filter { $0.pathExtension.lowercased() == "svg" }
            if svgs.isEmpty, !urls.isEmpty {
                model.appendInfoLog("Drop contained no SVG files.")
            } else {
                model.importURLs(svgs)
            }
        }
        return true
    }
}

struct InstantView_Previews: PreviewProvider {
    static var previews: some View {
        InstantView(model: InstantViewModel())
            .frame(width: 900, height: 800)
    }
}

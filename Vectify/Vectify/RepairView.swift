import AppKit
import Observation
import SwiftUI

/// Repair workspace aligned with `stitch_svg_vector_toolbox/repair_tool_dark_mode/code.html`.
struct RepairView: View {
    @Bindable var model: RepairViewModel

    private var canRepair: Bool {
        model.folderURL != nil && !model.rows.isEmpty && !model.isRepairing
    }

    var body: some View {
        VStack(spacing: 0) {
            repairTopBar

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    actionBarCard

                    HStack(alignment: .top, spacing: 16) {
                        fileStatusCard
                            .layoutPriority(2)
                        sidebarColumn
                            .frame(minWidth: 220, idealWidth: 260, maxWidth: 300)
                            .layoutPriority(1)
                    }

                    processLogSection
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.canvas)
        .foregroundStyle(AppTheme.body)
        .navigationTitle("Repair")
    }

    // MARK: - Top bar

    private var repairTopBar: some View {
        HStack(spacing: 16) {
            Spacer()

            Button {
                model.revealInFinder()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.system(size: 15, weight: .regular))
                    Text("Reveal in Finder")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(model.folderURL == nil ? AppTheme.outline : AppTheme.navInactive)
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .disabled(model.folderURL == nil)
            .opacity(model.folderURL == nil ? 0.45 : 1)

            Button {
                // Reserved for future repair preferences
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppTheme.navInactive)
                    .padding(6)
            }
            .buttonStyle(.plain)
            .help("Settings (coming soon)")
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

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Vector Repair")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.onSurface)
            Text("Select a Drawable folder to fix XML issues (viewport / stroke-fill parity).")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.outline)
        }
    }

    // MARK: - Action bar

    private var actionBarCard: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.outline)
                Text(model.folderPathDisplay.isEmpty ? "No folder selected" : model.folderPathDisplay)
                    .font(.system(size: 12))
                    .foregroundStyle(model.folderPathDisplay.isEmpty ? AppTheme.outline : Color(red: 0.78, green: 0.80, blue: 0.84))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.borderHairline, lineWidth: 1)
            )

            Button {
                model.chooseFolder()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 14, weight: .medium))
                    Text("Browse")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(AppTheme.onSurface)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                Task { await model.repairAll() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Repair All")
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .foregroundStyle(canRepair ? AppTheme.onPrimaryContainer : Color(red: 0.42, green: 0.44, blue: 0.48))
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(canRepair ? AppTheme.primaryContainer : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(canRepair ? Color.clear : AppTheme.borderSubtle, lineWidth: 1)
            )
            .disabled(!canRepair)
            .animation(.easeOut(duration: 0.15), value: canRepair)
        }
        .padding(14)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - File status

    private var fileStatusCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("File status")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.outline)
                    .tracking(0.5)
                    .textCase(.uppercase)
                Spacer()
                Text("\(model.rows.count) file(s) found")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryContainer)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.15))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppTheme.borderSubtle)
                    .frame(height: 1)
            }

            if model.rows.isEmpty {
                emptyFileStatusPlaceholder
            } else {
                Table(model.rows) {
                    TableColumn("Filename") { row in
                        Text(row.fileName)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(AppTheme.body)
                    }
                    .width(min: 100, ideal: 160)

                    TableColumn("Status") { row in
                        statusCell(for: row.status)
                    }
                    .width(ideal: 150)

                    TableColumn("Changelog") { row in
                        Text(row.changelog)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.secondary)
                            .italic(row.status == .fixed)
                            .lineLimit(2)
                    }
                }
                .tableStyle(.inset(alternatesRowBackgrounds: false))
                .frame(minHeight: 240)
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }

    private var emptyFileStatusPlaceholder: some View {
        VStack(spacing: 10) {
            Text(model.folderURL == nil ? "Choose a folder containing VectorDrawable XML." : "No `<vector>` XML files in this folder.")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.navInactive)
                .multilineTextAlignment(.center)
                .padding(.vertical, 40)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func statusCell(for status: VectorDrawablePostProcessor.DrawableRepairStatus) -> some View {
        switch status {
        case .fixed:
            HStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.primaryContainer)
                    .frame(width: 6, height: 6)
                Text("Fixed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.primaryContainer)
            }
        case .unchanged:
            HStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.outline)
                    .frame(width: 6, height: 6)
                Text("No changes needed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.outline)
            }
        case .pending:
            HStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.outline.opacity(0.5))
                    .frame(width: 6, height: 6)
                Text("Pending")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.outline)
            }
        case .failed:
            HStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.error)
                    .frame(width: 6, height: 6)
                Text("Failed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.error)
            }
        }
    }

    // MARK: - Sidebar

    private var sidebarColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            optimizationHealthCard
            proTipCard
        }
    }

    /// Ring shows **unchanged / total** after a repair run (higher = more files already optimal).
    private var optimizationHealthCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optimization health")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.outline)
                .tracking(0.5)
                .textCase(.uppercase)

            ZStack {
                Circle()
                    .stroke(AppTheme.outline.opacity(0.2), lineWidth: 10)
                    .frame(width: 112, height: 112)

                if model.hasCompletedRepairRun && model.lastTotalVectorFiles > 0 {
                    Circle()
                        .trim(from: 0, to: CGFloat(model.lastHealthOptimizedFraction))
                        .stroke(AppTheme.primaryContainer, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 112, height: 112)
                }

                VStack(spacing: 2) {
                    if model.hasCompletedRepairRun && model.lastTotalVectorFiles > 0 {
                        Text("\(model.healthPercentDisplay)%")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(AppTheme.onSurface)
                        Text("Optimized")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.outline)
                    } else {
                        Text("—")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(AppTheme.onSurface)
                        Text("Run repair")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.outline)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)

            VStack(spacing: 8) {
                HStack {
                    Text("Total assets")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.outline)
                    Spacer()
                    Text("\(model.lastTotalVectorFiles > 0 ? model.lastTotalVectorFiles : model.rows.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.onSurface)
                }
                HStack {
                    Text("Issues addressed")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.outline)
                    Spacer()
                    Text("\(model.hasCompletedRepairRun ? model.lastFixedCount : 0)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(model.lastFixedCount > 0 ? AppTheme.error : AppTheme.onSurface)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }

    private var proTipCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.max.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(red: 0.65, green: 0.58, blue: 1.0))
                Text("Pro tip")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.onSurface)
            }
            Text("Consistent viewports prevent scaling artifacts on high-density Android displays.")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.12, green: 0.11, blue: 0.22).opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(red: 0.35, green: 0.32, blue: 0.55).opacity(0.45), lineWidth: 1)
        )
    }

    // MARK: - Process logs

    private var processLogSection: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "terminal")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.navInactive)
                    Text("Process logs")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(red: 0.82, green: 0.84, blue: 0.88))
                }
                Spacer()
                HStack(spacing: 0) {
                    Button("Clear logs") { model.clearLog() }
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
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.2))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppTheme.borderSubtle)
                    .frame(height: 1)
            }

            ScrollView {
                Text(logBody)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(AppTheme.outline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(16)
            }
            .frame(minHeight: 120, maxHeight: 220)
            .background(Color.black.opacity(0.1))
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }

    private var logBody: String {
        let t = model.logText()
        if t.isEmpty { return "Ready — choose a folder, then run Repair All." }
        return t
    }
}

struct RepairView_Previews: PreviewProvider {
    static var previews: some View {
        RepairView(model: RepairViewModel())
            .frame(width: 900, height: 700)
    }
}

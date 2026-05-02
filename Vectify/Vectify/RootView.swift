import SwiftUI

private enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case convert
    case repair
    case environment
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .convert: return "Convert"
        case .repair: return "Repair"
        case .environment: return "Environment"
        case .about: return "About"
        }
    }

    var symbol: String {
        switch self {
        case .convert: return "arrow.triangle.2.circlepath"
        case .repair: return "hammer"
        case .environment: return "gearshape.2"
        case .about: return "info.circle"
        }
    }
}

/// Sidebar row matching `convert_initial_dark_mode`: inactive gray, hover white/5%, active `primary-container` + white.
private struct StitchSidebarRow: View {
    let section: SidebarSection
    let isSelected: Bool
    @Binding var hovered: SidebarSection?
    let action: () -> Void

    private var isHovered: Bool { hovered == section }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: section.symbol)
                    .font(.system(size: 16, weight: .regular))
                    .frame(width: 20, alignment: .center)
                    .symbolRenderingMode(.hierarchical)
                Text(section.title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(foreground)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .shadow(color: shadowColor, radius: isSelected ? 6 : 0, x: 0, y: isSelected ? 3 : 0)
        }
        .buttonStyle(.plain)
        .onHover { inside in
            if inside {
                hovered = section
            } else if hovered == section {
                hovered = nil
            }
        }
    }

    private var foreground: Color {
        if isSelected { return AppTheme.onPrimaryContainer }
        if isHovered { return AppTheme.onSurface }
        return AppTheme.navInactive
    }

    @ViewBuilder
    private var background: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(AppTheme.primaryContainer)
        } else if isHovered {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.05))
        } else {
            Color.clear
        }
    }

    private var shadowColor: Color {
        isSelected ? AppTheme.primaryContainer.opacity(0.35) : .clear
    }
}

struct RootView: View {
    @State private var selection: SidebarSection = .convert
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var conversionModel = ConversionViewModel()
    @State private var showJavaOverlay: Bool
    @State private var hoveredSidebar: SidebarSection?

    init() {
        let java = PrerequisiteChecker.javaRuntime()
        _showJavaOverlay = State(initialValue: !java.isInstalled)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection {
        case .convert:
            ConvertView(model: conversionModel)
        case .repair:
            RepairView()
        case .environment:
            EnvironmentDiagnosticsView()
        case .about:
            AboutView()
        }
    }

    private var stitchSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Vectify")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(AppTheme.primaryContainer)
                    .tracking(-0.3)
                Text("SVG to Android Vector")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.outline)
                    .tracking(1.2)
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(SidebarSection.allCases) { item in
                    StitchSidebarRow(
                        section: item,
                        isSelected: selection == item,
                        hovered: $hoveredSidebar
                    ) {
                        selection = item
                    }
                }
            }
            .padding(.horizontal, 4)

            Spacer(minLength: 0)
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(sidebarChrome)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(AppTheme.sidebarDivider)
                .frame(width: 1)
        }
    }

    /// `glass-sidebar` + dark tint: material under a thin `sidebarSurface` veil.
    private var sidebarChrome: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Rectangle().fill(AppTheme.sidebarSurface.opacity(0.78))
        }
        .ignoresSafeArea(edges: .vertical)
    }

    var body: some View {
        ZStack(alignment: .center) {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                stitchSidebar
                    .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
            } detail: {
                detailContent
                    .id(selection)
                    .navigationTitle(selection.title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .tint(AppTheme.primaryContainer)

            if showJavaOverlay {
                JavaRequiredOverlay {
                    showJavaOverlay = false
                }
                .transition(.opacity)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .preferredColorScheme(.dark)
        .onAppear {
            let java = PrerequisiteChecker.javaRuntime()
            if java.isInstalled {
                showJavaOverlay = false
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}

import SwiftUI

// MARK: - App toast (settings “coming soon”, etc.)

private struct PresentToastKey: EnvironmentKey {
    static let defaultValue: (String) -> Void = { _ in }
}

extension EnvironmentValues {
    /// Show a short banner toast at the top of the window (host: `RootView`).
    var presentToast: (String) -> Void {
        get { self[PresentToastKey.self] }
        set { self[PresentToastKey.self] = newValue }
    }
}

private struct ToastBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppTheme.onSurface)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.surfaceContainer)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AppTheme.borderSubtle, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 18, y: 8)
    }
}

private enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case convert
    case instant
    case repair
    case environment
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .convert: return "Convert"
        case .instant: return "Instant"
        case .repair: return "Repair"
        case .environment: return "Environment"
        case .about: return "About"
        }
    }

    var symbol: String {
        switch self {
        case .convert: return "arrow.triangle.2.circlepath"
        case .instant: return "bolt.fill"
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
    @State private var instantModel = InstantViewModel()
    @State private var repairModel = RepairViewModel()
    @State private var showJavaOverlay: Bool
    @State private var hoveredSidebar: SidebarSection?
    @State private var toastMessage: String?
    @State private var toastDismissTask: Task<Void, Never>?

    init() {
        let java = PrerequisiteChecker.javaRuntime()
        _showJavaOverlay = State(initialValue: !java.isInstalled)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection {
        case .convert:
            ConvertView(model: conversionModel)
        case .instant:
            InstantView(model: instantModel)
        case .repair:
            RepairView(model: repairModel)
        case .environment:
            EnvironmentDiagnosticsView()
        case .about:
            AboutView()
        }
    }

    private var stitchSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Image("vectify_main")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppTheme.borderHairline, lineWidth: 1)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Vectify")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryContainer)
                        .tracking(-0.2)
                    Text("SVG to Android Vector")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.outline)
                        .tracking(1.2)
                        .textCase(.uppercase)
                }
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .tint(AppTheme.primaryContainer)

            if showJavaOverlay {
                JavaRequiredOverlay {
                    showJavaOverlay = false
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .overlay(alignment: .top) {
            if let toastMessage {
                HStack {
                    Spacer(minLength: 0)
                    ToastBanner(message: toastMessage)
                    Spacer(minLength: 0)
                }
                .padding(.top, 12)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    )
                )
                .allowsHitTesting(false)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.84), value: toastMessage)
        .environment(\.presentToast, scheduleToast)
        .frame(minWidth: 900, minHeight: 600)
        .preferredColorScheme(.dark)
        .onAppear {
            let java = PrerequisiteChecker.javaRuntime()
            if java.isInstalled {
                showJavaOverlay = false
            }
        }
    }

    private func scheduleToast(_ message: String) {
        toastDismissTask?.cancel()
        toastMessage = message
        toastDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.1))
            guard !Task.isCancelled else { return }
            toastMessage = nil
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}

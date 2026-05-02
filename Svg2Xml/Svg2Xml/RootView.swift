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

struct RootView: View {
    @State private var selection: SidebarSection = .convert
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var conversionModel = ConversionViewModel()
    @State private var showJavaOverlay: Bool

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

    var body: some View {
        ZStack(alignment: .center) {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                // Avoid `List(selection:)` on macOS: the highlight can desync from `@State` so the
                // detail column stays on the previous screen while the sidebar shows another row selected.
                List {
                    ForEach(SidebarSection.allCases) { item in
                        Button {
                            selection = item
                        } label: {
                            Label(item.title, systemImage: item.symbol)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(selection == item ? AppTheme.primary.opacity(0.22) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.sidebar)
                .navigationTitle("Svg2Xml")
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
            } detail: {
                detailContent
                    .id(selection)
                    .navigationTitle(selection.title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .tint(AppTheme.primary)

            if showJavaOverlay {
                JavaRequiredOverlay {
                    showJavaOverlay = false
                }
                .transition(.opacity)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
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

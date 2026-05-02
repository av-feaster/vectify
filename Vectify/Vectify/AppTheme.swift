import SwiftUI

/// Dark UI tokens aligned with `stitch_svg_vector_toolbox/*_dark_mode` (Tailwind extend + hardcoded shell).
/// Primary reference: `environment_dark_mode/code.html`; sidebar chrome: `convert_initial_dark_mode/code.html`.
enum AppTheme {
    // Shell
    /// Main canvas `bg-[#121316]`
    static let canvas = Color(red: 0.071, green: 0.075, blue: 0.086)
    /// Sidebar base `bg-[#1a1b1f]/80` — solid here; blur layered in `RootView`
    static let sidebarSurface = Color(red: 0.102, green: 0.106, blue: 0.122)
    /// `border-white/5` sidebar edge
    static let sidebarDivider = Color.white.opacity(0.05)

    // Surfaces (dark tokens from environment_dark_mode)
    static let surfaceContainerLowest = Color(red: 0.059, green: 0.067, blue: 0.082) // #0f1115
    static let surfaceContainerLow = Color(red: 0.102, green: 0.106, blue: 0.122) // #1a1b1f
    static let surface = surfaceContainerLow
    static let surfaceContainer = Color(red: 0.118, green: 0.122, blue: 0.145) // #1e1f25
    static let surfaceContainerHigh = Color(red: 0.157, green: 0.165, blue: 0.184) // #282a2f

    static let borderSubtle = Color.white.opacity(0.10)
    static let borderHairline = Color.white.opacity(0.05)

    // Content
    static let onSurface = Color(red: 0.886, green: 0.886, blue: 0.902) // #e2e2e6
    static let onSurfaceVariant = Color(red: 0.757, green: 0.776, blue: 0.843) // #c1c6d7
    static let outline = Color(red: 0.545, green: 0.569, blue: 0.627) // #8b91a0
    static let outlineVariant = Color(red: 0.255, green: 0.278, blue: 0.333) // #414755

    // Brand / actions
    /// `primary-container` — solid blue for active nav, primary buttons
    static let primaryContainer = Color(red: 0.0, green: 0.439, blue: 0.922) // #0070eb
    static let onPrimaryContainer = Color(red: 0.996, green: 0.988, blue: 1.0) // #fefcff
    /// `primary` on dark — soft accent for icons / links
    static let primary = Color(red: 0.678, green: 0.776, blue: 1.0) // #adc6ff
    static let accentDim = primary

    /// Inactive sidebar labels (`text-gray-400`)
    static let navInactive = Color(red: 0.612, green: 0.639, blue: 0.686) // #9ca3af

    static let body = onSurface
    static let secondary = onSurfaceVariant

    static let success = Color.green.opacity(0.85)
    static let error = Color(red: 1.0, green: 0.706, blue: 0.671) // dark error #ffb4ab-ish
}

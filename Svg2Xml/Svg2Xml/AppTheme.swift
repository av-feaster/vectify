import SwiftUI

/// Dark UI tokens aligned with `stitch_svg_vector_toolbox` / plan §13.
enum AppTheme {
    static let canvas = Color(red: 0.07, green: 0.074, blue: 0.086) // #121316
    static let surface = Color(red: 0.102, green: 0.106, blue: 0.118) // #1a1b1f
    static let borderSubtle = Color.white.opacity(0.08)
    static let primary = Color(red: 0.0, green: 0.345, blue: 0.922) // #0070eb primary-container
    static let onPrimary = Color(red: 0.996, green: 0.988, blue: 1.0)
    static let accentDim = Color(red: 0.678, green: 0.737, blue: 1.0) // #adc6ff
    static let body = Color(red: 0.89, green: 0.89, blue: 0.90)
    static let secondary = Color(red: 0.55, green: 0.57, blue: 0.62)
    static let success = Color.green.opacity(0.85)
    static let error = Color(red: 1.0, green: 0.45, blue: 0.42)
}

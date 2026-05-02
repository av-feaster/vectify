import SwiftUI

struct AboutView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Svg2Xml")
                .font(.largeTitle.weight(.bold))
            Text("VectorConverter — SVG to Android VectorDrawable XML for Compose resources.")
                .foregroundStyle(AppTheme.secondary)
            Text("Version \(version) (\(build))")
            Divider()
            Text("Tier A: bundled vd-tool 4.0.2 (MIT). Install Java 8+ separately (e.g. Temurin). Optional SVGO uses Node when turned on.")
                .font(.callout)
            Link("vd-tool on npm", destination: URL(string: "https://www.npmjs.com/package/vd-tool")!)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.canvas)
        .foregroundStyle(AppTheme.body)
    }
}

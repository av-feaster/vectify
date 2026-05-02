import SwiftUI

struct JavaRequiredOverlay: View {
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.accentDim)
                Text("Java is required")
                    .font(.title2.weight(.semibold))
                Text("Install a JDK (Temurin 17+ recommended), or set JAVA_HOME to an existing JDK. Java 8+ is compatible with bundled vd-tool. Open Environment after installing to verify detection.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.secondary)
                HStack {
                    Link("Download Temurin", destination: URL(string: "https://adoptium.net/temurin/releases/")!)
                        .buttonStyle(.borderedProminent)
                    Button("Continue anyway") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(32)
            .frame(maxWidth: 420)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.borderSubtle, lineWidth: 1)
            )
        }
    }
}

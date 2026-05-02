import Observation
import SwiftUI

struct ConvertView: View {
    @Bindable var model: ConversionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("Choose input folder…") { model.chooseInputFolder() }
                Button("Choose output folder…") { model.chooseOutputFolder() }
                Spacer()
                Button("Convert") {
                    Task { await model.convertAll() }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
                .disabled(!model.canConvert)
            }

            HStack(alignment: .top, spacing: 16) {
                folderCard(title: "Input folder", path: model.inputFolderURL?.path ?? "None")
                folderCard(title: "Output folder", path: model.outputFolderURL?.path ?? "None")
            }

            Toggle("Apply SVGO first (requires Node / npx)", isOn: $model.applySvgo)
            Toggle("Overwrite existing XML (no _1 / _2 suffix)", isOn: $model.overwrite)

            Table(model.rows) {
                TableColumn("Name") { row in Text(row.name) }
                TableColumn("Status") { row in Text(row.status.rawValue) }
                TableColumn("Output") { row in Text(row.outputFileName ?? "—") }
                TableColumn("Message") { row in Text(row.message).lineLimit(2) }
            }
            .frame(minHeight: 200)

            HStack {
                Text("Conversion log")
                    .font(.headline)
                Spacer()
                Button("Clear") { model.clearLog() }
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(model.logText(), forType: .string)
                }
            }
            ScrollView {
                Text(model.logText())
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(minHeight: 120)
            .padding(8)
            .background(AppTheme.surface.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.canvas)
        .foregroundStyle(AppTheme.body)
    }

    private func folderCard(title: String, path: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondary)
            Text(path)
                .font(.callout)
                .lineLimit(2)
                .truncationMode(.middle)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }
}

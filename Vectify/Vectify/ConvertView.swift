import AppKit
import Observation
import SwiftUI
import UniformTypeIdentifiers

/// Convert workspace styled like `stitch_svg_vector_toolbox/convert_initial_dark_mode/code.html`.
struct ConvertView: View {
    @Bindable var model: ConversionViewModel
    @State private var fileDropHover = false
    @State private var showNewProjectSheet = false
    @State private var showRenameSheet = false
    @State private var newProjectNameDraft = ""
    @State private var renameDraft = ""

    private var canRunConvert: Bool {
        model.canConvert && !model.isConverting
    }

    var body: some View {
        VStack(spacing: 0) {
            convertTopBar

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 16) {
                        sourceFolderCard
                        outputFolderCard
                    }

                    engineSettingsStrip

                    fileWorkspaceSection

                    conversionLogSection
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.canvas)
        .foregroundStyle(AppTheme.body)
        .onChange(of: model.applySvgo) { _, _ in
            model.persistActiveProjectSnapshot()
        }
        .onChange(of: model.overwrite) { _, _ in
            model.persistActiveProjectSnapshot()
        }
        .sheet(isPresented: $showNewProjectSheet) {
            newProjectSheet
        }
        .sheet(isPresented: $showRenameSheet) {
            renameProjectSheet
        }
        .navigationTitle("Convert")
    }

    // MARK: - Top bar (`convert_initial_dark_mode` header)

    private var convertTopBar: some View {
        HStack(spacing: 16) {
            projectMenu

            Spacer()

            Button {
                model.chooseInputFolder()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 15, weight: .regular))
                    Text("Open Project")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(AppTheme.navInactive)
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.001))
            )
            .help("Choose source folder for the current project (saved with this project)")

            Button {
                // Reserved for future preferences
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppTheme.navInactive)
                    .padding(6)
            }
            .buttonStyle(.plain)
            .help("Settings (coming soon)")

            Rectangle()
                .fill(AppTheme.borderHairline)
                .frame(width: 1, height: 22)

            convertToolbarButton
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

    private var projectMenu: some View {
        Menu {
            ForEach(model.savedProjects) { project in
                Button {
                    model.selectProject(id: project.id)
                } label: {
                    HStack {
                        if project.id == model.activeProjectID {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.primaryContainer)
                        }
                        Text(project.name)
                    }
                }
            }
            Divider()
            Button("New Project…") {
                newProjectNameDraft = ""
                showNewProjectSheet = true
            }
            Button("Rename…") {
                renameDraft = model.activeProjectName
                showRenameSheet = true
            }
        } label: {
            HStack(spacing: 6) {
                Text(model.activeProjectName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(AppTheme.navInactive)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(AppTheme.borderHairline, lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize(horizontal: true, vertical: false)
        .help("Each project remembers its own input/output folders, toggles, and log.")
    }

    private var newProjectSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New project")
                .font(.system(size: 15, weight: .semibold))
            Text("Folders and log are stored separately per project.")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.secondary)
            TextField("Project name", text: $newProjectNameDraft)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { showNewProjectSheet = false }
                Spacer()
                Button("Create") {
                    model.createProject(name: newProjectNameDraft)
                    showNewProjectSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newProjectNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 300)
    }

    private var renameProjectSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rename project")
                .font(.system(size: 15, weight: .semibold))
            TextField("Name", text: $renameDraft)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { showRenameSheet = false }
                Spacer()
                Button("Save") {
                    model.renameActiveProject(to: renameDraft)
                    showRenameSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(renameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 300)
    }

    private var topBarChrome: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Rectangle().fill(AppTheme.sidebarSurface.opacity(0.55))
        }
    }

    private var convertToolbarButton: some View {
        Button {
            Task { await model.convertAll() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("Convert")
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .foregroundStyle(canRunConvert ? AppTheme.onPrimaryContainer : Color(red: 0.42, green: 0.44, blue: 0.48))
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(canRunConvert ? AppTheme.primaryContainer : Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(canRunConvert ? Color.clear : AppTheme.borderSubtle, lineWidth: 1)
        )
        .disabled(!canRunConvert)
        .animation(.easeOut(duration: 0.15), value: canRunConvert)
    }

    // MARK: - Folder cards

    private var sourceFolderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Source Folder")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.outline)
                    .tracking(0.6)
                    .textCase(.uppercase)
                Spacer()
                Text("REQUIRED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.primaryContainer)
            }

            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.outline)
                    Text(sourcePathDisplay)
                        .font(.system(size: 13))
                        .foregroundStyle(model.inputFolderURL == nil ? AppTheme.outline : Color(red: 0.78, green: 0.80, blue: 0.84))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(AppTheme.borderHairline, lineWidth: 1)
                )

                Button("Reveal in Finder") {
                    if let url = model.inputFolderURL {
                        NSWorkspace.shared.open(url)
                    }
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.onSurface)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
                .buttonStyle(.plain)
                .disabled(model.inputFolderURL == nil)
                .opacity(model.inputFolderURL == nil ? 0.45 : 1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }

    private var sourcePathDisplay: String {
        if let path = model.inputFolderURL?.path, !path.isEmpty { return path }
        return "Choose a source folder…"
    }

    private var outputFolderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Output Folder")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.outline)
                    .tracking(0.6)
                    .textCase(.uppercase)
                Spacer()
                Text("composeResources/drawable")
                    .font(.system(size: 10, weight: .medium))
                    .italic()
                    .foregroundStyle(AppTheme.outline.opacity(0.85))
            }

            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.outline)
                    Text(outputPathDisplay)
                        .font(.system(size: 13))
                        .foregroundStyle(model.outputFolderURL == nil ? AppTheme.outline : Color(red: 0.78, green: 0.80, blue: 0.84))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(AppTheme.borderHairline, lineWidth: 1)
                )

                Button("Choose") {
                    model.chooseOutputFolder()
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.onPrimaryContainer)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AppTheme.primaryContainer)
                )
                .shadow(color: AppTheme.primaryContainer.opacity(0.25), radius: 6, x: 0, y: 2)
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }

    private var outputPathDisplay: String {
        if let path = model.outputFolderURL?.path, !path.isEmpty { return path }
        return "Select destination directory…"
    }

    // MARK: - Engine toggles (same options as before; layout matches Stitch density)

    private var engineSettingsStrip: some View {
        HStack(spacing: 24) {
            Toggle(isOn: $model.applySvgo) {
                Text("SVGO Plugin")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.onSurfaceVariant)
            }
            .toggleStyle(.switch)
            .tint(AppTheme.primaryContainer)

            Toggle(isOn: $model.overwrite) {
                Text("Overwrite")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.onSurfaceVariant)
            }
            .toggleStyle(.switch)
            .tint(AppTheme.primaryContainer)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.surface.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.borderHairline, lineWidth: 1)
        )
    }

    // MARK: - File workspace (table header + empty or rows)

    private var fileWorkspaceSection: some View {
        VStack(spacing: 0) {
            if model.rows.isEmpty {
                tableHeaderRow
                emptyWorkspaceState
            } else {
                Table(model.rows) {
                    TableColumn("Name") { row in
                        Text(row.name)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.body)
                    }
                    .width(min: 120, ideal: 200)

                    TableColumn("Status") { row in
                        Text(row.status.rawValue.capitalized)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.onSurfaceVariant)
                    }
                    .width(ideal: 88)

                    TableColumn("Output") { row in
                        HStack(spacing: 6) {
                            Text(row.outputFileName ?? "—")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(AppTheme.onSurfaceVariant)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            if model.canOpenVdToolPreview(for: row) {
                                Button {
                                    model.openVdToolPreview(for: row)
                                } label: {
                                    Image(systemName: "eye.circle")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(AppTheme.primaryContainer)
                                }
                                .buttonStyle(.plain)
                                .help("Open vd-tool preview for this XML")
                            }
                        }
                    }
                    .width(min: 120, ideal: 180)

                    TableColumn("Message") { row in
                        Text(row.message)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.secondary)
                            .lineLimit(2)
                    }
                }
                .tableStyle(.inset(alternatesRowBackgrounds: false))
                .frame(minHeight: 280)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 400, alignment: .top)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(fileDropHover ? AppTheme.primaryContainer.opacity(0.55) : Color.clear, lineWidth: 2)
        )
        .onDrop(of: [.fileURL], isTargeted: $fileDropHover) { providers in
            handleFolderDrop(providers: providers)
        }
    }

    private var tableHeaderRow: some View {
        HStack(spacing: 0) {
            Text("Name")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Status")
                .frame(width: 100, alignment: .leading)
            Text("Output")
                .frame(width: 140, alignment: .leading)
            Text("Message")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(AppTheme.navInactive)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.2))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.borderSubtle)
                .frame(height: 1)
        }
    }

    private var emptyWorkspaceState: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 32)
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.borderHairline, lineWidth: 1)
                        )
                    Image(systemName: "arrow.up.doc")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.navInactive)
                }

                Text("Choose a folder with SVGs to begin")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.onSurface)

                Text(
                    "Drag and drop a folder here or use the navigation above to select your source directory. We'll automatically scan for SVG files."
                )
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.navInactive)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

                Button {
                    model.chooseInputFolder()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                        Text("Add Files")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.onSurface)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppTheme.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    // MARK: - Log

    private var conversionLogSection: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "terminal")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.navInactive)
                    Text("Conversion Log")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(red: 0.82, green: 0.84, blue: 0.88))
                }
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
            .frame(minHeight: 88)
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
        if t.isEmpty { return "Ready for conversion tasks…" }
        return t
    }

    // MARK: - Drop

    private func handleFolderDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        if provider.canLoadObject(ofClass: URL.self) {
            _ = provider.loadObject(ofClass: URL.self) { object, _ in
                guard let url = object as? URL else { return }
                var isDir: ObjCBool = false
                guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
                    isDir.boolValue
                else { return }
                Task { @MainActor in
                    model.adoptInputFolder(url)
                }
            }
            return true
        }
        return false
    }
}

import SwiftUI
import UniformTypeIdentifiers

public struct AppFileItem: Identifiable {
    public let id: String
    public let name: String
    public let url: URL
    public let isDirectory: Bool
    public let sizeFormatted: String
    public let modificationDate: Date

    public var iconName: String {
        if isDirectory { return "folder.fill" }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "json": return "curlybraces"
        case "txt", "log": return "doc.text.fill"
        case "pdf": return "doc.richtext.fill"
        case "jpg", "jpeg", "png": return "photo.fill"
        case "plist": return "gearshape.2.fill"
        default: return "doc.fill"
        }
    }
}

public struct AppFilesBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentURL: URL
    @State private var files: [AppFileItem] = []
    @State private var selectedFileForPreview: AppFileItem?
    @State private var filePreviewContent: String?

    public init(rootURL: URL? = nil) {
        let defaultURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
        self._currentURL = State(initialValue: rootURL ?? defaultURL)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Directory Corrente
                        LiquidGlassCard(cornerRadius: 16, padding: 12) {
                            HStack {
                                Image(systemName: "folder.badge.gearshape")
                                    .foregroundColor(.brandOrange)
                                Text(currentURL.lastPathComponent)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(files.count) elementi")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if files.isEmpty {
                            LiquidGlassCard(cornerRadius: 18, padding: 24) {
                                VStack(spacing: 8) {
                                    Image(systemName: "tray")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("Nessun file presente in questa cartella.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            ForEach(files) { file in
                                fileRow(file)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Esplora File App")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
            .onAppear {
                loadFiles()
            }
            .sheet(item: $selectedFileForPreview) { item in
                NavigationStack {
                    ZStack {
                        LiquidGlassBackground()

                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                if let text = filePreviewContent {
                                    Text(text)
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(14)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                } else {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, minHeight: 200)
                                }
                            }
                            .padding(16)
                        }
                    }
                    .navigationTitle(item.name)
                    .adaptiveInlineTitle()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            if let text = filePreviewContent {
                                ShareLink(item: text, preview: SharePreview(item.name)) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fatto") { selectedFileForPreview = nil }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func fileRow(_ file: AppFileItem) -> some View {
        LiquidGlassCard(cornerRadius: 16, padding: 12) {
            HStack(spacing: 12) {
                Image(systemName: file.iconName)
                    .font(.title3)
                    .foregroundColor(file.isDirectory ? .blue : .brandOrange)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(file.sizeFormatted)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.5))
                        Text(formattedDate(file.modificationDate))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if file.isDirectory {
                    NavigationLink(destination: AppFilesBrowserView(rootURL: file.url)) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button(action: {
                        openPreview(file)
                    }) {
                        Image(systemName: "eye.fill")
                            .font(.caption)
                            .foregroundColor(.brandOrange)
                            .padding(8)
                            .background(Color.brandOrange.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private func loadFiles() {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return
        }

        self.files = contents.map { url in
            let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey])
            let isDir = resourceValues?.isDirectory ?? false
            let size = resourceValues?.fileSize ?? 0
            let modDate = resourceValues?.contentModificationDate ?? Date()

            let sizeStr = isDir ? "Cartella" : ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)

            return AppFileItem(
                id: url.path,
                name: url.lastPathComponent,
                url: url,
                isDirectory: isDir,
                sizeFormatted: sizeStr,
                modificationDate: modDate
            )
        }.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    private func openPreview(_ file: AppFileItem) {
        selectedFileForPreview = file
        filePreviewContent = nil

        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: file.url),
               let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.filePreviewContent = text
                }
            } else {
                DispatchQueue.main.async {
                    self.filePreviewContent = "Impossibile visualizzare l'anteprima testuale per questo tipo di file (\(file.url.pathExtension))."
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

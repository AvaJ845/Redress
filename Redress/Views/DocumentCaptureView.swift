import SwiftUI
import PhotosUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

struct DocumentCaptureView: View {
    @Bindable var claim: Claim
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingFileImporter = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("This document stays on your device and is only sent when you tap Submit on the official claim portal.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Choose photo", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)

                Button {
                    showingFileImporter = true
                } label: {
                    Label("Choose PDF or file", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isSaving)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Add Document")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task { await savePhoto(newItem) }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.pdf, .image, .plainText],
                allowsMultipleSelection: false
            ) { result in
                saveFile(result)
            }
        }
    }

    private func savePhoto(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        isSaving = true
        persist(Self.downscaled(data))
    }

    /// A single full-resolution photo can run several MB; proof documents
    /// don't need print resolution, so cap the longest edge before it ever
    /// reaches encrypted storage.
    private static func downscaled(_ data: Data, maxDimension: CGFloat = 2000, quality: CGFloat = 0.8) -> Data {
        guard let image = UIImage(data: data) else { return data }
        let longestEdge = max(image.size.width, image.size.height)
        guard longestEdge > maxDimension else { return data }

        let scale = maxDimension / longestEdge
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: quality) ?? data
    }

    private func saveFile(_ result: Result<[URL], Error>) {
        guard let url = try? result.get().first else { return }
        isSaving = true
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Couldn't access that file."
            isSaving = false
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else {
            errorMessage = "Couldn't read that file."
            isSaving = false
            return
        }
        persist(data)
    }

    private func persist(_ data: Data) {
        if let fileName = try? DocumentVault.save(data: data, for: claim.id) {
            claim.documentFileNames.append(fileName)
            context.saveOrLog()
        } else {
            errorMessage = "Couldn't save that document."
        }
        isSaving = false
        if errorMessage == nil { dismiss() }
    }
}

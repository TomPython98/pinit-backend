import SwiftUI
import PhotosUI

struct ImageGalleryView: View {
    @StateObject private var imageManager = ImageManager.shared
    @EnvironmentObject var accountManager: AccountManager
    
    @State private var selectedImageType: UserImage.ImageType = .gallery
    @State private var showingImagePicker = false
    @State private var showingDeleteAlert = false
    @State private var imageToDelete: UserImage?
    @State private var showingCaptionEditor = false
    @State private var imageToCaption: UserImage?
    @State private var newCaption = ""
    
    let username: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Image Type Selector
                Picker("Image Type", selection: $selectedImageType) {
                    ForEach(UserImage.ImageType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.displayName)
                        }
                        .tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Images Grid
                if imageManager.isLoading {
                    ProgressView("Loading images...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredImages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: selectedImageType.icon)
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No \(selectedImageType.displayName.lowercased())s yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Tap the + button to add your first image")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(filteredImages) { image in
                                ImageGridItem(
                                    image: image,
                                    onDelete: { imageToDelete = image; showingDeleteAlert = true },
                                    onSetPrimary: { Task { await imageManager.setPrimaryImage(imageId: image.id, username: username) } },
                                    onEditCaption: { 
                                        imageToCaption = image
                        newCaption = image.caption
                        showingCaptionEditor = true
                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("My Images")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingImagePicker = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: Binding<PhotosPickerItem?>(
                    get: { nil },
                    set: { item in
                        if let item = item {
                            Task {
                                await handleImageSelection(item)
                            }
                        }
                    }
                ),
                matching: .images
            )
            .alert("Delete Image", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let image = imageToDelete {
                        Task {
                            await imageManager.deleteImage(imageId: image.id, username: username)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this image? This action cannot be undone.")
            }
            .sheet(isPresented: $showingCaptionEditor) {
                CaptionEditorView(
                    image: imageToCaption,
                    caption: $newCaption,
                    onSave: { caption in
                        // TODO: Implement caption update
                        showingCaptionEditor = false
                    }
                )
            }
            .onAppear {
                Task {
                    await imageManager.loadUserImages(username: username)
                }
            }
        }
    }
    
    private var filteredImages: [UserImage] {
        imageManager.userImages.filter { $0.imageType == selectedImageType }
    }
    
    private func handleImageSelection(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            return
        }
        
        // Compress image if needed
        let compressedData = compressImage(uiImage, maxSize: 1920)
        
        let request = ImageUploadRequest(
            username: username,
            imageData: compressedData,
            imageType: selectedImageType,
            isPrimary: selectedImageType == .profile && imageManager.getPrimaryImage() == nil,
            caption: "",
            filename: "image_\(Date().timeIntervalSince1970).jpg"
        )
        
        await imageManager.uploadImage(request)
    }
    
    private func compressImage(_ image: UIImage, maxSize: CGFloat) -> Data {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var newSize = size
        if max(size.width, size.height) > maxSize {
            if aspectRatio > 1 {
                newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
            } else {
                newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
            }
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let compressedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return compressedImage.jpegData(compressionQuality: 0.8) ?? Data()
    }
}

// MARK: - Image Grid Item
struct ImageGridItem: View {
    let image: UserImage
    let onDelete: () -> Void
    let onSetPrimary: () -> Void
    let onEditCaption: () -> Void
    
    @State private var showingImageDetail = false
    
    var body: some View {
        AsyncImage(url: URL(string: image.url)) { phase in
            switch phase {
            case .success(let loadedImage):
                loadedImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        VStack {
                            HStack {
                                Spacer()
                                if image.isPrimary {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                        .padding(4)
                                }
                            }
                            Spacer()
                            HStack {
                                Button(action: onEditCaption) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                        .padding(4)
                                }
                                Spacer()
                                Button(action: onDelete) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                        .padding(4)
                                }
                            }
                        }
                    )
                    .onTapGesture {
                        showingImageDetail = true
                    }
            case .failure:
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(8)
            case .empty:
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .overlay(
                        ProgressView()
                    )
                    .cornerRadius(8)
            @unknown default:
                EmptyView()
            }
        }
        .sheet(isPresented: $showingImageDetail) {
            ImageDetailView(image: image, onSetPrimary: onSetPrimary, onDelete: onDelete)
        }
    }
}

// MARK: - Image Detail View
struct ImageDetailView: View {
    let image: UserImage
    let onSetPrimary: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                AsyncImage(url: URL(string: image.url)) { phase in
                    switch phase {
                    case .success(let loadedImage):
                        loadedImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .failure:
                        Text("Failed to load image")
                            .foregroundColor(.red)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(image.imageType.displayName)
                            .font(.headline)
                        Spacer()
                        if image.isPrimary {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Primary")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if !image.caption.isEmpty {
                        Text(image.caption)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Uploaded: \(image.formattedUploadDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Image Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if !image.isPrimary {
                            Button("Set as Primary") {
                                onSetPrimary()
                                dismiss()
                            }
                        }
                        
                        Button("Delete", role: .destructive) {
                            onDelete()
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

// MARK: - Caption Editor
struct CaptionEditorView: View {
    let image: UserImage?
    @Binding var caption: String
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = image {
                    AsyncImage(url: URL(string: image.url)) { phase in
                        switch phase {
                        case .success(let loadedImage):
                            loadedImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 200)
                                .overlay(Text("Failed to load"))
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 200)
                                .overlay(ProgressView())
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                TextField("Add a caption...", text: $caption, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Caption")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(caption)
                    }
                }
            }
        }
    }
}

#Preview {
    ImageGalleryView(username: "testuser")
        .environmentObject(AccountManager())
}

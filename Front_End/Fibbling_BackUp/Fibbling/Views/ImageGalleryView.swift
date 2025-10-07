import SwiftUI
import PhotosUI

struct ImageGalleryView: View {
    @StateObject private var imageManager = ImageManager.shared
    
    @State private var selectedImageType: UserImage.ImageType = .gallery
    @State private var showingImagePicker = false
    @State private var showingDeleteAlert = false
    @State private var imageToDelete: UserImage?
    @State private var showingCaptionEditor = false
    @State private var imageToCaption: UserImage?
    @State private var newCaption = ""
    @State private var searchText = ""
    @State private var showingImageDetail = false
    @State private var selectedImage: UserImage?
    
    let username: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search and filter
                VStack(spacing: 16) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search images...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    
                    // Image Type Selector with modern design
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(UserImage.ImageType.allCases, id: \.self) { type in
                                FilterChip(
                                    title: type.displayName,
                                    icon: type.icon,
                                    isSelected: selectedImageType == type,
                                    count: filteredImages(for: type).count
                                ) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedImageType = type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
                .background(Color(.systemBackground))
                
                // Images Grid with modern layout
                if imageManager.isLoading {
                    LoadingStateView()
                } else if filteredImages.isEmpty {
                    ImageEmptyStateView(
                        imageType: selectedImageType,
                        onAddImage: { showingImagePicker = true }
                    )
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            ForEach(filteredImages) { image in
                                ModernImageGridItem(
                                    image: image,
                                    onDelete: { 
                                        imageToDelete = image
                                        showingDeleteAlert = true 
                                    },
                                    onSetPrimary: { 
                                        Task { 
                                            await imageManager.setPrimaryImage(imageId: image.id, username: username) 
                                        } 
                                    },
                                    onEditCaption: { 
                                        imageToCaption = image
                                        newCaption = image.caption
                                        showingCaptionEditor = true
                                    },
                                    onTap: {
                                        selectedImage = image
                                        showingImageDetail = true
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100) // Extra padding for tab bar
                    }
                }
            }
            .navigationTitle("Photos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingImagePicker = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
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
                ModernCaptionEditorView(
                    image: imageToCaption,
                    caption: $newCaption,
                    onSave: { caption in
                        // TODO: Implement caption update
                        showingCaptionEditor = false
                    }
                )
            }
            .fullScreenCover(isPresented: $showingImageDetail) {
                if let image = selectedImage {
                    ModernImageDetailView(
                        image: image,
                        onSetPrimary: { 
                            Task { 
                                await imageManager.setPrimaryImage(imageId: image.id, username: username) 
                            }
                        },
                        onDelete: { 
                            imageToDelete = image
                            showingDeleteAlert = true
                            showingImageDetail = false
                        }
                    )
                }
            }
            .onAppear {
                Task {
                    await imageManager.loadUserImages(username: username)
                    print("🖼️ Loaded \(imageManager.userImages.count) images for \(username)")
                }
            }
        }
    }
    
    private var filteredImages: [UserImage] {
        let typeFiltered = imageManager.userImages.filter { $0.imageType == selectedImageType }
        
        if searchText.isEmpty {
            return typeFiltered
        } else {
            return typeFiltered.filter { image in
                image.caption.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func filteredImages(for type: UserImage.ImageType) -> [UserImage] {
        imageManager.userImages.filter { $0.imageType == type }
    }
    
    private func handleImageSelection(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            return
        }
        
        // Compress image before upload - IMPORTANT!
        let compressedData = compressImage(uiImage, maxSize: 1920)
        
        // Create ImageUploadRequest
        let request = ImageUploadRequest(
            username: username,
            imageData: compressedData,
            imageType: selectedImageType,
            isPrimary: false, // New images are not primary by default
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
        
        // Initial compression
        return compressedImage.jpegData(compressionQuality: 0.8) ?? Data()
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Loading State View
struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.2)
                .tint(.accentColor)
            
            VStack(spacing: 8) {
                Text("Loading Photos")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Please wait while we load your images")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Image Empty State View
struct ImageEmptyStateView: View {
    let imageType: UserImage.ImageType
    let onAddImage: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: imageType.icon)
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.accentColor)
                }
                
                VStack(spacing: 8) {
                    Text("No \(imageType.displayName.lowercased())s yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Start building your collection by adding your first photo")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            Button(action: onAddImage) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Add Photo")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.accentColor)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Modern Image Grid Item
struct ModernImageGridItem: View {
    let image: UserImage
    let onDelete: () -> Void
    let onSetPrimary: () -> Void
    let onEditCaption: () -> Void
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var showingActions = false
    
    var body: some View {
        let fullURL = ImageManager.shared.getFullImageURL(image)
        
        ZStack {
            // Main image using cached AsyncImage
            ImageManager.shared.cachedAsyncImage(url: fullURL, contentMode: .fill)
                .frame(height: 120)
                .clipped()
                .cornerRadius(12)
            
            // Overlay with actions
            VStack {
                HStack {
                    Spacer()
                    
                    // Primary indicator
                    if image.isPrimary {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.yellow)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack {
                    Button(action: onEditCaption) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    
                    Spacer()
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                }
            }
            .padding(8)
            .opacity(showingActions ? 1 : 0)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.1) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingActions.toggle()
            }
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
        .contextMenu {
            if !image.isPrimary {
                Button("Set as Primary", action: onSetPrimary)
            }
            Button("Edit Caption", action: onEditCaption)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}

// MARK: - Modern Image Detail View
struct ModernImageDetailView: View {
    let image: UserImage
    let onSetPrimary: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingCaptionEditor = false
    @State private var caption = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Image using cached AsyncImage
                    ImageManager.shared.cachedAsyncImage(url: ImageManager.shared.getFullImageURL(image), contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Bottom info panel
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(image.imageType.displayName)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                if image.isPrimary {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                        Text("Primary Photo")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: { showingCaptionEditor = true }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                        
                        if !image.caption.isEmpty {
                            Text(image.caption)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Text("Uploaded \(image.formattedUploadDate)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(20)
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if !image.isPrimary {
                            Button("Set as Primary", action: onSetPrimary)
                        }
                        Button("Delete", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCaptionEditor) {
            ModernCaptionEditorView(
                image: image,
                caption: $caption,
                onSave: { newCaption in
                    // TODO: Implement caption update
                    showingCaptionEditor = false
                }
            )
        }
        .onAppear {
            caption = image.caption
        }
    }
}

// MARK: - Modern Caption Editor
struct ModernCaptionEditorView: View {
    let image: UserImage?
    @Binding var caption: String
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Image preview
                if let image = image {
                    ImageManager.shared.cachedAsyncImage(url: ImageManager.shared.getFullImageURL(image), contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                }
                
                // Caption text field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Caption")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Add a caption...", text: $caption, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isTextFieldFocused)
                        .lineLimit(3...6)
                }
                
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
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}
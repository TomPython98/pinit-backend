import SwiftUI

// MARK: - User Profile Image View
struct UserProfileImageView: View {
    let username: String
    let size: CGFloat
    let showBorder: Bool
    let borderColor: Color
    let enableFullScreen: Bool
    
    @StateObject private var imageManager = ImageManager.shared
    @State private var userImages: [UserImage] = []
    @State private var isLoading = false
    @State private var showFullScreen = false
    
    init(username: String, size: CGFloat = 50, showBorder: Bool = true, borderColor: Color = .blue, enableFullScreen: Bool = false) {
        self.username = username
        self.size = size
        self.showBorder = showBorder
        self.borderColor = borderColor
        self.enableFullScreen = enableFullScreen
    }
    
    var body: some View {
        Group {
            if let primaryImage = getPrimaryImage() {
                ImageManager.shared.cachedAsyncImage(
                    url: ImageManager.shared.getFullImageURL(primaryImage),
                    contentMode: .fill,
                    targetSize: CGSize(width: size * 2, height: size * 2) // 2x for retina
                )
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(showBorder ? borderColor : Color.clear, lineWidth: showBorder ? 2 : 0)
                )
            } else if isLoading {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: size, height: size)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.6)
                    )
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                borderColor.opacity(0.2),
                                borderColor.opacity(0.1),
                                borderColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        VStack(spacing: 2) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: size * 0.4))
                                .foregroundColor(borderColor)
                            Text(username.prefix(1).uppercased())
                                .font(.system(size: size * 0.25, weight: .bold))
                                .foregroundColor(borderColor)
                        }
                    )
                    .overlay(
                        Circle()
                            .stroke(showBorder ? borderColor : Color.clear, lineWidth: showBorder ? 2 : 0)
                    )
            }
        }
        .onTapGesture {
            if enableFullScreen {
                showFullScreen = true
            }
        }
        .onAppear {
            loadUserImages()
        }
        .onReceive(imageManager.$userImages) { images in
            // Update when the image manager's user images change
            if imageManager.currentUsername == username {
                userImages = images
            }
        }
        .sheet(isPresented: $showFullScreen) {
            FullScreenImageView(username: username)
        }
    }
    
    private func loadUserImages() {
        // Check if we already have images for this user
        if let cachedImages = imageManager.userImageCache[username] {
            userImages = cachedImages
            return
        }
        
        // Only load if we don't have any cached data and it's not already loading
        guard !isLoading else { return }
        
        isLoading = true
        Task {
            // Load images for this specific user
            await imageManager.loadUserImages(username: username)
            
            await MainActor.run {
                // Get images from cache
                userImages = imageManager.getUserImagesFromCache(username: username)
                isLoading = false
            }
        }
    }
    
    private func getPrimaryImage() -> UserImage? {
        // First try to find an image marked as primary
        if let primaryImage = userImages.first(where: { $0.isPrimary }) {
            return primaryImage
        }
        
        // If no image is marked as primary, use the most recent profile image
        let profileImages = userImages.filter { $0.imageType == .profile }
        if let mostRecentProfileImage = profileImages.sorted(by: { $0.uploadedAt > $1.uploadedAt }).first {
            return mostRecentProfileImage
        }
        
        // Fallback to most recent image of any type
        if let mostRecentImage = userImages.sorted(by: { $0.uploadedAt > $1.uploadedAt }).first {
            return mostRecentImage
        }
        
        return nil
    }
}

// MARK: - Preview
struct UserProfileImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            UserProfileImageView(username: "testuser", size: 50)
            UserProfileImageView(username: "testuser", size: 80, showBorder: false)
            UserProfileImageView(username: "testuser", size: 100, borderColor: .green)
        }
        .padding()
    }
}
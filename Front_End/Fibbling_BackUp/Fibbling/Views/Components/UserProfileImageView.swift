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
    @State private var refreshID = UUID() // Force view refresh when images change
    
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
                .id(refreshID) // Force SwiftUI to recreate view when ID changes
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProfileImageUpdated"))) { notification in
            // Reload images when profile is updated (critical for immediate refresh after upload!)
            if let updatedUsername = notification.userInfo?["username"] as? String {
                if updatedUsername == username {
                    print("🔄 UserProfileImageView: Received update notification for \(username), reloading...")
                    loadUserImages()
                }
            } else {
                // If no specific username, reload for all
                print("🔄 UserProfileImageView: Received general update notification, reloading...")
                loadUserImages()
            }
        }
        .sheet(isPresented: $showFullScreen) {
            FullScreenImageView(username: username)
        }
    }
    
    private func loadUserImages() {
        // DON'T use cached images as placeholder - this was causing the bug!
        // The old cached images would show the old URL, and the view wouldn't refresh
        
        // Only load if not already loading
        guard !isLoading else { return }
        
        isLoading = true
        Task {
            // Load images for this specific user (force refresh from server)
            await imageManager.loadUserImages(username: username)
            
            await MainActor.run {
                // Get fresh images from cache after reload
                let freshImages = imageManager.getUserImagesFromCache(username: username)
                
                // Only update if data actually changed
                if freshImages != userImages {
                    userImages = freshImages
                    refreshID = UUID() // Force view to refresh with new image
                    print("✅ UserProfileImageView: Updated with \(userImages.count) fresh images for \(username)")
                }
                
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
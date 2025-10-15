import SwiftUI

// MARK: - User Profile Image View
struct UserProfileImageView: View {
    let username: String
    let size: CGFloat
    let showBorder: Bool
    let borderColor: Color
    let enableFullScreen: Bool
    
    // CRITICAL FIX: Don't observe the entire ImageManager singleton!
    // This was causing ALL 50+ profile views to re-render when ANY image loaded
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
                // Use cached image view for better performance
                CachedProfileImageView(
                    url: ImageManager.shared.getFullImageURL(primaryImage),
                    size: size
                )
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(showBorder ? borderColor : Color.clear, lineWidth: showBorder ? 2 : 0)
                )
                .id(refreshID) // Force SwiftUI to recreate view when ID changes
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
            // ✅ FIXED: Check cache first, only load if truly needed
            let cachedImages = ImageManager.shared.getUserImagesFromCache(username: username)
            if cachedImages.isEmpty {
                // Only load if prefetch hasn't completed yet
                // This prevents thundering herd when 50+ views appear simultaneously
                Task.detached(priority: .userInitiated) {
                    await ImageManager.shared.loadUserImages(username: username, forceRefresh: false)
                }
            } else {
                refreshID = UUID() // Just refresh the view with cached data
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProfileImageUpdated"))) { notification in
            // Reload images when profile is updated (critical for immediate refresh after upload!)
            if let updatedUsername = notification.userInfo?["username"] as? String {
                if updatedUsername == username {
                    loadUserImages(forceRefresh: true)
                }
            } else {
                // If no specific username, reload for all
                loadUserImages(forceRefresh: true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ImagesPrefetchCompleted"))) { notification in
            // ✅ CRITICAL FIX: Refresh when prefetch completes
            if let prefetchedUsernames = notification.userInfo?["usernames"] as? [String] {
                if prefetchedUsernames.contains(username) {
                    refreshID = UUID() // Force view refresh with cached data
                }
            } else {
                // If no specific usernames, refresh all
                refreshID = UUID()
            }
        }
        .sheet(isPresented: $showFullScreen) {
            FullScreenImageView(username: username)
        }
    }
    
    private func loadUserImages(forceRefresh: Bool = false) {
        // Check if we already have cached images for this user
        let cachedImages = ImageManager.shared.getUserImagesFromCache(username: username)
        if !cachedImages.isEmpty && !forceRefresh {
            // We already have images, just refresh the view
            refreshID = UUID()
            return
        }
        
        Task {
            // Load images for this specific user (force refresh from server if needed)
            await ImageManager.shared.loadUserImages(username: username, forceRefresh: forceRefresh)
            
            await MainActor.run {
                refreshID = UUID() // Force view to refresh with new image
            }
        }
    }
    
    private func getPrimaryImage() -> UserImage? {
        // Compute from per-username cache to avoid cross-talk between different users
        let images = ImageManager.shared.getUserImagesFromCache(username: username)
        if let primaryImage = images.first(where: { $0.isPrimary }) {
            return primaryImage
        }
        let profileImages = images.filter { $0.imageType == .profile }
        if let mostRecentProfileImage = profileImages.sorted(by: { $0.uploadedAt > $1.uploadedAt }).first {
            return mostRecentProfileImage
        }
        if let mostRecentImage = images.sorted(by: { $0.uploadedAt > $1.uploadedAt }).first {
            return mostRecentImage
        }
        return nil
    }
}

// MARK: - Cached Profile Image View
struct CachedProfileImageView: View {
    let url: String  // ✅ CRITICAL: This must be declared
    let size: CGFloat
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                Circle()
                    .fill(Color(.systemGray6))
                    .overlay(
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: size * 0.5, height: size * 0.5)
                            .opacity(0.3)
                    )
            } else {
                Circle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: size * 0.4))
                            .foregroundColor(.secondary)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ImagesPrefetchCompleted"))) { notification in
            // ✅ CRITICAL FIX: Refresh when prefetch completes
            loadImage()
        }
    }
    
    private func loadImage() {
        Task {
            // Check professional cache first (where prefetch stores images)
            let cachedThumbnail = await MainActor.run {
                ProfessionalImageCache.shared.getImage(url: url, tier: .thumbnail)
            }
            
            if let cachedImage = cachedThumbnail {
                await MainActor.run {
                    image = cachedImage
                    isLoading = false
                }
                return
            }
            
            let cachedFullRes = await MainActor.run {
                ProfessionalImageCache.shared.getImage(url: url, tier: .fullRes)
            }
            
            if let cachedImage = cachedFullRes {
                await MainActor.run {
                    image = cachedImage
                    isLoading = false
                }
                return
            }
            
            // Not in cache, download from network using URLSession
            await downloadImage(from: url)
        }
    }
    
    private func downloadImage(from urlString: String) async {
        guard let url = URL(string: urlString) else {
            await MainActor.run { isLoading = false }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloadedImage = UIImage(data: data) {
                // Store in professional cache for future use
                await MainActor.run {
                    ProfessionalImageCache.shared.setImage(downloadedImage, url: urlString, tier: .fullRes)
                    // Also create and store thumbnail
                    let thumbnail = ProfessionalImageCache.shared.generateThumbnail(from: downloadedImage)
                    ProfessionalImageCache.shared.setImage(thumbnail, url: urlString, tier: .thumbnail)
                    
                    image = downloadedImage
                    isLoading = false
                }
            } else {
                await MainActor.run { isLoading = false }
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
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
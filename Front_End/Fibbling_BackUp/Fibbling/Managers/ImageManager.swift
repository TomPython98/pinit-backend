import Foundation
import SwiftUI
import PhotosUI

// MARK: - Image Manager
@MainActor
class ImageManager: ObservableObject {
    static let shared = ImageManager()
    
    @Published var userImages: [UserImage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let baseURL = "https://pinit-backend-production.up.railway.app"
    
    // Account-based caching
    var currentUsername: String?
    var userImageCache: [String: [UserImage]] = [:] // username -> images
    private var imageCache: [String: UIImage] = [:] // url -> image
    private let cacheQueue = DispatchQueue(label: "imageCache", attributes: .concurrent)
    
    // Professional components
    private let professionalCache = ProfessionalImageCache.shared
    private let networkMonitor = NetworkMonitor.shared
    private let uploadManager = ImageUploadManager.shared
    
    // Prevent out-of-order updates from older requests clobbering fresh data
    private var loadSequence: Int = 0
    
    // Prefetch queue
    private var prefetchQueue: [String] = []
    private var isPrefetching = false
    
    // Optimized URLSession for downloads
    private lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10 // Reduced from 30s
        config.timeoutIntervalForResource = 30 // Reduced from 120s
        config.httpMaximumConnectionsPerHost = 10 // Increased from 6
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 100 * 1024 * 1024, diskCapacity: 500 * 1024 * 1024) // Increased cache
        config.allowsCellularAccess = true
        config.waitsForConnectivity = false // Don't wait, fail fast
        config.httpShouldSetCookies = false
        config.httpShouldUsePipelining = true // Enable HTTP pipelining
        return URLSession(configuration: config)
    }()
    
    private init() {
        // Listen for logout notifications to clear caches
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UserWillLogout"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearAllCaches()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Load User Images
    func loadUserImages(username: String, forceRefresh: Bool = false) async {
        // Check if we have cached images for this user (unless forcing refresh)
        if !forceRefresh, let cachedImages = userImageCache[username] {
            userImages = cachedImages
            currentUsername = username
            return
        }
        
        isLoading = true
        errorMessage = nil
        currentUsername = username
        
        // Bump sequence to identify the latest load request
        loadSequence &+= 1
        let thisLoad = loadSequence
        
        // Use the backend_deployment URL which has the image endpoints
        let imageBackendURL = "https://pinit-backend-production.up.railway.app"
        guard var urlComponents = URLComponents(string: "\(imageBackendURL)/api/user_images/\(username)/") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        // Add cache buster to avoid any CDN/HTTP caches
        let cacheBuster = URLQueryItem(name: "t", value: String(Int(Date().timeIntervalSince1970)))
        var items = urlComponents.queryItems ?? []
        items.append(cacheBuster)
        urlComponents.queryItems = items
        guard let finalURL = urlComponents.url else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            var request = URLRequest(url: finalURL)
            // Force network fetch when refreshing
            request.cachePolicy = forceRefresh ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            request.setValue("no-cache", forHTTPHeaderField: "Pragma")
            let (data, response) = try await downloadSession.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    let response = try JSONDecoder().decode(UserImagesResponse.self, from: data)
                    // Ignore out-of-date responses
                    guard thisLoad == loadSequence else { return }
                    userImages = response.images
                    // Cache the images for this user
                    userImageCache[username] = response.images
                    AppLogger.logImage("Loaded \(response.images.count) images for user \(username)")
                } else {
                    AppLogger.error("HTTP \(httpResponse.statusCode) when loading images for user \(username)", category: AppLogger.image)
                    // Do NOT clobber existing images on non-200; keep last known good state
                }
            }
        } catch {
            AppLogger.error("Failed to load images for \(username)", error: error, category: AppLogger.image)
            // Preserve current images/cache on error
        }
        
        isLoading = false
    }
    
    // MARK: - Upload Image
    func uploadImage(_ request: ImageUploadRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Use the professional upload manager with network-aware compression
        let success = await uploadManager.uploadImage(request)
        
        if !success {
            errorMessage = uploadManager.uploadError
        }
        
        isLoading = false
        return success
    }
    
    // MARK: - Background Upload
    func queueUpload(_ request: ImageUploadRequest) {
        uploadManager.queueUpload(request)
    }
    
    // MARK: - Upload Progress
    var uploadProgress: Double {
        return uploadManager.getOverallProgress()
    }
    
    var hasActiveUploads: Bool {
        return uploadManager.hasActiveUploads()
    }
    
    // MARK: - Optimized Download
    func downloadImage(from request: URLRequest) async throws -> (Data, URLResponse) {
        return try await downloadSession.data(for: request)
    }
    
    // MARK: - Delete Image
    func deleteImage(imageId: String, username: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/user_image/\(imageId)/delete/") else {
            errorMessage = "Invalid URL"
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // Reload images to get updated list
                    await loadUserImages(username: username)
                    return true
                } else {
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorData["error"] as? String {
                        errorMessage = error
                    } else {
                        errorMessage = "Delete failed (Status: \(httpResponse.statusCode))"
                    }
                }
            }
        } catch {
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }
        
        return false
    }
    
    // MARK: - Set Primary Image
    func setPrimaryImage(imageId: String, username: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/user_image/\(imageId)/set_primary/") else {
            errorMessage = "Invalid URL"
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // Reload images to get updated list
                    await loadUserImages(username: username)
                    return true
                } else {
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorData["error"] as? String {
                        errorMessage = error
                    } else {
                        errorMessage = "Set primary failed (Status: \(httpResponse.statusCode))"
                    }
                }
            }
        } catch {
            errorMessage = "Set primary failed: \(error.localizedDescription)"
        }
        
        return false
    }
    
    // MARK: - Helper Methods
    func getPrimaryImage() -> UserImage? {
        // First try to find an image marked as primary
        if let primaryImage = userImages.first(where: { $0.isPrimary }) {
            return primaryImage
        }
        
        // If no image is marked as primary (due to backend issue), 
        // use the most recent profile image as primary
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
    
    func getProfileImages() -> [UserImage] {
        return userImages.filter { $0.imageType == .profile }
    }
    
    func getGalleryImages() -> [UserImage] {
        return userImages.filter { $0.imageType == .gallery }
    }
    
    func getCoverImages() -> [UserImage] {
        return userImages.filter { $0.imageType == .cover }
    }
    
    func getFullImageURL(_ image: UserImage) -> String {
        // Each upload creates a NEW file with unique filename, so the base URL is already unique
        // Just append the image ID as cache-busting parameter to ensure SwiftUI sees URL changes
        guard let rawUrl = image.url, !rawUrl.isEmpty else {
            // Fallback to API endpoint if URL missing
            return "\(baseURL)/api/user_image/\(image.id)/serve/?id=\(image.id)"
        }
        if rawUrl.hasPrefix("http") {
            // If it's an R2 endpoint URL, convert to public URL
            if rawUrl.contains("r2.cloudflarestorage.com") {
                // Convert R2 endpoint URL to public URL
                let publicDomain = "pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev"
                
                // Extract the path from the R2 URL (everything after /pinit-images/)
                if let urlComponents = URLComponents(string: rawUrl) {
                    let fullPath = urlComponents.path
                    // Remove /pinit-images/ prefix and use the rest
                    if fullPath.hasPrefix("/pinit-images/") {
                        let relativePath = String(fullPath.dropFirst("/pinit-images/".count))
                        // URL already unique (has timestamp in filename), just add ID for SwiftUI
                        return "https://\(publicDomain)/\(relativePath)?id=\(image.id)"
                    }
                }
            }
            // URL already contains unique filename, just add ID
            let separator = rawUrl.contains("?") ? "&" : "?"
            return "\(rawUrl)\(separator)id=\(image.id)"
        }
        // Fallback to API endpoint if needed
        return "\(baseURL)/api/user_image/\(image.id)/serve/?id=\(image.id)"
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Cache Management
    func clearAllCaches() {
        AppLogger.logCache("Clearing all caches")
        
        // Clear user image cache
        userImageCache.removeAll()
        
        // Clear current user data
        userImages.removeAll()
        currentUsername = nil
        
        // Clear image cache
        cacheQueue.async(flags: .barrier) {
            self.imageCache.removeAll()
        }
        
        // Clear URLSession cache
        URLCache.shared.removeAllCachedResponses()
        
        // Clear professional cache
        professionalCache.clearAll()
    }
    
    func clearUserCache(username: String) {
        AppLogger.logCache("Clearing cache for user: \(username)")
        userImageCache.removeValue(forKey: username)
        
        // If this is the current user, clear current data
        if currentUsername == username {
            userImages.removeAll()
            currentUsername = nil
        }
    }
    
    private func clearImageCache() async {
        // Clear URLSession cache
        URLCache.shared.removeAllCachedResponses()
        
        // Clear user images array to force refresh
        userImages.removeAll()
        
        // Clear image cache
        cacheQueue.async(flags: .barrier) {
            self.imageCache.removeAll()
        }
    }
    
    // MARK: - Cached Image Loading
    func loadCachedImage(from url: String) async -> (image: UIImage?, fromCache: Bool) {
        // Check cache first
        if let cachedImage = getCachedImage(for: url) {
            return (cachedImage, true) // Loaded from cache
        }
        
        // Load from URL if not in cache
        guard let imageURL = URL(string: url) else { return (nil, false) }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            if let image = UIImage(data: data) {
                // Cache the image
                setCachedImage(image, for: url)
                return (image, false) // Loaded from network
            }
        } catch {
            AppLogger.error("Failed to load image from URL", error: error, category: AppLogger.image)
        }
        
        return (nil, false)
    }
    
    // MARK: - Cached AsyncImage
    @ViewBuilder
    func cachedAsyncImage(url: String, contentMode: ContentMode = .fill, targetSize: CGSize? = nil) -> some View {
        // Use professional cached image view for better performance
        ProfessionalCachedImageView(url: url, contentMode: contentMode, targetSize: targetSize)
    }
    
    func getCachedImage(for url: String) -> UIImage? {
        return cacheQueue.sync {
            return imageCache[url]
        }
    }
    
    private func setCachedImage(_ image: UIImage, for url: String) {
        cacheQueue.async(flags: .barrier) {
            self.imageCache[url] = image
        }
    }
    
    // MARK: - Preload Images
    func preloadImages() async {
        for image in userImages {
            let fullURL = getFullImageURL(image)
            _ = await loadCachedImage(from: fullURL)
        }
    }
    
    // MARK: - Batch Load User Images
    func loadMultipleUserImages(usernames: [String]) async {
        // Load images for multiple users efficiently
        await withTaskGroup(of: Void.self) { group in
            for username in usernames {
                group.addTask {
                    // Only load if not already cached
                    let hasCachedImages = await MainActor.run {
                        return self.userImageCache[username] != nil
                    }
                    
                    if !hasCachedImages {
                        await self.loadUserImages(username: username)
                    }
                }
            }
        }
    }
    
    // MARK: - Get User Images from Cache
    func getUserImagesFromCache(username: String) -> [UserImage] {
        return userImageCache[username] ?? []
    }
    
    // MARK: - Professional Features
    
    /// Prefetch images for a list of usernames to improve perceived performance
    /// Returns when prefetching is complete
    func prefetchImagesForUsers(_ usernames: [String]) async {
        guard networkMonitor.isConnected else { return }
        
        // Filter out already cached users
        let uncachedUsers = usernames.filter { userImageCache[$0] == nil }
        guard !uncachedUsers.isEmpty else { return }
        
        AppLogger.logImage("Prefetching images for \(uncachedUsers.count) users")
        
        isPrefetching = true
        
        // ✅ OPTIMIZED: Use batch API endpoint for much better performance
        if uncachedUsers.count > 5 {
            await performBatchAPIRequest(usernames: uncachedUsers)
        } else {
            await performBatchPrefetch(usernames: uncachedUsers)
        }
        
        isPrefetching = false
    }
    
    /// ✅ NEW: Use batch API endpoint for optimal performance
    private func performBatchAPIRequest(usernames: [String]) async {
        AppLogger.logImage("Using batch API for \(usernames.count) users")
        
        let startTime = Date()
        
        guard let url = URL(string: "\(baseURL)/api/multiple_user_images/") else {
            AppLogger.error("Invalid batch API URL", category: AppLogger.image)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let body = ["usernames": usernames]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await downloadSession.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                
                let batchResponse = try JSONDecoder().decode(BatchUserImagesResponse.self, from: data)
                
                // Update cache with all user images at once
                await MainActor.run {
                    for (username, userData) in batchResponse.users {
                        let userImages = userData.images.map { imageData in
                            UserImage(
                                id: imageData.id,
                                url: imageData.url,
                                imageType: UserImage.ImageType(rawValue: imageData.imageType) ?? .gallery,
                                isPrimary: imageData.isPrimary,
                                caption: imageData.caption,
                                uploadedAt: imageData.uploadedAt
                            )
                        }
                        self.userImageCache[username] = userImages
                    }
                }
                
                // Now download all primary images in parallel
                await withTaskGroup(of: Void.self) { group in
                    for (username, userData) in batchResponse.users {
                        if let primaryImage = userData.images.first(where: { $0.isPrimary }) {
                            group.addTask(priority: .userInitiated) {
                                let imageURL = await MainActor.run {
                                    return self.getFullImageURL(UserImage(
                                        id: primaryImage.id,
                                        url: primaryImage.url,
                                        imageType: UserImage.ImageType(rawValue: primaryImage.imageType) ?? .gallery,
                                        isPrimary: primaryImage.isPrimary,
                                        caption: primaryImage.caption,
                                        uploadedAt: primaryImage.uploadedAt
                                    ))
                                }
                                _ = await self.professionalCache.loadCachedImage(from: imageURL)
                            }
                        }
                    }
                }
                
                let duration = Date().timeIntervalSince(startTime)
                AppLogger.logImage("Batch API complete in \(String(format: "%.2f", duration))s for \(usernames.count) users")
                
            } else {
                AppLogger.error("Batch API failed with status: \(httpResponse?.statusCode ?? -1)", category: AppLogger.image)
            }
            
        } catch {
            AppLogger.error("Batch API request failed", error: error, category: AppLogger.image)
        }
    }
    
    private func performBatchPrefetch(usernames: [String]) async {
        AppLogger.logImage("Batch prefetching \(usernames.count) users")
        
        let startTime = Date()
        
        // ✅ OPTIMIZED: Load ALL metadata first in parallel, then download ALL images
        // This maximizes network efficiency and reduces total time
        await withTaskGroup(of: Void.self) { group in
            // Phase 1: Load metadata for all users in parallel
            for username in usernames {
                group.addTask(priority: .userInitiated) {
                    await self.loadUserImages(username: username, forceRefresh: false)
                }
            }
        }
        
        // Phase 2: Collect all primary images and download them in parallel
        var imageURLs: [String] = []
        for username in usernames {
            let images = await MainActor.run {
                return self.getUserImagesFromCache(username: username)
            }
            
            if let primaryImage = images.first(where: { $0.isPrimary }) {
                let imageURL = await MainActor.run {
                    return self.getFullImageURL(primaryImage)
                }
                imageURLs.append(imageURL)
            }
        }
        
        // Phase 3: Download all images in parallel with higher concurrency
        await withTaskGroup(of: Void.self) { group in
            for imageURL in imageURLs {
                group.addTask(priority: .userInitiated) {
                    _ = await self.professionalCache.loadCachedImage(from: imageURL)
                }
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        AppLogger.logImage("Batch prefetching complete in \(String(format: "%.2f", duration))s for \(usernames.count) users")
    }
    
    private func performPrefetch() async {
        let maxConcurrent = min(networkMonitor.connectionSpeed.maxConcurrentDownloads, 6) // Cap at 6 for stability
        
        // Process queue in batches based on connection speed
        while !prefetchQueue.isEmpty && networkMonitor.isConnected {
            let batch = Array(prefetchQueue.prefix(maxConcurrent))
            prefetchQueue.removeFirst(min(maxConcurrent, prefetchQueue.count))
            
            // Load images for batch concurrently with higher priority
            await withTaskGroup(of: Void.self) { group in
                for username in batch {
                    group.addTask(priority: .userInitiated) { // Higher priority for immediate UI updates
                        await self.loadUserImages(username: username, forceRefresh: false)
                        
                        // Prefetch the actual image data for immediate display
                        let images = await MainActor.run {
                            return self.getUserImagesFromCache(username: username)
                        }
                        
                        if let primaryImage = images.first(where: { $0.isPrimary }) {
                            let imageURL = await MainActor.run {
                                return self.getFullImageURL(primaryImage)
                            }
                            
                            // Prefetch thumbnail for immediate display
                            _ = await self.professionalCache.loadCachedImage(from: imageURL)
                        }
                    }
                }
            }
            
            // Reduced delay between batches for faster loading
            if !prefetchQueue.isEmpty {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            }
        }
        
        await MainActor.run {
            isPrefetching = false
            prefetchQueue.removeAll()
        }
        
        AppLogger.logImage("Prefetching complete")
    }
    
    /// Cancel ongoing prefetch operations
    func cancelPrefetch() {
        isPrefetching = false
        prefetchQueue.removeAll()
    }
    
    /// Get cache statistics for debugging
    func printCacheStatistics() {
        AppLogger.logCache("Cache Stats - Users: \(userImageCache.count), Current: \(currentUsername ?? "none"), Images: \(userImages.count), Queue: \(prefetchQueue.count)")
        professionalCache.printCacheStats()
    }
}

// MARK: - Professional Image Cache Helper Extension
extension ProfessionalImageCache {
    /// Load image from URL with caching using optimized session
    func loadCachedImage(from url: String) async -> UIImage? {
        // Check if we have it in any tier
        if let fullRes = getImage(url: url, tier: .fullRes) {
            return fullRes
        }
        
        if let thumbnail = getImage(url: url, tier: .thumbnail) {
            return thumbnail
        }
        
        // Load from network using optimized session
        guard let imageURL = URL(string: url) else { return nil }
        
        do {
            var request = URLRequest(url: imageURL)
            request.timeoutInterval = 10 // Fast timeout
            request.cachePolicy = .returnCacheDataElseLoad
            
            // Use ImageManager's optimized downloadSession (10 concurrent connections)
            let (data, _) = try await ImageManager.shared.downloadImage(from: request)
            
            if let image = UIImage(data: data) {
                // For small profile images, skip thumbnail generation - use full image directly
                // This saves significant CPU time during batch loading
                setImage(image, url: url, tier: .thumbnail)
                return image
            }
        } catch {
            print("❌ Failed to prefetch image: \(error.localizedDescription)")
        }
        
        return nil
    }
}

// MARK: - Cached AsyncImage View
struct CachedAsyncImageView: View {
    let url: String
    let contentMode: ContentMode
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var loadError: String?
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("Failed to load")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        // Check if we already have this image cached
        if let cachedImage = ImageManager.shared.getCachedImage(for: url) {
            loadedImage = cachedImage
            isLoading = false
            return
        }
        
        // Load from network
        Task {
            let result = await ImageManager.shared.loadCachedImage(from: url)
            await MainActor.run {
                loadedImage = result.image
                isLoading = false
                if result.image == nil {
                    loadError = "Failed to load image"
                }
            }
        }
    }
}

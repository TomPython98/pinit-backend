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
    
    private let baseURL = "https://pinit-backend-production.up.railway.app"
    
    // Account-based caching
    private var currentUsername: String?
    private var userImageCache: [String: [UserImage]] = [:] // username -> images
    private var imageCache: [String: UIImage] = [:] // url -> image
    private let cacheQueue = DispatchQueue(label: "imageCache", attributes: .concurrent)
    
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
    func loadUserImages(username: String) async {
        // Check if we have cached images for this user
        if let cachedImages = userImageCache[username] {
            userImages = cachedImages
            currentUsername = username
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/api/user_images/\(username)/") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    let response = try JSONDecoder().decode(UserImagesResponse.self, from: data)
                    userImages = response.images
                    
                    // Cache the images for this user
                    userImageCache[username] = response.images
                    currentUsername = username
                } else {
                    errorMessage = "Failed to load images (Status: \(httpResponse.statusCode))"
                }
            }
        } catch {
            errorMessage = "Failed to load images: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Upload Image
    func uploadImage(_ request: ImageUploadRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Clear any cached images before upload
        await clearImageCache()
        
        guard let url = URL(string: "\(baseURL)/api/upload_user_image/") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return false
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add form fields
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"username\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(request.username)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(request.imageType.rawValue)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"is_primary\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(request.isPrimary ? "true" : "false")\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"caption\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(request.caption)\r\n".data(using: .utf8)!)
        
        // Add image file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(request.filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(request.mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(request.imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        urlRequest.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    let uploadResponse = try JSONDecoder().decode(ImageUploadResponse.self, from: data)
                    if uploadResponse.success {
                        // Clear cache for this user to force refresh
                        userImageCache.removeValue(forKey: request.username)
                        // Reload images to get updated list
                        await loadUserImages(username: request.username)
                        return true
                    } else {
                        errorMessage = uploadResponse.message
                    }
                } else {
                    // Try to parse error message
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorData["error"] as? String {
                        errorMessage = error
                    } else {
                        errorMessage = "Upload failed (Status: \(httpResponse.statusCode))"
                    }
                }
            }
        } catch {
            errorMessage = "Upload failed: \(error.localizedDescription)"
        }
        
        isLoading = false
        return false
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
        // Use R2 URL directly - the backend now returns R2 URLs
        if image.url.hasPrefix("http") {
            // If it's an R2 endpoint URL, convert to public URL
            if image.url.contains("r2.cloudflarestorage.com") {
                // Convert R2 endpoint URL to public URL
                let publicDomain = "pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev"
                
                // Extract the path from the R2 URL (everything after /pinit-images/)
                if let urlComponents = URLComponents(string: image.url) {
                    let fullPath = urlComponents.path
                    // Remove /pinit-images/ prefix and use the rest
                    if fullPath.hasPrefix("/pinit-images/") {
                        let relativePath = String(fullPath.dropFirst("/pinit-images/".count))
                        return "https://\(publicDomain)/\(relativePath)"
                    }
                }
            }
            return image.url
        }
        // Fallback to API endpoint if needed
        return "\(baseURL)/api/user_image/\(image.id)/serve/"
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Cache Management
    func clearAllCaches() {
        print("🧹 Clearing all caches")
        
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
    }
    
    func clearUserCache(username: String) {
        print("🧹 Clearing cache for user: \(username)")
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
            print("❌ Failed to load image from \(url): \(error)")
        }
        
        return (nil, false)
    }
    
    // MARK: - Cached AsyncImage
    @ViewBuilder
    func cachedAsyncImage(url: String, contentMode: ContentMode = .fill) -> some View {
        CachedAsyncImageView(url: url, contentMode: contentMode)
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

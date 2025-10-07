import SwiftUI
import UIKit

// MARK: - Professional Cached Image View
/// Advanced image view with progressive loading, retry logic, and network awareness
struct ProfessionalCachedImageView: View {
    let url: String
    let contentMode: ContentMode
    let targetSize: CGSize?
    
    @StateObject private var loader = ImageLoader()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var cache = ProfessionalImageCache.shared
    
    init(url: String, contentMode: ContentMode = .fill, targetSize: CGSize? = nil) {
        self.url = url
        self.contentMode = contentMode
        self.targetSize = targetSize
    }
    
    var body: some View {
        Group {
            if let image = loader.finalImage {
                // Final high-quality image loaded
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            } else if let thumbnail = loader.thumbnailImage {
                // Show thumbnail while loading full image
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .blur(radius: 2)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.7)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.2))
                                    .frame(width: 40, height: 40)
                            )
                    )
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            } else if let blurHash = loader.blurHashImage {
                // Show blur hash placeholder while loading thumbnail
                Image(uiImage: blurHash)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .blur(radius: 8)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.7)
                    )
                    .transition(.opacity.animation(.easeInOut(duration: 0.1)))
            } else if loader.isLoading {
                // Initial loading state
                Rectangle()
                    .fill(Color(.systemGray6))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            } else if loader.error != nil {
                // Error state with retry button
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "photo.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            if networkMonitor.connectionSpeed == .offline {
                                Text("Offline")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Button(action: {
                                    Task {
                                        await loader.load(url: url, targetSize: targetSize)
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Retry")
                                    }
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    )
            } else {
                // Empty state
                Rectangle()
                    .fill(Color(.systemGray6))
            }
        }
        .onAppear {
            Task {
                await loader.load(url: url, targetSize: targetSize)
            }
        }
        .onChange(of: url) { newURL in
            Task {
                await loader.load(url: newURL, targetSize: targetSize)
            }
        }
    }
}

// MARK: - Image Loader
/// Handles progressive image loading with retry logic
@MainActor
class ImageLoader: ObservableObject {
    @Published var blurHashImage: UIImage?
    @Published var thumbnailImage: UIImage?
    @Published var finalImage: UIImage?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let cache = ProfessionalImageCache.shared
    private let networkMonitor = NetworkMonitor.shared
    
    private var currentTask: Task<Void, Never>?
    private var retryCount = 0
    private let maxRetries = 3
    
    func load(url: String, targetSize: CGSize? = nil) async {
        // Cancel any existing load
        currentTask?.cancel()
        
        // Reset state
        error = nil
        isLoading = true
        
        // Create new load task
        currentTask = Task {
            await performLoad(url: url, targetSize: targetSize)
        }
        
        await currentTask?.value
    }
    
    private func performLoad(url: String, targetSize: CGSize?) async {
        // Check if we already have the full image in cache
        if let cached = cache.getImage(url: url, tier: .fullRes) {
            finalImage = cached
            isLoading = false
            return
        }
        
        // Try to load thumbnail first for progressive loading
        if let cachedThumbnail = cache.getImage(url: url, tier: .thumbnail) {
            thumbnailImage = cachedThumbnail
        } else {
            // Try to load blur hash
            if let cachedBlurHash = cache.getImage(url: url, tier: .blurHash) {
                blurHashImage = cachedBlurHash
            }
        }
        
        // Determine whether to load full image or just thumbnail based on network
        let shouldLoadFullImage = !networkMonitor.connectionSpeed.shouldLoadThumbnailsOnly
        
        // Load the image with retry logic
        await loadWithRetry(url: url, targetSize: targetSize, loadFullImage: shouldLoadFullImage)
    }
    
    private func loadWithRetry(url: String, targetSize: CGSize?, loadFullImage: Bool) async {
        var attempt = 0
        
        while attempt <= maxRetries {
            do {
                // Check if task was cancelled
                try Task.checkCancellation()
                
                // Perform the actual download
                let image = try await downloadImage(url: url, timeout: networkMonitor.connectionSpeed.timeout)
                
                // Process and cache the image
                await processAndCacheImage(image, url: url, targetSize: targetSize, loadFullImage: loadFullImage)
                
                isLoading = false
                error = nil
                retryCount = 0
                return
                
            } catch is CancellationError {
                // Task was cancelled, stop retrying
                isLoading = false
                return
                
            } catch {
                attempt += 1
                
                if attempt > maxRetries {
                    // Max retries reached
                    self.error = error
                    isLoading = false
                    print("❌ Failed to load image after \(maxRetries) attempts: \(error.localizedDescription)")
                    return
                }
                
                // Wait before retrying (exponential backoff)
                let delay = Double(attempt) * 2.0
                print("⏳ Retrying image load (attempt \(attempt)/\(maxRetries)) in \(delay)s...")
                
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
    
    private func downloadImage(url: String, timeout: TimeInterval) async throws -> UIImage {
        guard let imageURL = URL(string: url) else {
            throw ImageLoadError.invalidURL
        }
        
        var request = URLRequest(url: imageURL)
        request.timeoutInterval = timeout
        request.cachePolicy = .returnCacheDataElseLoad
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP response
        if let httpResponse = response as? HTTPURLResponse {
            guard (200...299).contains(httpResponse.statusCode) else {
                throw ImageLoadError.httpError(statusCode: httpResponse.statusCode)
            }
        }
        
        // Convert to UIImage
        guard let image = UIImage(data: data) else {
            throw ImageLoadError.invalidImageData
        }
        
        return image
    }
    
    private func processAndCacheImage(_ image: UIImage, url: String, targetSize: CGSize?, loadFullImage: Bool) async {
        // Generate and cache blur hash if we don't have it
        if blurHashImage == nil {
            let blurHash = cache.generateBlurHash(from: image)
            blurHashImage = blurHash
            cache.setImage(blurHash, url: url, tier: .blurHash)
        }
        
        // Generate and cache thumbnail
        let thumbnailSize = targetSize ?? CGSize(width: 200, height: 200)
        let thumbnail = cache.generateThumbnail(from: image, targetSize: thumbnailSize)
        thumbnailImage = thumbnail
        cache.setImage(thumbnail, url: url, tier: .thumbnail)
        
        // If we should load full image, process and cache it
        if loadFullImage {
            // Optimize image if needed
            let optimizedImage = optimizeImage(image)
            finalImage = optimizedImage
            cache.setImage(optimizedImage, url: url, tier: .fullRes)
        } else {
            // On slow connections, use thumbnail as final image
            finalImage = thumbnail
        }
    }
    
    private func optimizeImage(_ image: UIImage) -> UIImage {
        // If image is already small enough, return as is
        let maxDimension: CGFloat = 1920
        if image.size.width <= maxDimension && image.size.height <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let ratio = min(maxDimension / image.size.width, maxDimension / image.size.height)
        let newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        
        // Render optimized image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let optimized = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return optimized
    }
    
    enum ImageLoadError: LocalizedError {
        case invalidURL
        case invalidImageData
        case httpError(statusCode: Int)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid image URL"
            case .invalidImageData:
                return "Could not parse image data"
            case .httpError(let code):
                return "HTTP error: \(code)"
            }
        }
    }
}

// MARK: - Preview
struct ProfessionalCachedImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProfessionalCachedImageView(
                url: "https://picsum.photos/800/800",
                contentMode: .fill,
                targetSize: CGSize(width: 200, height: 200)
            )
            .frame(width: 200, height: 200)
            .clipShape(Circle())
            
            ProfessionalCachedImageView(
                url: "https://picsum.photos/400/600",
                contentMode: .fit
            )
            .frame(height: 300)
        }
        .padding()
    }
}


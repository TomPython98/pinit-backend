import Foundation
import SwiftUI
import UIKit

// MARK: - Professional Image Cache
/// Multi-tier image caching system with thumbnail support
@MainActor
class ProfessionalImageCache: ObservableObject {
    static let shared = ProfessionalImageCache()
    
    // Memory cache for fast access
    private var fullResCache: [String: UIImage] = [:]
    private var thumbnailCache: [String: UIImage] = [:]
    private var blurHashCache: [String: UIImage] = [:]
    
    // Disk cache location
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // Cache size limits
    private let maxMemoryCacheSize = 100 // images
    private let maxDiskCacheSize: Int64 = 200 * 1024 * 1024 // 200MB
    
    // Access tracking for LRU eviction
    private var accessOrder: [String] = []
    
    // Cache queue for thread safety
    private let cacheQueue = DispatchQueue(label: "ProfessionalImageCache", attributes: .concurrent)
    
    enum CacheTier {
        case thumbnail
        case fullRes
        case blurHash
    }
    
    private init() {
        // Setup cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachesDirectory.appendingPathComponent("PinItImageCache", isDirectory: true)
        
        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        
        // Cleanup old cache on init
        Task {
            await cleanupOldCache()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Get Image
    
    func getImage(url: String, tier: CacheTier = .fullRes) -> UIImage? {
        let cacheKey = cacheKey(for: url, tier: tier)
        
        // Update access order for LRU
        updateAccessOrder(cacheKey)
        
        // Check memory cache
        if let cached = getFromMemoryCache(key: cacheKey, tier: tier) {
            return cached
        }
        
        // Check disk cache
        if let diskImage = getFromDiskCache(key: cacheKey) {
            // Store in memory cache for faster future access
            setInMemoryCache(image: diskImage, key: cacheKey, tier: tier)
            return diskImage
        }
        
        return nil
    }
    
    // MARK: - Set Image
    
    func setImage(_ image: UIImage, url: String, tier: CacheTier = .fullRes) {
        let cacheKey = cacheKey(for: url, tier: tier)
        
        // Store in memory
        setInMemoryCache(image: image, key: cacheKey, tier: tier)
        
        // Store on disk asynchronously
        Task.detached(priority: .background) {
            await self.setInDiskCache(image: image, key: cacheKey)
        }
    }
    
    // MARK: - Generate Thumbnail
    
    func generateThumbnail(from image: UIImage, targetSize: CGSize = CGSize(width: 200, height: 200)) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let thumbnail = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return thumbnail
    }
    
    // MARK: - Generate Blur Hash Placeholder
    
    func generateBlurHash(from image: UIImage) -> UIImage {
        // Create a very low resolution version for blur effect
        let blurSize = CGSize(width: 20, height: 20)
        let renderer = UIGraphicsImageRenderer(size: blurSize)
        let blurred = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: blurSize))
        }
        
        // Apply Gaussian blur
        guard let ciImage = CIImage(image: blurred) else { return blurred }
        
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(10.0, forKey: kCIInputRadiusKey)
        
        if let outputImage = filter?.outputImage,
           let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return blurred
    }
    
    // MARK: - Memory Cache Operations
    
    private func getFromMemoryCache(key: String, tier: CacheTier) -> UIImage? {
        return cacheQueue.sync {
            switch tier {
            case .thumbnail:
                return thumbnailCache[key]
            case .fullRes:
                return fullResCache[key]
            case .blurHash:
                return blurHashCache[key]
            }
        }
    }
    
    private func setInMemoryCache(image: UIImage, key: String, tier: CacheTier) {
        cacheQueue.async(flags: .barrier) {
            // Enforce cache size limit
            self.enforceMemoryCacheLimit(for: tier)
            
            switch tier {
            case .thumbnail:
                self.thumbnailCache[key] = image
            case .fullRes:
                self.fullResCache[key] = image
            case .blurHash:
                self.blurHashCache[key] = image
            }
        }
    }
    
    private func enforceMemoryCacheLimit(for tier: CacheTier) {
        let currentCache: [String: UIImage]
        
        switch tier {
        case .thumbnail:
            currentCache = thumbnailCache
        case .fullRes:
            currentCache = fullResCache
        case .blurHash:
            currentCache = blurHashCache
        }
        
        if currentCache.count >= maxMemoryCacheSize {
            // Remove least recently used items
            let keysToRemove = accessOrder.prefix(currentCache.count - maxMemoryCacheSize + 1)
            for key in keysToRemove {
                switch tier {
                case .thumbnail:
                    thumbnailCache.removeValue(forKey: key)
                case .fullRes:
                    fullResCache.removeValue(forKey: key)
                case .blurHash:
                    blurHashCache.removeValue(forKey: key)
                }
                accessOrder.removeAll { $0 == key }
            }
        }
    }
    
    // MARK: - Disk Cache Operations
    
    private func getFromDiskCache(key: String) -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    private func setInDiskCache(image: UIImage, key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        // Compress image for disk storage
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        do {
            try data.write(to: fileURL)
        } catch {
            print("❌ Failed to write image to disk cache: \(error)")
        }
    }
    
    // MARK: - Cache Key Generation
    
    private func cacheKey(for url: String, tier: CacheTier) -> String {
        let hash = url.hash
        let tierSuffix: String
        
        switch tier {
        case .thumbnail:
            tierSuffix = "_thumb"
        case .fullRes:
            tierSuffix = "_full"
        case .blurHash:
            tierSuffix = "_blur"
        }
        
        return "\(hash)\(tierSuffix)"
    }
    
    // MARK: - Access Order Management
    
    private func updateAccessOrder(_ key: String) {
        cacheQueue.async(flags: .barrier) {
            // Remove if exists and add to end (most recently used)
            self.accessOrder.removeAll { $0 == key }
            self.accessOrder.append(key)
        }
    }
    
    // MARK: - Cache Management
    
    func clearAll() {
        cacheQueue.async(flags: .barrier) {
            // Clear memory caches
            self.fullResCache.removeAll()
            self.thumbnailCache.removeAll()
            self.blurHashCache.removeAll()
            self.accessOrder.removeAll()
            
            // Clear disk cache
            try? self.fileManager.removeItem(at: self.cacheDirectory)
            try? self.fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
        }
        
        print("🧹 Cleared all image caches")
    }
    
    func clearMemoryCache() {
        cacheQueue.async(flags: .barrier) {
            self.fullResCache.removeAll()
            self.thumbnailCache.removeAll()
            self.blurHashCache.removeAll()
            self.accessOrder.removeAll()
        }
        
        print("🧹 Cleared memory caches")
    }
    
    private func handleMemoryWarning() {
        print("⚠️ Memory warning - clearing caches")
        clearMemoryCache()
    }
    
    private func cleanupOldCache() async {
        // Remove files older than 7 days
        let expirationDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return }
        
        for file in files {
            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let modificationDate = attributes[.modificationDate] as? Date,
               modificationDate < expirationDate {
                try? fileManager.removeItem(at: file)
            }
        }
    }
    
    // MARK: - Cache Statistics
    
    func getCacheSize() -> (memory: Int, disk: Int64) {
        let memoryCount = fullResCache.count + thumbnailCache.count + blurHashCache.count
        
        var diskSize: Int64 = 0
        if let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                   let fileSize = attributes[.size] as? Int64 {
                    diskSize += fileSize
                }
            }
        }
        
        return (memoryCount, diskSize)
    }
    
    func printCacheStats() {
        let stats = getCacheSize()
        print("📊 Cache Stats:")
        print("   Memory: \(stats.memory) images")
        print("   Disk: \(stats.disk / 1024 / 1024) MB")
    }
}


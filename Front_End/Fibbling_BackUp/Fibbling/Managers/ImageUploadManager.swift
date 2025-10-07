import Foundation
import SwiftUI
import UIKit

// MARK: - Image Upload Manager
/// Professional image upload system with network-aware compression and background uploads
@MainActor
class ImageUploadManager: ObservableObject {
    static let shared = ImageUploadManager()
    
    @Published var uploadProgress: [String: Double] = [:] // filename -> progress
    @Published var isUploading = false
    @Published var uploadError: String?
    
    private let networkMonitor = NetworkMonitor.shared
    private var uploadQueue: [UploadTask] = []
    private var activeUploads: Set<String> = []
    private let maxConcurrentUploads = 2
    
    // Optimized URLSession for uploads
    private lazy var uploadSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120 // 2 minutes
        config.timeoutIntervalForResource = 300 // 5 minutes
        config.httpMaximumConnectionsPerHost = 2
        config.allowsCellularAccess = true
        config.waitsForConnectivity = true
        return URLSession(configuration: config, delegate: nil, delegateQueue: nil)
    }()
    
    private init() {}
    
    // MARK: - Smart Upload with Network-Aware Compression
    
    func uploadImage(_ request: ImageUploadRequest) async -> Bool {
        let uploadId = UUID().uuidString
        
        do {
            // Step 1: Optimize image based on network conditions
            isUploading = true
            uploadProgress[uploadId] = 0.1
            
            let optimizedData = await optimizeForUpload(
                imageData: request.imageData,
                connectionSpeed: networkMonitor.connectionSpeed
            )
            
            uploadProgress[uploadId] = 0.3
            
            print("📤 Uploading: Original \(request.imageData.count / 1024)KB → Optimized \(optimizedData.count / 1024)KB")
            
            // Step 2: Perform upload
            let success = await performUpload(
                data: optimizedData,
                request: request,
                uploadId: uploadId
            )
            
            uploadProgress.removeValue(forKey: uploadId)
            isUploading = false
            
            return success
            
        } catch {
            uploadError = error.localizedDescription
            uploadProgress.removeValue(forKey: uploadId)
            isUploading = false
            return false
        }
    }
    
    // MARK: - Network-Aware Compression
    
    private func optimizeForUpload(imageData: Data, connectionSpeed: NetworkMonitor.ConnectionSpeed) async -> Data {
        guard let image = UIImage(data: imageData) else {
            return imageData
        }
        
        // Determine target size and quality based on connection
        let (targetSize, quality) = getOptimizationSettings(for: connectionSpeed)
        
        // Resize image
        let resizedImage = await resizeImage(image, to: targetSize)
        
        // Compress with appropriate quality
        guard let compressedData = resizedImage.jpegData(compressionQuality: quality) else {
            return imageData
        }
        
        // If still too large on slow connections, compress more aggressively
        if connectionSpeed == .poor || connectionSpeed == .fair {
            if compressedData.count > 100 * 1024 { // > 100KB
                if let extraCompressed = resizedImage.jpegData(compressionQuality: quality * 0.7) {
                    return extraCompressed
                }
            }
        }
        
        return compressedData
    }
    
    private func getOptimizationSettings(for speed: NetworkMonitor.ConnectionSpeed) -> (size: CGFloat, quality: CGFloat) {
        switch speed {
        case .excellent:
            return (1920, 0.85) // High quality for WiFi
        case .good:
            return (1440, 0.75) // Good quality for 4G
        case .fair:
            return (1080, 0.65) // Reduced quality for 3G
        case .poor:
            return (720, 0.50)  // Low quality for 2G
        case .offline:
            return (720, 0.50)  // Minimal for offline queue
        }
    }
    
    private func resizeImage(_ image: UIImage, to maxSize: CGFloat) async -> UIImage {
        return await Task.detached(priority: .userInitiated) {
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
            return renderer.image { context in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }.value
    }
    
    // MARK: - Upload Execution
    
    private func performUpload(data: Data, request: ImageUploadRequest, uploadId: String) async -> Bool {
        let baseURL = "https://pinit-backend-production.up.railway.app"
        guard let url = URL(string: "\(baseURL)/api/upload_user_image/") else {
            uploadError = "Invalid URL"
            return false
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = networkMonitor.connectionSpeed.timeout
        
        // Create multipart form data with progress tracking
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
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        urlRequest.httpBody = body
        
        uploadProgress[uploadId] = 0.5
        
        do {
            let (responseData, response) = try await uploadSession.data(for: urlRequest)
            
            uploadProgress[uploadId] = 0.9
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    let uploadResponse = try JSONDecoder().decode(ImageUploadResponse.self, from: responseData)
                    
                    if uploadResponse.success {
                        uploadProgress[uploadId] = 1.0
                        
                        // Clear cache and reload in background
                        Task {
                            await ImageManager.shared.clearUserCache(username: request.username)
                            await ImageManager.shared.loadUserImages(username: request.username)
                        }
                        
                        return true
                    } else {
                        uploadError = uploadResponse.message
                    }
                } else {
                    uploadError = "Upload failed (Status: \(httpResponse.statusCode))"
                }
            }
        } catch {
            uploadError = "Upload failed: \(error.localizedDescription)"
            print("❌ Upload error: \(error)")
        }
        
        return false
    }
    
    // MARK: - Background Upload Queue
    
    func queueUpload(_ request: ImageUploadRequest) {
        let task = UploadTask(id: UUID().uuidString, request: request)
        uploadQueue.append(task)
        
        Task {
            await processUploadQueue()
        }
    }
    
    private func processUploadQueue() async {
        guard !uploadQueue.isEmpty,
              activeUploads.count < maxConcurrentUploads else {
            return
        }
        
        while !uploadQueue.isEmpty && activeUploads.count < maxConcurrentUploads {
            let task = uploadQueue.removeFirst()
            activeUploads.insert(task.id)
            
            Task {
                let success = await uploadImage(task.request)
                await MainActor.run {
                    activeUploads.remove(task.id)
                }
                
                // Continue processing queue
                await processUploadQueue()
                
                if success {
                    print("✅ Background upload completed: \(task.request.filename)")
                } else {
                    print("❌ Background upload failed: \(task.request.filename)")
                }
            }
        }
    }
    
    // MARK: - Progress Tracking
    
    func getOverallProgress() -> Double {
        guard !uploadProgress.isEmpty else { return 0.0 }
        let total = uploadProgress.values.reduce(0.0, +)
        return total / Double(uploadProgress.count)
    }
    
    func hasActiveUploads() -> Bool {
        return !uploadProgress.isEmpty || !uploadQueue.isEmpty
    }
    
    // MARK: - Cancel Uploads
    
    func cancelAll() {
        uploadQueue.removeAll()
        uploadProgress.removeAll()
        activeUploads.removeAll()
        isUploading = false
    }
}

// MARK: - Upload Task
private struct UploadTask {
    let id: String
    let request: ImageUploadRequest
}

// MARK: - Helper Extension for Data
private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}


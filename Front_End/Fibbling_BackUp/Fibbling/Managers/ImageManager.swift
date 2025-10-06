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
    
    private init() {}
    
    // MARK: - Load User Images
    func loadUserImages(username: String) async {
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
        return userImages.first { $0.isPrimary }
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
    
    func clearError() {
        errorMessage = nil
    }
}

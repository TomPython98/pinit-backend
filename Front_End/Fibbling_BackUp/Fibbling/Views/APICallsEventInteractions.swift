// APIService.swift
// Add this file to your project to handle event feed API calls

import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

class EventAPIService {
    private let baseURL = "http://127.0.0.1:8000/api"
    private var cancellables = Set<AnyCancellable>()
    
    // Fetch event social feed
    func fetchEventFeed(eventID: UUID, currentUser: String, completion: @escaping (Result<EventInteractions, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/events/feed/\(eventID.uuidString)/?current_user=\(currentUser)")!
        
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.invalidResponse
                }
                return data
            }
            .decode(type: EventInteractions.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    if case .failure(let error) = result {
                        completion(.failure(error))
                    }
                },
                receiveValue: { interactions in
                    completion(.success(interactions))
                }
            )
            .store(in: &cancellables)
    }
    
    // Add a new post with possible images
    #if canImport(UIKit)
    func addPost(eventID: UUID, text: String, images: [UIImage]?, username: String, completion: @escaping (Result<EventInteractions.Post, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/events/comment/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // For now, we'll just handle text posts - image uploads would need multipart form data
        let postData: [String: Any] = [
            "username": username,
            "event_id": eventID.uuidString,
            "text": text
        ]
        
        // If you implement image uploads, you would process the images here
        // and add their URLs to the request
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: postData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.invalidResponse
                }
                return data
            }
            .decode(type: PostResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    if case .failure(let error) = result {
                        completion(.failure(error))
                    }
                },
                receiveValue: { response in
                    completion(.success(response.post))
                }
            )
            .store(in: &cancellables)
    }
    #else
    func addPost(eventID: UUID, text: String, images: [Any]?, username: String, completion: @escaping (Result<EventInteractions.Post, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/events/comment/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let postData: [String: Any] = [
            "username": username,
            "event_id": eventID.uuidString,
            "text": text
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: postData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.invalidResponse
                }
                return data
            }
            .decode(type: PostResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    if case .failure(let error) = result {
                        completion(.failure(error))
                    }
                },
                receiveValue: { response in
                    completion(.success(response.post))
                }
            )
            .store(in: &cancellables)
    }
    #endif
    
    // Like or unlike a post
    func toggleLike(eventID: UUID, postID: Int? = nil, username: String, completion: @escaping (Result<LikeResponse, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/events/like/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var likeData: [String: Any] = [
            "username": username,
            "event_id": eventID.uuidString
        ]
        
        // If postID is provided, we're liking a specific post rather than the event
        if let postID = postID {
            likeData["post_id"] = postID
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: likeData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.invalidResponse
                }
                return data
            }
            .decode(type: LikeResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    if case .failure(let error) = result {
                        completion(.failure(error))
                    }
                },
                receiveValue: { response in
                    completion(.success(response))
                }
            )
            .store(in: &cancellables)
    }
    
    // Add a reply to a post
    func addReply(eventID: UUID, postID: Int, text: String, username: String, completion: @escaping (Result<EventInteractions.Post, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/events/comment/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let replyData: [String: Any] = [
            "username": username,
            "event_id": eventID.uuidString,
            "text": text,
            "parent_id": postID
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: replyData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.invalidResponse
                }
                return data
            }
            .decode(type: PostResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    if case .failure(let error) = result {
                        completion(.failure(error))
                    }
                },
                receiveValue: { response in
                    completion(.success(response.post))
                }
            )
            .store(in: &cancellables)
    }
    
    // Record a share event
    func shareEvent(eventID: UUID, username: String, platform: String = "other", completion: @escaping (Result<ShareResponse, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/events/share/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let shareData: [String: Any] = [
            "username": username,
            "event_id": eventID.uuidString,
            "platform": platform
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: shareData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.invalidResponse
                }
                return data
            }
            .decode(type: ShareResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    if case .failure(let error) = result {
                        completion(.failure(error))
                    }
                },
                receiveValue: { response in
                    completion(.success(response))
                }
            )
            .store(in: &cancellables)
    }
}

// Response Types
struct PostResponse: Codable {
    let success: Bool
    let post: EventInteractions.Post
}

struct LikeResponse: Codable {
    let success: Bool
    let liked: Bool
    let total_likes: Int
}

struct ShareResponse: Codable {
    let success: Bool
    let total_shares: Int
}

// Error Type
enum APIError: Error {
    case invalidResponse
    case invalidData
    case requestFailed(Error)
}

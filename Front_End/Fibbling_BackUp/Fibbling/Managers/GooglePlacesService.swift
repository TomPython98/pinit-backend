//
//  GooglePlacesService.swift
//  Fibbling
//
//  Created by Cursor on 2025-10-13.
//

import Foundation
import CoreLocation
import SwiftUI

/// Thread-safe cache for images using actor
actor ImageCache {
    private var cache: [String: UIImage] = [:]
    private let maxSize: Int
    
    init(maxSize: Int = 50) {
        self.maxSize = maxSize
    }
    
    func get(_ key: String) -> UIImage? {
        return cache[key]
    }
    
    func set(_ key: String, image: UIImage) {
        // Prevent cache from growing too large
        if cache.count >= maxSize {
            // Remove oldest entries (simple LRU)
            let keysToRemove = Array(cache.keys.prefix(10))
            keysToRemove.forEach { cache.removeValue(forKey: $0) }
        }
        cache[key] = image
    }
    
    func clear() {
        cache.removeAll()
    }
}

/// Service to handle location searches using Google Places API
class GooglePlacesService {
    
    // Google Places API Key
    private let apiKey = "AIzaSyDyqfynUb6JNp2oklHh5cMqcxsfFkII6vA"
    
    // Thread-safe image cache
    private let imageCache = ImageCache()
    
    // Singleton for shared instance
    static let shared = GooglePlacesService()
    
    /// Enhanced location suggestion model with rich place data
    struct LocationSuggestion: Identifiable, Hashable {
        let id: String // place_id from Google
        let name: String
        let address: String
        let coordinate: CLLocationCoordinate2D
        let rating: Double?
        let userRatingsTotal: Int?
        let priceLevel: Int?
        let types: [String]
        let photoReferences: [String]
        let isOpenNow: Bool?
        let businessStatus: String?
        let phoneNumber: String?
        let website: String?
        
        // Convenience computed properties
        var hasPhotos: Bool {
            !photoReferences.isEmpty
        }
        
        var ratingText: String? {
            guard let rating = rating else { return nil }
            return String(format: "%.1f", rating)
        }
        
        var priceText: String? {
            guard let level = priceLevel else { return nil }
            return String(repeating: "$", count: level)
        }
        
        var primaryType: String? {
            types.first?.replacingOccurrences(of: "_", with: " ").capitalized
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: LocationSuggestion, rhs: LocationSuggestion) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    /// Search for location suggestions using Google Places Autocomplete API
    /// - Parameters:
    ///   - query: The search query
    ///   - coordinate: Optional coordinate for proximity bias
    /// - Returns: Array of location suggestions
    func searchLocations(query: String, near coordinate: CLLocationCoordinate2D? = nil) async throws -> [LocationSuggestion] {
        // Safety checks
        guard !query.isEmpty,
              query.count >= 2,
              query.count <= 100 else {
            return []
        }
        
        // Build URL for Google Places Autocomplete API
        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/autocomplete/json")!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "input", value: query),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "types", value: "establishment|geocode")
        ]
        
        // Add location bias if coordinate is provided
        if let coordinate = coordinate {
            queryItems.append(URLQueryItem(name: "location", value: "\(coordinate.latitude),\(coordinate.longitude)"))
            queryItems.append(URLQueryItem(name: "radius", value: "50000")) // 50km radius
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Parse the response
        let response = try JSONDecoder().decode(GooglePlacesAutocompleteResponse.self, from: data)
        
        guard response.status == "OK" || response.status == "ZERO_RESULTS" else {
            throw GooglePlacesError.apiError(response.status)
        }
        
        // Get details for each prediction to fetch coordinates
        var suggestions: [LocationSuggestion] = []
        
        for prediction in response.predictions.prefix(10) {
            // Safety check for valid prediction
            guard !prediction.place_id.isEmpty else { continue }
            
            if let suggestion = try? await getPlaceDetails(placeId: prediction.place_id) {
                suggestions.append(suggestion)
            }
        }
        
        return suggestions
    }
    
    /// Get place details including coordinates, ratings, photos, and more
    /// - Parameter placeId: Google Place ID
    /// - Returns: Location suggestion with full details
    private func getPlaceDetails(placeId: String) async throws -> LocationSuggestion {
        // Safety check
        guard !placeId.isEmpty else {
            throw GooglePlacesError.apiError("Invalid place ID")
        }
        
        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/details/json")!
        
        components.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "fields", value: "name,formatted_address,geometry,rating,user_ratings_total,price_level,types,photos,opening_hours,business_status,formatted_phone_number,website"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let response = try JSONDecoder().decode(GooglePlaceDetailsResponse.self, from: data)
        
        guard response.status == "OK",
              let result = response.result else {
            throw GooglePlacesError.apiError(response.status)
        }
        
        // Safety checks for required fields
        guard !result.name.isEmpty,
              !result.formatted_address.isEmpty else {
            throw GooglePlacesError.apiError("Invalid place data")
        }
        
        let coordinate = CLLocationCoordinate2D(
            latitude: result.geometry.location.lat,
            longitude: result.geometry.location.lng
        )
        
        // Extract photo references with safety checks
        let photoRefs: [String] = result.photos?.prefix(5).compactMap { photo in
            guard !photo.photo_reference.isEmpty else { return nil }
            return photo.photo_reference
        } ?? []
        
        return LocationSuggestion(
            id: placeId,
            name: result.name,
            address: result.formatted_address,
            coordinate: coordinate,
            rating: result.rating,
            userRatingsTotal: result.user_ratings_total,
            priceLevel: result.price_level,
            types: result.types ?? [],
            photoReferences: photoRefs,
            isOpenNow: result.opening_hours?.open_now,
            businessStatus: result.business_status,
            phoneNumber: result.formatted_phone_number,
            website: result.website
        )
    }
    
    /// Fetch a place photo with proper memory management and thread safety
    /// - Parameters:
    ///   - photoReference: Photo reference from place details
    ///   - maxWidth: Maximum width of the photo (default 400)
    /// - Returns: UIImage of the place
    func fetchPlacePhoto(photoReference: String, maxWidth: Int = 400) async throws -> UIImage {
        // Safety checks
        guard !photoReference.isEmpty else {
            throw GooglePlacesError.noResults
        }
        
        // Check cache first (thread-safe)
        if let cachedImage = await imageCache.get(photoReference) {
            return cachedImage
        }
        
        // Build URL
        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/photo")!
        
        components.queryItems = [
            URLQueryItem(name: "photo_reference", value: photoReference),
            URLQueryItem(name: "maxwidth", value: String(maxWidth)),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        // Fetch image data
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GooglePlacesError.noResults
        }
        
        // Create image from data
        guard let image = UIImage(data: data) else {
            throw GooglePlacesError.noResults
        }
        
        // Cache the image (thread-safe)
        await imageCache.set(photoReference, image: image)
        
        return image
    }
    
    /// Geocode an address to get coordinates
    /// - Parameter address: Address string to geocode
    /// - Returns: Location suggestion with coordinates
    func geocodeAddress(_ address: String) async throws -> LocationSuggestion {
        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/geocode/json")!
        
        components.queryItems = [
            URLQueryItem(name: "address", value: address),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let response = try JSONDecoder().decode(GoogleGeocodeResponse.self, from: data)
        
        guard response.status == "OK",
              let result = response.results.first else {
            throw GooglePlacesError.apiError(response.status)
        }
        
        let coordinate = CLLocationCoordinate2D(
            latitude: result.geometry.location.lat,
            longitude: result.geometry.location.lng
        )
        
        return LocationSuggestion(
            id: UUID().uuidString,
            name: result.formatted_address,
            address: result.formatted_address,
            coordinate: coordinate,
            rating: nil,
            userRatingsTotal: nil,
            priceLevel: nil,
            types: [],
            photoReferences: [],
            isOpenNow: nil,
            businessStatus: nil,
            phoneNumber: nil,
            website: nil
        )
    }
}

// MARK: - Response Models

private struct GooglePlacesAutocompleteResponse: Codable {
    let predictions: [Prediction]
    let status: String
    
    struct Prediction: Codable {
        let place_id: String
        let description: String
    }
}

private struct GooglePlaceDetailsResponse: Codable {
    let result: Result?
    let status: String
    
    struct Result: Codable {
        let name: String
        let formatted_address: String
        let geometry: Geometry
        let rating: Double?
        let user_ratings_total: Int?
        let price_level: Int?
        let types: [String]?
        let photos: [Photo]?
        let opening_hours: OpeningHours?
        let business_status: String?
        let formatted_phone_number: String?
        let website: String?
    }
    
    struct Geometry: Codable {
        let location: Location
    }
    
    struct Location: Codable {
        let lat: Double
        let lng: Double
    }
    
    struct Photo: Codable {
        let photo_reference: String
        let height: Int?
        let width: Int?
    }
    
    struct OpeningHours: Codable {
        let open_now: Bool?
    }
}

private struct GoogleGeocodeResponse: Codable {
    let results: [Result]
    let status: String
    
    struct Result: Codable {
        let formatted_address: String
        let geometry: Geometry
    }
    
    struct Geometry: Codable {
        let location: Location
    }
    
    struct Location: Codable {
        let lat: Double
        let lng: Double
    }
}

// MARK: - Error Types

enum GooglePlacesError: Error, LocalizedError {
    case apiError(String)
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .apiError(let status):
            return "Google Places API error: \(status)"
        case .noResults:
            return "No results found"
        }
    }
}


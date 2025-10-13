//
//  EnhancedLocationViews.swift
//  Fibbling
//
//  Created by Cursor on 2025-10-13.
//

import SwiftUI
import CoreLocation

// MARK: - Enhanced Location Suggestion Card with Photos & Ratings

struct EnhancedLocationSuggestionCard: View {
    let suggestion: GooglePlacesService.LocationSuggestion
    let onTap: () -> Void
    
    @State private var placeImage: UIImage?
    @State private var isLoadingImage = false
    @State private var imageTask: Task<Void, Never>?
    
    private let googlePlacesService = GooglePlacesService.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Photo Section
                placePhotoView
                    .frame(width: 100, height: 100)
                
                // Details Section
                VStack(alignment: .leading, spacing: 8) {
                    // Place Name
                    Text(suggestion.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    // Rating & Reviews
                    if let rating = suggestion.rating {
                        HStack(spacing: 4) {
                            // Stars
                            HStack(spacing: 1) {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < Int(rating.rounded()) ? "star.fill" : "star")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(index < Int(rating.rounded()) ? .yellow : .gray.opacity(0.3))
                                }
                            }
                            
                            // Rating number and review count combined
                            if let total = suggestion.userRatingsTotal {
                                Text("\(String(format: "%.1f", rating)) (\(formatReviewCount(total)))")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            } else {
                                Text(String(format: "%.1f", rating))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                    .lineLimit(1)
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Place Type & Price
                    HStack(spacing: 8) {
                        if let type = suggestion.primaryType {
                            HStack(spacing: 3) {
                                Image(systemName: iconForPlaceType(suggestion.types.first ?? ""))
                                    .font(.system(size: 10))
                                    .foregroundColor(.brandPrimary)
                                
                                Text(type)
                                    .font(.system(size: 11))
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.brandPrimary.opacity(0.1))
                            .cornerRadius(4)
                        }
                        
                        if let priceText = suggestion.priceText {
                            Text(priceText)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        if let isOpen = suggestion.isOpenNow {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(isOpen ? Color.green : Color.red)
                                    .frame(width: 6, height: 6)
                                
                                Text(isOpen ? "Open" : "Closed")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(isOpen ? .green : .red)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background((isOpen ? Color.green : Color.red).opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                    
                    // Address
                    Text(suggestion.address)
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 100)
            .background(Color.bgCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cardStroke, lineWidth: 1)
            )
            .shadow(color: Color.cardShadow.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadPlacePhoto()
        }
        .onDisappear {
            imageTask?.cancel()
            imageTask = nil
        }
    }
    
    private var placePhotoView: some View {
        ZStack {
            if let image = placeImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
            } else if isLoadingImage {
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(width: 100, height: 100)
                    .background(Color.bgSecondary)
            } else {
                // Placeholder with icon
                ZStack {
                    Color.brandPrimary.opacity(0.1)
                    
                    Image(systemName: iconForPlaceType(suggestion.types.first ?? ""))
                        .font(.system(size: 30))
                        .foregroundColor(.brandPrimary)
                }
                .frame(width: 100, height: 100)
            }
        }
        .cornerRadius(12, corners: [.topLeft, .bottomLeft])
    }
    
    private func loadPlacePhoto() {
        guard let photoRef = suggestion.photoReferences.first else { return }
        guard placeImage == nil && !isLoadingImage else { return }
        
        isLoadingImage = true
        
        imageTask = Task {
            do {
                let image = try await googlePlacesService.fetchPlacePhoto(photoReference: photoRef, maxWidth: 200)
                
                // Check if task was cancelled before updating UI
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.placeImage = image
                        self.isLoadingImage = false
                    }
                }
            } catch {
                // Check if task was cancelled before updating UI
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.isLoadingImage = false
                }
            }
        }
    }
    
    private func formatReviewCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        }
        return "\(count)"
    }
    
    private func iconForPlaceType(_ type: String) -> String {
        let typeStr = type.lowercased()
        
        if typeStr.contains("restaurant") || typeStr.contains("food") {
            return "fork.knife"
        } else if typeStr.contains("cafe") || typeStr.contains("coffee") {
            return "cup.and.saucer.fill"
        } else if typeStr.contains("bar") || typeStr.contains("night_club") {
            return "wineglass.fill"
        } else if typeStr.contains("hotel") || typeStr.contains("lodging") {
            return "bed.double.fill"
        } else if typeStr.contains("museum") || typeStr.contains("art") {
            return "building.columns.fill"
        } else if typeStr.contains("park") {
            return "leaf.fill"
        } else if typeStr.contains("gym") || typeStr.contains("fitness") {
            return "figure.run"
        } else if typeStr.contains("library") || typeStr.contains("book") {
            return "book.fill"
        } else if typeStr.contains("shopping") || typeStr.contains("store") {
            return "cart.fill"
        } else if typeStr.contains("university") || typeStr.contains("school") {
            return "graduationcap.fill"
        } else if typeStr.contains("church") || typeStr.contains("mosque") || typeStr.contains("temple") {
            return "building.fill"
        } else {
            return "mappin.circle.fill"
        }
    }
}

// MARK: - Compact Location Suggestion (for smaller spaces)

struct CompactLocationSuggestionCard: View {
    let suggestion: GooglePlacesService.LocationSuggestion
    let onTap: () -> Void
    
    @State private var placeImage: UIImage?
    
    private let googlePlacesService = GooglePlacesService.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Compact Photo
                if let image = placeImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.brandPrimary.opacity(0.1))
                        
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.brandPrimary)
                    }
                    .frame(width: 50, height: 50)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(suggestion.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)
                        
                        if let rating = suggestion.ratingText {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                                Text(rating)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }
                    
                    Text(suggestion.address)
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }
            .padding(12)
            .background(Color.bgCard)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.cardStroke, lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if let photoRef = suggestion.photoReferences.first {
                Task {
                    if let image = try? await googlePlacesService.fetchPlacePhoto(photoReference: photoRef, maxWidth: 100) {
                        await MainActor.run {
                            withAnimation {
                                self.placeImage = image
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Selected Location Detail Card

struct SelectedLocationDetailCard: View {
    let suggestion: GooglePlacesService.LocationSuggestion
    let onDeselect: () -> Void
    
    @State private var placeImages: [UIImage] = []
    @State private var isLoadingImages = false
    @State private var currentPhotoIndex = 0
    @State private var imageTasks: [Task<Void, Never>] = []
    
    private let googlePlacesService = GooglePlacesService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Photo Gallery
            if !placeImages.isEmpty {
                TabView(selection: $currentPhotoIndex) {
                    ForEach(Array(placeImages.enumerated()), id: \.offset) { index, image in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .tag(index)
                    }
                }
                .frame(height: 200)
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            } else if isLoadingImages {
                ZStack {
                    Color.bgSecondary
                    ProgressView()
                }
                .frame(height: 200)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.brandPrimary.opacity(0.3), Color.brandPrimary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(spacing: 8) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 40))
                            .foregroundColor(.brandPrimary)
                        
                        Text("No photos available")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                    }
                }
                .frame(height: 200)
            }
            
            // Details Section
            VStack(alignment: .leading, spacing: 16) {
                // Header with deselect button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.textPrimary)
                        
                        if let type = suggestion.primaryType {
                            Text(type)
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: onDeselect) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // Rating & Status Row
                HStack(spacing: 12) {
                    if let rating = suggestion.rating {
                        HStack(spacing: 6) {
                            HStack(spacing: 2) {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < Int(rating.rounded()) ? "star.fill" : "star")
                                        .font(.system(size: 14))
                                        .foregroundColor(index < Int(rating.rounded()) ? .yellow : .gray.opacity(0.3))
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text(String(format: "%.1f", rating))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.textPrimary)
                                
                                if let total = suggestion.userRatingsTotal {
                                    Text("\(formatReviewCount(total)) reviews")
                                        .font(.system(size: 10))
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.bgSecondary)
                        .cornerRadius(8)
                    }
                    
                    if let priceText = suggestion.priceText {
                        VStack(spacing: 2) {
                            Text(priceText)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                            
                            Text("Price")
                                .font(.system(size: 10))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    if let isOpen = suggestion.isOpenNow {
                        VStack(spacing: 2) {
                            Circle()
                                .fill(isOpen ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(isOpen ? "Open now" : "Closed")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(isOpen ? .green : .red)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background((isOpen ? Color.green : Color.red).opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                Divider()
                
                // Address
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.brandPrimary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Address")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textSecondary)
                        
                        Text(suggestion.address)
                            .font(.system(size: 14))
                            .foregroundColor(.textPrimary)
                    }
                }
                
                // Coordinates
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.brandAccent)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Coordinates")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textSecondary)
                        
                        Text("\(String(format: "%.4f", suggestion.coordinate.latitude)), \(String(format: "%.4f", suggestion.coordinate.longitude))")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.textPrimary)
                    }
                }
                
                // Contact Info
                if suggestion.phoneNumber != nil || suggestion.website != nil {
                    Divider()
                    
                    if let phone = suggestion.phoneNumber {
                        HStack(alignment: .center, spacing: 10) {
                            Image(systemName: "phone.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.brandSuccess)
                            
                            Text(phone)
                                .font(.system(size: 14))
                                .foregroundColor(.brandPrimary)
                        }
                    }
                    
                    if let _ = suggestion.website {
                        HStack(alignment: .center, spacing: 10) {
                            Image(systemName: "globe")
                                .font(.system(size: 20))
                                .foregroundColor(.brandAccent)
                            
                            Text("Website available")
                                .font(.system(size: 14))
                                .foregroundColor(.brandPrimary)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.bgCard)
        .cornerRadius(16)
        .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
        .onAppear {
            loadPlacePhotos()
        }
        .onDisappear {
            // Cancel all image loading tasks
            imageTasks.forEach { $0.cancel() }
            imageTasks.removeAll()
        }
    }
    
    private func loadPlacePhotos() {
        guard !suggestion.photoReferences.isEmpty else { return }
        guard placeImages.isEmpty && !isLoadingImages else { return }
        
        isLoadingImages = true
        
        // Cancel any existing tasks
        imageTasks.forEach { $0.cancel() }
        imageTasks.removeAll()
        
        let photoRefs = Array(suggestion.photoReferences.prefix(5))
        
        for photoRef in photoRefs {
            let task = Task {
                do {
                    let image = try await googlePlacesService.fetchPlacePhoto(photoReference: photoRef, maxWidth: 400)
                    
                    // Check if task was cancelled before updating UI
                    guard !Task.isCancelled else { return }
                    
                    await MainActor.run {
                        // Only add if we're still loading and haven't exceeded limit
                        if isLoadingImages && placeImages.count < 5 {
                            placeImages.append(image)
                        }
                        
                        // If this was the last image, stop loading
                        if placeImages.count >= photoRefs.count {
                            isLoadingImages = false
                        }
                    }
                } catch {
                    // Check if task was cancelled before updating UI
                    guard !Task.isCancelled else { return }
                    
                    await MainActor.run {
                        // If this was the last image, stop loading
                        if placeImages.count >= photoRefs.count - 1 {
                            isLoadingImages = false
                        }
                    }
                }
            }
            
            imageTasks.append(task)
        }
    }
    
    private func formatReviewCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}

// Note: RoundedCorner and cornerRadius extension are defined in CalendarView.swift
// to avoid duplicate declarations


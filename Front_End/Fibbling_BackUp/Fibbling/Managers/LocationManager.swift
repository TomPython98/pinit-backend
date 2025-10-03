import Foundation
import CoreLocation
import SwiftUI
import Combine

// MARK: - Location Manager for Real-time User Location
class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Default fallback location (can be updated based on user's region)
    @Published var defaultLocation = CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816) // Buenos Aires
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Show alert to user about enabling location in settings
            errorMessage = "Location access is required for finding nearby events. Please enable location services in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        isLoading = true
        errorMessage = nil
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLoading = false
    }
    
    func getCurrentLocation() -> CLLocationCoordinate2D {
        return location?.coordinate ?? defaultLocation
    }
    
    func isLocationAvailable() -> Bool {
        return location != nil && authorizationStatus == .authorizedWhenInUse
    }
    
    // Calculate distance between user and event
    func distanceToEvent(_ eventLocation: CLLocationCoordinate2D) -> Double? {
        guard let userLocation = location else { return nil }
        let eventCLLocation = CLLocation(latitude: eventLocation.latitude, longitude: eventLocation.longitude)
        return userLocation.distance(from: eventCLLocation) / 1000 // Return in kilometers
    }
    
    // Get nearby events within radius
    func getNearbyEvents(_ events: [StudyEvent], radiusKm: Double = 10.0) -> [StudyEvent] {
        guard let userLocation = location else { return events }
        
        return events.filter { event in
            let eventLocation = CLLocation(latitude: event.coordinate.latitude, longitude: event.coordinate.longitude)
            let distance = userLocation.distance(from: eventLocation) / 1000 // Convert to km
            return distance <= radiusKm
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        DispatchQueue.main.async {
            self.location = newLocation
            self.isLoading = false
            self.errorMessage = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "Failed to get location: \(error.localizedDescription)"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startLocationUpdates()
            case .denied, .restricted:
                self.errorMessage = "Location access denied. Please enable location services in Settings to find nearby events."
            case .notDetermined:
                self.requestLocationPermission()
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Location Permission View
struct LocationPermissionView: View {
    @ObservedObject var locationManager: LocationManager
    let onPermissionGranted: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.brandPrimary)
            
            VStack(spacing: 12) {
                Text("location_access_required".localized)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.textPrimary)
                
                Text("location_permission_message".localized)
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    locationManager.requestLocationPermission()
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("allow_location_access".localized)
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.brandPrimary)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    onPermissionGranted()
                }) {
                    Text("continue_without_location".localized)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            
            if let errorMessage = locationManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.brandWarning)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .padding(40)
        .background(Color.bgSurface)
        .cornerRadius(20)
        .shadow(color: Color.cardShadow, radius: 20, x: 0, y: 10)
        .onChange(of: locationManager.authorizationStatus) { status in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                onPermissionGranted()
            }
        }
    }
}

// MARK: - Location Status Indicator
struct LocationStatusIndicator: View {
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: locationIcon)
                .font(.caption)
                .foregroundColor(locationColor)
            
            Text(locationText)
                .font(.caption.weight(.medium))
                .foregroundColor(locationColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(locationColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var locationIcon: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return locationManager.location != nil ? "location.fill" : "location"
        case .denied, .restricted:
            return "location.slash"
        case .notDetermined:
            return "location.circle"
        @unknown default:
            return "location.circle"
        }
    }
    
    private var locationColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return locationManager.location != nil ? .brandSuccess : .brandWarning
        case .denied, .restricted:
            return .brandWarning
        case .notDetermined:
            return .textSecondary
        @unknown default:
            return .textSecondary
        }
    }
    
    private var locationText: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return locationManager.location != nil ? "location_active".localized : "getting_location".localized
        case .denied, .restricted:
            return "location_disabled".localized
        case .notDetermined:
            return "location_needed".localized
        @unknown default:
            return "location_needed".localized
        }
    }
}

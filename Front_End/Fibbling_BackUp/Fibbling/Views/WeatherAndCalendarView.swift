import SwiftUI
import MapKit
import Combine
import CoreLocation

// Conditionally import MapboxMaps if available
#if canImport(MapboxMaps)
import MapboxMaps
#endif

struct WeatherAndCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var showCalendar: Bool
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
    
    // Add state properties for map
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816), // Buenos Aires coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var mapEvents: [StudyEvent] = []

    var body: some View {
        NavigationLink(destination: StudyMapView()
            .environmentObject(accountManager)
            .environmentObject(calendarManager)) {
            VStack(spacing: 0) {
                // Map Preview with Mapbox
                ZStack(alignment: .topLeading) {
                    // Using a compact version of StudyMapBoxView
                    CompactMapboxView(events: mapEvents, region: $region)
                        .frame(height: 160)
                        .cornerRadius(16)
                }
                
                // View Map Button Section with refined styling
                HStack {
                    Spacer()
                    
                    Image(systemName: "map.fill")
                        .font(.headline)
                        .foregroundColor(.brandPrimary)
                        .padding(.trailing, 4)
                    
                    Text("View Full Map")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.textPrimary)
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.brandPrimary)
                        .padding(.leading, 4)
                    
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.bgCard, .bgAccent.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.bgCard)
                    .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
            )
            .onAppear {
                fetchEvents()
            }
        }
        .buttonStyle(PlainButtonStyle()) // Prevents default navigation button styling
    }
    
    // Function to fetch events, same as in StudyMapView
    private func fetchEvents() {
        guard let username = accountManager.currentUser else {
            return
        }
        
        
        // Use calendar manager's events directly
        DispatchQueue.main.async {
            // This gives us the already filtered and properly decoded events
            if !self.calendarManager.events.isEmpty {
                self.mapEvents = self.calendarManager.events
            } else {
            }
        }
    }
}

// Simplified MapboxView for compact display that uses the same approach as the full map
#if canImport(MapboxMaps)
struct CompactMapboxView: UIViewRepresentable {
    var events: [StudyEvent]
    var region: Binding<MKCoordinateRegion>
    
    func makeUIView(context: Context) -> MapView {
        // Use the same Mapbox setup as in StudyMapBoxView
        MapboxOptions.accessToken = "pk.eyJ1IjoidG9tYmVzaSIsImEiOiJjbTdwNDdvbXAwY3I3MmtzYmZ3dzVtaGJrIn0.yiXVdzVGYjTucLPZPa0hjw"
        let initialRegion = region.wrappedValue
        let cameraOptions = CameraOptions(
            center: initialRegion.center,
            zoom: 13,  // Slightly higher zoom for the smaller map
            bearing: 0,
            pitch: 0
        )
        let mapInitOptions = MapInitOptions(
            cameraOptions: cameraOptions,
            styleURI: StyleURI.streets
        )
        // REVERT: Let SwiftUI handle frame sizing
        let mapView = MapView(frame: .zero, mapInitOptions: mapInitOptions)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Configure location provider
        let locationProvider = AppleLocationProvider()
        locationProvider.options.activityType = .automotiveNavigation
        mapView.location.override(provider: locationProvider)
        
        // Add annotations when style is loaded
        mapView.mapboxMap.onStyleLoaded
            .observeNext { _ in
                updateAnnotations(on: mapView, region: initialRegion, events: events)
            }
            .store(in: &context.coordinator.cancelables)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MapView, context: Context) {
        // Update annotations when events or region changes
        let newClusters = clusterEvents(events, region: region.wrappedValue)
        
        // Simple refresh mechanism to match StudyMapBoxView
        if newClusters != context.coordinator.lastClusters || 
           context.coordinator.forceRefresh != events.count {
            // Clear all existing annotations
            uiView.viewAnnotations.removeAll()
            
            // Add updated annotations
            updateAnnotations(on: uiView, region: region.wrappedValue, events: events)
            
            // Update tracking state
            context.coordinator.lastClusters = newClusters
            context.coordinator.forceRefresh = events.count
            
            // Force layout update
            uiView.setNeedsLayout()
        }
    }
    
    private func updateAnnotations(on mapView: MapView, region: MKCoordinateRegion, events: [StudyEvent]) {
        // Use the same clustering logic as in StudyMapBoxView
        let clusters = clusterEvents(events, region: region)
        for cluster in clusters {
            if cluster.events.count == 1, let event = cluster.events.first {
                let annotationView = createAnnotationView(for: event)
                let viewAnnotation = ViewAnnotation(coordinate: event.coordinate, view: annotationView)
                viewAnnotation.allowOverlap = true
                mapView.viewAnnotations.add(viewAnnotation)
            } else {
                let clusterView = ClusterAnnotationView(events: cluster.events, frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                let viewAnnotation = ViewAnnotation(coordinate: cluster.coordinate, view: clusterView)
                viewAnnotation.allowOverlap = true
                mapView.viewAnnotations.add(viewAnnotation)
            }
        }
    }
    
    private func createAnnotationView(for event: StudyEvent) -> AnimatedAnnotationView {
        // Create annotation views just like in StudyMapBoxView
        let annotationView = AnimatedAnnotationView(frame: CGRect(x: 0, y: 0, width: 100, height: 70))
        annotationView.configure(for: event)
        return annotationView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var cancelables = Set<AnyCancellable>()
        var lastClusters: [Cluster] = []
        var forceRefresh: Int = 0
    }
}
#else
// Fallback to a simple MapKit implementation if MapboxMaps is not available
struct CompactMapboxView: UIViewRepresentable {
    var events: [StudyEvent]
    var region: Binding<MKCoordinateRegion>
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region.wrappedValue
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        let annotations = events.map { event in
            let annotation = MKPointAnnotation()
            annotation.coordinate = event.coordinate
            annotation.title = event.title
            return annotation
        }
        uiView.addAnnotations(annotations)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var cancelables = Set<AnyCancellable>()
        var lastClusters: [MKAnnotation] = []
        var forceRefresh: Int = 0
    }
}
#endif

import SwiftUI
import MapboxMaps
import Combine
import CoreLocation
import MapKit
import UIKit

// MARK: - Dummy Model Definitions



// For simplicity, extend CLLocationCoordinate2D to conform to Codable.
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lat = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let lon = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        self.init(latitude: lat, longitude: lon)
    }
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

import Foundation
import CoreLocation

// Updated EventHotPost to conform to Hashable
struct EventHotPost: Identifiable, Codable, Hashable {
    let id: UUID
    let eventId: UUID
    let text: String
    let username: String
    let coordinate: CLLocationCoordinate2D
    let likeCount: Int
    
    // Implement Hashable methods
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(eventId)
        hasher.combine(text)
        hasher.combine(username)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
        hasher.combine(likeCount)
    }
    
    // Implement == for Hashable
    static func == (lhs: EventHotPost, rhs: EventHotPost) -> Bool {
        return lhs.id == rhs.id &&
               lhs.eventId == rhs.eventId &&
               lhs.text == rhs.text &&
               lhs.username == rhs.username &&
               lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude &&
               lhs.likeCount == rhs.likeCount
    }
    
    // Add an initializer that requires an explicit id
    init(id: UUID = UUID(), eventId: UUID, text: String, username: String, coordinate: CLLocationCoordinate2D, likeCount: Int) {
        self.id = id
        self.eventId = eventId
        self.text = text
        self.username = username
        self.coordinate = coordinate
        self.likeCount = likeCount
    }
}
// Dummy function to simulate fetching hot posts.
func getHotPostsForMap() -> [EventHotPost] {
    return [
        EventHotPost(
            eventId: UUID(),
            text: "Hot Post 1",
            username: "alice",
            coordinate: CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816),
            likeCount: 10
        ),
        EventHotPost(
            eventId: UUID(),
            text: "Hot Post 2",
            username: "bob",
            coordinate: CLLocationCoordinate2D(latitude: -34.5889, longitude: -58.4108),
            likeCount: 5
        )
    ]
}

// Modify the StudyMapView to add a computed property for hot posts button
fileprivate struct HotPostsButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "flame.fill")
                .resizable()
                .frame(width: 24, height: 30)
                .foregroundColor(.orange)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
        }
        .padding(.trailing, 8)
    }
}


// MARK: - Networking Response Structures

struct EventPost: Codable {
    let id: Int
    let text: String
    let username: String
    let created_at: String
    let imageURLs: [String]?
    var likes: Int  // Make this mutable
    let isLikedByCurrentUser: Bool
    let replies: [EventPost]
}

struct EventFeedResponse: Codable {
    let posts: [EventPost]
    let likes: EventLikes
    let shares: EventShares
}

struct EventLikes: Codable {
    let total: Int
    let users: [String]
}

struct EventShares: Codable {
    let total: Int
    let breakdown: [String: Int]
}



// MARK: - HotPostTapHandler (Helper for tap gesture on hot posts)
private class HotPostTapHandler: NSObject {
    private let onTap: () -> Void
    init(onTap: @escaping () -> Void) {
        self.onTap = onTap
        super.init()
    }
    @objc func handleTap() {
        onTap()
    }
}
private var hotPostTapHandlerKey: UInt8 = 0

// MARK: - AnimatedAnnotationView
final class AnimatedAnnotationView: UIView {
    var onSelect: (() -> Void)?
    var onClose: (() -> Void)?
    
    private var eventType: EventType = .study
    private var isPublic: Bool = true
    private var isCertified: Bool = false
    
    var selected: Bool = false {
        didSet {
            animateSelection()
            if selected {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.selected = false
                }
            }
        }
    }
    
    @objc private func handleTap() {
        selected = true
        onSelect?()
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        label.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.layer.borderWidth = 0.5
        label.layer.borderColor = UIColor.black.withAlphaComponent(0.3).cgColor
        return label
    }()
    
    private let pinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let certifiedBadge: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
        imageView.tintColor = UIColor.systemGreen
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    private let privateBadge: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "lock.fill"))
        imageView.tintColor = UIColor.systemOrange
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    private let pinContainer = UIView()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [pinContainer, titleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    var title: String? {
        get { titleLabel.text }
        set {
            titleLabel.text = newValue
            let minWidth: CGFloat = 90
            let maxWidth: CGFloat = 130
            let horizontalPadding: CGFloat = 10
            let verticalPadding: CGFloat = 6
            let expectedSize = titleLabel.sizeThatFits(CGSize(width: maxWidth - horizontalPadding, height: .greatestFiniteMagnitude))
            let calculatedWidth = max(minWidth, min(maxWidth, expectedSize.width + horizontalPadding))
            let calculatedHeight = expectedSize.height + verticalPadding
            frame.size.width = calculatedWidth
            frame.size.height = calculatedHeight + 50
            titleLabel.frame = CGRect(x: horizontalPadding / 2,
                                      y: verticalPadding / 2,
                                      width: calculatedWidth - horizontalPadding,
                                      height: calculatedHeight)
        }
    }
    
    func configure(for event: StudyEvent) {
        self.eventType = event.eventType
        self.isPublic = event.isPublic
        self.isCertified = event.host.userprofile.is_certified
        self.title = event.title
        updateAppearance()
    }
    
    private func updateAppearance() {
        let pinImageName: String
        let pinTintColor: UIColor
        switch eventType {
        case .study:
            pinImageName = "Study"
            pinTintColor = .systemBlue
        case .party:
            pinImageName = "Party"
            pinTintColor = .systemPurple
        case .business:
            pinImageName = "Business"
            pinTintColor = .systemIndigo
        case .cultural:
            pinImageName = "Cultural"
            pinTintColor = .systemOrange
        case .academic:
            pinImageName = "Academic"
            pinTintColor = .systemGreen
        case .networking:
            pinImageName = "Networking"
            pinTintColor = .systemPink
        case .social:
            pinImageName = "Social"
            pinTintColor = .systemRed
        case .language_exchange:
            pinImageName = "LanguageExchange"
            pinTintColor = .systemTeal
        case .other:
            pinImageName = "Other"
            pinTintColor = .systemGray
        }
        if let image = UIImage(named: pinImageName) {
            pinImageView.image = image
            pinImageView.tintColor = pinTintColor
        } else {
            pinImageView.image = UIImage(named: "dest-pin")
        }
        certifiedBadge.isHidden = !isCertified
        privateBadge.isHidden = isPublic
        
        pinContainer.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        pinContainer.layer.borderWidth = 2
        pinContainer.layer.borderColor = UIColor.black.cgColor
        pinContainer.layer.cornerRadius = 20
        
        if !isPublic {
            layer.borderWidth = 1.0
            layer.borderColor = UIColor.systemOrange.cgColor
            layer.cornerRadius = 10
            backgroundColor = UIColor.white.withAlphaComponent(0.1)
            titleLabel.layer.borderWidth = 0.5
            titleLabel.layer.borderColor = UIColor.systemOrange.cgColor
        } else {
            layer.borderWidth = 0
            backgroundColor = .clear
            titleLabel.layer.borderWidth = 0
        }
        
        titleLabel.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        titleLabel.layer.shadowRadius = 2
        titleLabel.layer.shadowOpacity = 0.3
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear
        pinContainer.translatesAutoresizingMaskIntoConstraints = false
        pinContainer.addSubview(pinImageView)
        pinContainer.addSubview(certifiedBadge)
        pinContainer.addSubview(privateBadge)
        addSubview(stackView)
        titleLabel.layoutMargins = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        pinImageView.translatesAutoresizingMaskIntoConstraints = false
        certifiedBadge.translatesAutoresizingMaskIntoConstraints = false
        privateBadge.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            pinContainer.heightAnchor.constraint(equalToConstant: 40),
            pinContainer.widthAnchor.constraint(equalToConstant: 40),
            
            pinImageView.centerXAnchor.constraint(equalTo: pinContainer.centerXAnchor),
            pinImageView.centerYAnchor.constraint(equalTo: pinContainer.centerYAnchor),
            pinImageView.widthAnchor.constraint(equalToConstant: 30),
            pinImageView.heightAnchor.constraint(equalToConstant: 30),
            
            certifiedBadge.topAnchor.constraint(equalTo: pinContainer.topAnchor, constant: -4),
            certifiedBadge.trailingAnchor.constraint(equalTo: pinContainer.trailingAnchor, constant: 4),
            certifiedBadge.widthAnchor.constraint(equalToConstant: 16),
            certifiedBadge.heightAnchor.constraint(equalToConstant: 16),
            
            privateBadge.topAnchor.constraint(equalTo: pinContainer.topAnchor, constant: -4),
            privateBadge.leadingAnchor.constraint(equalTo: pinContainer.leadingAnchor, constant: -4),
            privateBadge.widthAnchor.constraint(equalToConstant: 16),
            privateBadge.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    private func animateSelection() {
        UIView.animate(withDuration: 0.3) {
            self.pinImageView.transform = self.selected ? CGAffineTransform(scaleX: 1.3, y: 1.3) : .identity
            if !self.certifiedBadge.isHidden {
                self.certifiedBadge.transform = self.selected ? CGAffineTransform(scaleX: 1.2, y: 1.2) : .identity
            }
            if !self.privateBadge.isHidden {
                self.privateBadge.transform = self.selected ? CGAffineTransform(scaleX: 1.2, y: 1.2) : .identity
            }
        }
    }
}

// MARK: - HotPostAnnotationView
struct HotPostAnnotationView: UIViewRepresentable {
    let hotPost: EventHotPost
    var onTap: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 180, height: 80))
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        
        let textLabel = UILabel(frame: CGRect(x: 10, y: 10, width: 160, height: 40))
        textLabel.text = hotPost.text
        textLabel.font = UIFont.systemFont(ofSize: 12)
        textLabel.numberOfLines = 2
        view.addSubview(textLabel)
        
        let userLabel = UILabel(frame: CGRect(x: 10, y: 55, width: 100, height: 20))
        userLabel.text = "@\(hotPost.username)"
        userLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        userLabel.textColor = .gray
        view.addSubview(userLabel)
        
        let likesLabel = UILabel(frame: CGRect(x: 140, y: 55, width: 30, height: 20))
        likesLabel.text = "❤️ \(hotPost.likeCount)"
        likesLabel.font = UIFont.systemFont(ofSize: 10)
        likesLabel.textAlignment = .right
        view.addSubview(likesLabel)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No dynamic update needed.
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: HotPostAnnotationView
        init(_ parent: HotPostAnnotationView) {
            self.parent = parent
        }
        @objc func handleTap() {
            parent.onTap()
        }
    }
}

// MARK: - HotPostDetailView
struct HotPostDetailView: View {
    let hotPost: EventHotPost
    var onViewEvent: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text(hotPost.text)
                    .font(.body)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                HStack {
                    Text("Posted by @\(hotPost.username)")
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                    Spacer()
                    Label("\(hotPost.likeCount)", systemImage: "heart.fill")
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 4)
            .padding()
            
            Button(action: {
                dismiss()
                onViewEvent()
            }) {
                Label("View Related Event", systemImage: "calendar")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("Popular Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - ClusterAnnotationView
final class ClusterAnnotationView: UIView {
    private var eventCounts: [EventType: Int] = [:]
    private var hasPrivateEvents: Bool = false
    private var hasCertifiedEvents: Bool = false
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let circleView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    private let mixedTypesIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "square.grid.2x2.fill"))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    private let privateBadge: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "lock.fill"))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    init(events: [StudyEvent], frame: CGRect) {
        super.init(frame: frame)
        configureWithEvents(events)
    }
    
    private func configureWithEvents(_ events: [StudyEvent]) {
        backgroundColor = .clear
        
        for event in events {
            eventCounts[event.eventType, default: 0] += 1
            if !event.isPublic { hasPrivateEvents = true }
            if event.host.userprofile.is_certified { hasCertifiedEvents = true }
        }
        
        circleView.frame = bounds
        circleView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(circleView)
        
        countLabel.text = "\(events.count)"
        countLabel.frame = bounds
        countLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(countLabel)
        
        mixedTypesIcon.isHidden = eventCounts.keys.count <= 1
        addSubview(mixedTypesIcon)
        
        privateBadge.isHidden = !hasPrivateEvents
        addSubview(privateBadge)
        
        let dominantType = eventCounts.max(by: { $0.value < $1.value })?.key ?? .other
        let (size, color) = getAppearanceForCluster(count: events.count, dominantType: dominantType)
        
        self.frame = CGRect(x: 0, y: 0, width: size, height: size)
        circleView.backgroundColor = color
        circleView.layer.cornerRadius = size / 2
        countLabel.font = UIFont.boldSystemFont(ofSize: size * 0.4)
        
        let iconSize = size * 0.25
        mixedTypesIcon.frame = CGRect(x: size * 0.15, y: size * 0.6, width: iconSize, height: iconSize)
        privateBadge.frame = CGRect(x: size * 0.65, y: size * 0.6, width: iconSize, height: iconSize)
        
        layer.shadowColor = UIColor.white.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 50
        layer.shadowOffset = .zero
    }
    
    private func getAppearanceForCluster(count: Int, dominantType: EventType) -> (CGFloat, UIColor) {
        let size: CGFloat
        if count >= 15 { size = 65 }
        else if count >= 8 { size = 55 }
        else if count >= 3 { size = 45 }
        else { size = 40 }
        
        let color: UIColor
        switch dominantType {
        case .study:
            color = UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1)  // Blue
        case .party:
            color = UIColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 1)  // Purple
        case .business:
            color = UIColor(red: 0.3, green: 0.3, blue: 0.7, alpha: 1)  // Dark Blue
        case .cultural:
            color = UIColor(red: 0.9, green: 0.5, blue: 0.2, alpha: 1)  // Orange
        case .academic:
            color = UIColor(red: 0.2, green: 0.7, blue: 0.4, alpha: 1)  // Green
        case .networking:
            color = UIColor(red: 0.7, green: 0.2, blue: 0.7, alpha: 1)  // Magenta
        case .social:
            color = UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1)  // Red
        case .language_exchange:
            color = UIColor(red: 0.3, green: 0.8, blue: 0.8, alpha: 1)  // Cyan
        case .other:
            color = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)  // Gray
        }
        
        return (size, color)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Clustering Logic
struct Cluster: Equatable {
    var events: [StudyEvent]
    var coordinate: CLLocationCoordinate2D {
        let lat = events.map { $0.coordinate.latitude }.reduce(0, +) / Double(events.count)
        let lon = events.map { $0.coordinate.longitude }.reduce(0, +) / Double(events.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    static func == (lhs: Cluster, rhs: Cluster) -> Bool {
        let lhsIDs = Set(lhs.events.map { $0.id })
        let rhsIDs = Set(rhs.events.map { $0.id })
        return lhsIDs == rhsIDs &&
            abs(lhs.coordinate.latitude - rhs.coordinate.latitude) < 0.0001 &&
            abs(lhs.coordinate.longitude - rhs.coordinate.longitude) < 0.0001
    }
}

/// Clusters events based on a distance threshold that scales with the current map region.
func clusterEvents(_ events: [StudyEvent], region: MKCoordinateRegion) -> [Cluster] {
    // First, deduplicate events by ID only
    var uniqueEvents: [StudyEvent] = []
    var seenIDs = Set<UUID>()
    
    for event in events {
        // Only deduplicate by ID, not by content signature
        // Multiple events can have the same title and location
        if !seenIDs.contains(event.id) {
            uniqueEvents.append(event)
            seenIDs.insert(event.id)
        } else {
        }
    }
    
    // Now proceed with clustering using the deduplicated events
    let threshold = region.span.longitudeDelta * 0.2
    var clusters: [Cluster] = []
    var unclustered = uniqueEvents
    
    while !unclustered.isEmpty {
        let event = unclustered.removeFirst()
        var clusterEvents = [event]
        unclustered.removeAll { otherEvent in
            let dLat = abs(event.coordinate.latitude - otherEvent.coordinate.latitude)
            let dLon = abs(event.coordinate.longitude - otherEvent.coordinate.longitude)
            if dLat < threshold && dLon < threshold {
                clusterEvents.append(otherEvent)
                return true
            }
            return false
        }
        clusters.append(Cluster(events: clusterEvents))
    }
    return clusters
}

// MARK: - StudyMapBoxView (Mapbox with Clustering)
struct StudyMapBoxView: UIViewRepresentable {
    var events: [StudyEvent]
    var region: Binding<MKCoordinateRegion>
    var onSelect: ((StudyEvent) -> Void)?
    
    func makeUIView(context: Context) -> MapView {
        MapboxOptions.accessToken = "pk.eyJ1IjoidG9tYmVzaSIsImEiOiJjbTdwNDdvbXAwY3I3MmtzYmZ3dzVtaGJrIn0.yiXVdzVGYjTucLPZPa0hjw"
        let initialRegion = region.wrappedValue
        let cameraOptions = CameraOptions(
            center: initialRegion.center,
            zoom: 12,
            bearing: 0,
            pitch: 0
        )
        let mapInitOptions = MapInitOptions(
            cameraOptions: cameraOptions,
            styleURI: StyleURI.streets
        )
        let mapView = MapView(frame: .zero, mapInitOptions: mapInitOptions)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let locationProvider = AppleLocationProvider()
        locationProvider.options.activityType = .automotiveNavigation
        mapView.location.override(provider: locationProvider)
        
        // Enable user location display with beautiful custom styling
        let puck2DConfiguration = Puck2DConfiguration(
            topImage: createCustomLocationIcon(),
            bearingImage: createCustomBearingIcon(),
            shadowImage: nil,
            scale: .constant(1.2),
            showsAccuracyRing: true,
            accuracyRingColor: UIColor.systemBlue.withAlphaComponent(0.2),
            accuracyRingBorderColor: UIColor.systemBlue.withAlphaComponent(0.4)
        )
        mapView.location.options.puckType = .puck2D(puck2DConfiguration)
        mapView.location.options.puckBearingEnabled = true
        
        mapView.mapboxMap.onCameraChanged.observe { [weak mapView] event in
            guard let mapView = mapView else { return }
            let topLeft = mapView.mapboxMap.coordinate(for: CGPoint(x: 0, y: 0))
            let bottomRight = mapView.mapboxMap.coordinate(for: CGPoint(x: mapView.bounds.width, y: mapView.bounds.height))
            let center = event.cameraState.center
            let span = MKCoordinateSpan(
                latitudeDelta: abs(topLeft.latitude - bottomRight.latitude),
                longitudeDelta: abs(topLeft.longitude - bottomRight.longitude)
            )
            DispatchQueue.main.async {
                region.wrappedValue = MKCoordinateRegion(center: center, span: span)
            }
        }.store(in: &context.coordinator.cancelables)
        
        mapView.mapboxMap.onStyleLoaded
            .observeNext { _ in
                updateAnnotations(on: mapView, region: initialRegion, events: events)
            }
            .store(in: &context.coordinator.cancelables)
        
        // Center map on user location only once when first detected
        var hasCenteredOnLocation = false
        mapView.location.onLocationChange.observe { [weak mapView] locations in
            guard let mapView = mapView, let location = locations.first, !hasCenteredOnLocation else { return }
            DispatchQueue.main.async {
                let cameraOptions = CameraOptions(
                    center: location.coordinate,
                    zoom: 15,
                    bearing: 0,
                    pitch: 0
                )
                mapView.mapboxMap.setCamera(to: cameraOptions)
                hasCenteredOnLocation = true
            }
        }.store(in: &context.coordinator.cancelables)
        
        return mapView
    }
    
    
    func updateUIView(_ uiView: MapView, context: Context) {
        let newClusters = clusterEvents(events, region: region.wrappedValue)
        
        // Simple refresh mechanism to avoid cascading calls
        if newClusters != context.coordinator.lastClusters || 
           context.coordinator.forceRefresh != events.count {
            
            // Clear all existing annotations
            uiView.viewAnnotations.removeAll()
            
            // Add updated annotations
            updateAnnotations(on: uiView, region: region.wrappedValue, events: events)
            
            // Update tracking state
            context.coordinator.lastClusters = newClusters
            context.coordinator.forceRefresh = events.count
            
            // Force layout update to ensure annotations are properly displayed
            uiView.setNeedsLayout()
        }
    }
    

    
    private func updateAnnotations(on mapView: MapView, region: MKCoordinateRegion, events: [StudyEvent]) {
        let clusters = clusterEvents(events, region: region)
        for cluster in clusters {
            if cluster.events.count == 1, let event = cluster.events.first {
                let customView = createAnnotationView(for: event)
                let viewAnnotation = ViewAnnotation(coordinate: event.coordinate, view: customView)
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    private func createAnnotationView(for event: StudyEvent) -> AnimatedAnnotationView {
        let annotationView = AnimatedAnnotationView(frame: CGRect(x: 0, y: 0, width: 100, height: 70))
        annotationView.configure(for: event)
        annotationView.onSelect = {
            onSelect?(event)
        }
        return annotationView
    }
    
    class Coordinator: NSObject {
        var cancelables = Set<AnyCancellable>()
        var lastClusters: [Cluster] = []
        var forceRefresh: Int = 0
    }
    
    // MARK: - Custom Icon Creation
    private func createCustomLocationIcon() -> UIImage? {
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Create a beautiful gradient circle
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemBlue.withAlphaComponent(0.8).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
            
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = size.width / 2 - 2
            
            // Draw gradient circle
            cgContext.addEllipse(in: CGRect(x: 2, y: 2, width: radius * 2, height: radius * 2))
            cgContext.clip()
            cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
            
            // Add white center dot
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.addEllipse(in: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8))
            cgContext.fillPath()
        }
    }
    
    private func createCustomBearingIcon() -> UIImage? {
        let size = CGSize(width: 16, height: 16)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Create a small arrow pointing north
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.setStrokeColor(UIColor.systemBlue.cgColor)
            cgContext.setLineWidth(1.5)
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: size.width / 2, y: 2))
            path.addLine(to: CGPoint(x: size.width - 2, y: size.height - 2))
            path.addLine(to: CGPoint(x: size.width / 2, y: size.height - 4))
            path.addLine(to: CGPoint(x: 2, y: size.height - 2))
            path.close()
            
            cgContext.addPath(path.cgPath)
            cgContext.fillPath()
            cgContext.addPath(path.cgPath)
            cgContext.strokePath()
        }
    }
}

// MARK: - StudyMapView
struct StudyMapView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816), // Default to Buenos Aires
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var showLocationPermission = false
    @State private var showEventCreationSheet = false
    @State private var newEventCoordinate: CLLocationCoordinate2D? = nil
    @State private var isSearchExpanded = false
    @State private var showSearchSheet = false
    @State private var selectedEvent: StudyEvent?
    
    @State private var mapSearchQuery = ""
    @State private var mapSearchResults: [MKMapItem] = []
    @State private var filterQuery: String = ""
    @State private var filterPrivateOnly: Bool = false
    @State private var filterCertifiedOnly: Bool = false
    @State private var filterEventType: EventType? = nil
    @State private var showFilterView: Bool = false
    
    @State private var showHotPosts: [EventHotPost] = []
    @State private var isCreatingEvent = false
    @State private var lastCreatedEventTitle = ""
    @State private var lastCreationTime = Date(timeIntervalSince1970: 0)
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Auto-refresh settings
    @State private var showViewModeSelector: Bool = false
    
    enum EventViewMode: CaseIterable {
        case all, autoMatched, rsvpedOnly
    }
    @State private var eventViewMode: EventViewMode = .all

    // MARK: - State for UI Animation
    
    // MARK: - Helper Functions
    
    /// Convert a date to a human-readable "time ago" string
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.second, .minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "yesterday" : "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1h ago" : "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1m ago" : "\(minute)m ago"
        } else if let second = components.second {
            return second < 30 ? "just now" : "\(second)s ago"
        }
        
        return "just now"
    }
    
    var filteredEvents: [StudyEvent] {
        let lowercaseQuery = filterQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let mathematicsRelatedTerms = [
            "mathematics", "math",
            "calculus",
            "differentiation", "integration",
            "problem-solving",
            "algorithms",
            "computational",
            "mathematical",
            "study",
            "physics",
            "engineering",
            "analysis",
            "solutions",
            "concepts"
        ]
        
        let username = accountManager.currentUser ?? ""
        
        
        // First filter events by view mode - Read from calendarManager.events
        let eventsFilteredByType = calendarManager.events.filter { event in
            switch eventViewMode {
            case .all:
                // Show all events
                return true
                
            case .autoMatched:
                // Show only auto-matched events that user hasn't RSVPed to
                let isAutoMatched = event.isAutoMatched ?? false
                return isAutoMatched && !event.attendees.contains(username) // User hasn't RSVPed
                
            case .rsvpedOnly:
                // Show events the user has RSVPed to OR is hosting
                return event.attendees.contains(username) || event.host == username
                
            @unknown default:
                // Default to showing all events if an unknown case is added in the future
                return true
            }
        }
        
        
        // Apply standard filtering
        let events = eventsFilteredByType.filter { event in
            // If no filters are applied, show all events (matching CalendarManager behavior)
            let hasActiveFilters = !lowercaseQuery.isEmpty || filterPrivateOnly || filterCertifiedOnly || filterEventType != nil
            
            if !hasActiveFilters {
                // No filters applied - show all events from CalendarManager
                return true
            }
            
            // Apply filters only when they are actively set
            let queryMatches = lowercaseQuery.isEmpty || mathematicsRelatedTerms.contains(lowercaseQuery)
            let titleMatches = queryMatches ||
                mathematicsRelatedTerms.contains { term in
                    event.title.lowercased().contains(term)
                } || event.title.lowercased().contains(lowercaseQuery)
            let descriptionMatches = queryMatches ||
                (event.description?.lowercased().contains(lowercaseQuery) ?? false) ||
                (event.description.map { description in
                    mathematicsRelatedTerms.contains { term in
                        description.lowercased().contains(term)
                    }
                } ?? false)
            let anyTextMatches = titleMatches || descriptionMatches
            let privateMatches = !filterPrivateOnly || (!event.isPublic)
            let certifiedMatches = !filterCertifiedOnly || event.hostIsCertified
            let typeMatches = filterEventType == nil || event.eventType == filterEventType!
            let notExpired = event.endTime > Date()
            
            let include = anyTextMatches && privateMatches && certifiedMatches && typeMatches && notExpired
            
            if !include {
            }
            
            return include
        }
        
        for event in events {
        }
        
        return events
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map View
                StudyMapBoxView(events: filteredEvents, region: $region, onSelect: { event in
                    // Always get the most up-to-date version of the event from studyEvents
                    if let freshEvent = calendarManager.events.first(where: { $0.id == event.id }) {
                        selectedEvent = freshEvent
                    } else {
                        selectedEvent = event
                    }
                })
                .edgesIgnoringSafeArea(.all)
                
                // Location permission overlay
                if showLocationPermission {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showLocationPermission = false
                        }
                    
                    LocationPermissionView(locationManager: locationManager) {
                        showLocationPermission = false
                    }
                    .padding(.horizontal, 20)
                }
                
                // Overall UI Container
                VStack(spacing: 0) {
                    // Simple Top Bar with Back Arrow and Search
                    HStack {
                        // Back Button
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.textPrimary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.bgCard)
                                        .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
                                )
                        }
                        .padding(.leading, 16)
                        
                Spacer()
                
                // Location Status Indicator
                LocationStatusIndicator(locationManager: locationManager)
                
                // Search Button
                Button(action: {
                    showSearchSheet = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.bgCard)
                                .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
                        )
                }
                .padding(.trailing, 16)
                    }
                    .padding(.top, 55)
                    
                    // Search Bar when expanded
                    if isSearchExpanded {
                        searchBarView
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    // Bottom Button Row
                    bottomControlBar
                        .padding(.horizontal, 20)
                }
                
                // Hot Posts Overlay
                hotPostsOverlay
                
                // Loading indicator
                if calendarManager.isLoading {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(spacing: 15) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.brandPrimary)
                                Text("Updating events...")
                                    .font(.caption)
                                    .foregroundColor(.textPrimary)
                            }
                            .frame(width: 150, height: 90)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.bgCard)
                                    .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
                            )
                            Spacer()
                        }
                        Spacer().frame(height: 100)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: calendarManager.isLoading)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Request location permission on first load
                if locationManager.authorizationStatus == .notDetermined {
                    showLocationPermission = true
                } else {
                    locationManager.startLocationUpdates()
                }
                
                // Also request location permission for the map
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    locationManager.requestLocationPermission()
                }
            }
            .onChange(of: locationManager.location) { newLocation in
                // Only update region once when location is first detected
                if let location = newLocation, region.center.latitude == -34.6037 && region.center.longitude == -58.3816 {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        region.center = location.coordinate
                        region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // Zoom in closer
                    }
                }
            }
            .sheet(isPresented: $showEventCreationSheet) {
                EventCreationView(
                    coordinate: newEventCoordinate ?? CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816), // Default to Buenos Aires
                    onSave: { newEvent in
                        createStudyEvent(newEvent)
                        // Do NOT add to local calendar here! Only add after backend confirms creation.
                        // calendarManager.addEvent(newEvent)
                    }
                )
            }
            .sheet(item: $selectedEvent) { event in
                NavigationStack {
                    // Pass calendarManager.events binding or relevant subset if needed
                    EventDetailView(event: event, studyEvents: $calendarManager.events, onRSVP: rsvpEvent)
                }
                .onDisappear {
                    // Force refresh of the event data when returning to map - Read from calendarManager.events
                    if let eventId = selectedEvent?.id,
                       let updatedEvent = calendarManager.events.first(where: { $0.id == eventId }) {
                        // This will trigger a refresh of selectedEvent with latest data
                        selectedEvent = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            selectedEvent = updatedEvent
                        }
                    } else {
                        selectedEvent = nil
                    }
                }
            }
            .sheet(isPresented: $showFilterView) {
                EventFilterView(
                    filterQuery: $filterQuery,
                    filterPrivateOnly: $filterPrivateOnly,
                    filterCertifiedOnly: $filterCertifiedOnly,
                    filterEventType: $filterEventType,
                    isPresented: $showFilterView,
                    onApply: { searchEvents() }
                )
            }
            .sheet(isPresented: $showSearchSheet) {
                EventSearchView(
                    searchQuery: $filterQuery,
                    onSearch: { searchEvents() },
                    isPresented: $showSearchSheet
                )
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            // Add confirmation dialog for view mode selection
            .confirmationDialog(
                "Select View Mode",
                isPresented: $showViewModeSelector,
                titleVisibility: .visible
            ) {
                Button("All Events") {
                    eventViewMode = .all
                }
                
                // Get auto-matched count - Read from calendarManager.events
                let autoMatchCount = calendarManager.events.filter { event in
                    guard let isAutoMatched = event.isAutoMatched, isAutoMatched else { return false }
                    let username = accountManager.currentUser ?? ""
                    return !event.attendees.contains(username)
                }.count
                
                Button(autoMatchCount > 0 ? "Auto-Matched (\(autoMatchCount))" : "Auto-Matched") {
                    eventViewMode = .autoMatched
                }
                
                // Get RSVP count - Read from calendarManager.events
                let rsvpCount = calendarManager.events.filter { event in
                    let username = accountManager.currentUser ?? ""
                    return event.attendees.contains(username) || event.host == username
                }.count
                
                Button(rsvpCount > 0 ? "My Events (\(rsvpCount))" : "My Events") {
                    eventViewMode = .rsvpedOnly
                }
                
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    
    // Redesigned search bar
    var searchBarView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "location.magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                
                TextField("Search locations...", text: $mapSearchQuery)
                    .padding(10)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .onChange(of: mapSearchQuery) { oldValue, newValue in 
                        searchMapLocations() 
                    }
                
                Button(action: { withAnimation { isSearchExpanded = false } }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                }
            }
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
            .padding(.horizontal, 16)
            
            if !mapSearchResults.isEmpty {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(mapSearchResults, id: \.self) { place in
                            Button(action: {
                                mapSearchQuery = place.placemark.name ?? "Unknown Place"
                                newEventCoordinate = place.placemark.coordinate
                                region.center = place.placemark.coordinate
                                withAnimation { isSearchExpanded = false }
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(place.placemark.name ?? "Unknown")
                                            .font(.headline)
                                        Text(place.placemark.title ?? "")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.blue)
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 3)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                .padding(.horizontal, 16)
                .frame(height: 200)
            }
        }
    }
    
    // Bottom control bar with buttons
    private var bottomControlBar: some View {
        VStack {
            // Raise bottom controls from the very bottom edge
            HStack {
                // Position to avoid the MapBox logo in bottom left
                viewModeButton
                    .padding(.leading, 10)
                
                Spacer()
                
                // Position to avoid the MapBox info button in bottom right
                addEventButton
                    .padding(.trailing, 10)
            }
            // Add extra bottom padding to raise buttons above MapBox controls
            .padding(.bottom, 35)
        }
    }
    
    // New view mode button at bottom left
    private var viewModeButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                showViewModeSelector = true
            }
        }) {
            HStack(spacing: 12) {
                // Icon represents current mode
                Image(systemName: viewModeIcon)
                    .font(.system(size: 22, weight: .semibold))
                
                // Text label
                Text(viewModeLabel)
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .foregroundColor(.white)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [viewModeColor, viewModeColor.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
            )
            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
            )
        }
    }
    
    var addEventButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                newEventCoordinate = CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816) // Default to Buenos Aires
                showEventCreationSheet = true
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                
                Text("Add Event")
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .foregroundColor(.white)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
            )
            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
            )
        }
    }
    
    // Helper computed properties for the view mode button styling
    private var viewModeIcon: String {
        switch eventViewMode {
        case .all: return "list.bullet"
        case .autoMatched: return "sparkles"
        case .rsvpedOnly: return "checkmark.circle"
        }
    }
    
    private var viewModeLabel: String {
        switch eventViewMode {
        case .all: return "All Events"
        case .autoMatched: return "Auto-Matched"
        case .rsvpedOnly: return "My Events"
        }
    }
    
    private var viewModeColor: Color {
        switch eventViewMode {
        case .all: return Color(red: 0.4, green: 0.4, blue: 0.4)
        case .autoMatched: return Color(red: 0.2, green: 0.5, blue: 0.9)
        case .rsvpedOnly: return Color(red: 0.2, green: 0.7, blue: 0.3)
        }
    }
    
    // MARK: - Overlay Components
    private var hotPostsOverlay: some View {
        ZStack {
            if !showHotPosts.isEmpty {
                VStack {
                    Spacer()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(showHotPosts) { hotPost in
                                HotPostAnnotationView(hotPost: hotPost) {
                                    presentHotPostDetailView(hotPost)
                                }
                                .frame(width: 180, height: 80)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                ))
                            }
                        }
                        .padding()
                    }
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding()
                }
            }
        }
        .animation(.easeInOut, value: showHotPosts)
    }
    
    // MARK: - Networking & Backend Integration
    func createStudyEvent(_ event: StudyEvent) {
        // Add the event to the local list immediately for faster UI feedback
        
        // Only add if it doesn't already exist in our list
        if !calendarManager.events.contains(where: { $0.id == event.id }) {
            // Create a local copy of the event
            var localEvent = event
            
            // Ensure the current user is in the attendees list
            let currentUser = accountManager.currentUser ?? "Guest"
            if !localEvent.attendees.contains(currentUser) {
                localEvent.attendees.append(currentUser)
            }
            
            // Add to local list immediately
            DispatchQueue.main.async {
                self.calendarManager.events.append(localEvent)
                
                // Show a toast or alert to instruct user to tap refresh button if needed
                self.alertTitle = "Event Created"
                self.alertMessage = "Your event has been added. Use the refresh button if you need to update with server data."
                self.showAlert = true
            }
        }
    }
    
    func rsvpEvent(eventID: UUID) {
        guard let username = accountManager.currentUser else {
            return
        }
        
        
        // First update the local event list immediately for better UX
        if let index = calendarManager.events.firstIndex(where: { $0.id == eventID }) {
            var updatedEvent = calendarManager.events[index]
            
            
            // Check if the current user is the host (for logging purposes only)
            let isCurrentUserHost = updatedEvent.host == username
            if isCurrentUserHost {
            }
            
            // Toggle attendance (now allowed for hosts too)
            if updatedEvent.attendees.contains(username) {
                // User is already attending, so remove them
                updatedEvent.attendees.removeAll(where: { $0 == username })
            } else {
                // User is not attending, so add them
                updatedEvent.attendees.append(username)
            }
            
            
            // Create a completely new copy of the events array to ensure SwiftUI detects the change
            var newEventsList = calendarManager.events
            newEventsList[index] = updatedEvent
            
            // Force immediate UI update by replacing the entire array 
            DispatchQueue.main.async {
                self.calendarManager.events = newEventsList

                // If the selectedEvent is the one being modified, update it too for consistency
                if self.selectedEvent?.id == eventID {
                    self.selectedEvent = updatedEvent
                }

                // Notify any observers about the event update
                NotificationCenter.default.post(
                    name: Notification.Name("EventRSVPUpdated"),
                    object: nil,
                    userInfo: ["eventID": eventID]
                )
            }
        } else {
            // Could not find event with ID in studyEvents array
            return
        }
        
        guard let url = URL(string: "\(APIConfig.primaryBaseURL)/rsvp_study_event/") else { 
            return 
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let rsvpData = ["username": username, "event_id": eventID.uuidString]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: rsvpData)
            
            // Start the task
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                
                if let error = error {
                    // Network error occurred
                    return
                }
                
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                
                // Handle response data
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    // Try to parse response to check for success
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            let success = json["success"] as? Bool ?? false
                            
                            // If the operation was successful, update UI immediately
                            if success {
                                DispatchQueue.main.async {
                                    // Update local data immediately without fetching from server
                                    if let index = self.calendarManager.events.firstIndex(where: { $0.id == eventID }) {
                                        var updatedEvent = self.calendarManager.events[index]
                                        // Toggle the current user's attendance
                                        let currentUsername = self.accountManager.currentUser ?? ""
                                        if updatedEvent.attendees.contains(currentUsername) {
                                            updatedEvent.attendees.removeAll(where: { $0 == currentUsername })
                                        } else {
                                            updatedEvent.attendees.append(currentUsername)
                                        }
                                        // Update in the array
                                        self.calendarManager.events[index] = updatedEvent
                                    }
                                    
                                    // Notify any observers about the event update
                                    NotificationCenter.default.post(
                                        name: Notification.Name("EventRSVPUpdated"), 
                                        object: nil,
                                        userInfo: ["eventID": eventID]
                                    )
                                    
                                }
                                return
                            }
                        }
                    } catch {
                    }
                } else {
                }
                
                // Only run this if we didn't get a successful response above
                DispatchQueue.main.async {
                    // Restore the original state since the RSVP network request will not be sent
                    // self.calendarManager.fetchEvents() // REMOVED
                    // We should ideally revert the optimistic UI update here instead of fetching all
                }
            }
            
            task.resume()
            
        } catch {
            // Log more detailed error information
            
            // Notify user or handle the error more gracefully
            DispatchQueue.main.async {
                // Restore the original state since the RSVP network request will not be sent
                // self.calendarManager.fetchEvents() // REMOVED
            }
        }
    }
    
    func searchMapLocations() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = mapSearchQuery
        request.region = region
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            if let response = response {
                self.mapSearchResults = response.mapItems
            }
        }
    }
}

extension StudyMapView {
    func searchEvents() {
        guard let username = accountManager.currentUser else {
            return
        }
        var components = URLComponents(string: "\(APIConfig.primaryBaseURL)/enhanced_search_events/")
        
        var queryItems = [URLQueryItem]()
        if !filterQuery.isEmpty {
            queryItems.append(URLQueryItem(name: "query", value: filterQuery))
        }
        queryItems.append(URLQueryItem(name: "public_only", value: filterPrivateOnly ? "true" : "false"))
        queryItems.append(URLQueryItem(name: "certified_only", value: filterCertifiedOnly ? "true" : "false"))
        if let eventType = filterEventType {
            queryItems.append(URLQueryItem(name: "event_type", value: eventType.rawValue))
        }
        let useSemanticSearch = UserDefaults.standard.bool(forKey: "useSemanticSearch")
        queryItems.append(URLQueryItem(name: "semantic", value: useSemanticSearch ? "true" : "false"))
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                return
            }
            guard let data = data else {
                return
            }
            do {
                let eventsResponse = try JSONDecoder().decode(StudyEventsResponse.self, from: data)
                DispatchQueue.main.async {
                    let validEvents = eventsResponse.events.filter { $0.endTime > Date() }
                    self.calendarManager.events.removeAll()
                    self.calendarManager.events = validEvents
                    self.filteredEvents.forEach { event in
                    }
                }
            } catch {
                if let rawResponse = String(data: data, encoding: .utf8) {
                }
            }
        }.resume()
    }
    
    // Enhanced version of getTopPostFor with debugging
    func getTopPostFor(event: StudyEvent) -> EventPost? {
        
        guard let url = URL(string: "\(APIConfig.primaryBaseURL)/events/feed/\(event.id.uuidString)/") else {
            return nil
        }
        
        
        var topPost: EventPost?
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return
            }
            
            
            guard let data = data else {
                return
            }
            
            // Print the raw JSON response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
            }
            
            do {
                let response = try JSONDecoder().decode(EventFeedResponse.self, from: data)
                
                // Print details of each post
                for (index, post) in response.posts.enumerated() {
                }
                
                if response.posts.isEmpty {
                    return
                }
                
                topPost = response.posts.max(by: {
                    ($0.likes + $0.replies.count) < ($1.likes + $1.replies.count)
                })
                
                if let post = topPost {
                } else {
                }
            } catch {
            }
        }.resume()
        
        _ = semaphore.wait(timeout: .now() + 2)
        
        if topPost == nil {
        }
        
        return topPost
    }
}

// MARK: - StudyMapView Previews
struct StudyMapView_Previews: PreviewProvider {
    static var previews: some View {
        StudyMapView()
            .environmentObject(UserAccountManager())
    }
}

extension String {
    var userprofile: MapUserProfile {
        return MapUserProfile(is_certified: false)
    }
}

struct MapUserProfile: Codable {
    let is_certified: Bool
}


extension StudyMapView {
    // Method to fetch hot posts for the map
    func fetchHotPostsForMap() -> [EventHotPost] {
        var hotPosts: [EventHotPost] = []
        
        for event in calendarManager.events {
            // Fetch the top post for each event
            if let topPost = getTopPostFor(event: event) {
                
                // Create an EventHotPost from the top post
                let hotPost = EventHotPost(
                    eventId: event.id,
                    text: topPost.text,
                    username: topPost.username,
                    coordinate: event.coordinate,
                    likeCount: topPost.likes  // Use the latest like count from the server
                )
                hotPosts.append(hotPost)
            }
        }
        
        // Sort hot posts by like count and take top 5
        return hotPosts.sorted { $0.likeCount > $1.likeCount }.prefix(5).map { $0 }
    }
    
    // Method to present hot post detail view
    private func presentHotPostDetailView(_ hotPost: EventHotPost) {
        // Find the corresponding event
        if let event = calendarManager.events.first(where: { $0.id == hotPost.eventId }) {
            selectedEvent = event
        }
    }
}

// MARK: - Event Search View
struct EventSearchView: View {
    @Binding var searchQuery: String
    let onSearch: () -> Void
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.brandPrimary)
                    
                    Text("Search Events")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Find events using AI-powered semantic search")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Search Input
                VStack(spacing: 16) {
                    TextField("Search for events...", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                        .padding(.horizontal, 20)
                    
                    // Search Examples
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Try searching for:")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.textSecondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• \"study groups for computer science\"")
                            Text("• \"networking events this week\"")
                            Text("• \"language exchange partners\"")
                            Text("• \"research collaboration\"")
                        }
                        .font(.caption)
                        .foregroundColor(.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onSearch()
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search Events")
                        }
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.brandPrimary)
                        )
                    }
                    .disabled(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.bgSurface.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}





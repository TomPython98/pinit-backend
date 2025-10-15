import SwiftUI
import MapboxMaps
import Combine
import CoreLocation
import MapKit
import UIKit
import Turf

// MARK: - RefreshController for debouncing
class RefreshController: ObservableObject {
    private var refreshWorkItem: DispatchWorkItem?
    private var refreshCount = 0
    private var lastRefreshTime = Date()
    
    func debouncedRefresh(delay: TimeInterval = 0.3, action: @escaping () -> Void) {
        // Cancel previous work item
        refreshWorkItem?.cancel()
        
        // Create new work item
        refreshWorkItem = DispatchWorkItem {
            self.refreshCount += 1
            self.lastRefreshTime = Date()
            action()
        }
        
        // Schedule with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: refreshWorkItem!)
    }
    
    func getRefreshStats() -> String {
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshTime)
        return "Refreshes: \(refreshCount), Last: \(String(format: "%.1f", timeSinceLastRefresh))s ago"
    }
}

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
            pinImageName = "book.fill"
            pinTintColor = .systemBlue
        case .party:
            pinImageName = "party.popper.fill"
            pinTintColor = .systemPurple
        case .business:
            pinImageName = "briefcase.fill"
            pinTintColor = .systemIndigo
        case .cultural:
            pinImageName = "theatermasks.fill"
            pinTintColor = .systemOrange
        case .academic:
            pinImageName = "graduationcap.fill"
            pinTintColor = .systemGreen
        case .networking:
            pinImageName = "person.2.fill"
            pinTintColor = .systemPink
        case .social:
            pinImageName = "person.3.fill"
            pinTintColor = .systemRed
        case .language_exchange:
            pinImageName = "globe"
            pinTintColor = .systemTeal
        case .other:
            pinImageName = "ellipsis.circle.fill"
            pinTintColor = .systemGray
        }
        
        // Use SF Symbol instead of PNG image
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        if let symbolImage = UIImage(systemName: pinImageName, withConfiguration: config) {
            pinImageView.image = symbolImage
            pinImageView.tintColor = pinTintColor
        } else {
            // Fallback to a default SF Symbol
            pinImageView.image = UIImage(systemName: "mappin.circle.fill", withConfiguration: config)
            pinImageView.tintColor = .systemBlue
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
    
    // Add tap callback property
    var onTap: (() -> Void)?
    
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
        
        // Scale font size based on cluster size and count
        let fontSize: CGFloat
        if events.count >= 100 { fontSize = size * 0.25 }  // Smaller font for very large numbers
        else if events.count >= 50 { fontSize = size * 0.3 }
        else if events.count >= 20 { fontSize = size * 0.35 }
        else { fontSize = size * 0.4 }
        
        countLabel.font = UIFont.boldSystemFont(ofSize: fontSize)
        
        let iconSize = size * 0.25
        mixedTypesIcon.frame = CGRect(x: size * 0.15, y: size * 0.6, width: iconSize, height: iconSize)
        privateBadge.frame = CGRect(x: size * 0.65, y: size * 0.6, width: iconSize, height: iconSize)
        
        layer.shadowColor = UIColor.white.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 50
        layer.shadowOffset = .zero
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleClusterTap))
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
    }
    
    @objc private func handleClusterTap() {
        onTap?()
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func getAppearanceForCluster(count: Int, dominantType: EventType) -> (CGFloat, UIColor) {
        let size: CGFloat
        if count >= 100 { size = 80 }        // Very large clusters (mega-clusters)
        else if count >= 50 { size = 70 }   // Large clusters
        else if count >= 20 { size = 60 }   // Medium-large clusters
        else if count >= 10 { size = 55 }   // Medium clusters
        else if count >= 5 { size = 50 }    // Small-medium clusters
        else if count >= 3 { size = 45 }    // Small clusters
        else { size = 40 }                  // Very small clusters
        
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

/// Clusters events based on zoom level with proper thresholds to prevent events from disappearing
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
        }
    }
    
    // Calculate zoom level from region span
    // longitudeDelta roughly corresponds to zoom level
    let longitudeDelta = region.span.longitudeDelta
    let zoomLevel = log2(360.0 / longitudeDelta)
    
    
    // Safety check: If there's only one event, don't cluster it
    if uniqueEvents.count == 1 {
        return [Cluster(events: uniqueEvents)]
    }
    
    // Define clustering thresholds based on zoom level - industry best practices
    let threshold: Double
    switch zoomLevel {
    case 0..<3:      // World/continent view
        threshold = 5.0      // ~550km - cluster large regions
    case 3..<6:      // Country/region view  
        threshold = 1.0      // ~110km - cluster cities
    case 6..<9:      // City view
        threshold = 0.2      // ~22km - cluster districts
    case 9..<12:     // Neighborhood view
        threshold = 0.05     // ~5.5km - cluster close areas
    case 12..<15:    // Street view
        threshold = 0.005    // ~550m - cluster same block
    default:         // Building level (zoom 15+)
        threshold = 0.001    // ~110m - only cluster very close events
    }
    
    
    var clusters: [Cluster] = []
    var unclustered = uniqueEvents
    
    while !unclustered.isEmpty {
        let event = unclustered.removeFirst()
        var clusterEvents = [event]
        
        // Find all events within threshold distance
        var indicesToRemove: [Int] = []
        for (index, otherEvent) in unclustered.enumerated() {
            let dLat = abs(event.coordinate.latitude - otherEvent.coordinate.latitude)
            let dLon = abs(event.coordinate.longitude - otherEvent.coordinate.longitude)
            if dLat < threshold && dLon < threshold {
                clusterEvents.append(otherEvent)
                indicesToRemove.append(index)
            }
        }
        
        // Remove clustered events from unclustered list (in reverse order to maintain indices)
        for index in indicesToRemove.reversed() {
            unclustered.remove(at: index)
        }
        
        clusters.append(Cluster(events: clusterEvents))
    }
    
    
    // Safety mechanism: If we're at very low zoom and have too many clusters,
    // create a single mega-cluster to ensure events are always visible
    if zoomLevel < 2 && clusters.count > 50 {
        let megaCluster = Cluster(events: uniqueEvents)
        return [megaCluster]
    }
    
    return clusters
}

// MARK: - StudyMapBoxView (Mapbox with Clustering)
struct StudyMapBoxView: UIViewRepresentable {
    var events: [StudyEvent]
    var region: Binding<MKCoordinateRegion>
    var refreshVersion: Int = 0
    var onSelect: ((StudyEvent) -> Void)?
    var onMultiEventSelect: (([StudyEvent]) -> Void)?
    
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
        // Ensure non-zero initial size to avoid 64x64 fallback
        if mapView.frame.size == .zero {
            mapView.frame = UIScreen.main.bounds
        }
        
        let locationProvider = AppleLocationProvider()
        locationProvider.options.activityType = .automotiveNavigation
        mapView.location.override(provider: locationProvider)
        
        // Enable user location display with beautiful custom styling
        let puck2DConfiguration = Puck2DConfiguration(
            topImage: createCustomLocationIcon(),
            bearingImage: createCustomBearingIcon(),
            shadowImage: nil,
            scale: .constant(1.0), // Reduced scale to be less intrusive
            showsAccuracyRing: true,
            accuracyRingColor: UIColor.systemBlue.withAlphaComponent(0.15), // More transparent
            accuracyRingBorderColor: UIColor.systemBlue.withAlphaComponent(0.3) // More transparent
        )
        mapView.location.options.puckType = .puck2D(puck2DConfiguration)
        mapView.location.options.puckBearingEnabled = true
        
        // Add camera change observer to track zoom changes and trigger re-clustering
        mapView.mapboxMap.onCameraChanged.observe { [weak mapView] _ in
            guard let mapView = mapView else { return }
            let camera = mapView.mapboxMap.cameraState
            
            // Debounce camera changes to prevent excessive updates
            let currentTime = Date()
            if currentTime.timeIntervalSince(context.coordinator.lastCameraUpdateTime) < 1.0 {
                return
            }
            context.coordinator.lastCameraUpdateTime = currentTime
            
            // Update the region binding to trigger re-clustering
            let newRegion = MKCoordinateRegion(
                center: camera.center,
                span: MKCoordinateSpan(
                    latitudeDelta: self.calculateLatitudeDelta(from: camera.zoom),
                    longitudeDelta: self.calculateLongitudeDelta(from: camera.zoom)
                )
            )
            
            DispatchQueue.main.async {
                self.region.wrappedValue = newRegion
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
        
        // Guard against invalid map view sizes (e.g., 64x64 fallback) which can hide annotations
        let viewSize = uiView.bounds.size
        if viewSize.width < 100 || viewSize.height < 100 {
            uiView.setNeedsLayout()
            return
        }
        
        // Debounce rapid calls to prevent excessive clustering
        let currentTime = Date()
        if currentTime.timeIntervalSince(context.coordinator.lastUpdateTime) < 0.3 {
            return
        }
        context.coordinator.lastUpdateTime = currentTime
        
        let newClusters = clusterEvents(events, region: region.wrappedValue)
        
        // Simple refresh mechanism to avoid cascading calls
        if newClusters != context.coordinator.lastClusters ||
           context.coordinator.forceRefresh != refreshVersion {
            
            
            // PERFORMANCE FIX: Limit annotation updates to prevent hangs
            // Clear all existing annotations
            uiView.viewAnnotations.removeAll()
            
            // Add updated annotations
            updateAnnotations(on: uiView, region: region.wrappedValue, events: events)
            
            // Update tracking state
            context.coordinator.lastClusters = newClusters
            context.coordinator.forceRefresh = refreshVersion
            
            // Force layout update to ensure annotations are properly displayed
            uiView.setNeedsLayout()
        } else {
        }
    }
    

    
    private func updateAnnotations(on mapView: MapView, region: MKCoordinateRegion, events: [StudyEvent]) {
        
        // Special handling for single events - bypass clustering entirely
        if events.count == 1, let event = events.first {
            let customView = createAnnotationView(for: event)
            customView.layer.zPosition = 1000
            let options = ViewAnnotationOptions(
                annotatedFeature: AnnotatedFeature.geometry(Point(event.coordinate)),
                width: customView.bounds.width,
                height: customView.bounds.height,
                allowOverlap: true,
                allowOverlapWithPuck: true,
                visible: true,
                priority: 1000,
                variableAnchors: .center,
                ignoreCameraPadding: true
            )
            try? mapView.viewAnnotations.add(customView, options: options)
            return
        }
        
        // Use clustering for multiple events
        let clusters = clusterEvents(events, region: region)
        for cluster in clusters {
            if cluster.events.count == 1, let event = cluster.events.first {
                let customView = createAnnotationView(for: event)
                customView.layer.zPosition = 1000
                let options = ViewAnnotationOptions(
                    annotatedFeature: AnnotatedFeature.geometry(Point(event.coordinate)),
                    width: customView.bounds.width,
                    height: customView.bounds.height,
                    allowOverlap: true,
                    allowOverlapWithPuck: true,
                    visible: true,
                    priority: 1000,
                    variableAnchors: .center,
                    ignoreCameraPadding: true
                )
                try? mapView.viewAnnotations.add(customView, options: options)
            } else {
                let clusterView = ClusterAnnotationView(events: cluster.events, frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                clusterView.layer.zPosition = 1000
                
                // Check if all events in cluster are at nearly same location
                let coordinates = cluster.events.map { $0.coordinate }
                let maxLatDiff = coordinates.map { $0.latitude }.max()! - coordinates.map { $0.latitude }.min()!
                let maxLonDiff = coordinates.map { $0.longitude }.max()! - coordinates.map { $0.longitude }.min()!
                
                if maxLatDiff < 0.0001 && maxLonDiff < 0.0001 && cluster.events.count > 1 {
                    // Events are at same location - cluster tap should show multi-event selection
                    clusterView.onTap = {
                        // Already on main thread, no need for async dispatch
                        self.onMultiEventSelect?(Array(cluster.events))
                    }
                } else {
                    // Events are at different locations - cluster tap should zoom in
                    clusterView.onTap = { [weak mapView] in
                        // Calculate zoom level that would separate this cluster
                        let currentZoom = mapView?.mapboxMap.cameraState.zoom ?? 12
                        let targetZoom = min(currentZoom + 2, 18) // Zoom in by 2 levels, max 18
                        
                        let cameraOptions = CameraOptions(
                            center: cluster.coordinate,
                            zoom: CGFloat(targetZoom),
                            bearing: 0,
                            pitch: 0
                        )
                        mapView?.camera.ease(to: cameraOptions, duration: 0.8, completion: nil)
                    }
                }
                let options = ViewAnnotationOptions(
                    annotatedFeature: AnnotatedFeature.geometry(Point(cluster.coordinate)),
                    width: clusterView.bounds.width,
                    height: clusterView.bounds.height,
                    allowOverlap: true,
                    allowOverlapWithPuck: true,
                    visible: true,
                    priority: 900,
                    variableAnchors: .center,
                    ignoreCameraPadding: true
                )
                try? mapView.viewAnnotations.add(clusterView, options: options)
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
    
    // MARK: - Helper Functions for Zoom Conversion
    private func calculateLatitudeDelta(from zoom: CGFloat) -> CLLocationDegrees {
        return 360.0 / pow(2.0, Double(zoom))
    }
    
    private func calculateLongitudeDelta(from zoom: CGFloat) -> CLLocationDegrees {
        return 360.0 / pow(2.0, Double(zoom))
    }
    
    class Coordinator: NSObject {
        var cancelables = Set<AnyCancellable>()
        var lastClusters: [Cluster] = []
        var forceRefresh: Int = 0
        var lastUpdateTime: Date = Date()
        var lastCameraUpdateTime: Date = Date()
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
    @StateObject private var tutorialManager = TutorialManager.shared
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816), // Default to Buenos Aires
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5) // Much wider default view
    )
    @State private var showLocationPermission = false
    @State private var showEventCreationSheet = false
    @State private var newEventCoordinate: CLLocationCoordinate2D? = nil
    @State private var isSearchExpanded = false
    @State private var showSearchSheet = false
    @State private var selectedEvent: StudyEvent?
    @State private var showMultiEventSelection = false
    @State private var multiEventSelectionEvents: [StudyEvent] = []
    @State private var multiEventSelectionId = UUID()
    @State private var mapRefreshVersion: Int = 0
    @StateObject private var refreshController = RefreshController()
    @State private var refreshStats = ""
    
    @State private var mapSearchQuery = ""
    @State private var mapSearchResults: [MapSearchResult] = []
    
    // Simple struct to hold map search results
    struct MapSearchResult: Hashable {
        let name: String
        let title: String
        let coordinate: CLLocationCoordinate2D
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(coordinate.latitude)
            hasher.combine(coordinate.longitude)
        }
    }
    @State private var filterQuery: String = ""
    @State private var filterPrivateOnly: Bool = false
    @State private var filterCertifiedOnly: Bool = false
    @State private var filterEventType: EventType? = nil
    @State private var showFilterView: Bool = false
    
    // Search results state management
    @State private var searchResults: [StudyEvent] = []
    @State private var isShowingSearchResults: Bool = false
    
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
        // If showing search results, use those instead of calendarManager.events
        let sourceEvents = isShowingSearchResults ? searchResults : calendarManager.events
        
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
        
        // First filter events by view mode - Read from sourceEvents
        let eventsFilteredByType = sourceEvents.filter { event in
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
            
            return include
        }
        
        return events
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map View
                StudyMapBoxView(events: filteredEvents, region: $region, refreshVersion: mapRefreshVersion, onSelect: { event in
                    // Track tutorial progress - user tapped on map pin!
                    tutorialManager.mapPinTapped()
                    
                    // Always get the most up-to-date version of the event from studyEvents
                    if let freshEvent = calendarManager.events.first(where: { $0.id == event.id }) {
                        selectedEvent = freshEvent
                    } else {
                        selectedEvent = event
                    }
                }, onMultiEventSelect: { events in
                    // Set events and generate new ID to force view recreation
                    multiEventSelectionEvents = Array(events)
                    multiEventSelectionId = UUID()
                    showMultiEventSelection = true
                })
                .edgesIgnoringSafeArea(.all)
                .onChange(of: calendarManager.events) { oldValue, newValue in
                    // Update map annotations when events change
                    if !filteredEvents.isEmpty {
                        mapRefreshVersion += 1
                        
                        // ✅ IMMEDIATE: If this is the first load of events, center the map
                        if oldValue.isEmpty && !newValue.isEmpty {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                region = regionThatFits(events: filteredEvents)
                            }
                        }
                    }
                }
                .onChange(of: eventViewMode) { oldValue, newValue in
                    // Update map annotations when view mode changes, but don't recenter
                    if !filteredEvents.isEmpty {
                        mapRefreshVersion += 1
                    }
                }
                
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
                
                // ✅ IMMEDIATE: Fetch events right away (no delay!)
                if calendarManager.events.isEmpty && !calendarManager.isLoading {
                    calendarManager.fetchEvents(force: true)
                }
                
                // ✅ IMMEDIATE: Show events if we have them (no 1s delay!)
                if !filteredEvents.isEmpty {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        region = regionThatFits(events: filteredEvents)
                    }
                    mapRefreshVersion += 1
                } else {
                    // If no events yet, try again after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if !filteredEvents.isEmpty {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                region = regionThatFits(events: filteredEvents)
                            }
                            mapRefreshVersion += 1
                        }
                    }
                }
            }
            .onChange(of: locationManager.location) { newLocation in
                // Only update region once when location is first detected
                if let location = newLocation, region.center.latitude == -34.6037 && region.center.longitude == -58.3816 {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        region.center = location.coordinate
                        region.span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2) // Reasonable zoom level
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
                            // Recenter map on the updated event so it's visible after edits
                            withAnimation(.easeInOut(duration: 0.6)) {
                                region.center = updatedEvent.coordinate
                                region.span = MKCoordinateSpan(latitudeDelta: max(region.span.latitudeDelta, 0.05),
                                                               longitudeDelta: max(region.span.longitudeDelta, 0.05))
                            }
                            // Bump map refresh version to force re-annotation
                            mapRefreshVersion += 1
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
            .sheet(isPresented: $showMultiEventSelection) {
                MultiEventSelectionView(
                    events: multiEventSelectionEvents,
                    onEventSelected: { event in
                        selectedEvent = event
                        showMultiEventSelection = false
                    }
                )
                .id(multiEventSelectionId)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            // Recenter when we receive a location update from the edit screen
            // Unified notification handler for focusing on events
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FocusEventOnMap"))) { notification in
                guard let userInfo = notification.userInfo else { return }
                
                // Handle coordinate-based focus (from event edit)
                if let lat = userInfo["lat"] as? CLLocationDegrees,
                   let lon = userInfo["lon"] as? CLLocationDegrees {
                    let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    withAnimation(.easeInOut(duration: 0.6)) {
                        region.center = coord
                        region.span = MKCoordinateSpan(latitudeDelta: max(region.span.latitudeDelta, 0.05),
                                                       longitudeDelta: max(region.span.longitudeDelta, 0.05))
                    }
                    mapRefreshVersion += 1
                }
                // Handle event ID-based focus (from event detail)
                else if let eventIDString = userInfo["eventID"] as? String,
                        let eventID = UUID(uuidString: eventIDString) {
                    
                    // Support payloads with explicit lat/lon to avoid type bridging issues
                    var targetCoord: CLLocationCoordinate2D? = nil
                    if let lat = userInfo["lat"] as? CLLocationDegrees,
                       let lon = userInfo["lon"] as? CLLocationDegrees {
                        targetCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    } else if let coordinate = userInfo["coordinate"] as? CLLocationCoordinate2D {
                        targetCoord = coordinate
                    }
                    
                    // Center the map with a closer zoom
                    if let coordinate = targetCoord {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            region.center = coordinate
                            region.span = MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                        }
                    }
                    
                    // Ensure the correct event is selected
                    if let event = calendarManager.events.first(where: { $0.id == eventID }) {
                        selectedEvent = event
                    }
                    
                    mapRefreshVersion += 1
                }
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

    // MARK: - Region helpers
    private func isDefaultRegion(_ center: CLLocationCoordinate2D) -> Bool {
        // Default to Buenos Aires in app; treat near that as default
        abs(center.latitude - (-34.6037)) < 0.01 && abs(center.longitude - (-58.3816)) < 0.01
    }
    
    private func regionThatFits(events: [StudyEvent]) -> MKCoordinateRegion {
        guard let first = events.first else {
            return region
        }
        
        var minLat = first.coordinate.latitude
        var maxLat = first.coordinate.latitude
        var minLon = first.coordinate.longitude
        var maxLon = first.coordinate.longitude
        
        for e in events {
            minLat = min(minLat, e.coordinate.latitude)
            maxLat = max(maxLat, e.coordinate.latitude)
            minLon = min(minLon, e.coordinate.longitude)
            maxLon = max(maxLon, e.coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
        
        // Add padding and enforce a reasonable minimum span (much wider)
        let latDelta = max((maxLat - minLat) * 1.4, 0.3) // Increased from 0.1 to 0.3
        let lonDelta = max((maxLon - minLon) * 1.4, 0.3) // Increased from 0.1 to 0.3
        
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
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
                                mapSearchQuery = place.name
                                newEventCoordinate = place.coordinate
                                region.center = place.coordinate
                                withAnimation { isSearchExpanded = false }
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(place.name)
                                            .font(.headline)
                                        Text(place.title)
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
        VStack(spacing: 10) {
            // When search is active, show clear button on its own row
            if isShowingSearchResults {
                HStack {
                    Spacer()
                    clearSearchButton
                        .transition(.scale.combined(with: .opacity))
                    Spacer()
                }
            }
            
            // Main button row
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
            HStack(spacing: 8) {
                // Icon represents current mode
                Image(systemName: viewModeIcon)
                    .font(.system(size: 18, weight: .semibold))
                
                // Text label
                Text(viewModeLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
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
            // Track tutorial progress - user tapped add event button!
            tutorialManager.addButtonTapped()
            
            withAnimation(.spring()) {
                newEventCoordinate = CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816) // Default to Buenos Aires
                showEventCreationSheet = true
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                
                Text("Add Event")
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
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
    
    // Clear search button (shown when search results are active)
    private var clearSearchButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                // Clear all filters and search state
                filterQuery = ""
                filterPrivateOnly = false
                filterCertifiedOnly = false
                filterEventType = nil
                isShowingSearchResults = false
                searchResults = []
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Clear Filters")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .foregroundColor(.white)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.7)]),
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
                
                // Debug overlay for refresh statistics (only in debug builds)
                #if DEBUG
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Debug Stats")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text(refreshController.getRefreshStats())
                                .font(.caption2)
                                .foregroundColor(.white)
                            Text("Map Version: \(mapRefreshVersion)")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.trailing, 16)
                        .padding(.bottom, 100)
                    }
                }
                #endif
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
                
                // Show success message
                self.alertTitle = "Event Created"
                self.alertMessage = "Your event has been created successfully!"
                self.showAlert = true
                
                // 🔧 FIX: Fetch only the specific event instead of all events
                // This ensures the event list is synchronized with the backend
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.calendarManager.fetchSpecificEvent(eventID: localEvent.id)
                }
                
                // Post unified notification to focus on the new event
                NotificationCenter.default.post(
                    name: Notification.Name("FocusEventOnMap"),
                    object: nil,
                    userInfo: [
                        "eventID": localEvent.id.uuidString,
                        "lat": localEvent.coordinate.latitude,
                        "lon": localEvent.coordinate.longitude
                    ]
                )
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
        guard !mapSearchQuery.isEmpty else {
            mapSearchResults = []
            return
        }
        
        // Use Apple Maps (MKLocalSearch) for better POI results
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = mapSearchQuery
        searchRequest.region = region
        searchRequest.resultTypes = [.pointOfInterest, .address]
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.mapSearchResults = []
                    return
                }
                
                guard let response = response else {
                    self.mapSearchResults = []
                    return
                }
                
                self.mapSearchResults = response.mapItems.prefix(8).compactMap { item in
                    guard let name = item.name else { return nil }
                    
                    let coordinate = item.placemark.coordinate
                    
                    // Build display string
                    var displayParts: [String] = [name]
                    var addressParts: [String] = []
                    
                    if let thoroughfare = item.placemark.thoroughfare {
                        addressParts.append(thoroughfare)
                    }
                    if let locality = item.placemark.locality {
                        addressParts.append(locality)
                    }
                    
                    let title = addressParts.isEmpty ? name : "\(name), \(addressParts.joined(separator: ", "))"
                    
                    return MapSearchResult(
                        name: name,
                        title: title,
                        coordinate: coordinate
                    )
                }
                
            }
        }
    }
}

extension StudyMapView {
    func searchEvents() {
        guard let username = accountManager.currentUser else {
            return
        }
        
        // Check if there are any active filters
        let hasActiveFilters = !filterQuery.isEmpty || filterPrivateOnly || filterCertifiedOnly || filterEventType != nil
        
        // If no active filters, clear search mode and show all events
        if !hasActiveFilters {
            DispatchQueue.main.async {
                self.isShowingSearchResults = false
                self.searchResults = []
            }
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
        
        var request = URLRequest(url: url)
        accountManager.addAuthHeader(to: &request)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    // On error, show all events
                    self.isShowingSearchResults = false
                    self.searchResults = []
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    // On missing data, show all events
                    self.isShowingSearchResults = false
                    self.searchResults = []
                }
                return
            }
            do {
                let eventsResponse = try JSONDecoder().decode(StudyEventsResponse.self, from: data)
                DispatchQueue.main.async {
                    let validEvents = eventsResponse.events.filter { $0.endTime > Date() }
                    // Store search results separately instead of replacing calendarManager.events
                    self.searchResults = validEvents
                    self.isShowingSearchResults = true
                }
            } catch {
                DispatchQueue.main.async {
                    // On decode error, show all events
                    self.isShowingSearchResults = false
                    self.searchResults = []
                }
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
                    ZStack(alignment: .leading) {
                        if searchQuery.isEmpty {
                            Text("Search for events...")
                                .foregroundColor(Color.gray.opacity(0.6))
                                .padding(.horizontal, 12)
                        }
                        TextField("", text: $searchQuery)
                            .padding(12)
                            .foregroundColor(Color.textPrimary)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.bgCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cardStroke, lineWidth: 1)
                    )
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


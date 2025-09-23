import SwiftUI

struct EventAnnotationView: View {
    let event: StudyEvent
    
    // Pre-store system images to avoid repeated lookups.
    private static let publicSymbol  = Image(systemName: "mappin.circle.fill")
    private static let privateSymbol = Image(systemName: "lock.circle.fill")
    private static let autoMatchSymbol = Image(systemName: "sparkles")

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Base pin icon
                (event.isPublic ? Self.publicSymbol : Self.privateSymbol)
                    .renderingMode(.original)
                    .frame(width: 32, height: 32)
                    .foregroundColor(event.isPublic ? .blue : .red)
                
                // Auto-match indicator overlay
                if event.isAutoMatched ?? false {
                    Self.autoMatchSymbol
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(2)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .offset(x: 8, y: -8)
                        .shadow(radius: 1)
                }
            }
            
            VStack(spacing: 2) {
                // Event title
                Text(event.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Capsule())
                    .shadow(radius: 1)
                
                // Auto-match badge
                if event.isAutoMatched ?? false {
                    Text("Auto-Matched")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange.opacity(0.8))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(radius: 0.5)
                }
            }
        }
    }
}

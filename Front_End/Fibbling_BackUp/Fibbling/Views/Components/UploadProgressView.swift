import SwiftUI

// MARK: - Upload Progress View
/// Professional upload progress indicator with animations

struct UploadProgressView: View {
    let progress: Double  // 0.0 to 1.0
    let fileName: String
    let showCancel: Bool
    let onCancel: (() -> Void)?
    
    @State private var isAnimating = false
    
    init(progress: Double, fileName: String = "Image", showCancel: Bool = true, onCancel: (() -> Void)? = nil) {
        self.progress = progress
        self.fileName = fileName
        self.showCancel = showCancel
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress circle with percentage
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.brandPrimary, Color.brandAccent]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
                
                // Percentage or checkmark
                if progress >= 1.0 {
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.brandPrimary)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.textPrimary)
                }
            }
            
            // Status text
            VStack(spacing: 6) {
                if progress >= 1.0 {
                    Text("Upload Complete!")
                        .font(.headline)
                        .foregroundColor(.brandPrimary)
                        .transition(.opacity)
                } else {
                    Text("Uploading \(fileName)...")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            
            // Cancel button
            if showCancel && progress < 1.0 {
                Button(action: {
                    HapticManager.shared.medium()
                    onCancel?()
                }) {
                    Text("Cancel")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
        .onAppear {
            if progress >= 1.0 {
                // Trigger success haptic
                HapticManager.shared.uploadSuccess()
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            if newValue >= 1.0 && oldValue < 1.0 {
                // Trigger success haptic when complete
                HapticManager.shared.uploadSuccess()
            }
        }
    }
    
    private var statusMessage: String {
        switch progress {
        case 0..<0.3:
            return "Preparing..."
        case 0.3..<0.7:
            return "Uploading..."
        case 0.7..<1.0:
            return "Almost done..."
        default:
            return "Complete!"
        }
    }
}

// MARK: - Compact Upload Progress Bar
struct CompactUploadProgressBar: View {
    let progress: Double
    let fileName: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Progress icon
            ZStack {
                Circle()
                    .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 3)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.brandPrimary, lineWidth: 3)
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                
                if progress >= 1.0 {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.brandPrimary)
                } else {
                    Text("\(Int(progress * 100))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.brandPrimary)
                }
            }
            
            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(fileName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.brandPrimary.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(Color.brandPrimary)
                            .frame(width: geometry.size.width * progress, height: 4)
                            .cornerRadius(2)
                            .animation(.easeInOut, value: progress)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Multiple Uploads Progress View
struct MultipleUploadsProgressView: View {
    let uploads: [UploadItem]
    
    struct UploadItem: Identifiable {
        let id = UUID()
        let fileName: String
        let progress: Double
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Uploading \(uploads.count) file\(uploads.count > 1 ? "s" : "")")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(Int(overallProgress * 100))%")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.brandPrimary)
            }
            
            ForEach(uploads) { upload in
                CompactUploadProgressBar(progress: upload.progress, fileName: upload.fileName)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
        )
    }
    
    private var overallProgress: Double {
        guard !uploads.isEmpty else { return 0 }
        let total = uploads.reduce(0.0) { $0 + $1.progress }
        return total / Double(uploads.count)
    }
}

// MARK: - Upload Progress Overlay
struct UploadProgressOverlay: ViewModifier {
    let isUploading: Bool
    let progress: Double
    let fileName: String
    let onCancel: (() -> Void)?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isUploading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                UploadProgressView(
                    progress: progress,
                    fileName: fileName,
                    showCancel: true,
                    onCancel: onCancel
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isUploading)
    }
}

extension View {
    func uploadProgressOverlay(isUploading: Bool, progress: Double, fileName: String = "Image", onCancel: (() -> Void)? = nil) -> some View {
        self.modifier(UploadProgressOverlay(isUploading: isUploading, progress: progress, fileName: fileName, onCancel: onCancel))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        Text("Upload Progress Components").font(.title.bold())
        
        UploadProgressView(progress: 0.65, fileName: "profile.jpg", showCancel: true, onCancel: {
        })
        
        UploadProgressView(progress: 1.0, fileName: "photo.jpg", showCancel: false)
        
        CompactUploadProgressBar(progress: 0.45, fileName: "image_long_filename.jpg")
        
        MultipleUploadsProgressView(uploads: [
            .init(fileName: "photo1.jpg", progress: 0.8),
            .init(fileName: "photo2.jpg", progress: 0.4),
            .init(fileName: "photo3.jpg", progress: 0.2)
        ])
    }
    .padding()
    .background(Color.bgSurface)
}

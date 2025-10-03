import SwiftUI

struct ImageGridView: View {
    let images: [String] // Image names or URLs
    let columns: Int
    var onImageTap: ((Int) -> Void)? = nil
    
    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 8) {
            ForEach(0..<images.count, id: \.self) { index in
                imageCell(for: index)
            }
        }
    }
    
    private func imageCell(for index: Int) -> some View {
        let imageName = images[index]
        
        return Button(action: {
            onImageTap?(index)
        }) {
            // If it's a system image
            if imageName.hasPrefix("system:") {
                let systemName = String(imageName.dropFirst(7))
                Image(systemName: systemName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            // If it's a local asset
            else if imageName.hasPrefix("local:") {
                let localName = String(imageName.dropFirst(6))
                Image(localName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            // Otherwise assume it's a URL
            else {
                AsyncImage(url: URL(string: imageName)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fill)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.gray)
                            .padding()
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fill)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    @unknown default:
                        EmptyView()
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        Text("Image Grid")
            .font(.headline)
            .padding(.bottom, 8)
        
        ImageGridView(
            images: [
                "system:person.circle.fill",
                "system:heart.fill",
                "system:star.fill",
                "system:book.fill",
                "system:camera.fill",
                "https://picsum.photos/200",
                "https://picsum.photos/201",
                "https://picsum.photos/202"
            ],
            columns: 3,
            onImageTap: { index in
            }
        )
    }
    .padding()
    .background(Color.white)
} 
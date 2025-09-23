import SwiftUI

struct UniversityCard: View {
    let university: University
    let isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: university.logo)
                .resizable()
                .scaledToFit()
                .frame(width: isSelected ? 65 : 40, height: isSelected ? 65 : 40)
                .foregroundColor(university.textColor)
                .shadow(color: isSelected ? .white.opacity(0.6) : .clear, radius: 10)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isSelected)

            Spacer(minLength: isSelected ? 0 : 5)

            Text(university.name)
                .font(.caption.bold())
                .foregroundColor(university.textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 5)
                .opacity(isSelected ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 0.4), value: isSelected)

            Spacer()
        }
        .padding()
        .frame(width: 140, height: 100)
        .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? university.color.opacity(0.95) : university.color.opacity(0.75)))
        .shadow(radius: isSelected ? 12 : 4)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        .onTapGesture { withAnimation { onSelect() } }
    }
}

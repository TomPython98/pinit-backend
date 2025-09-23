import SwiftUI

struct UniversitySelectionView: View {
    @Binding var selectedUniversity: University?

    let universities: [University]

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("🏫 University")
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.secondary.opacity(0.8),
                            Color.primary.opacity(0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(12)
                )
                .shadow(radius: 10)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(universities, id: \.name) { university in
                    UniversityCard(university: university, isSelected: university.name == selectedUniversity?.name) {
                        selectedUniversity = university
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 30)
    }
}

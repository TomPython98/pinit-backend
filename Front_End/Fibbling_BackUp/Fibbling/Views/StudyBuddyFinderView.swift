import SwiftUI

// 🎯 Study Buddy Model
struct StudyBuddy: Identifiable {
    let id = UUID()
    let name: String
    let subjects: [String]
    let availability: String
    let learningStyle: String
}

// StudyBuddy data will be loaded from backend API

// 🎯 Study Buddy Finder View
struct StudyBuddyFinderView: View {
    @State private var selectedSubject = ""
    @State private var selectedAvailability = ""
    @State private var selectedLearningStyle = ""
    
    @State private var matchedBuddies: [StudyBuddy] = []

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Find a Study Buddy")) {
                        Picker("Subject", selection: $selectedSubject) {
                            Text("Select a Subject").tag("")
                            ForEach(["Mathematics", "Physics", "History", "Economics", "Biology", "Chemistry"], id: \.self) {
                                Text($0)
                            }
                        }

                        Picker("Availability", selection: $selectedAvailability) {
                            Text("Select Availability").tag("")
                            ForEach(["Mornings", "Afternoons", "Evenings"], id: \.self) {
                                Text($0)
                            }
                        }

                        Picker("Learning Style", selection: $selectedLearningStyle) {
                            Text("Select Learning Style").tag("")
                            ForEach(["Visual", "Auditory", "Hands-on"], id: \.self) {
                                Text($0)
                            }
                        }
                    }

                    Section {
                        Button(action: findStudyBuddies) {
                            Text("Find a Buddy")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }

                // Display Matched Study Buddies
                if !matchedBuddies.isEmpty {
                    List(matchedBuddies) { buddy in
                        VStack(alignment: .leading) {
                            Text(buddy.name)
                                .font(.headline)
                            Text("📚 Subjects: \(buddy.subjects.joined(separator: ", "))")
                            Text("⏳ Availability: \(buddy.availability)")
                            Text("🧠 Learning Style: \(buddy.learningStyle)")
                        }
                        .padding()
                        .listRowBackground(Color.bgCard)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.bgSurface)
                }
            }
            .navigationTitle("Study Buddy Finder")
        }
    }

    // 🎯 Find Matching Buddies
    func findStudyBuddies() {
        // Load study buddies from backend API
        // TODO: Implement real API call to find study buddies
        matchedBuddies = []
    }
}

// 🚀 Preview
#Preview {
    StudyBuddyFinderView()
}

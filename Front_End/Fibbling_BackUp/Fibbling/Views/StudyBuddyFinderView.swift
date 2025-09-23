import SwiftUI

// 🎯 Study Buddy Model
struct StudyBuddy: Identifiable {
    let id = UUID()
    let name: String
    let subjects: [String]
    let availability: String
    let learningStyle: String
}

// 🎯 Sample Data
let sampleBuddies: [StudyBuddy] = [
    StudyBuddy(name: "Alice", subjects: ["Mathematics", "Physics"], availability: "Evenings", learningStyle: "Visual"),
    StudyBuddy(name: "Bob", subjects: ["History", "Economics"], availability: "Afternoons", learningStyle: "Auditory"),
    StudyBuddy(name: "Charlie", subjects: ["Biology", "Chemistry"], availability: "Mornings", learningStyle: "Hands-on")
]

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
                    }
                }
            }
            .navigationTitle("Study Buddy Finder")
        }
    }

    // 🎯 Find Matching Buddies
    func findStudyBuddies() {
        matchedBuddies = sampleBuddies.filter { buddy in
            (selectedSubject.isEmpty || buddy.subjects.contains(selectedSubject)) &&
            (selectedAvailability.isEmpty || buddy.availability == selectedAvailability) &&
            (selectedLearningStyle.isEmpty || buddy.learningStyle == selectedLearningStyle)
        }
    }
}

// 🚀 Preview
#Preview {
    StudyBuddyFinderView()
}

import SwiftUI
import MapKit

// MARK: - StudyGroup Model

struct StudyGroup: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var subject: String
    var description: String?
    var meetingTime: Date?
    var members: [String]  // List of usernames

    // A simple matching function (case-insensitive subject match)
    func matches(subject query: String) -> Bool {
        return subject.lowercased().contains(query.lowercased())
    }
}

// MARK: - StudyGroupManager

class StudyGroupManager: ObservableObject {
    @Published var groups: [StudyGroup] = []
    
    // Add a new study group (avoid duplicates)
    func addGroup(_ group: StudyGroup) {
        if !groups.contains(where: { $0.id == group.id }) {
            groups.append(group)
        }
    }
    
    // Join a group (if not already a member)
    func joinGroup(group: StudyGroup, username: String) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            if !groups[index].members.contains(username) {
                groups[index].members.append(username)
            }
        }
    }
    
    // Filter groups based on a search query (by subject)
    func filteredGroups(query: String) -> [StudyGroup] {
        if query.isEmpty {
            return groups
        } else {
            return groups.filter { $0.matches(subject: query) }
        }
    }
}

// MARK: - StudyGroupFinderView

struct StudyGroupFinderView: View {
    @EnvironmentObject var groupManager: StudyGroupManager
    @EnvironmentObject var accountManager: UserAccountManager
    @State private var searchQuery: String = ""
    @State private var showCreateGroupView: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                TextField("Search by subject...", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                // List of matching groups
                List {
                    ForEach(groupManager.filteredGroups(query: searchQuery)) { group in
                        StudyGroupRowView(group: group)
                    }
                }
                .listStyle(PlainListStyle())
                
                // Create Group Button
                Button(action: {
                    showCreateGroupView = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Study Group")
                    }
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .padding()
                .sheet(isPresented: $showCreateGroupView) {
                    StudyGroupCreationView()
                        .environmentObject(groupManager)
                        .environmentObject(accountManager)
                }
            }
            .navigationTitle("Study Group Finder")
        }
    }
}

// MARK: - StudyGroupRowView

struct StudyGroupRowView: View {
    let group: StudyGroup
    @EnvironmentObject var groupManager: StudyGroupManager
    @EnvironmentObject var accountManager: UserAccountManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                Text("Subject: \(group.subject)")
                    .font(.subheadline)
                    .foregroundColor(Color.textSecondary)
                if let meetingTime = group.meetingTime {
                    Text("Meeting: \(meetingTime, formatter: groupDateFormatter)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            // If user is already a member, show "Joined"; else show a Join button.
            if let currentUser = accountManager.currentUser, group.members.contains(currentUser) {
                Text("Joined")
                    .foregroundColor(.green)
                    .font(.subheadline)
            } else {
                Button(action: {
                    if let currentUser = accountManager.currentUser {
                        groupManager.joinGroup(group: group, username: currentUser)
                    }
                }) {
                    Text("Join")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                        .padding(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private let groupDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

// MARK: - StudyGroupCreationView

struct StudyGroupCreationView: View {
    @EnvironmentObject var groupManager: StudyGroupManager
    @EnvironmentObject var accountManager: UserAccountManager
    @Environment(\.dismiss) var dismiss
    
    @State private var groupName: String = ""
    @State private var subject: String = ""
    @State private var groupDescription: String = ""
    @State private var meetingTime: Date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Group Details")) {
                    TextField("Group Name", text: $groupName)
                    TextField("Subject", text: $subject)
                    TextEditor(text: $groupDescription)
                        .scrollContentBackground(.hidden)
                        .frame(height: 100)
                }
                Section(header: Text("Meeting Time (optional)")) {
                    DatePicker("Meeting Time", selection: $meetingTime, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Create Study Group")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Create") {
                    createGroup()
                    dismiss()
                }
                .disabled(groupName.isEmpty || subject.isEmpty)
            )
        }
    }
    
    private func createGroup() {
        // Create a new group with the current user as the first member.
        let newGroup = StudyGroup(
            id: UUID(),
            name: groupName,
            subject: subject,
            description: groupDescription.isEmpty ? nil : groupDescription,
            meetingTime: meetingTime,
            members: [accountManager.currentUser ?? "Unknown"]
        )
        groupManager.addGroup(newGroup)
    }
}

// MARK: - Preview

struct StudyGroupFinderView_Previews: PreviewProvider {
    static var previews: some View {
        StudyGroupFinderView()
            .environmentObject(StudyGroupManager())
            .environmentObject(UserAccountManager())
    }
}

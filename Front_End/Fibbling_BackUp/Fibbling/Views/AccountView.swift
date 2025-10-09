import SwiftUI

struct AccountView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            VStack {
                if let currentUser = accountManager.currentUser {
                    VStack(spacing: 15) {
                        Text("Welcome, \(currentUser)! 👋")
                            .font(.title.bold())
                            .padding(.top, 20)

                        Divider()

                        // ✅ Show Friend Requests
                        if !accountManager.friendRequests.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Pending Friend Requests")
                                    .font(.headline)
                                    .padding(.top)

                                ForEach(accountManager.friendRequests, id: \.self) { request in
                                    HStack {
                                        Text(request)
                                            .font(.body)
                                        Spacer()
                                        Button("Accept") {
                                            accountManager.acceptFriendRequest(from: request)
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            Text("No pending friend requests.")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .padding(.top, 10)
                        }

                        Divider()

                        // ✅ Show List of Friends
                        VStack(alignment: .leading) {
                            Text("Your Friends")
                                .font(.headline)

                            if accountManager.friends.isEmpty {
                                Text("No friends yet. 😢")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            } else {
                                List(accountManager.friends, id: \.self) { friend in
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.blue)
                                        Text(friend)
                                    }
                                    .listRowBackground(Color.bgCard)
                                }
                                .scrollContentBackground(.hidden)
                                .background(Color.bgSurface)
                                .frame(height: 150)
                            }
                        }
                        .padding(.horizontal)

                        Divider()

                        // ✅ Logout Button
                        Button("Logout") {
                            showLogoutAlert = true
                        }
                        .foregroundColor(.red)
                        .padding(.top, 10)
                        .alert("Are you sure you want to log out?", isPresented: $showLogoutAlert) {
                            Button("Cancel", role: .cancel) {}
                            Button("Logout", role: .destructive) {
                                accountManager.logout { success, _ in
                                    if success {
                                        DispatchQueue.main.async {
                                            // The accountManager.logout already sets isLoggedIn to false
                                            // No need to set it again here
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                } else {
                    Text("No user logged in.")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Account")
        }
        .onAppear {
            accountManager.fetchFriendRequests()
            accountManager.fetchFriends()
        }
    }
}

#Preview {
    AccountView().environmentObject(UserAccountManager())
}

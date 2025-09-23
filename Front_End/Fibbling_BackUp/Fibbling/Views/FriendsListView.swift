import SwiftUI

// MARK: - Modern FriendsListView following Apple Design Guidelines
struct FriendsListView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var chatManager: ChatManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchQuery = ""
    @State private var allUsers: [String] = []
    @State private var pendingRequests: [String] = []
    @State private var sentRequests: [String] = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedTab = 0
    @State private var isLoading = false
    
    private let tabs = ["Friends", "Requests", "Discover"]
    private let baseURL = "http://127.0.0.1:8000/api"

    // MARK: - Filtering Logic
    var filteredFriends: [String] {
        if searchQuery.isEmpty {
            return accountManager.friends
        } else {
            return accountManager.friends.filter { $0.localizedCaseInsensitiveContains(searchQuery) }
        }
    }

    var filteredUsers: [String] {
        if searchQuery.isEmpty {
            return allUsers.filter {
                !accountManager.friends.contains($0) &&
                !pendingRequests.contains($0) &&
                !sentRequests.contains($0) &&
                $0 != accountManager.currentUser
            }
        } else {
            return allUsers.filter {
                $0.localizedCaseInsensitiveContains(searchQuery) &&
                !accountManager.friends.contains($0) &&
                !pendingRequests.contains($0) &&
                !sentRequests.contains($0) &&
                $0 != accountManager.currentUser
            }
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern search bar
                    searchSection
                    
                    // Tab selector with modern design
                    tabSelector
                    
                    // Content area
                    TabView(selection: $selectedTab) {
                        friendsTab
                            .tag(0)
                        
                        requestsTab
                            .tag(1)
                        
                        discoverTab
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Social")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { refreshData() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .rotationEffect(.degrees(isLoading ? 360 : 0))
                            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Friend Request", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Search people...", text: $searchQuery)
                        .font(.system(size: 17))
                        .onChange(of: searchQuery) { _, newValue in
                            if !newValue.isEmpty {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedTab = 2
                                }
                            }
                        }
                    
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.system(size: 16, weight: selectedTab == index ? .semibold : .medium))
                            .foregroundColor(selectedTab == index ? .primary : .secondary)
                        
                        // Active indicator
                        Rectangle()
                            .fill(selectedTab == index ? Color.accentColor : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Friends Tab
    private var friendsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // General chat card
                generalChatCard
                
                if filteredFriends.isEmpty {
                    emptyFriendsView
                } else {
                    friendsList
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
    
    private var generalChatCard: some View {
        NavigationLink(destination: ChatView(sender: accountManager.currentUser ?? "Guest", receiver: "general")) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.gradient)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("General Chat")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Connect with everyone")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    private var emptyFriendsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Friends Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Start connecting with people by sending friend requests")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = 2
                }
            }) {
                Text("Discover People")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var friendsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredFriends, id: \.self) { friend in
                NavigationLink(destination: ChatView(sender: accountManager.currentUser ?? "Guest", receiver: friend)) {
                    HStack(spacing: 16) {
                        // Avatar
                        Circle()
                            .fill(friendColor(for: friend).gradient)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(friend.prefix(1).uppercased())
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(friend)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Tap to chat")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "message.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
                }
            }
        }
    }
    
    // MARK: - Requests Tab
    private var requestsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if pendingRequests.isEmpty && sentRequests.isEmpty {
                    emptyRequestsView
                } else {
                    if !pendingRequests.isEmpty {
                        pendingRequestsSection
                    }
                    
                    if !sentRequests.isEmpty {
                        sentRequestsSection
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
    
    private var emptyRequestsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Requests")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("When you send or receive friend requests, they'll appear here")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var pendingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.orange)
                
                Text("Pending Requests")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(pendingRequests.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(pendingRequests, id: \.self) { user in
                    HStack(spacing: 16) {
                        Circle()
                            .fill(friendColor(for: user).gradient)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(user.prefix(1).uppercased())
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Wants to connect")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button(action: { declineFriendRequest(from: user) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.red)
                                    .cornerRadius(16)
                            }
                            
                            Button(action: { acceptFriendRequest(from: user) }) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.green)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
                }
            }
        }
    }
    
    private var sentRequestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("Sent Requests")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(sentRequests.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(sentRequests, id: \.self) { user in
                    HStack(spacing: 16) {
                        Circle()
                            .fill(friendColor(for: user).gradient)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(user.prefix(1).uppercased())
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                Text("Pending approval")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text("Sent")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.secondary)
                            .cornerRadius(8)
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
                }
            }
        }
    }
    
    // MARK: - Discover Tab
    private var discoverTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if filteredUsers.isEmpty {
                    emptyDiscoverView
                } else {
                    discoverUsersList
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
    
    private var emptyDiscoverView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Users Found")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Try adjusting your search or check back later")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var discoverUsersList: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredUsers, id: \.self) { user in
                HStack(spacing: 16) {
                    Circle()
                        .fill(friendColor(for: user).gradient)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(user.prefix(1).uppercased())
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Fibbling User")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { sendFriendRequest(to: user) }) {
                        Text("Connect")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func friendColor(for username: String) -> Color {
        let colors: [Color] = [.blue, .green, .purple, .orange, .pink, .teal, .indigo, .mint]
        var total = 0
        for char in username.utf8 {
            total += Int(char)
        }
        return colors[total % colors.count]
    }
    
    private func loadData() {
        isLoading = true
        fetchAllUsers()
        fetchPendingRequests()
        fetchSentRequests()
        fetchFriends()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
        }
    }
    
    private func refreshData() {
        loadData()
    }
    
    // MARK: - Networking Methods (keeping existing implementation)
    private func fetchAllUsers() {
        guard let url = URL(string: "\(baseURL)/get_all_users/") else {
            print("❌ [FriendsListView] Invalid URL for fetching all users")
            return
        }
        
        print("🔍 [FriendsListView] Fetching all users...")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ [FriendsListView] Error fetching all users: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [FriendsListView] Invalid response type")
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ [FriendsListView] HTTP error \(httpResponse.statusCode) when fetching all users")
                return
            }
            
            guard let data = data else {
                print("❌ [FriendsListView] No data when fetching all users")
                return
            }
            
            do {
                let users = try JSONSerialization.jsonObject(with: data, options: []) as? [String] ?? []
                DispatchQueue.main.async {
                    self.allUsers = users
                    print("✅ [FriendsListView] Fetched \(users.count) users")
                }
            } catch {
                print("❌ [FriendsListView] Error decoding all users JSON: \(error)")
                DispatchQueue.main.async {
                    self.allUsers = []
                }
            }
        }.resume()
    }

    private func fetchPendingRequests() {
        guard let username = accountManager.currentUser,
              let url = URL(string: "\(baseURL)/get_pending_requests/\(username)/") else {
            print("❌ [FriendsListView] Invalid URL for pending requests")
            return
        }

        print("🔍 [FriendsListView] Fetching pending requests for \(username)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ [FriendsListView] Error fetching pending requests: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [FriendsListView] Invalid response type")
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ [FriendsListView] HTTP error \(httpResponse.statusCode) when fetching pending requests")
                return
            }
            
            guard let data = data else {
                print("❌ [FriendsListView] No data when fetching pending requests")
                return
            }

            do {
                print("📦 [FriendsListView] Raw pending requests: \(String(data: data, encoding: .utf8) ?? "invalid data")")
                
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let pendingRequestsList = json?["pending_requests"] as? [String] {
                    DispatchQueue.main.async {
                        self.pendingRequests = pendingRequestsList
                        print("✅ [FriendsListView] Fetched \(pendingRequestsList.count) Pending Requests")
                    }
                } else {
                    print("❌ [FriendsListView] Invalid pending requests JSON structure")
                    DispatchQueue.main.async {
                        self.pendingRequests = []
                    }
                }
            } catch {
                print("❌ [FriendsListView] Error decoding pending requests JSON: \(error)")
                DispatchQueue.main.async {
                    self.pendingRequests = []
                }
            }
        }.resume()
    }

    private func fetchSentRequests() {
        guard let username = accountManager.currentUser,
              let url = URL(string: "\(baseURL)/get_sent_requests/\(username)/") else {
            print("❌ [FriendsListView] Invalid URL for sent requests")
            return
        }

        print("🔍 [FriendsListView] Fetching sent requests for \(username)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ [FriendsListView] Error fetching sent requests: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [FriendsListView] Invalid response type")
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ [FriendsListView] HTTP error \(httpResponse.statusCode) when fetching sent requests")
                return
            }
            
            guard let data = data else {
                print("❌ [FriendsListView] No data when fetching sent requests")
                return
            }

            do {
                print("📦 [FriendsListView] Raw sent requests: \(String(data: data, encoding: .utf8) ?? "invalid data")")
                
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let sentRequestsList = json?["sent_requests"] as? [String] {
                    DispatchQueue.main.async {
                        self.sentRequests = sentRequestsList
                        print("✅ [FriendsListView] Fetched \(sentRequestsList.count) Sent Requests")
                    }
                } else {
                    print("❌ [FriendsListView] Invalid sent requests JSON structure")
                    DispatchQueue.main.async {
                        self.sentRequests = []
                    }
                }
            } catch {
                print("❌ [FriendsListView] Error decoding sent requests JSON: \(error)")
                DispatchQueue.main.async {
                    self.sentRequests = []
                }
            }
        }.resume()
    }

    private func fetchFriends() {
        guard let username = accountManager.currentUser,
              let url = URL(string: "\(baseURL)/get_friends/\(username)/") else {
            print("❌ [FriendsListView] Invalid URL for friends")
            return
        }

        print("🔍 [FriendsListView] Fetching friends for \(username)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ [FriendsListView] Error fetching friends: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [FriendsListView] Invalid response type")
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ [FriendsListView] HTTP error \(httpResponse.statusCode) when fetching friends")
                return
            }
            
            guard let data = data else {
                print("❌ [FriendsListView] No data when fetching friends")
                return
            }
            
            print("📦 [FriendsListView] Raw friends response: \(String(data: data, encoding: .utf8) ?? "invalid data")")

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let friendsList = json?["friends"] as? [String] {
                    DispatchQueue.main.async {
                        self.accountManager.friends = friendsList
                        print("✅ [FriendsListView] Updated friends list: \(friendsList)")
                    }
                } else {
                    print("❌ [FriendsListView] Invalid friends JSON structure")
                    DispatchQueue.main.async {
                        self.accountManager.friends = []
                    }
                }
            } catch {
                print("❌ [FriendsListView] Error decoding friends JSON: \(error)")
                DispatchQueue.main.async {
                    self.accountManager.friends = []
                }
            }
        }.resume()
    }

    private func acceptFriendRequest(from username: String) {
        accountManager.acceptFriendRequest(from: username)
        DispatchQueue.main.async {
            self.pendingRequests.removeAll { $0 == username }
            if !self.accountManager.friends.contains(username) {
                self.accountManager.friends.append(username)
            }
            self.fetchFriends()
            self.fetchPendingRequests()
            
            self.alertMessage = "You are now friends with \(username)!"
            self.showAlert = true
        }
    }

    private func declineFriendRequest(from username: String) {
        DispatchQueue.main.async {
            self.pendingRequests.removeAll { $0 == username }
            self.alertMessage = "Declined request from \(username)."
            self.showAlert = true
        }
    }

    private func sendFriendRequest(to username: String) {
        guard !sentRequests.contains(username) else {
            alertMessage = "You've already sent a request to \(username)"
            showAlert = true
            return
        }
        accountManager.sendFriendRequest(to: username)
        DispatchQueue.main.async {
            self.sentRequests.append(username)
            self.alertMessage = "Friend request sent to \(username)!"
            self.showAlert = true
        }
    }
}

// MARK: - Preview
#Preview {
    FriendsListView()
        .environmentObject(UserAccountManager())
        .environmentObject(ChatManager())
}


import SwiftUI

// MARK: - Identifiable String Wrapper
struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}

// MARK: - Modern FriendsListView following Apple Design Guidelines
struct FriendsListView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var chatManager: ChatManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    
    @State private var searchQuery = ""
    @State private var allUsers: [String] = []
    // Use UserAccountManager's friendRequests instead of separate state
    @State private var sentRequests: [String] = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedTab = 0
    @State private var isLoading = false
    @State private var isPrefetchingImages = true // Start as true to show loading initially
    @State private var selectedChatUser: IdentifiableString? = nil
    @State private var showUserProfileSheet = false
    @State private var selectedUserProfile: String? = nil
    
    private var tabs: [String] {
        ["Friends", "Requests", "Discover"]
    }
    private let baseURL = APIConfig.primaryBaseURL

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
                !accountManager.friendRequests.contains($0) &&
                !sentRequests.contains($0) &&
                $0 != accountManager.currentUser
            }
        } else {
            return allUsers.filter {
                $0.localizedCaseInsensitiveContains(searchQuery) &&
                !accountManager.friends.contains($0) &&
                !accountManager.friendRequests.contains($0) &&
                !sentRequests.contains($0) &&
                $0 != accountManager.currentUser
            }
        }
    }

    // MARK: - Body
    var body: some View {
            ZStack {
            // Professional background like ContentView
                Color.bgSurface
                .ignoresSafeArea()
            
            // Elegant background gradient
            LinearGradient(
                colors: [Color.gradientStart.opacity(0.05), Color.gradientEnd.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                // Professional header
                headerView
                    
                // Tab selector
                    tabSelector
                
                // Content based on selected tab
                contentView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                fetchAllUsers()
                accountManager.fetchFriendRequests() // Use UserAccountManager's method
                fetchCurrentUserFriends()
                
                // ✅ Refresh unread counts for all friends
                if let currentUser = accountManager.currentUser {
                    chatManager.refreshUnreadCounts(currentUser: currentUser)
                }
                
                // Wait for prefetch to complete before showing content
                await prefetchVisibleImages()
            }
        }
        .onChange(of: selectedTab) { _ in
            // Prefetch images when switching tabs
            Task {
                await prefetchVisibleImages()
            }
        }
        .alert("Social", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(item: $selectedChatUser) { chatUser in
            NavigationStack {
                ChatView(
                    sender: accountManager.currentUser ?? "Guest",
                    receiver: chatUser.value
                )
                .environmentObject(accountManager)
                .environmentObject(chatManager)
                .onAppear {
                    print("🔍 ChatView sheet appeared with:")
                    print("   Sender: '\(accountManager.currentUser ?? "Guest")'")
                    print("   Receiver: '\(chatUser.value)'")
                }
            }
        }
        .sheet(isPresented: $showUserProfileSheet) {
            if let username = selectedUserProfile {
                UserProfileView(username: username)
                    .environmentObject(accountManager)
                    .environmentObject(chatManager)
            }
        }
        .onChange(of: selectedUserProfile) { newValue in
            if newValue != nil {
            }
        }
        .onChange(of: showUserProfileSheet) { newValue in
            if newValue {
            } else {
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ImagesPrefetchCompleted"))) { notification in
            // ✅ CRITICAL FIX: Mark prefetching as complete
            isPrefetchingImages = false
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
            HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.bgCard)
                            .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
                    )
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Friends & Social")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                Text("Connect with students")
                    .font(.caption)
                                .foregroundColor(Color.textSecondary)
                        }
            
            Spacer()
            
            Button(action: {
                fetchAllUsers()
                accountManager.fetchFriendRequests()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .foregroundColor(Color.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.bgCard)
                            .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
                    )
                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(tabs[index])
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(selectedTab == index ? Color.brandPrimary : Color.textSecondary)
                        
                        Rectangle()
                            .fill(Color.brandPrimary)
                            .frame(height: 2)
                            .opacity(selectedTab == index ? 1 : 0)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.bgCard)
    }
    
    // MARK: - Content View
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading || isPrefetchingImages {
                    loadingView
                } else {
                    switch selectedTab {
                    case 0: // Friends
                        friendsSection
                    case 1: // Requests
                        requestsSection
                    case 2: // Discover
                        discoverSection
                    default:
                        EmptyView()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            // Show skeleton loaders for better perceived performance
            SkeletonListView(itemType: .userCard, count: 5)
        }
    }
    
    // MARK: - Friends Section
    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Friends")
                    .font(.headline)
                    .fontWeight(.bold)
                        .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Text("\(accountManager.friends.count)")
                    .font(.subheadline)
                    .foregroundColor(Color.brandPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandPrimary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if accountManager.friends.isEmpty {
                emptyFriendsState
            } else {
            ForEach(filteredFriends, id: \.self) { friend in
                    friendCard(username: friend)
                }
            }
        }
    }
    
    // MARK: - Requests Section
    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Friend Requests")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Text("\(accountManager.friendRequests.count)")
                    .font(.subheadline)
                    .foregroundColor(Color.brandWarning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandWarning.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if accountManager.friendRequests.isEmpty {
                emptyRequestsState
            } else {
                ForEach(accountManager.friendRequests, id: \.self) { request in
                    friendRequestCard(username: request)
                }
            }
        }
    }
    
    // MARK: - Discover Section
    private var discoverSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Discover Friends")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Text("\(filteredUsers.count)")
                    .font(.subheadline)
                    .foregroundColor(Color.brandSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandSecondary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.textMuted)
                    .font(.title3)
                
                TextField("Search users...", text: $searchQuery)
                    .padding(12)
                    .background(Color.bgSecondary)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cardStroke, lineWidth: 1)
                    )
            }
            
            if filteredUsers.isEmpty {
                emptyDiscoverState
            } else {
                ForEach(filteredUsers, id: \.self) { user in
                    discoverUserCard(username: user)
                }
            }
        }
    }
    
    // MARK: - Friend Card
    private func friendCard(username: String) -> some View {
        Button(action: {
            selectedUserProfile = username
            showUserProfileSheet = true
        }) {
            HStack(spacing: 16) {
                // Profile Picture
                UserProfileImageView(username: username, size: 50, borderColor: Color.brandPrimary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(username)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.textPrimary)
                    
                    Text("Friend")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    print("🔍 Chat button tapped for: '\(username)'")
                    selectedChatUser = IdentifiableString(value: username)
                    print("🔍 Opening chat with: '\(username)'")
                }) {
                    ZStack(alignment: .topTrailing) {
                        HStack(spacing: 6) {
                            Image(systemName: "message.fill")
                                .font(.caption)
                            Text("Chat")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.brandPrimary)
                        .cornerRadius(10)
                        
                        // Unread message badge
                        if let unreadCount = chatManager.unreadCounts[username], unreadCount > 0 {
                            Text(unreadCount > 9 ? "9+" : "\(unreadCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 18, minHeight: 18)
                                .padding(2)
                                .background(
                                    Circle()
                                        .fill(Color.red)
                                )
                                .offset(x: 8, y: -8)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle()) // Prevent the outer button from interfering
            }
            .padding(16)
            .background(Color.bgCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cardStroke, lineWidth: 1)
            )
            .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle()) // Remove default button styling
    }
    
    // MARK: - Friend Request Card
    private func friendRequestCard(username: String) -> some View {
        HStack(spacing: 16) {
            // Profile Picture
            UserProfileImageView(username: username, size: 50, borderColor: Color.brandWarning)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(username)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.textPrimary)
                
                Text("Wants to be friends")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {
                    acceptFriendRequest(username)
                }) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.brandSuccess)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    declineFriendRequest(username)
                }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.brandWarning)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.bgCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Discover User Card
    private func discoverUserCard(username: String) -> some View {
        Button(action: {
            selectedUserProfile = username
            showUserProfileSheet = true
        }) {
            HStack(spacing: 16) {
                // Profile Picture
                UserProfileImageView(username: username, size: 50, borderColor: Color.brandSecondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(username)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.textPrimary)
                    
                    Text("New user")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    sendFriendRequest(username)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                            .font(.caption)
                        Text("Add")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.brandSecondary)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle()) // Prevent the outer button from interfering
            }
            .padding(16)
            .background(Color.bgCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cardStroke, lineWidth: 1)
            )
            .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle()) // Remove default button styling
    }
    
    // MARK: - Empty States
    private var emptyFriendsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(Color.textMuted)
            
            Text("No Friends Yet")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.textPrimary)
            
            Text("Start connecting with people by exploring the Discover tab")
                .font(.subheadline)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.bgCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    private var emptyRequestsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.open")
                .font(.system(size: 60))
                .foregroundColor(Color.textMuted)
            
            Text("No Pending Requests")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.textPrimary)
            
            Text("When someone sends you a friend request, it will appear here")
                .font(.subheadline)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.bgCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    private var emptyDiscoverState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(Color.textMuted)
            
            Text("No Users Found")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.textPrimary)
            
            Text("Try adjusting your search or check back later")
                .font(.subheadline)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.bgCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Actions
    private func acceptFriendRequest(_ username: String) {
        guard let currentUser = accountManager.currentUser,
              let url = URL(string: "\(baseURL)/accept_friend_request/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        accountManager.addAuthHeader(to: &request)
        
        let body = ["from_user": username]  // Only send from_user - backend gets to_user from JWT
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        showAlert(message: "Error accepting request: \(error.localizedDescription)")
                return
            }
            
                    // Remove from pending requests and add to friends
                    accountManager.friendRequests.removeAll { $0 == username }
                    if !accountManager.friends.contains(username) {
                        accountManager.friends.append(username)
                    }
                    
                    showAlert(message: "Friend request accepted!")
                }
            }.resume()
            } catch {
            showAlert(message: "Error processing request")
        }
    }
    
    private func declineFriendRequest(_ username: String) {
        guard let currentUser = accountManager.currentUser,
              let url = URL(string: "\(baseURL)/decline_friend_request/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        accountManager.addAuthHeader(to: &request)
        
        let body = ["from_user": username]  // Only send from_user - backend gets to_user from JWT
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        showAlert(message: "Error declining request: \(error.localizedDescription)")
                return
            }
            
                    // Remove from pending requests
                    accountManager.friendRequests.removeAll { $0 == username }
                    
                    showAlert(message: "Friend request declined")
                }
            }.resume()
        } catch {
            showAlert(message: "Error processing request")
        }
    }
    
    private func sendFriendRequest(_ username: String) {
        guard let currentUser = accountManager.currentUser,
              let url = URL(string: "\(baseURL)/send_friend_request/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        accountManager.addAuthHeader(to: &request)
        
        let body = ["to_user": username]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                    DispatchQueue.main.async {
                    if let error = error {
                        showAlert(message: "Error sending request: \(error.localizedDescription)")
                        return
                    }
                    
                    // Add to sent requests
                    if !sentRequests.contains(username) {
                        sentRequests.append(username)
                    }
                    
                    showAlert(message: "Friend request sent!")
                }
            }.resume()
            } catch {
            showAlert(message: "Error processing request")
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
    
    // MARK: - Network Functions
    private func fetchAllUsers() {
        isLoading = true
        
        let urlString = "\(baseURL)/get_all_users/"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                }
                
                if let data = data {
                    do {
                        let response = try JSONDecoder().decode([String].self, from: data)
                        // Filter out the current user from the list
                        let currentUser = self.accountManager.currentUser ?? ""
                        self.allUsers = response.filter { $0 != currentUser }
                    } catch {
                        self.showAlert(message: "Failed to load users")
                    }
                } else {
                    self.showAlert(message: "Failed to load users")
                }
            }
        }.resume()
    }
    
    
    private func fetchCurrentUserFriends() {
        guard let currentUser = accountManager.currentUser else {
            return
        }
        
        let urlString = "\(baseURL)/get_friends/\(currentUser)/"
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        var request = URLRequest(url: url)
        accountManager.addAuthHeader(to: &request)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            DispatchQueue.main.async {
                if let error = error {
                    return
                }
                
                guard let data = data else {
                    return
                }
                
                
                // Log raw response for debugging
                if let rawString = String(data: data, encoding: .utf8) {
                }
                
                do {
                    let response = try JSONDecoder().decode(FriendsData.self, from: data)
                    self.accountManager.friends = response.friends
                } catch {
                }
            }
        }.resume()
    }
    
    // MARK: - Image Prefetching
    private func prefetchVisibleImages() async {
        isPrefetchingImages = true
        
        var usernamesToPrefetch: [String] = []
        
        switch selectedTab {
        case 0: // Friends
            // Prefetch images for friends (increased limit for better UX)
            usernamesToPrefetch = Array(accountManager.friends.prefix(50))
        case 1: // Requests
            // Prefetch images for pending requests
            usernamesToPrefetch = Array(accountManager.friendRequests.prefix(30))
        case 2: // Discover
            // Prefetch images for discover users (increased limit)
            usernamesToPrefetch = Array(filteredUsers.prefix(25))
        default:
            break
        }
        
        if !usernamesToPrefetch.isEmpty {
            await ImageManager.shared.prefetchImagesForUsers(usernamesToPrefetch)
        }
        
        isPrefetchingImages = false
    }
}

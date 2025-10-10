import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var accountManager: UserAccountManager
    @StateObject private var profileManager: UserProfileManager
    @ObservedObject private var imageManager = ImageManager.shared
    
    init() {
        _profileManager = StateObject(wrappedValue: UserProfileManager())
    }
    
    // User profile data
    @State private var username = ""
    @State private var email = ""
    @State private var fullName = ""
    @State private var location = ""
    @State private var website = ""
    @State private var bio = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var profileImageData: Data?
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showingImageGallery = false
    @State private var refreshID = UUID() // Force view refresh
    
    // Form validation
    @State private var emailIsValid = true
    @State private var websiteIsValid = true
    
    // Interests state
    @State private var interests: [String] = []
    @State private var newInterest: String = ""
    @State private var showingAddInterest = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Professional clean background
                Color.bgSurface
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        profileForm
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Initialize profile manager with account manager for JWT authentication
                profileManager.setAccountManager(accountManager)
                
                loadProfileData()
                Task {
                    await imageManager.loadUserImages(username: username, forceRefresh: true)
                }
            }
            .onReceive(imageManager.$userImages) { _ in
                // Force view refresh when images change
                refreshID = UUID()
                AppLogger.debug("EditProfileView: Images updated, refreshing view", category: AppLogger.ui)
            }
            .alert("Profile", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Profile Form
    private var profileForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            profilePictureSection
            basicInfoSection
            bioSection
            interestsSection
            saveButton
        }
    }
    
    // MARK: - Profile Picture Section
    private var profilePictureSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "camera")
                    .foregroundColor(.brandPrimary)
                Text("Profile Pictures")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button("Manage All") {
                    showingImageGallery = true
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.brandPrimary)
            }
            
            // Primary Profile Picture
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.brandPrimary, .brandSecondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    
                    if let primaryImage = imageManager.getPrimaryImage() {
                        imageManager.cachedAsyncImage(
                            url: imageManager.getFullImageURL(primaryImage),
                            contentMode: .fill,
                            targetSize: CGSize(width: 160, height: 160)
                        )
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .id(refreshID) // Force recreation when refreshID changes
                    } else if let profileImage = profileImage {
                        profileImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Profile Picture")
                        .font(.subheadline)
                        .foregroundColor(.textPrimary)
                    
                    Text("This is your main profile picture")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    HStack(spacing: 12) {
                        Button(action: { showImagePicker = true }) {
                            Text("Upload New")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.brandPrimary)
                        }
                        
                        if imageManager.getPrimaryImage() != nil {
                            Button(action: { showingImageGallery = true }) {
                                Text("Change")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            
            // Quick Stats
            if !imageManager.userImages.isEmpty {
                HStack {
                    Image(systemName: "photo.stack")
                        .foregroundColor(.textSecondary)
                    Text("\(imageManager.userImages.count) images total")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    Text("Tap 'Manage All' to organize")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedImage, matching: .images)
        .onChange(of: selectedImage) { newValue in
            Task {
                if let newValue = newValue {
                    await handleImageSelection(newValue)
                }
            }
        }
        .sheet(isPresented: $showingImageGallery) {
            ImageGalleryView(username: username)
        }
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        Group {
            formField(title: "Username", text: $username, icon: "at")
            formField(title: "Full Name", text: $fullName, icon: "person")
            formField(title: "Email", text: $email, icon: "envelope")
            formField(title: "Location", text: $location, icon: "location")
            formField(title: "Website", text: $website, icon: "globe")
        }
    }
    
    // MARK: - Bio Section
    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "text.quote")
                    .foregroundColor(.brandPrimary)
                Text("Bio")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
            }
            
            TextEditor(text: $bio)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.bgCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cardStroke, lineWidth: 1)
                )
                .foregroundColor(Color.textPrimary)
        }
    }
    
    // MARK: - Interests Section
    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            interestsHeader
            interestsList
            addInterestButton
            if showingAddInterest {
                addInterestRow
            }
        }
    }
    
    private var interestsHeader: some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundColor(.brandPrimary)
            Text("Interests")
                .font(.headline)
                .foregroundColor(.textPrimary)
            Spacer()
        }
    }
    
    private var interestsList: some View {
        Group {
            if !interests.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(interests, id: \.self) { interest in
                        interestTag(interest)
                    }
                }
            } else {
                Text("No interests added yet")
                    .foregroundColor(Color.textSecondary)
                    .italic()
                    .padding(.vertical, 8)
            }
        }
    }
    
    private func interestTag(_ interest: String) -> some View {
        HStack {
            Text(interest)
                .font(.caption)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Button(action: {
                interests.removeAll { $0 == interest }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.brandPrimary.opacity(0.1))
        )
    }
    
    private var addInterestButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingAddInterest.toggle()
                if !showingAddInterest {
                    newInterest = ""
                }
            }
        }) {
            HStack {
                Image(systemName: showingAddInterest ? "minus.circle.fill" : "plus.circle.fill")
                    .foregroundColor(.white)
                Text(showingAddInterest ? "Cancel" : "Add Interests")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(showingAddInterest ? Color.red : Color.brandPrimary)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var addInterestRow: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Type your interest here...", text: $newInterest)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        addInterest()
                    }
                
                Button("Add") {
                    addInterest()
                }
                .disabled(newInterest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
            }
            
            if !newInterest.isEmpty && interests.contains(newInterest.trimmingCharacters(in: .whitespacesAndNewlines)) {
                Text("This interest already exists")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveProfile) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text("Save Profile")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brandPrimary)
            )
            .foregroundColor(.white)
        }
        .disabled(isLoading)
    }
    
    // MARK: - Helper Views
    private func formField(title: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.brandPrimary)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
            }
            
            TextField(title, text: text)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.bgCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cardStroke, lineWidth: 1)
                )
                .foregroundColor(Color.textPrimary)
        }
    }
    
    // MARK: - Actions
    private func addInterest() {
        let trimmedInterest = newInterest.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInterest.isEmpty else { return }
        
        if !interests.contains(trimmedInterest) {
            interests.append(trimmedInterest)
            newInterest = ""
            
            // Hide the add interest field after successful addition
            withAnimation(.easeInOut(duration: 0.3)) {
                showingAddInterest = false
            }
        }
    }
    
    private func loadProfileData() {
        guard let username = UserDefaults.standard.string(forKey: "username"), !username.isEmpty else {
            alertMessage = "No username found"
            showAlert = true
            return
        }
        
        // Load profile data from backend
        profileManager.fetchUserProfile(username: username) { success in
            if success {
                // Update local state with backend data
                self.username = username
                self.fullName = self.profileManager.fullName
                self.bio = self.profileManager.bio
                self.interests = self.profileManager.interests
                
                // Set other fields from UserDefaults as fallback
                self.email = UserDefaults.standard.string(forKey: "email") ?? ""
                self.location = UserDefaults.standard.string(forKey: "location") ?? ""
                self.website = UserDefaults.standard.string(forKey: "website") ?? ""
            } else {
                self.alertMessage = self.profileManager.errorMessage ?? "Failed to load profile"
                self.showAlert = true
            }
        }
    }
    
    private func saveProfile() {
        guard let username = UserDefaults.standard.string(forKey: "username"), !username.isEmpty else {
            alertMessage = "No username found"
            showAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            // First upload profile picture if one was selected
            let pictureUploadSuccess = await uploadProfilePicture()
            
            // Then update profile using UserProfileManager
            profileManager.updateUserProfile(
                username: username,
                fullName: fullName,
                university: profileManager.university,
                degree: profileManager.degree,
                year: profileManager.year,
                bio: bio,
                interests: interests,
                skills: profileManager.skills,
                autoInviteEnabled: profileManager.autoInviteEnabled,
                preferredRadius: profileManager.preferredRadius
            ) { success in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if success && pictureUploadSuccess {
                        self.alertMessage = "Profile saved successfully!"
                        self.showAlert = true
                        
                        // Dismiss after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.dismiss()
                        }
                    } else {
                        let errorMsg = !pictureUploadSuccess ? "Failed to upload profile picture" : (self.profileManager.errorMessage ?? "Failed to save profile")
                        self.alertMessage = errorMsg
                        self.showAlert = true
                    }
                }
            }
        }
    }
    
    // MARK: - Image Loading
    private func loadImage(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            return
        }
        
        DispatchQueue.main.async {
            self.profileImage = Image(uiImage: uiImage)
            self.profileImageData = data
        }
    }
    
    private func handleImageSelection(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            return
        }
        
        // Compress image if needed
        let compressedData = compressImage(uiImage, maxSize: 1920)
        
        let request = ImageUploadRequest(
            username: username,
            imageData: compressedData,
            imageType: .profile,
            isPrimary: true, // Always set profile images as primary
            caption: "",
            filename: "profile_\(Date().timeIntervalSince1970).jpg"
        )
        
        let success = await imageManager.uploadImage(request)
        
        if success {
            print("✅ Image uploaded successfully, refreshing ImageManager")
            // The uploadImage method already calls loadUserImages, but let's ensure it's refreshed
            await imageManager.loadUserImages(username: username, forceRefresh: true)
            
            // Post notification to refresh other views
            NotificationCenter.default.post(
                name: NSNotification.Name("ProfileImageUpdated"), 
                object: nil,
                userInfo: ["username": username]
            )
        } else {
            print("❌ Image upload failed")
        }
    }
    
    private func compressImage(_ image: UIImage, maxSize: CGFloat) -> Data {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var newSize = size
        if max(size.width, size.height) > maxSize {
            if aspectRatio > 1 {
                newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
            } else {
                newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
            }
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let compressedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return compressedImage.jpegData(compressionQuality: 0.8) ?? Data()
    }
    
    // MARK: - Profile Picture Upload
    private func uploadProfilePicture() async -> Bool {
        guard let imageData = profileImageData else { return true } // No image to upload
        
        // Convert to base64 for backend
        let base64String = imageData.base64EncodedString()
        
        // Use the existing update profile endpoint
        guard let url = URL(string: "https://pinit-backend-production.up.railway.app/api/update_user_profile/") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "username": username,
            "profile_picture": base64String
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200 || httpResponse.statusCode == 201
            }
        } catch {
            print("Profile picture upload error: \(error)")
        }
        
        return false
    }
}

#Preview {
    EditProfileView()
}

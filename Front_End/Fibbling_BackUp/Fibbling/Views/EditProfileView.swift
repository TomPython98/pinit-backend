import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = UserProfileManager()
    
    // User profile data
    @State private var username = ""
    @State private var email = ""
    @State private var fullName = ""
    @State private var location = ""
    @State private var website = ""
    @State private var bio = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
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
                // Background with subtle gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
                loadProfileData()
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
            basicInfoSection
            bioSection
            interestsSection
            saveButton
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
                .frame(minHeight: 100)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.bgSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cardStroke, lineWidth: 1)
                )
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
                    .foregroundColor(.secondary)
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
                .textFieldStyle(RoundedBorderTextFieldStyle())
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
        
        // Save to backend using UserProfileManager
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
                if success {
                    self.alertMessage = "Profile saved successfully!"
                    self.showAlert = true
                    
                    // Dismiss after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.dismiss()
                    }
                } else {
                    self.alertMessage = self.profileManager.errorMessage ?? "Failed to save profile"
                    self.showAlert = true
                }
            }
        }
    }
}

#Preview {
    EditProfileView()
}

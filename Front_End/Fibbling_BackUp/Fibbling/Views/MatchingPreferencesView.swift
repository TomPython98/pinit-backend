import SwiftUI
import PhotosUI

struct MatchingPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var theme = PinItTheme()
    @StateObject private var imageManager = ImageManager.shared
    @EnvironmentObject var accountManager: UserAccountManager

    // MARK: - App Storage for Matching Preferences
    @AppStorage("allowAutoMatching") private var allowAutoMatching = true
    @AppStorage("preferredRadius") private var preferredRadius = 10.0
    @AppStorage("matchingAgeRange") private var matchingAgeRange = "18-25"
    @AppStorage("matchingUniversity") private var matchingUniversity = ""
    @AppStorage("matchingDegree") private var matchingDegree = ""
    @AppStorage("matchingYear") private var matchingYear = ""
    
    // State variables for arrays (AppStorage doesn't support arrays directly)
    @State private var matchingInterests: [String] = []
    @State private var matchingSkills: [String] = []
    @State private var preferredEventTypes: [String] = []
    
    // State variables
    @State private var newInterest = ""
    @State private var newSkill = ""
    @State private var showAddInterest = false
    @State private var showAddSkill = false
    
    // Image management state
    @State private var showingImageGallery = false
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var profileImageData: Data?

    let availableInterests = [
        "Study Groups", "Language Exchange", "Cultural Events", "Sports", "Music",
        "Art", "Technology", "Business", "Science", "Literature", "Travel",
        "Food", "Photography", "Gaming", "Fitness", "Volunteering"
    ]

    let availableSkills = [
        "Programming", "Design", "Writing", "Public Speaking", "Leadership",
        "Languages", "Mathematics", "Science", "Art", "Music", "Sports",
        "Cooking", "Photography", "Teaching", "Mentoring"
    ]

    let ageRanges = ["18-25", "26-35", "36-45", "46-55", "55+", "Any"]
    let academicYears = ["Freshman", "Sophomore", "Junior", "Senior", "Graduate", "PhD", "Any"]

    var body: some View {
        NavigationStack {
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Auto-Matching Toggle
                        settingsCard("Auto-Matching", icon: PinItIcons.people, color: .pinItPrimary) {
                            VStack(spacing: 16) {
                                Toggle("Enable Auto-Matching", isOn: $allowAutoMatching)
                                    .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))

                                if allowAutoMatching {
                                    Text("PinIt will automatically suggest events and people based on your preferences")
                                        .font(.caption)
                                        .foregroundStyle(Color.pinItTextSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Profile Images Section
                        settingsCard("Profile Images", icon: "camera", color: .pinItPrimary) {
                            VStack(alignment: .leading, spacing: 16) {
                                // Primary Profile Picture Display
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(
                                                gradient: Gradient(colors: [Color.pinItPrimary, Color.pinItSecondary]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 60, height: 60)
                                        
                                        if let primaryImage = imageManager.getPrimaryImage() {
                                            AsyncImage(url: URL(string: primaryImage.url)) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 60, height: 60)
                                                        .clipShape(Circle())
                                                case .failure, .empty:
                                                    Image(systemName: "person.fill")
                                                        .font(.title2)
                                                        .foregroundColor(.white)
                                                @unknown default:
                                                    Image(systemName: "person.fill")
                                                        .font(.title2)
                                                        .foregroundColor(.white)
                                                }
                                            }
                                        } else if let profileImage = profileImage {
                                            profileImage
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 60, height: 60)
                                                .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Profile Picture")
                                            .font(.headline)
                                            .foregroundStyle(Color.pinItTextPrimary)
                                        
                                        Text("Manage your profile images")
                                            .font(.caption)
                                            .foregroundStyle(Color.pinItTextSecondary)
                                        
                                        HStack(spacing: 12) {
                                            Button("Upload New") {
                                                showingImagePicker = true
                                            }
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(.pinItPrimary)
                                            
                                            Button("Manage All") {
                                                showingImageGallery = true
                                            }
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(.pinItTextSecondary)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Image Stats
                                if !imageManager.userImages.isEmpty {
                                    HStack {
                                        Image(systemName: "photo.stack")
                                            .foregroundColor(.pinItTextSecondary)
                                        Text("\(imageManager.userImages.count) images")
                                            .font(.caption)
                                            .foregroundColor(.pinItTextSecondary)
                                        
                                        Spacer()
                                        
                                        Text("Tap 'Manage All' to organize")
                                            .font(.caption)
                                            .foregroundColor(.pinItTextSecondary)
                                    }
                                }
                            }
                        }
                        
                        if allowAutoMatching {
                            // Location Preferences
                            settingsCard("Location", icon: PinItIcons.location, color: .pinItAccent) {
                                VStack(alignment: .leading, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Preferred Radius")
                                                .foregroundStyle(Color.pinItTextPrimary)
                                            Spacer()
                                            Text("\(Int(preferredRadius)) km")
                                                .foregroundStyle(Color.pinItTextSecondary)
                                        }
                                        Slider(value: $preferredRadius, in: 1...50, step: 1)
                                            .accentColor(theme.primaryColor)
                                    }
                                    
                                    Text("Events within this radius will be prioritized for matching")
                                        .font(.caption)
                                        .foregroundStyle(Color.pinItTextSecondary)
                                }
                            }
                            
                            // Interest Preferences
                            settingsCard("Interests", icon: PinItIcons.tag, color: .pinItSecondary) {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Your Interests")
                                            .foregroundStyle(Color.pinItTextPrimary)
                                        Spacer()
                                        Button("Add") {
                                            showAddInterest = true
                                        }
                                        .foregroundStyle(theme.primaryColor)
                                    }
                                    
                                    if matchingInterests.isEmpty {
                                        Text("No interests selected")
                                            .font(.caption)
                                            .foregroundStyle(Color.pinItTextSecondary)
                                    } else {
                                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                            ForEach(matchingInterests, id: \.self) { interest in
                                                HStack {
                                                    Text(interest)
                                                        .font(.caption)
                                                        .foregroundStyle(Color.pinItTextPrimary)
                                                    Spacer()
                                                    Button(action: { removeInterest(interest) }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundStyle(Color.pinItTextSecondary)
                                                    }
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(theme.primaryColor.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Academic Preferences
                            settingsCard("Academic Info", icon: "graduationcap.fill", color: .pinItAcademic) {
                                VStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Age Range")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.pinItTextSecondary)
                                        Picker("Age Range", selection: $matchingAgeRange) {
                                            ForEach(ageRanges, id: \.self) { range in
                                                Text(range).tag(range)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("University")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.pinItTextSecondary)
                                        TextField("Enter university", text: $matchingUniversity)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Degree Level")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.pinItTextSecondary)
                                        Picker("Degree Level", selection: $matchingYear) {
                                            ForEach(academicYears, id: \.self) { year in
                                                Text(year).tag(year)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: PinItIcons.close)
                            .font(.title2)
                                                        .foregroundStyle(Color.pinItTextPrimary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: PinItIcons.people)
                            .foregroundStyle(Color.pinItPrimary)
                        Text("Matching Preferences")
                            .font(.title3.bold())
                                                        .foregroundStyle(Color.pinItTextPrimary)
                    }
                }
            }
        }
        .onAppear {
            theme.isDarkMode = false
            theme.selectedAccentColor = .blue
        }
        .sheet(isPresented: $showAddInterest) {
            addInterestSheet
        }
        .sheet(isPresented: $showingImageGallery) {
            if let username = accountManager.currentUser {
                ImageGalleryView(username: username)
            }
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage, matching: .images)
        .onChange(of: selectedImage) { _, newValue in
            Task {
                if let newValue = newValue {
                    await handleImageSelection(newValue)
                }
            }
        }
        .onAppear {
            if let username = accountManager.currentUser {
                Task {
                    await imageManager.loadUserImages(username: username)
                }
            }
        }
    }
    
    // MARK: - Settings Card
    private func settingsCard<Content: View>(_ title: String, icon: String, color: Color, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.headline)
                                                        .foregroundStyle(Color.pinItTextPrimary)
            }
            
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Add Interest Sheet
    private var addInterestSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Add Interest")
                    .font(.title2.bold())
                    .padding(.top)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(availableInterests, id: \.self) { interest in
                        Button(action: { addInterest(interest) }) {
                            Text(interest)
                                .font(.subheadline)
                                .foregroundStyle(matchingInterests.contains(interest) ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(matchingInterests.contains(interest) ? Color.pinItPrimary : Color.pinItLight)
                                )
                        }
                        .disabled(matchingInterests.contains(interest))
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showAddInterest = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func addInterest(_ interest: String) {
        if !matchingInterests.contains(interest) {
            matchingInterests.append(interest)
        }
    }
    
    private func removeInterest(_ interest: String) {
        matchingInterests.removeAll { $0 == interest }
    }
    
    // MARK: - Image Handling
    private func handleImageSelection(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data),
              let username = accountManager.currentUser else {
            return
        }
        
        // Compress image if needed
        let compressedData = compressImage(uiImage, maxSize: 1920)
        
        let request = ImageUploadRequest(
            username: username,
            imageData: compressedData,
            imageType: .profile,
            isPrimary: imageManager.getPrimaryImage() == nil, // Set as primary if no primary exists
            caption: "",
            filename: "profile_\(Date().timeIntervalSince1970).jpg"
        )
        
        await imageManager.uploadImage(request)
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
}

// MARK: - Preview
#Preview {
    MatchingPreferencesView()
}
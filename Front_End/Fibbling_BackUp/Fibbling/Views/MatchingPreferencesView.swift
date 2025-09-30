import SwiftUI

struct MatchingPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var theme = PinItTheme()

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
                // Clean background
                Color.pinItBackground
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
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
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
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            Text("\(Int(preferredRadius)) km")
                                                .foregroundStyle(.secondary)
                                        }
                                        Slider(value: $preferredRadius, in: 1...50, step: 1)
                                            .accentColor(theme.primaryColor)
                                    }
                                    
                                    Text("Events within this radius will be prioritized for matching")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            // Interest Preferences
                            settingsCard("Interests", icon: PinItIcons.tag, color: .pinItSecondary) {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Your Interests")
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Button("Add") {
                                            showAddInterest = true
                                        }
                                        .foregroundStyle(theme.primaryColor)
                                    }
                                    
                                    if matchingInterests.isEmpty {
                                        Text("No interests selected")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                            ForEach(matchingInterests, id: \.self) { interest in
                                                HStack {
                                                    Text(interest)
                                                        .font(.caption)
                                                        .foregroundStyle(.primary)
                                                    Spacer()
                                                    Button(action: { removeInterest(interest) }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundStyle(.secondary)
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
                                            .foregroundStyle(.secondary)
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
                                            .foregroundStyle(.secondary)
                                        TextField("Enter university", text: $matchingUniversity)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Degree Level")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
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
                            .foregroundStyle(.primary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: PinItIcons.people)
                            .foregroundStyle(Color.pinItPrimary)
                        Text("Matching Preferences")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
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
                    .foregroundStyle(.primary)
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
}

// MARK: - Preview
#Preview {
    MatchingPreferencesView()
}
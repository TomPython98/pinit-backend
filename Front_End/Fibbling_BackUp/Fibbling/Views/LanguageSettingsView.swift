import SwiftUI

struct LanguageSettingsView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "globe")
                        .font(.system(size: 50))
                        .foregroundColor(.brandPrimary)
                    
                    Text("language".localized)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Choose your preferred language")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal, 20)
                
                // Language Options
                VStack(spacing: 12) {
                    ForEach(LocalizationManager.Language.allCases, id: \.self) { language in
                        LanguageOptionCard(
                            language: language,
                            isSelected: localizationManager.currentLanguage == language
                        ) {
                            localizationManager.setLanguage(language)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                
                Spacer()
                
                // Done Button
                Button(action: {
                    dismiss()
                }) {
                    Text("done".localized)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.brandPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.bgSurface.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

struct LanguageOptionCard: View {
    let language: LocalizationManager.Language
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Flag
                Text(language.flag)
                    .font(.system(size: 30))
                
                // Language Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text(language.rawValue.uppercased())
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.brandPrimary)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(20)
            .background(Color.bgCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.brandPrimary : Color.cardStroke, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LanguageSettingsView()
}











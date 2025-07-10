import SwiftUI

struct WelcomeView: View {
    @State private var showMainApp = false
    @State private var animateTitle = false
    @State private var showLanguageSelection = false
    @State private var selectedLanguage = UserSettings.appLanguage
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo和标题
                VStack(spacing: 20) {
                    // Brain Icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .scaleEffect(animateTitle ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateTitle)
                    
                    VStack(spacing: 8) {
                        Text(LocalizedTexts.Welcome.appTitle(language: selectedLanguage))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(LocalizedTexts.Welcome.appSubtitle(language: selectedLanguage))
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(LocalizedTexts.Welcome.appDescription(language: selectedLanguage))
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // 语言选择按钮
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showLanguageSelection = true
                    }
                }) {
                    HStack {
                        Image(systemName: "globe")
                        Text(LocalizedTexts.Welcome.languageSelection(language: selectedLanguage))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.bottom, 20)
                
                // 开始使用按钮
                Button(action: {
                    // 保存选择的语言
                    UserSettings.appLanguage = selectedLanguage
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showMainApp = true
                    }
                }) {
                    HStack {
                        Text(LocalizedTexts.Welcome.startLearning(language: selectedLanguage))
                            .font(.headline)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .scaleEffect(showMainApp ? 0.9 : 1.0)
                
                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 30)
        }
        .onAppear {
            animateTitle = true
        }
        .fullScreenCover(isPresented: $showMainApp) {
            MainTabView()
        }
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionView(selectedLanguage: $selectedLanguage)
        }
    }
}

// MARK: - Language Selection View
struct LanguageSelectionView: View {
    @Binding var selectedLanguage: UserSettings.AppLanguage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "globe")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text(LocalizedTexts.Welcome.selectLanguagePrompt(language: selectedLanguage))
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                }
                .padding(.top, 40)
                
                VStack(spacing: 16) {
                    ForEach(UserSettings.AppLanguage.allCases, id: \.self) { language in
                        LanguageOptionView(
                            language: language,
                            isSelected: selectedLanguage == language
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedLanguage = language
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Text(LocalizedTexts.Common.confirm(language: selectedLanguage))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(25)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle(LocalizedTexts.Welcome.languageSelection(language: selectedLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedTexts.Common.done(language: selectedLanguage)) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Language Option View
struct LanguageOptionView: View {
    let language: UserSettings.AppLanguage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(language.code)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    WelcomeView()
} 
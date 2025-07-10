import SwiftUI

struct LanguageTestView: View {
    @State private var currentLanguage = UserSettings.appLanguage
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Text("Language Test View")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Current Language: \(currentLanguage.displayName)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                Text("Welcome Text:")
                    .font(.headline)
                
                Text(LocalizedTexts.Welcome.appTitle(language: currentLanguage))
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(LocalizedTexts.Welcome.appDescription(language: currentLanguage))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                Text("Tab Bar Text:")
                    .font(.headline)
                
                HStack {
                    Text(LocalizedTexts.TabBar.home(language: currentLanguage))
                    Text(LocalizedTexts.TabBar.learning(language: currentLanguage))
                    Text(LocalizedTexts.TabBar.quiz(language: currentLanguage))
                    Text(LocalizedTexts.TabBar.statistics(language: currentLanguage))
                    Text(LocalizedTexts.TabBar.settings(language: currentLanguage))
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text("Switch Language:")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    Button("中文") {
                        withAnimation {
                            UserSettings.appLanguage = .chinese
                            currentLanguage = .chinese
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(currentLanguage == .chinese ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(currentLanguage == .chinese ? .white : .primary)
                    .cornerRadius(8)
                    
                    Button("English") {
                        withAnimation {
                            UserSettings.appLanguage = .english
                            currentLanguage = .english
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(currentLanguage == .english ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(currentLanguage == .english ? .white : .primary)
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            currentLanguage = UserSettings.appLanguage
        }
    }
}

#Preview {
    LanguageTestView()
}
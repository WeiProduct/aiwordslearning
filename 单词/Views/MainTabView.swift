import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var currentLanguage = UserSettings.appLanguage
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text(LocalizedTexts.TabBar.home(language: currentLanguage))
                }
                .tag(0)
            
            WordLearningView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "book.fill" : "book")
                    Text(LocalizedTexts.TabBar.learning(language: currentLanguage))
                }
                .tag(1)
            
            QuizModeView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "questionmark.circle.fill" : "questionmark.circle")
                    Text(LocalizedTexts.TabBar.quiz(language: currentLanguage))
                }
                .tag(2)
            
            ProgressStatsView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "chart.bar.fill" : "chart.bar")
                    Text(LocalizedTexts.TabBar.statistics(language: currentLanguage))
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "gear.fill" : "gear")
                    Text(LocalizedTexts.TabBar.settings(language: currentLanguage))
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onAppear {
            // 确保tab bar样式正确
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // 更新当前语言
            currentLanguage = UserSettings.appLanguage
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            // 监听用户设置变化，更新语言
            currentLanguage = UserSettings.appLanguage
        }
    }
}

#Preview {
    MainTabView()
} 
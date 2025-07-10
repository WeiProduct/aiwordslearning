import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProgress: [UserProgress]
    @Query private var words: [Word]
    @Query private var sessions: [StudySession]
    
    @State private var todayStudiedWords = 0
    @State private var currentStreak = 0
    @State private var totalLearned = 0
    @State private var showVocabularySelection = false
    @State private var selectedVocabularyCategory: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 用户欢迎信息
                    headerSection
                    
                    // 今日学习统计
                    todayStatsSection
                    
                    // 快速学习按钮
                    quickActionsSection
                    
                    // 今日推荐单词
                    recommendedWordsSection
                    
                    // 学习建议
                    studyTipsSection
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("主页")
            .onAppear {
                loadUserStats()
                loadSelectedVocabulary()
            }
            .sheet(isPresented: $showVocabularySelection) {
                VocabularySelectionView()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("早上好，小明！")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("今天要继续学习单词哦 💪")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 头像
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text("小明")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
            }
            
            // 词汇选择按钮
            Button(action: { showVocabularySelection = true }) {
                HStack {
                    Image(systemName: "books.vertical.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("当前词汇库")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(getVocabularyCategoryName())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var todayStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("今日学习")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 12) {
                // 已学单词
                StatCard(
                    icon: "book.fill",
                    title: "已学单词",
                    value: "\(todayStudiedWords)",
                    color: .blue
                )
                
                // 连续天数
                StatCard(
                    icon: "flame.fill",
                    title: "连续天数",
                    value: "\(currentStreak)",
                    color: .orange
                )
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("快速学习")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 12) {
                NavigationLink(destination: WordLearningView()) {
                    ActionButton(
                        icon: "book.fill",
                        title: "开始学习",
                        subtitle: "学习新单词",
                        color: .green
                    )
                }
                
                NavigationLink(destination: QuizModeView()) {
                    ActionButton(
                        icon: "questionmark.circle.fill",
                        title: "智能测试",
                        subtitle: "检验学习成果",
                        color: .purple
                    )
                }
            }
            
            NavigationLink(destination: WordCollectionsView()) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("今日测试")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private var recommendedWordsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("AI推荐")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Text("基于今日的学习进度智能推荐以下各")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(words.prefix(3)), id: \.english) { word in
                        RecommendedWordCard(word: word)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            NavigationLink(destination: WordLearningView()) {
                Text("开始学习")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
    }
    
    private var studyTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("学习建议")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• 建议每天学习15-20个新单词")
                Text("• 最好在睡前温习当天学习的单词")
                Text("• 可通过造句练习来巩固记忆")
            }
            .font(.body)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func loadUserStats() {
        if let progress = userProgress.first {
            currentStreak = progress.currentStreak
            totalLearned = progress.totalWordsLearned
        }
        
        // 计算今日学习的单词数
        let today = Calendar.current.startOfDay(for: Date())
        let todaySessions = sessions.filter { session in
            Calendar.current.startOfDay(for: session.date) == today
        }
        todayStudiedWords = todaySessions.reduce(0) { $0 + $1.wordsStudied }
    }
    
    private func loadSelectedVocabulary() {
        selectedVocabularyCategory = UserDefaults.standard.string(forKey: "selectedVocabularyCategory")
    }
    
    private func getVocabularyCategoryName() -> String {
        guard let categoryString = selectedVocabularyCategory,
              let category = VocabularyCategory(rawValue: categoryString) else {
            return "默认词汇库"
        }
        return category.displayName
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendedWordCard: View {
    let word: Word
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(word.english)
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("\(word.difficulty)⭐")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Text(word.chinese)
                .font(.body)
                .foregroundColor(.secondary)
            
            Text(word.partOfSpeech)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(4)
        }
        .padding()
        .frame(width: 200)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Word.self, UserProgress.self, StudySession.self], inMemory: true)
} 
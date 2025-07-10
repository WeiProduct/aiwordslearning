import SwiftUI
import SwiftData

struct VocabularySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var extendedWordManager = ExtendedWordDataManager()
    @EnvironmentObject var wordDataManager: WordDataManager
    
    @State private var selectedCategory: VocabularyCategory?
    @State private var showLoadingAlert = false
    @State private var currentLanguage = UserSettings.appLanguage
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 头部说明
                    VStack(spacing: 8) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text(currentLanguage == .chinese ? "选择词汇库" : "Choose Vocabulary")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(currentLanguage == .chinese ? 
                            "选择适合您的词汇分类开始学习" : 
                            "Select a vocabulary category to start learning")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // 词汇分组
                    ForEach(VocabularyGroup.allCases, id: \.self) { group in
                        VocabularyGroupSection(
                            group: group,
                            selectedCategory: $selectedCategory,
                            availableCategories: extendedWordManager.availableCategories,
                            language: currentLanguage
                        )
                    }
                }
                .padding()
            }
            .navigationTitle(currentLanguage == .chinese ? "词汇选择" : "Vocabulary Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(currentLanguage == .chinese ? "取消" : "Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(currentLanguage == .chinese ? "确认" : "Confirm") {
                        loadSelectedVocabulary()
                    }
                    .disabled(selectedCategory == nil)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            extendedWordManager.setModelContext(modelContext)
        }
        .alert(
            currentLanguage == .chinese ? "正在加载词汇" : "Loading Vocabulary",
            isPresented: $showLoadingAlert
        ) {
            if extendedWordManager.isLoading {
                ProgressView()
            } else {
                Button(currentLanguage == .chinese ? "确定" : "OK") {
                    if extendedWordManager.errorMessage == nil {
                        dismiss()
                    }
                }
            }
        } message: {
            if extendedWordManager.isLoading {
                VStack {
                    Text(currentLanguage == .chinese ? 
                        "正在加载 \(selectedCategory?.displayName ?? "")..." : 
                        "Loading \(selectedCategory?.englishDisplayName ?? "")...")
                    
                    ProgressView(value: extendedWordManager.loadingProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                }
            } else if let error = extendedWordManager.errorMessage {
                Text(error)
            } else {
                Text(currentLanguage == .chinese ? "加载完成！" : "Loading completed!")
            }
        }
    }
    
    private func loadSelectedVocabulary() {
        guard let category = selectedCategory else { return }
        
        showLoadingAlert = true
        
        Task {
            await extendedWordManager.loadVocabularyForCategory(category)
            
            if extendedWordManager.errorMessage == nil {
                // 更新用户设置
                UserDefaults.standard.set(category.rawValue, forKey: "selectedVocabularyCategory")
                
                // 刷新主词汇管理器
                await MainActor.run {
                    wordDataManager.clearCache()
                }
            }
        }
    }
}

// MARK: - 词汇分组视图
struct VocabularyGroupSection: View {
    let group: VocabularyGroup
    @Binding var selectedCategory: VocabularyCategory?
    let availableCategories: [VocabularyCategory]
    let language: UserSettings.AppLanguage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 分组标题
            HStack {
                Image(systemName: groupIcon)
                    .foregroundColor(.blue)
                
                Text(language == .chinese ? group.displayName : group.englishDisplayName)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 4)
            
            // 分类卡片
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(group.categories, id: \.self) { category in
                    VocabularyCategoryCard(
                        category: category,
                        isSelected: selectedCategory == category,
                        isAvailable: availableCategories.contains(category),
                        language: language
                    ) {
                        if availableCategories.contains(category) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var groupIcon: String {
        switch group {
        case .international: return "globe.americas"
        case .domestic: return "graduationcap"
        case .textbook: return "book"
        }
    }
}

// MARK: - 词汇分类卡片
struct VocabularyCategoryCard: View {
    let category: VocabularyCategory
    let isSelected: Bool
    let isAvailable: Bool
    let language: UserSettings.AppLanguage
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // 图标
                Image(systemName: category.icon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .white : (isAvailable ? .blue : .gray))
                
                // 标题
                Text(language == .chinese ? category.displayName : category.englishDisplayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : (isAvailable ? .primary : .gray))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // 词汇数量
                Text("\(category.wordCount) " + (language == .chinese ? "词" : "words"))
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                
                // 难度指示器
                DifficultyIndicator(level: category.difficulty)
                    .frame(height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : (isAvailable ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .disabled(!isAvailable)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - 难度指示器
struct DifficultyIndicator: View {
    let level: Int
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(1...6, id: \.self) { index in
                    Rectangle()
                        .fill(index <= level ? difficultyColor : Color.gray.opacity(0.2))
                        .frame(width: (geometry.size.width - 10) / 6)
                }
            }
        }
    }
    
    private var difficultyColor: Color {
        switch level {
        case 1...2: return .green
        case 3...4: return .orange
        case 5...6: return .red
        default: return .gray
        }
    }
}

// MARK: - 词汇统计视图
struct VocabularyStatisticsView: View {
    let category: VocabularyCategory
    let statistics: (total: Int, learned: Int, mastered: Int)
    let language: UserSettings.AppLanguage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(language == .chinese ? "学习进度" : "Learning Progress")
                .font(.headline)
            
            VStack(spacing: 12) {
                StatRow(
                    title: language == .chinese ? "总词汇" : "Total Words",
                    value: statistics.total,
                    color: .blue
                )
                
                StatRow(
                    title: language == .chinese ? "已学习" : "Learned",
                    value: statistics.learned,
                    color: .orange
                )
                
                StatRow(
                    title: language == .chinese ? "已掌握" : "Mastered",
                    value: statistics.mastered,
                    color: .green
                )
            }
            
            // 进度条
            ProgressView(value: Double(statistics.mastered), total: Double(statistics.total))
                .tint(.green)
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatRow: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack {
            Label(title, systemImage: "circle.fill")
                .foregroundColor(color)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(value)")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    VocabularySelectionView()
        .environmentObject(WordDataManager())
}
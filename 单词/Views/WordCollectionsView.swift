import SwiftUI
import SwiftData

struct WordCollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var words: [Word]
    
    @State private var selectedCategory = CollectionCategory.favorites
    @State private var searchText = ""
    @State private var showingWordDetail = false
    @State private var selectedWord: Word?
    
    enum CollectionCategory: String, CaseIterable {
        case favorites = "收藏夹"
        case learned = "已掌握"
        case difficult = "困难本"
        case all = "全部"
        
        var icon: String {
            switch self {
            case .favorites: return "heart.fill"
            case .learned: return "checkmark.circle.fill"
            case .difficult: return "exclamationmark.triangle.fill"
            case .all: return "list.bullet"
            }
        }
        
        var color: Color {
            switch self {
            case .favorites: return .red
            case .learned: return .green
            case .difficult: return .orange
            case .all: return .blue
            }
        }
    }
    
    var filteredWords: [Word] {
        var baseWords: [Word]
        
        switch selectedCategory {
        case .favorites:
            baseWords = words.filter { $0.isFavorited }
        case .learned:
            baseWords = words.filter { $0.isLearned }
        case .difficult:
            baseWords = words.filter { $0.learningCount > 0 && $0.accuracy < 0.5 }
        case .all:
            baseWords = words
        }
        
        if searchText.isEmpty {
            return baseWords
        } else {
            return baseWords.filter { word in
                word.english.localizedCaseInsensitiveContains(searchText) ||
                word.chinese.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 分类选择器
                categorySelector
                
                // 搜索栏
                searchBar
                
                // 统计信息
                statsSection
                
                // 单词列表
                wordsList
            }
            .navigationTitle("单词收藏")
            .sheet(isPresented: $showingWordDetail) {
                if let word = selectedWord {
                    WordDetailView(word: word)
                }
            }
        }
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CollectionCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        count: getCategoryCount(category)
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索单词...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button("清除") {
                    searchText = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
    
    private var statsSection: some View {
        HStack {
            Text("共找到 \(filteredWords.count) 个单词")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if selectedCategory == .favorites {
                Button("全部取消收藏") {
                    unfavoriteAll()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var wordsList: some View {
        List {
            ForEach(filteredWords, id: \.english) { word in
                WordRowView(word: word) {
                    selectedWord = word
                    showingWordDetail = true
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            // 刷新数据
        }
    }
    
    private func getCategoryCount(_ category: CollectionCategory) -> Int {
        switch category {
        case .favorites:
            return words.filter { $0.isFavorited }.count
        case .learned:
            return words.filter { $0.isLearned }.count
        case .difficult:
            return words.filter { $0.learningCount > 0 && $0.accuracy < 0.5 }.count
        case .all:
            return words.count
        }
    }
    
    private func unfavoriteAll() {
        for word in words where word.isFavorited {
            word.isFavorited = false
        }
        try? modelContext.save()
    }
}

struct CategoryButton: View {
    let category: WordCollectionsView.CollectionCategory
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.caption)
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("(\(count))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? category.color.opacity(0.2) : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? category.color : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? category.color : .clear, lineWidth: 1)
            )
        }
    }
}

struct WordRowView: View {
    let word: Word
    let action: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(word.english)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(word.chinese)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        if !word.partOfSpeech.isEmpty {
                            Text(word.partOfSpeech)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        // 收藏按钮
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                word.isFavorited.toggle()
                            }
                            try? modelContext.save()
                        }) {
                            Image(systemName: word.isFavorited ? "heart.fill" : "heart")
                                .font(.title3)
                                .foregroundColor(word.isFavorited ? .red : .gray)
                        }
                        
                        // 学习状态
                        if word.isLearned {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        // 难度星级
                        HStack(spacing: 2) {
                            ForEach(0..<word.difficulty, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                // 学习统计
                if word.learningCount > 0 {
                    HStack {
                        StatChip(
                            icon: "repeat",
                            value: "\(word.learningCount)",
                            label: "次"
                        )
                        
                        StatChip(
                            icon: "target",
                            value: String(format: "%.0f%%", word.accuracy * 100),
                            label: "正确率"
                        )
                        
                        if let lastStudy = word.lastStudyDate {
                            StatChip(
                                icon: "clock",
                                value: formatRelativeDate(lastStudy),
                                label: ""
                            )
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct StatChip: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
            if !label.isEmpty {
                Text(label)
                    .font(.caption2)
            }
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}

struct WordDetailView: View {
    let word: Word
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 单词卡片
                    WordDetailCard(word: word)
                    
                    // 学习统计
                    WordStatsSection(word: word)
                    
                    // 例句部分
                    if !word.example.isEmpty {
                        ExampleSection(word: word)
                    }
                    
                    // 操作按钮
                    WordActionsSection(word: word)
                }
                .padding()
            }
            .navigationTitle("单词详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WordDetailCard: View {
    let word: Word
    
    var body: some View {
        VStack(spacing: 16) {
            Text(word.english)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if !word.pronunciation.isEmpty {
                Text(word.pronunciation)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            if !word.partOfSpeech.isEmpty {
                Text(word.partOfSpeech)
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            Divider()
            
            Text(word.chinese)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct WordStatsSection: View {
    let word: Word
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("学习统计")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 12) {
                StatCard(
                    icon: "repeat",
                    title: "学习次数",
                    value: "\(word.learningCount)",
                    color: .blue
                )
                
                StatCard(
                    icon: "target",
                    title: "正确率",
                    value: String(format: "%.0f%%", word.accuracy * 100),
                    color: .green
                )
                
                StatCard(
                    icon: "star.fill",
                    title: "难度等级",
                    value: "\(word.difficulty)",
                    color: .orange
                )
            }
        }
    }
}

struct ExampleSection: View {
    let word: Word
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("例句")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                Text(word.example)
                    .font(.body)
                    .italic()
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if !word.exampleTranslation.isEmpty {
                    Text(word.exampleTranslation)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct WordActionsSection: View {
    let word: Word
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                word.isFavorited.toggle()
                try? modelContext.save()
            }) {
                HStack {
                    Image(systemName: word.isFavorited ? "heart.fill" : "heart")
                    Text(word.isFavorited ? "取消收藏" : "添加收藏")
                }
                .font(.headline)
                .foregroundColor(word.isFavorited ? .red : .blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Button(action: {
                word.isLearned.toggle()
                try? modelContext.save()
            }) {
                HStack {
                    Image(systemName: word.isLearned ? "checkmark.circle.fill" : "circle")
                    Text(word.isLearned ? "标记为未掌握" : "标记为已掌握")
                }
                .font(.headline)
                .foregroundColor(word.isLearned ? .green : .blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    WordCollectionsView()
        .modelContainer(for: [Word.self], inMemory: true)
} 
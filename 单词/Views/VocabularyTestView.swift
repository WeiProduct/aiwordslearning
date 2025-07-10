import SwiftUI

struct VocabularyTestView: View {
    @StateObject private var extendedWordManager = ExtendedWordDataManager()
    @State private var selectedCategory: VocabularyCategory = .ielts
    @State private var loadedWords: [Word] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                // 分类选择
                Picker("选择词汇分类", selection: $selectedCategory) {
                    ForEach(extendedWordManager.availableCategories, id: \.self) { category in
                        Text(category.displayName)
                            .tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                
                // 加载按钮
                Button(action: loadVocabulary) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("加载词汇")
                    }
                }
                .padding()
                .disabled(isLoading)
                
                // 错误信息
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // 加载进度
                if isLoading {
                    ProgressView(value: extendedWordManager.loadingProgress)
                        .padding()
                }
                
                // 词汇列表
                List(loadedWords.prefix(10), id: \.english) { word in
                    VStack(alignment: .leading) {
                        Text(word.english)
                            .font(.headline)
                        Text(word.chinese)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("词汇测试")
            .onAppear {
                extendedWordManager.checkAvailableCategories()
            }
        }
    }
    
    private func loadVocabulary() {
        isLoading = true
        errorMessage = nil
        
        Task {
            // 使用模拟数据加载
            let mockProvider = MockVocabularyDataProvider.shared
            let mockWords = mockProvider.getMockWords(for: selectedCategory)
            
            await MainActor.run {
                self.loadedWords = mockWords.map { jsonWord in
                    Word(
                        english: jsonWord.word,
                        chinese: jsonWord.translations.first?.translation ?? "",
                        pronunciation: "/\(jsonWord.word)/",
                        partOfSpeech: jsonWord.translations.first?.type ?? "n",
                        example: jsonWord.phrases.first?.phrase ?? "",
                        exampleTranslation: jsonWord.phrases.first?.translation ?? "",
                        difficulty: selectedCategory.difficulty
                    )
                }
                self.isLoading = false
            }
        }
    }
}

#Preview {
    VocabularyTestView()
}
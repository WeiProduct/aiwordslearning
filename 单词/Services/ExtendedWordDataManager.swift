import Foundation
import SwiftData

@MainActor
final class ExtendedWordDataManager: ObservableObject {
    @Published var selectedCategory: VocabularyCategory = .ielts
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var availableCategories: [VocabularyCategory] = []
    
    private let jsonBasePath = "/Users/weifu/Downloads/english-vocabulary-master/json_original/json-simple"
    private var modelContext: ModelContext?
    private let logger = AppLogger.shared
    
    // 缓存已加载的词汇数据
    private var categoryCache: [VocabularyCategory: [Word]] = [:]
    
    init() {
        checkAvailableCategories()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - 检查可用的词汇分类
    private func checkAvailableCategories() {
        availableCategories = []
        
        for category in VocabularyCategory.allCases {
            let files = getFilesForCategory(category)
            if !files.isEmpty {
                // 检查文件是否存在
                let fileExists = files.contains { file in
                    FileManager.default.fileExists(atPath: "\(jsonBasePath)/\(file)")
                }
                if fileExists {
                    availableCategories.append(category)
                }
            }
        }
        
        logger.log(.info, category: .database, message: "Found \(availableCategories.count) available vocabulary categories")
    }
    
    // MARK: - 获取分类对应的文件列表
    private func getFilesForCategory(_ category: VocabularyCategory) -> [String] {
        var files: [String] = []
        
        // 根据不同的分类返回相应的文件列表
        switch category {
        case .ielts:
            files = ["IELTS_2.json", "IELTS_3.json", "IELTSluan_2.json"]
        case .toefl:
            files = ["TOEFL_2.json", "TOEFL_3.json"]
        case .gre:
            files = ["GRE_2.json", "GRE_3.json"]
        case .gmat:
            files = ["GMAT_2.json", "GMAT_3.json", "GMATluan_2.json"]
        case .sat:
            files = ["SAT_2.json", "SAT_3.json"]
        case .bec:
            files = ["BEC_2.json", "BEC_3.json"]
        case .cet4:
            files = ["CET4_1.json", "CET4_2.json", "CET4_3.json", "CET4luan_1.json", "CET4luan_2.json"]
        case .cet6:
            files = ["CET6_1.json", "CET6_2.json", "CET6_3.json", "CET6luan_1.json"]
        case .tem4:
            files = ["Level4_1.json", "Level4_2.json", "Level4luan_1.json", "Level4luan_2.json"]
        case .tem8:
            files = ["Level8_1.json", "Level8_2.json", "Level8luan_2.json"]
        case .kaoyan:
            files = ["KaoYan_1.json", "KaoYan_2.json", "KaoYan_3.json", "KaoYanluan_1.json"]
        case .pepPrimary:
            files = ["PEPXiaoXue3_1.json", "PEPXiaoXue3_2.json", "PEPXiaoXue4_1.json", "PEPXiaoXue4_2.json", 
                    "PEPXiaoXue5_1.json", "PEPXiaoXue5_2.json", "PEPXiaoXue6_1.json", "PEPXiaoXue6_2.json"]
        case .pepJunior:
            files = ["PEPChuZhong7_1.json", "PEPChuZhong7_2.json", "PEPChuZhong8_1.json", 
                    "PEPChuZhong8_2.json", "PEPChuZhong9_1.json"]
        case .pepSenior:
            files = (1...11).map { "PEPGaoZhong_\($0).json" }
        case .beijingSenior:
            files = (1...11).map { "BeiShiGaoZhong_\($0).json" }
        case .fltrpJunior:
            files = (1...6).map { "WaiYanSheChuZhong_\($0).json" }
        case .generalJunior:
            files = ["ChuZhong_2.json", "ChuZhong_3.json", "ChuZhongluan_2.json"]
        case .generalSenior:
            files = ["GaoZhong_2.json", "GaoZhong_3.json", "GaoZhongluan_2.json"]
        }
        
        return files
    }
    
    // MARK: - 加载词汇数据
    func loadVocabularyForCategory(_ category: VocabularyCategory) async {
        // 检查缓存
        if let cachedWords = categoryCache[category], !cachedWords.isEmpty {
            logger.log(.info, category: .database, message: "Using cached words for \(category.displayName)")
            return
        }
        
        await MainActor.run {
            isLoading = true
            loadingProgress = 0.0
            errorMessage = nil
        }
        
        do {
            let words = try await loadWordsFromFiles(category: category)
            
            // 保存到数据库
            if let context = modelContext {
                try await saveWordsToDatabase(words, context: context, category: category)
            }
            
            // 缓存数据
            await MainActor.run {
                self.categoryCache[category] = words
                self.isLoading = false
                self.loadingProgress = 1.0
            }
            
            logger.log(.info, category: .database, message: "Successfully loaded \(words.count) words for \(category.displayName)")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "加载词汇失败: \(error.localizedDescription)"
                self.isLoading = false
            }
            logger.error("Failed to load vocabulary: \(error)", category: .database)
        }
    }
    
    // MARK: - 从文件加载词汇
    private func loadWordsFromFiles(category: VocabularyCategory) async throws -> [Word] {
        let files = getFilesForCategory(category)
        var allWords: [Word] = []
        
        for (index, file) in files.enumerated() {
            let filePath = "\(jsonBasePath)/\(file)"
            
            guard FileManager.default.fileExists(atPath: filePath) else {
                logger.warning("File not found: \(file)", category: .database)
                continue
            }
            
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let jsonWords = try JSONDecoder().decode([JSONWord].self, from: data)
            
            // 转换为 Word 模型
            let words = jsonWords.compactMap { jsonWord -> Word? in
                createWord(from: jsonWord, category: category)
            }
            
            allWords.append(contentsOf: words)
            
            // 更新进度
            await MainActor.run {
                self.loadingProgress = Double(index + 1) / Double(files.count)
            }
        }
        
        return allWords
    }
    
    // MARK: - 创建 Word 对象
    private func createWord(from jsonWord: JSONWord, category: VocabularyCategory) -> Word? {
        // 组合所有翻译
        let translations = jsonWord.translations.map { "\($0.type). \($0.translation)" }.joined(separator: "; ")
        
        // 生成音标（简单规则，实际应用中可能需要词典）
        let pronunciation = generatePronunciation(for: jsonWord.word)
        
        // 获取主要词性
        let partOfSpeech = jsonWord.translations.first?.type ?? "n"
        
        // 选择一个例句（从短语中）
        let example = jsonWord.phrases.first?.phrase ?? ""
        let exampleTranslation = jsonWord.phrases.first?.translation ?? ""
        
        // 根据类别设置难度
        let difficulty = calculateDifficulty(word: jsonWord.word, category: category)
        
        let word = Word(
            english: jsonWord.word,
            chinese: translations,
            pronunciation: pronunciation,
            partOfSpeech: partOfSpeech,
            example: example,
            exampleTranslation: exampleTranslation,
            difficulty: difficulty
        )
        
        // 设置词汇来源标签
        word.tags = [category.rawValue]
        
        return word
    }
    
    // MARK: - 生成音标
    private func generatePronunciation(for word: String) -> String {
        // 这是一个简化的音标生成，实际应用中应该使用词典数据
        return "/\(word)/"
    }
    
    // MARK: - 计算难度
    private func calculateDifficulty(word: String, category: VocabularyCategory) -> Int {
        let baseDifficulty = category.difficulty
        let lengthFactor = word.count > 10 ? 1 : 0
        return min(baseDifficulty + lengthFactor, 5)
    }
    
    // MARK: - 保存到数据库
    private func saveWordsToDatabase(_ words: [Word], context: ModelContext, category: VocabularyCategory) async throws {
        // 批量保存以提高性能
        let batchSize = 100
        
        for i in stride(from: 0, to: words.count, by: batchSize) {
            let batch = Array(words[i..<min(i + batchSize, words.count)])
            
            for word in batch {
                // 检查是否已存在
                let wordEnglish = word.english
                let descriptor = FetchDescriptor<Word>(
                    predicate: #Predicate { w in
                        w.english == wordEnglish
                    }
                )
                
                let existingWords = try context.fetch(descriptor)
                
                if existingWords.isEmpty {
                    context.insert(word)
                } else if let existingWord = existingWords.first {
                    // 更新标签
                    if !existingWord.tags.contains(category.rawValue) {
                        existingWord.tags.append(category.rawValue)
                    }
                }
            }
            
            // 定期保存
            if i % (batchSize * 5) == 0 {
                try context.save()
            }
        }
        
        // 最终保存
        try context.save()
    }
    
    // MARK: - 获取分类词汇
    func getWordsForCategory(_ category: VocabularyCategory) -> [Word] {
        return categoryCache[category] ?? []
    }
    
    // MARK: - 清理缓存
    func clearCache() {
        categoryCache.removeAll()
    }
    
    // MARK: - 获取分类统计信息
    func getCategoryStatistics(_ category: VocabularyCategory) async -> (total: Int, learned: Int, mastered: Int) {
        guard let context = modelContext else { return (0, 0, 0) }
        
        do {
            let categoryValue = category.rawValue
            let descriptor = FetchDescriptor<Word>(
                predicate: #Predicate { word in
                    word.vocabularyTags.contains(categoryValue)
                }
            )
            
            let words = try context.fetch(descriptor)
            let learned = words.filter { $0.learningCount > 0 }.count
            let mastered = words.filter { $0.isLearned }.count
            
            return (words.count, learned, mastered)
        } catch {
            logger.error("Failed to get category statistics: \(error)", category: .database)
            return (0, 0, 0)
        }
    }
}

// MARK: - Word 扩展
extension Word {
    var tags: [String] {
        get { vocabularyTags }
        set { vocabularyTags = newValue }
    }
}
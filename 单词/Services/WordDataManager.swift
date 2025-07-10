import Foundation
import SwiftData

class WordDataManager: WordDataProviding {
    
    // MARK: - Properties
    private var modelContext: ModelContext?
    private var _cachedWords: [Word] = []
    private var _lastCacheUpdate: Date?
    private let cacheExpiryInterval: TimeInterval = 300 // 5分钟缓存过期
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var totalWordsCount = 0
    @Published var learnedWordsCount = 0
    
    // MARK: - Constants
    private struct Constants {
        static let ieltsFileName = "IELTS"
        static let fileExtension = "txt"
        static let defaultWordsCount = 50
        static let batchSize = 100
    }
    
    // MARK: - Protocol Properties
    var cachedWords: [Word] {
        return _cachedWords
    }
    
    var lastCacheUpdate: Date? {
        return _lastCacheUpdate
    }
    
    // MARK: - Public Methods
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task {
            await loadWordsFromFile()
        }
    }
    
    // MARK: - Protocol Implementation
    func getAllWords() async throws -> [Word] {
        if let cachedWords = getCachedWords() {
            return cachedWords
        }
        
        return await fetchWordsFromDatabase()
    }
    
    func searchWords(query: String) async throws -> [Word] {
        let allWords = try await getAllWords()
        let lowercasedQuery = query.lowercased()
        
        return allWords.filter { word in
            word.english.lowercased().contains(lowercasedQuery) ||
            word.chinese.lowercased().contains(lowercasedQuery) ||
            word.partOfSpeech.lowercased().contains(lowercasedQuery)
        }
    }
    
    func getWordsByDifficulty(_ difficulty: WordDifficulty) async throws -> [Word] {
        let allWords = try await getAllWords()
        return allWords.filter { $0.difficulty == difficulty.rawValue }
    }
    
    func getRandomWords(count: Int) async throws -> [Word] {
        let allWords = try await getAllWords()
        return Array(allWords.shuffled().prefix(count))
    }
    
    func updateWordProgress(_ word: Word, isCorrect: Bool) async throws {
        word.learningCount += 1
        word.lastStudyDate = Date()
        
        if isCorrect {
            word.correctCount += 1
        }
        
        if word.accuracy >= 0.8 && word.learningCount >= 3 {
            word.isLearned = true
        }
        
        try await saveContext()
    }
    
    func markWordAsLearned(_ word: Word) async throws {
        word.isLearned = true
        word.lastStudyDate = Date()
        try await saveContext()
    }
    
    func getWordsForReview() async throws -> [Word] {
        let allWords = try await getAllWords()
        let today = Date()
        
        return allWords.filter { word in
            word.isLearned &&
            (word.lastStudyDate == nil ||
             Calendar.current.dateComponents([.day], from: word.lastStudyDate!, to: today).day! >= 1)
        }
    }
    
    func importWordsFromFile(fileName: String) async throws {
        await loadFromCustomFile(fileName: fileName)
    }
    
    func clearCache() {
        invalidateCache()
    }
    
    // MARK: - Legacy Methods (keep for backward compatibility)
    func getLearnedWords() async -> [Word] {
        do {
            let allWords = try await getAllWords()
            return allWords.filter { $0.isLearned }
        } catch {
            return []
        }
    }
    
    func getUnlearnedWords() async -> [Word] {
        do {
            let allWords = try await getAllWords()
            return allWords.filter { !$0.isLearned }
        } catch {
            return []
        }
    }
    
    func getFavoritedWords() async -> [Word] {
        do {
            let allWords = try await getAllWords()
            return allWords.filter { $0.isFavorited }
        } catch {
            return []
        }
    }
    
    func getDifficultWords() async -> [Word] {
        do {
            let allWords = try await getAllWords()
            return allWords.filter { $0.difficulty >= 4 && $0.learningCount > 0 && $0.accuracy < 0.5 }
        } catch {
            return []
        }
    }
    

    
    // MARK: - Statistics Methods
    func updateStatistics() async {
        do {
            let allWords = try await getAllWords()
            await MainActor.run {
                self.totalWordsCount = allWords.count
                self.learnedWordsCount = allWords.filter { $0.isLearned }.count
            }
        } catch {
            await MainActor.run {
                self.totalWordsCount = 0
                self.learnedWordsCount = 0
            }
        }
    }
    
    // MARK: - Data Management Methods
    func refreshData() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        invalidateCache()
        await loadWordsFromFile()
        await updateStatistics()
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    func clearAllData() async {
        guard let context = modelContext else { return }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            try context.delete(model: Word.self)
            try context.delete(model: StudySession.self)
            try context.delete(model: UserProgress.self)
            try context.save()
            
            invalidateCache()
            await loadWordsFromFile()
            await initializeUserProgress()
            
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "清除数据失败: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadWordsFromFile() async {
        guard let context = modelContext else { return }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // 检查是否已有数据
            let descriptor = FetchDescriptor<Word>()
            let existingWords = try context.fetch(descriptor)
            
            if !existingWords.isEmpty {
                _cachedWords = existingWords
                _lastCacheUpdate = Date()
                await updateStatistics()
                await MainActor.run {
                    self.isLoading = false
                }
                print("使用现有词汇数据：\(existingWords.count) 个单词")
                return
            }
            
            // 从文件加载词汇
            await loadFromIELTSFile(context: context)
            
        } catch {
            await MainActor.run {
                self.errorMessage = "加载词汇失败: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("加载词汇失败: \(error)")
        }
    }
    
    private func loadFromIELTSFile(context: ModelContext) async {
        guard let path = Bundle.main.path(forResource: Constants.ieltsFileName, ofType: Constants.fileExtension),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("无法读取IELTS.txt文件，使用默认词汇")
            await initializeDefaultWords(context: context)
            return
        }
        
        await parseWordsFromContent(content, context: context)
    }
    
    private func parseWordsFromContent(_ content: String, context: ModelContext) async {
        let lines = content.components(separatedBy: .newlines)
        var parsedWords: [Word] = []
        var processedCount = 0
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !trimmedLine.isEmpty else { continue }
            
            if let word = parseWordFromLine(trimmedLine, index: index) {
                parsedWords.append(word)
                processedCount += 1
                
                // 批量处理以提高性能
                if processedCount % Constants.batchSize == 0 {
                    await insertWordsInBatch(parsedWords, context: context)
                    parsedWords.removeAll()
                }
            }
        }
        
        // 处理剩余的单词
        if !parsedWords.isEmpty {
            await insertWordsInBatch(parsedWords, context: context)
        }
        
        await finalizeWordLoading(context: context, totalProcessed: processedCount)
    }
    
    private func parseWordFromLine(_ line: String, index: Int) -> Word? {
        let components = line.components(separatedBy: "\t")
        
        guard components.count >= 2 else {
            print("警告：第\(index + 1)行格式不正确：\(line)")
            return nil
        }
        
        let english = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let definitionAndChinese = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 解析定义和中文释义
        let (definition, chinese) = parseDefinitionAndChinese(definitionAndChinese)
        
        guard !english.isEmpty && !chinese.isEmpty else {
            print("警告：第\(index + 1)行单词或释义为空")
            return nil
        }
        
        return createWordObject(
            english: english,
            definition: definition,
            chinese: chinese,
            index: index
        )
    }
    
    private func parseDefinitionAndChinese(_ text: String) -> (definition: String, chinese: String) {
        if let colonIndex = text.firstIndex(of: ":") {
            let definition = String(text[..<colonIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            let chinese = String(text[text.index(after: colonIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return (definition, chinese)
        } else {
            return ("", text)
        }
    }
    
    private func createWordObject(english: String, definition: String, chinese: String, index: Int) -> Word {
        let word = Word(
            english: english,
            chinese: chinese,
            pronunciation: generatePronunciation(for: english),
            partOfSpeech: extractPartOfSpeech(from: definition),
            example: generateExample(for: english),
            exampleTranslation: generateExampleTranslation(for: generateExample(for: english)),
            difficulty: determineDifficulty(for: english, index: index)
        )
        
        return word
    }
    
    private func insertWordsInBatch(_ words: [Word], context: ModelContext) async {
        for word in words {
            context.insert(word)
        }
        
        do {
            try context.save()
            await MainActor.run {
                self._cachedWords.append(contentsOf: words)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "保存单词失败: \(error.localizedDescription)"
            }
            print("批量保存失败: \(error)")
        }
    }
    
    private func finalizeWordLoading(context: ModelContext, totalProcessed: Int) async {
        if totalProcessed == 0 {
            print("未能解析任何词汇，使用默认词汇")
            await initializeDefaultWords(context: context)
        } else {
            print("成功加载 \(totalProcessed) 个词汇")
            _lastCacheUpdate = Date()
            await updateStatistics()
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    private func fetchWordsFromDatabase() async -> [Word] {
        guard let context = modelContext else { return [] }
        
        do {
            let descriptor = FetchDescriptor<Word>()
            let words = try context.fetch(descriptor)
            await MainActor.run {
                self._cachedWords = words
                self._lastCacheUpdate = Date()
            }
            return words
        } catch {
            await MainActor.run {
                self.errorMessage = "获取单词失败: \(error.localizedDescription)"
            }
            return []
        }
    }
    
    private func getCachedWords() -> [Word]? {
        guard !_cachedWords.isEmpty,
              let lastUpdate = _lastCacheUpdate,
              Date().timeIntervalSince(lastUpdate) < cacheExpiryInterval else {
            return nil
        }
        return _cachedWords
    }
    
    private func invalidateCache() {
        _cachedWords.removeAll()
        _lastCacheUpdate = nil
    }
    
    private func saveContext() async throws {
        guard let context = modelContext else { 
            throw AppError.dataError("模型上下文未初始化")
        }
        try context.save()
    }
    
    private func loadFromCustomFile(fileName: String) async {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "txt"),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("无法读取自定义文件：\(fileName)")
            return
        }
        
        guard let context = modelContext else { return }
        await parseWordsFromContent(content, context: context)
    }
    
    // MARK: - Helper Methods
    private func generatePronunciation(for word: String) -> String {
        // 简单的音标生成逻辑
        return "/\(word.lowercased())/"
    }
    
    private func extractPartOfSpeech(from definition: String) -> String {
        let commonPatterns = [
            ("to ", "v."),
            ("a ", "adj."),
            ("an ", "adj."),
            ("very ", "adv."),
            ("quickly", "adv."),
            ("person", "n."),
            ("thing", "n."),
            ("place", "n.")
        ]
        
        for (pattern, pos) in commonPatterns {
            if definition.lowercased().contains(pattern) {
                return pos
            }
        }
        
        return "n." // 默认为名词
    }
    
    private func generateExample(for word: String) -> String {
        return "This is an example sentence with \(word.lowercased())."
    }
    
    private func generateExampleTranslation(for example: String) -> String {
        return "这是一个包含该单词的例句。"
    }
    
    private func determineDifficulty(for word: String, index: Int) -> Int {
        let length = word.count
        let position = index % 3
        
        if length <= 4 || position == 0 {
            return 1 // easy
        } else if length <= 7 || position == 1 {
            return 2 // medium
        } else {
            return 3 // hard
        }
    }
    
    private func initializeDefaultWords(context: ModelContext) async {
        let defaultWords = createDefaultWords()
        
        for word in defaultWords {
            context.insert(word)
        }
        
        do {
            try context.save()
            await MainActor.run {
                self._cachedWords = defaultWords
                self._lastCacheUpdate = Date()
            }
            await updateStatistics()
            print("默认词汇初始化完成：\(defaultWords.count) 个单词")
        } catch {
            await MainActor.run {
                self.errorMessage = "初始化默认词汇失败: \(error.localizedDescription)"
            }
        }
    }
    
    private func initializeUserProgress() async {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<UserProgress>()
        let existingProgress = try? context.fetch(descriptor)
        
        if existingProgress?.isEmpty ?? true {
            let progress = UserProgress()
            context.insert(progress)
            try? context.save()
        }
    }
    
    private func createDefaultWords() -> [Word] {
        let defaultWordsData = [
            ("beautiful", "having beauty; pleasing to look at", "美丽的"),
            ("adventure", "an exciting or dangerous experience", "冒险"),
            ("challenge", "something difficult that requires effort", "挑战"),
            ("knowledge", "information and understanding", "知识"),
            ("opportunity", "a chance to do something", "机会")
        ]
        
        return defaultWordsData.enumerated().map { index, data in
            Word(
                english: data.0,
                chinese: data.2,
                pronunciation: generatePronunciation(for: data.0),
                partOfSpeech: extractPartOfSpeech(from: data.1),
                example: generateExample(for: data.0),
                exampleTranslation: generateExampleTranslation(for: generateExample(for: data.0)),
                difficulty: determineDifficulty(for: data.0, index: index)
            )
        }
    }
} 
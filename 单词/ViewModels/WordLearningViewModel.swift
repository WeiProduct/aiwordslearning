import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
class WordLearningViewModel: @unchecked Sendable {
    
    // MARK: - Properties
    private var modelContext: ModelContext?
    var speechManager: SpeechManager
    
    // MARK: - Published State
    var currentWordIndex = 0
    var showMeaning = false
    var studiedWords: Set<String> = []
    var sessionStartTime = Date()
    var wordsToStudy: [Word] = []
    var showCompletionSheet = false
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Computed Properties
    var currentWord: Word? {
        guard !wordsToStudy.isEmpty && currentWordIndex < wordsToStudy.count else {
            return nil
        }
        return wordsToStudy[currentWordIndex]
    }
    
    var progress: Double {
        guard !wordsToStudy.isEmpty else { return 0 }
        return Double(currentWordIndex) / Double(wordsToStudy.count)
    }
    
    var hasValidSession: Bool {
        !wordsToStudy.isEmpty && currentWordIndex < wordsToStudy.count
    }
    
    var sessionStats: SessionStats {
        SessionStats(
            wordsStudied: studiedWords.count,
            totalWords: wordsToStudy.count,
            currentIndex: currentWordIndex,
            accuracy: calculateAccuracy(),
            timeSpent: Date().timeIntervalSince(sessionStartTime)
        )
    }
    
    // MARK: - Initialization
    init(speechManager: SpeechManager) {
        self.speechManager = speechManager
    }
    
    // MARK: - Public Methods
    func configure(modelContext: ModelContext, words: [Word]) {
        self.modelContext = modelContext
        setupLearningSession(with: words)
    }
    
    func setupLearningSession(with words: [Word]) {
        isLoading = true
        
        Task { @MainActor in
            do {
                let sessionWords = try await prepareSessionWords(from: words)
                self.wordsToStudy = sessionWords
                self.resetSessionState()
                
                // 自动播放第一个单词
                if let firstWord = sessionWords.first {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.speechManager.speakWord(firstWord.english)
                    }
                }
                
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func showWordMeaning() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showMeaning = true
        }
    }
    
    func markWordAsStudied(known: Bool) {
        guard let word = currentWord else { return }
        
        // 更新单词统计
        updateWordStatistics(word: word, known: known)
        
        // 记录学习状态
        studiedWords.insert(word.english)
        
        // 保存到数据库
        saveContext()
        
        // 移动到下一个单词或完成会话
        moveToNextWordOrComplete()
    }
    
    func playCurrentWordAudio() {
        guard let word = currentWord else { return }
        speechManager.speakWord(word.english)
    }
    
    func resetSession() {
        speechManager.stopSpeaking()
        guard let context = modelContext else { return }
        
        Task { @MainActor in
            let descriptor = FetchDescriptor<Word>()
            let words = try? context.fetch(descriptor)
            setupLearningSession(with: words ?? [])
        }
        
        showCompletionSheet = false
    }
    
    func handleWordIndexChange() {
        if let word = currentWord {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.speechManager.speakWord(word.english)
            }
        }
    }
    
    // MARK: - Private Methods
    private func prepareSessionWords(from words: [Word]) async throws -> [Word] {
        // 获取未学习的单词
        let unlearnedWords = words.filter { !$0.isLearned }
        
        // 获取需要复习的单词（已学但需要复习）
        let reviewWords = words.filter { word in
            word.isLearned &&
            (word.lastStudyDate == nil ||
             Calendar.current.dateComponents([.day], from: word.lastStudyDate!, to: Date()).day! >= 1)
        }
        
        // 智能分配学习单词数量
        let targetNewWords = min(15, unlearnedWords.count)
        let targetReviewWords = min(5, reviewWords.count)
        
        var sessionWords: [Word] = []
        sessionWords.append(contentsOf: Array(unlearnedWords.shuffled().prefix(targetNewWords)))
        sessionWords.append(contentsOf: Array(reviewWords.shuffled().prefix(targetReviewWords)))
        
        return sessionWords.shuffled()
    }
    
    private func resetSessionState() {
        currentWordIndex = 0
        showMeaning = false
        studiedWords.removeAll()
        sessionStartTime = Date()
        errorMessage = nil
    }
    
    private func updateWordStatistics(word: Word, known: Bool) {
        word.learningCount += 1
        if known {
            word.correctCount += 1
        }
        word.lastStudyDate = Date()
        
        // 根据准确率判断是否已掌握
        let accuracy = word.accuracy
        word.isLearned = accuracy >= 0.7 && word.learningCount >= 3
    }
    
    private func moveToNextWordOrComplete() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            if currentWordIndex < wordsToStudy.count - 1 {
                currentWordIndex += 1
                showMeaning = false
            } else {
                completeSession()
            }
        }
    }
    
    private func completeSession() {
        speechManager.stopSpeaking()
        
        guard let context = modelContext else { return }
        
        // 创建学习会话记录
        let session = StudySession(
            date: Date(),
            wordsStudied: studiedWords.count,
            correctAnswers: calculateCorrectAnswers(),
            totalQuestions: studiedWords.count,
            studyTime: Date().timeIntervalSince(sessionStartTime),
            sessionType: "learning"
        )
        context.insert(session)
        
        // 更新用户进度
        updateUserProgress(context: context)
        
        saveContext()
        showCompletionSheet = true
    }
    
    private func updateUserProgress(context: ModelContext) {
        let descriptor = FetchDescriptor<UserProgress>()
        if let progress = try? context.fetch(descriptor).first {
            progress.totalWordsLearned += studiedWords.count
            progress.updateStreak()
        }
    }
    
    private func calculateAccuracy() -> Double {
        guard !studiedWords.isEmpty else { return 0 }
        let correctWords = wordsToStudy.prefix(currentWordIndex).filter { $0.accuracy >= 0.7 }
        return Double(correctWords.count) / Double(studiedWords.count)
    }
    
    private func calculateCorrectAnswers() -> Int {
        return wordsToStudy.prefix(currentWordIndex).filter { $0.accuracy >= 0.7 }.count
    }
    
    private func saveContext() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            errorMessage = "保存数据失败: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Types
struct SessionStats {
    let wordsStudied: Int
    let totalWords: Int
    let currentIndex: Int
    let accuracy: Double
    let timeSpent: TimeInterval
    
    var formattedTime: String {
        let minutes = Int(timeSpent) / 60
        let seconds = Int(timeSpent) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var progressPercentage: Double {
        guard totalWords > 0 else { return 0 }
        return Double(currentIndex) / Double(totalWords)
    }
} 
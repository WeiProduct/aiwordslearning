//
//  LearningSessionManager.swift
//  单词
//
//  Created by Claude on 2025-06-28.
//

import Foundation

@MainActor
class LearningSessionManager: LearningSessionProviding {
    private let wordRepository: WordRepositoryProtocol
    private let sessionRepository: StudySessionRepositoryProtocol
    private let logger: LoggerProtocol
    
    @Published var currentSession: StudySession?
    @Published var isSessionActive: Bool = false
    @Published var sessionProgress: Double = 0.0
    
    private var sessionWords: [Word] = []
    private var currentWordIndex: Int = 0
    private var sessionStartTime: Date?
    private var sessionMode: UserSettings.StudyMode = .adaptive
    
    init(wordRepository: WordRepositoryProtocol, 
         sessionRepository: StudySessionRepositoryProtocol,
         logger: LoggerProtocol) {
        self.wordRepository = wordRepository
        self.sessionRepository = sessionRepository
        self.logger = logger
    }
    
    func startSession(words: [Word], mode: UserSettings.StudyMode) async throws {
        logger.info("开始学习会话，单词数量: \(words.count)，模式: \(mode.displayName)", category: .learning, file: #file, function: #function, line: #line)
        
        guard !words.isEmpty else {
            throw AppError.validationError("学习单词列表不能为空")
        }
        
        try await endSession()
        
        sessionWords = words
        sessionMode = mode
        currentWordIndex = 0
        sessionStartTime = Date()
        
        let session = StudySession(
            wordsStudied: 0,
            correctAnswers: 0,
            totalQuestions: words.count,
            totalWords: words.count,
            startTime: Date()
        )
        
        currentSession = session
        isSessionActive = true
        updateProgress()
        
        try await sessionRepository.save(session)
        
        logger.info("学习会话已启动", category: .learning, file: #file, function: #function, line: #line)
    }
    
    func endSession() async throws {
        guard let session = currentSession else { return }
        
        logger.info("结束学习会话", category: .learning, file: #file, function: #function, line: #line)
        
        session.endTime = Date()
        session.isCompleted = true
        
        try await sessionRepository.update(session)
        
        currentSession = nil
        isSessionActive = false
        sessionProgress = 0.0
        sessionWords.removeAll()
        currentWordIndex = 0
        sessionStartTime = nil
        
        logger.info("学习会话已结束", category: .learning, file: #file, function: #function, line: #line)
    }
    
    func submitAnswer(word: Word, isCorrect: Bool) async throws {
        guard let session = currentSession else {
            throw AppError.dataError("当前没有活跃的学习会话")
        }
        
        logger.debug("提交答案: \(word.english) - \(isCorrect ? "正确" : "错误")", category: .learning, file: #file, function: #function, line: #line)
        
        try await wordRepository.update(word)
        
        session.wordsStudied += 1
        if isCorrect {
            session.correctAnswers += 1
        }
        
        try await sessionRepository.update(session)
        
        currentWordIndex += 1
        updateProgress()
        
        if currentWordIndex >= sessionWords.count {
            try await endSession()
        }
    }
    
    func getSessionStatistics() -> SessionStatistics {
        guard let session = currentSession else {
            return SessionStatistics(
                totalWords: 0,
                correctAnswers: 0,
                incorrectAnswers: 0,
                skippedWords: 0,
                accuracy: 0.0,
                timeSpent: 0,
                wordsPerMinute: 0.0
            )
        }
        
        let incorrectAnswers = session.wordsStudied - session.correctAnswers
        let accuracy = session.wordsStudied > 0 ? Double(session.correctAnswers) / Double(session.wordsStudied) : 0.0
        
        let timeSpent: TimeInterval
        if let startTime = sessionStartTime {
            timeSpent = Date().timeIntervalSince(startTime)
        } else {
            timeSpent = 0
        }
        
        let wordsPerMinute = timeSpent > 0 ? Double(session.wordsStudied) / (timeSpent / 60.0) : 0.0
        
        return SessionStatistics(
            totalWords: session.totalWords,
            correctAnswers: session.correctAnswers,
            incorrectAnswers: incorrectAnswers,
            skippedWords: session.totalWords - session.wordsStudied,
            accuracy: accuracy,
            timeSpent: timeSpent,
            wordsPerMinute: wordsPerMinute
        )
    }
    
    func pauseSession() {
        logger.info("暂停学习会话", category: .learning, file: #file, function: #function, line: #line)
        isSessionActive = false
    }
    
    func resumeSession() {
        logger.info("恢复学习会话", category: .learning, file: #file, function: #function, line: #line)
        isSessionActive = true
    }
    
    func skipCurrentWord() async throws -> Word? {
        guard isSessionActive,
              currentWordIndex < sessionWords.count else {
            return nil
        }
        
        let word = sessionWords[currentWordIndex]
        logger.debug("跳过单词: \(word.english)", category: .learning, file: #file, function: #function, line: #line)
        
        currentWordIndex += 1
        updateProgress()
        
        if currentWordIndex >= sessionWords.count {
            try await endSession()
            return nil
        }
        
        return getCurrentWord()
    }
    
    func getCurrentWord() -> Word? {
        guard currentWordIndex < sessionWords.count else { return nil }
        return sessionWords[currentWordIndex]
    }
    
    private func updateProgress() {
        if sessionWords.isEmpty {
            sessionProgress = 0.0
        } else {
            sessionProgress = Double(currentWordIndex) / Double(sessionWords.count)
        }
    }
}
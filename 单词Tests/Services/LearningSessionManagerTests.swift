//
//  LearningSessionManagerTests.swift
//  单词Tests
//
//  Created by Claude on 2025-06-28.
//

import XCTest
@testable import 单词

@MainActor
final class LearningSessionManagerTests: XCTestCase {
    var learningManager: LearningSessionManager!
    var mockWordRepo: MockWordRepository!
    var mockSessionRepo: MockStudySessionRepository!
    var mockLogger: MockLogger!
    
    override func setUpWithError() throws {
        mockWordRepo = MockWordRepository()
        mockSessionRepo = MockStudySessionRepository()
        mockLogger = MockLogger()
        
        learningManager = LearningSessionManager(
            wordRepository: mockWordRepo,
            sessionRepository: mockSessionRepo,
            logger: mockLogger
        )
    }
    
    override func tearDownWithError() throws {
        learningManager = nil
        mockWordRepo = nil
        mockSessionRepo = nil
        mockLogger = nil
    }
    
    func testStartSession() async throws {
        let testWords = createTestWords(count: 5)
        
        try await learningManager.startSession(words: testWords, mode: .adaptive)
        
        XCTAssertTrue(learningManager.isSessionActive)
        XCTAssertNotNil(learningManager.currentSession)
        XCTAssertEqual(learningManager.currentSession?.totalWords, 5)
        XCTAssertEqual(learningManager.sessionProgress, 0.0)
        XCTAssertTrue(mockLogger.hasLoggedMessage(containing: "开始学习会话"))
    }
    
    func testStartSessionWithEmptyWords() async throws {
        do {
            try await learningManager.startSession(words: [], mode: .adaptive)
            XCTFail("应该抛出验证错误")
        } catch let error as AppError {
            if case .validationError(let message) = error {
                XCTAssertTrue(message.contains("不能为空"))
            } else {
                XCTFail("应该是验证错误")
            }
        }
    }
    
    func testSubmitCorrectAnswer() async throws {
        let testWords = createTestWords(count: 3)
        try await learningManager.startSession(words: testWords, mode: .adaptive)
        
        let firstWord = learningManager.getCurrentWord()
        XCTAssertNotNil(firstWord)
        
        try await learningManager.submitAnswer(word: firstWord!, isCorrect: true)
        
        XCTAssertEqual(learningManager.currentSession?.wordsStudied, 1)
        XCTAssertEqual(learningManager.currentSession?.correctAnswers, 1)
        XCTAssertEqual(learningManager.sessionProgress, 1.0/3.0, accuracy: 0.01)
    }
    
    func testSubmitIncorrectAnswer() async throws {
        let testWords = createTestWords(count: 3)
        try await learningManager.startSession(words: testWords, mode: .adaptive)
        
        let firstWord = learningManager.getCurrentWord()
        try await learningManager.submitAnswer(word: firstWord!, isCorrect: false)
        
        XCTAssertEqual(learningManager.currentSession?.wordsStudied, 1)
        XCTAssertEqual(learningManager.currentSession?.correctAnswers, 0)
    }
    
    func testSessionCompletion() async throws {
        let testWords = createTestWords(count: 2)
        try await learningManager.startSession(words: testWords, mode: .adaptive)
        
        for word in testWords {
            try await learningManager.submitAnswer(word: word, isCorrect: true)
        }
        
        XCTAssertFalse(learningManager.isSessionActive)
        XCTAssertNil(learningManager.currentSession)
        XCTAssertEqual(learningManager.sessionProgress, 0.0)
    }
    
    func testSkipWord() async throws {
        let testWords = createTestWords(count: 3)
        try await learningManager.startSession(words: testWords, mode: .adaptive)
        
        let firstWord = learningManager.getCurrentWord()
        XCTAssertEqual(firstWord?.english, "test0")
        
        let nextWord = try await learningManager.skipCurrentWord()
        XCTAssertEqual(nextWord?.english, "test1")
        XCTAssertEqual(learningManager.sessionProgress, 1.0/3.0, accuracy: 0.01)
    }
    
    func testGetSessionStatistics() async throws {
        let testWords = createTestWords(count: 4)
        try await learningManager.startSession(words: testWords, mode: .adaptive)
        
        try await learningManager.submitAnswer(word: testWords[0], isCorrect: true)
        try await learningManager.submitAnswer(word: testWords[1], isCorrect: false)
        try await learningManager.submitAnswer(word: testWords[2], isCorrect: true)
        
        let stats = learningManager.getSessionStatistics()
        
        XCTAssertEqual(stats.totalWords, 4)
        XCTAssertEqual(stats.correctAnswers, 2)
        XCTAssertEqual(stats.incorrectAnswers, 1)
        XCTAssertEqual(stats.skippedWords, 1)
        XCTAssertEqual(stats.accuracy, 2.0/3.0, accuracy: 0.01)
    }
    
    func testPauseAndResumeSession() async throws {
        let testWords = createTestWords(count: 3)
        try await learningManager.startSession(words: testWords, mode: .adaptive)
        
        XCTAssertTrue(learningManager.isSessionActive)
        
        learningManager.pauseSession()
        XCTAssertFalse(learningManager.isSessionActive)
        XCTAssertTrue(mockLogger.hasLoggedMessage(containing: "暂停学习会话"))
        
        learningManager.resumeSession()
        XCTAssertTrue(learningManager.isSessionActive)
        XCTAssertTrue(mockLogger.hasLoggedMessage(containing: "恢复学习会话"))
    }
    
    func testEndSession() async throws {
        let testWords = createTestWords(count: 3)
        try await learningManager.startSession(words: testWords, mode: .adaptive)
        
        XCTAssertTrue(learningManager.isSessionActive)
        XCTAssertNotNil(learningManager.currentSession)
        
        try await learningManager.endSession()
        
        XCTAssertFalse(learningManager.isSessionActive)
        XCTAssertNil(learningManager.currentSession)
        XCTAssertEqual(learningManager.sessionProgress, 0.0)
        XCTAssertTrue(mockLogger.hasLoggedMessage(containing: "学习会话已结束"))
    }
    
    private func createTestWords(count: Int) -> [Word] {
        return (0..<count).map { i in
            Word(
                english: "test\(i)",
                chinese: "测试\(i)",
                pronunciation: "/test\(i)/",
                partOfSpeech: "n.",
                example: "Example \(i)",
                exampleTranslation: "例句\(i)",
                difficulty: 1
            )
        }
    }
}

class MockStudySessionRepository: StudySessionRepositoryProtocol {
    private var sessions: [StudySession] = []
    var shouldThrowError = false
    var errorToThrow: Error = AppError.databaseError("Mock error")
    
    func findAll() async throws -> [StudySession] {
        if shouldThrowError { throw errorToThrow }
        return sessions
    }
    
    func findById(_ id: String) async throws -> StudySession? {
        if shouldThrowError { throw errorToThrow }
        return sessions.first { $0.id == id }
    }
    
    func findByDateRange(from: Date, to: Date) async throws -> [StudySession] {
        if shouldThrowError { throw errorToThrow }
        return sessions.filter { $0.startTime >= from && $0.startTime <= to }
    }
    
    func findRecentSessions(limit: Int) async throws -> [StudySession] {
        if shouldThrowError { throw errorToThrow }
        return Array(sessions.prefix(limit))
    }
    
    func save(_ session: StudySession) async throws {
        if shouldThrowError { throw errorToThrow }
        sessions.append(session)
    }
    
    func update(_ session: StudySession) async throws {
        if shouldThrowError { throw errorToThrow }
    }
    
    func delete(_ session: StudySession) async throws {
        if shouldThrowError { throw errorToThrow }
        sessions.removeAll { $0.id == session.id }
    }
    
    func deleteAll() async throws {
        if shouldThrowError { throw errorToThrow }
        sessions.removeAll()
    }
    
    func getTotalStudyTime() async throws -> TimeInterval {
        if shouldThrowError { throw errorToThrow }
        return sessions.reduce(0) { total, session in
            if let endTime = session.endTime {
                return total + endTime.timeIntervalSince(session.startTime)
            }
            return total
        }
    }
    
    func getSessionCount() async throws -> Int {
        if shouldThrowError { throw errorToThrow }
        return sessions.count
    }
}
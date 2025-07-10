//
//  LearningSessionProviding.swift
//  单词
//
//  Created by Claude on 2025-06-28.
//

import Foundation

@MainActor
protocol LearningSessionProviding: ObservableObject {
    var currentSession: StudySession? { get }
    var isSessionActive: Bool { get }
    var sessionProgress: Double { get }
    
    func startSession(words: [Word], mode: UserSettings.StudyMode) async throws
    func endSession() async throws
    func submitAnswer(word: Word, isCorrect: Bool) async throws
    func getSessionStatistics() -> SessionStatistics
    func pauseSession()
    func resumeSession()
    func skipCurrentWord() async throws -> Word?
    func getCurrentWord() -> Word?
}

struct SessionStatistics {
    let totalWords: Int
    let correctAnswers: Int
    let incorrectAnswers: Int
    let skippedWords: Int
    let accuracy: Double
    let timeSpent: TimeInterval
    let wordsPerMinute: Double
}
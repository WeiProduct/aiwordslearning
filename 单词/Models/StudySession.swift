import Foundation
import SwiftData

@Model
final class StudySession: @unchecked Sendable {
    var date: Date
    var wordsStudied: Int
    var correctAnswers: Int
    var totalQuestions: Int
    var studyTime: TimeInterval // 学习时长（秒）
    var sessionType: String // "learning", "quiz", "review"
    
    // Additional properties needed by LearningSessionManager
    var totalWords: Int
    var endTime: Date?
    var isCompleted: Bool
    var startTime: Date
    
    init(date: Date = Date(), wordsStudied: Int = 0, correctAnswers: Int = 0, totalQuestions: Int = 0, studyTime: TimeInterval = 0, sessionType: String = "learning", totalWords: Int = 0, startTime: Date = Date()) {
        self.date = date
        self.wordsStudied = wordsStudied
        self.correctAnswers = correctAnswers
        self.totalQuestions = totalQuestions
        self.studyTime = studyTime
        self.sessionType = sessionType
        self.totalWords = totalWords
        self.startTime = startTime
        self.endTime = nil
        self.isCompleted = false
    }
    
    var accuracy: Double {
        return totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) : 0.0
    }
} 
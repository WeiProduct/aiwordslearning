import Foundation
import SwiftData

@Model
final class Word: @unchecked Sendable {
    var english: String
    var chinese: String
    var pronunciation: String
    var partOfSpeech: String // 词性
    var example: String
    var exampleTranslation: String
    var difficulty: Int // 1-5 难度等级
    var isLearned: Bool
    var isFavorited: Bool
    var learningCount: Int
    var correctCount: Int
    var lastStudyDate: Date?
    var createdDate: Date
    
    init(english: String, chinese: String, pronunciation: String = "", partOfSpeech: String = "", example: String = "", exampleTranslation: String = "", difficulty: Int = 1) {
        self.english = english
        self.chinese = chinese
        self.pronunciation = pronunciation
        self.partOfSpeech = partOfSpeech
        self.example = example
        self.exampleTranslation = exampleTranslation
        self.difficulty = difficulty
        self.isLearned = false
        self.isFavorited = false
        self.learningCount = 0
        self.correctCount = 0
        self.lastStudyDate = nil
        self.createdDate = Date()
    }
    
    var accuracy: Double {
        return learningCount > 0 ? Double(correctCount) / Double(learningCount) : 0.0
    }
} 
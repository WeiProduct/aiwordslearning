import Foundation
import SwiftData

@Model
final class UserProgress: @unchecked Sendable {
    var totalWordsLearned: Int
    var currentStreak: Int // 连续学习天数
    var longestStreak: Int
    var totalStudyTime: TimeInterval
    var level: Int
    var experience: Int
    var lastStudyDate: Date?
    var dailyGoal: Int // 每日学习目标
    var weeklyGoal: Int // 每周学习目标
    
    init() {
        self.totalWordsLearned = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalStudyTime = 0
        self.level = 1
        self.experience = 0
        self.lastStudyDate = nil
        self.dailyGoal = 20
        self.weeklyGoal = 100
    }
    
    func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = lastStudyDate {
            let lastStudyDay = Calendar.current.startOfDay(for: lastDate)
            let daysDifference = Calendar.current.dateComponents([.day], from: lastStudyDay, to: today).day ?? 0
            
            if daysDifference == 1 {
                // 连续学习
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else if daysDifference > 1 {
                // 断连
                currentStreak = 1
            }
            // daysDifference == 0 表示今天已经学习过，不更新
        } else {
            currentStreak = 1
        }
        
        lastStudyDate = Date()
    }
} 
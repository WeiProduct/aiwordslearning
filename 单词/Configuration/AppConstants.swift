import Foundation
import SwiftUI

// MARK: - 应用常量
struct AppConstants {
    
    // MARK: - App Information
    struct App {
        static let name = "AI背单词"
        static let version = "1.0.0"
        static let minimumIOSVersion = "18.0"
        static let developer = "智能学习工作室"
    }
    
    // MARK: - Learning Configuration
    struct Learning {
        static let defaultDailyGoal = 20
        static let defaultSessionSize = 15
        static let reviewSessionSize = 5
        static let maxSessionSize = 50
        static let minSessionSize = 5
        static let masteryThreshold = 0.7 // 70% 正确率认为掌握
        static let minLearningCount = 3   // 最少学习次数
        static let reviewIntervalDays = 1 // 复习间隔天数
    }
    
    // MARK: - Quiz Configuration
    struct Quiz {
        static let defaultQuestionCount = 10
        static let optionsCount = 4
        static let timeoutSeconds = 30
        static let passingScore = 0.6 // 60% 及格
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let animationDuration = 0.6
        static let cornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 20
        static let buttonHeight: CGFloat = 50
        
        // 颜色主题
        struct Colors {
            static let primary = Color.blue
            static let secondary = Color.gray
            static let accent = Color.orange
            static let success = Color.green
            static let warning = Color.orange
            static let error = Color.red
            
            // 难度颜色
            static let easyColor = Color.green
            static let mediumColor = Color.orange
            static let hardColor = Color.red
        }
        
        // 字体配置
        struct Typography {
            static let largeTitle = Font.largeTitle
            static let title = Font.title
            static let headline = Font.headline
            static let body = Font.body
            static let caption = Font.caption
        }
    }
    
    // MARK: - Speech Configuration
    struct Speech {
        static let defaultRate: Double = 0.5
        static let defaultVolume: Double = 1.0
        static let defaultPitch: Double = 1.0
        static let autoPlayDelay = 1.0 // 秒
        static let speechTimeout = 10.0 // 秒
        
        struct Languages {
            static let english = "en-US"
            static let chinese = "zh-CN"
        }
    }
    
    // MARK: - Cache Configuration
    struct Cache {
        static let wordsCacheExpiry: TimeInterval = 300 // 5分钟
        static let statisticsCacheExpiry: TimeInterval = 60 // 1分钟
        static let maxCacheSize = 1000 // 最大缓存单词数量
    }
    
    // MARK: - Data Configuration
    struct Data {
        static let batchSize = 100
        static let maxRetryAttempts = 3
        static let saveInterval: TimeInterval = 10 // 自动保存间隔
        
        struct Files {
            static let wordsFileName = "IELTS"
            static let wordsFileExtension = "txt"
            static let backupFileName = "backup"
        }
    }
    
    // MARK: - Achievement Configuration
    struct Achievements {
        static let firstWordThreshold = 1
        static let beginnerThreshold = 10
        static let intermediateThreshold = 50
        static let advancedThreshold = 100
        static let expertThreshold = 500
        static let masterThreshold = 1000
        
        static let perfectScoreThreshold = 1.0
        static let consistentLearnerDays = 7
        static let speedLearnerWordsPerDay = 50
    }
    
    // MARK: - Statistics Configuration
    struct Statistics {
        static let chartDataPoints = 30 // 显示最近30天数据
        static let accuracyDecimalPlaces = 1
        static let progressUpdateInterval: TimeInterval = 5
    }
    
    // MARK: - Notification Configuration
    struct Notifications {
        static let dailyReminderIdentifier = "dailyReminder"
        static let studyStreakIdentifier = "studyStreak"
        static let achievementIdentifier = "achievement"
        
        static let defaultReminderHour = 19 // 晚上7点
        static let defaultReminderMinute = 0
    }
}

// MARK: - 用户设置配置
struct UserSettings {
    
    // MARK: - Keys for UserDefaults
    private struct Keys {
        static let dailyGoal = "dailyGoal"
        static let enableNotifications = "enableNotifications"
        static let reminderTime = "reminderTime"
        static let autoPlaySpeech = "autoPlaySpeech"
        static let speechRate = "speechRate"
        static let difficultyPreference = "difficultyPreference"
        static let showPronunciation = "showPronunciation"
        static let studyMode = "studyMode"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastLaunchDate = "lastLaunchDate"
        static let appLanguage = "appLanguage"
    }
    
    // MARK: - Settings Properties
    @AppStorage(Keys.dailyGoal) static var dailyGoal = AppConstants.Learning.defaultDailyGoal
    @AppStorage(Keys.enableNotifications) static var enableNotifications = true
    @AppStorage(Keys.reminderTime) static var reminderTime = Date()
    @AppStorage(Keys.autoPlaySpeech) static var autoPlaySpeech = true
    @AppStorage(Keys.speechRate) static var speechRate = AppConstants.Speech.defaultRate
    @AppStorage(Keys.showPronunciation) static var showPronunciation = true
    @AppStorage(Keys.hasCompletedOnboarding) static var hasCompletedOnboarding = false
    @AppStorage(Keys.lastLaunchDate) static var lastLaunchDate = Date.distantPast
    
    // 应用语言
    @AppStorage(Keys.appLanguage) private static var _appLanguage = "chinese"
    static var appLanguage: AppLanguage {
        get { AppLanguage(rawValue: _appLanguage) ?? .chinese }
        set { _appLanguage = newValue.rawValue }
    }
    
    // 难度偏好
    @AppStorage(Keys.difficultyPreference) private static var _difficultyPreference = "mixed"
    static var difficultyPreference: DifficultyPreference {
        get { DifficultyPreference(rawValue: _difficultyPreference) ?? .mixed }
        set { _difficultyPreference = newValue.rawValue }
    }
    
    // 学习模式
    @AppStorage(Keys.studyMode) private static var _studyMode = "adaptive"
    static var studyMode: StudyMode {
        get { StudyMode(rawValue: _studyMode) ?? .adaptive }
        set { _studyMode = newValue.rawValue }
    }
    
    enum DifficultyPreference: String, CaseIterable {
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"
        case mixed = "mixed"
        
        var displayName: String {
            switch self {
            case .easy: return "简单"
            case .medium: return "中等"
            case .hard: return "困难"
            case .mixed: return "混合"
            }
        }
    }
    
    enum StudyMode: String, CaseIterable {
        case adaptive = "adaptive"
        case sequential = "sequential"
        case random = "random"
        case spaced = "spaced"
        
        var displayName: String {
            switch self {
            case .adaptive: return "智能自适应"
            case .sequential: return "顺序学习"
            case .random: return "随机学习"
            case .spaced: return "间隔重复"
            }
        }
        
        var description: String {
            switch self {
            case .adaptive: return "根据学习表现智能调整"
            case .sequential: return "按顺序逐个学习"
            case .random: return "随机顺序学习"
            case .spaced: return "基于遗忘曲线的间隔复习"
            }
        }
    }
    
    enum AppLanguage: String, CaseIterable {
        case chinese = "chinese"
        case english = "english"
        
        var displayName: String {
            switch self {
            case .chinese: return "中文"
            case .english: return "English"
            }
        }
        
        var code: String {
            switch self {
            case .chinese: return "zh-CN"
            case .english: return "en-US"
            }
        }
    }
    
    // MARK: - Helper Methods
    static func reset() {
        dailyGoal = AppConstants.Learning.defaultDailyGoal
        enableNotifications = true
        autoPlaySpeech = true
        speechRate = AppConstants.Speech.defaultRate
        showPronunciation = true
        difficultyPreference = .mixed
        studyMode = .adaptive
        hasCompletedOnboarding = false
        appLanguage = .chinese
    }
    
    static func updateLastLaunchDate() {
        lastLaunchDate = Date()
    }
}

// MARK: - 应用环境配置
enum AppEnvironment {
    case development
    case staging
    case production
    
    static let current: AppEnvironment = {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }()
    
    var apiBaseURL: String {
        switch self {
        case .development:
            return "https://dev-api.example.com"
        case .staging:
            return "https://staging-api.example.com"
        case .production:
            return "https://api.example.com"
        }
    }
    
    var enableLogging: Bool {
        switch self {
        case .development, .staging:
            return true
        case .production:
            return false
        }
    }
}

// MARK: - 日志配置
extension AppConstants {
    struct Logging {
        static let enableLogging = AppEnvironment.current.enableLogging
        static let writeToFile = true
        static let maxFileSize: UInt64 = 10 * 1024 * 1024 // 10MB
        static let logRetentionDays = 7
    }
}

// MARK: - 错误类型定义
enum AppError: LocalizedError {
    case dataLoadingFailed(String)
    case speechSynthesisFailed(String)
    case databaseError(String)
    case dataError(String)
    case networkError(String)
    case validationError(String)
    case fileError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .dataLoadingFailed(let message):
            return "数据加载失败: \(message)"
        case .speechSynthesisFailed(let message):
            return "语音合成失败: \(message)"
        case .databaseError(let message):
            return "数据库错误: \(message)"
        case .dataError(let message):
            return "数据错误: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .validationError(let message):
            return "验证错误: \(message)"
        case .fileError(let message):
            return "文件错误: \(message)"
        case .unknownError:
            return "未知错误"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataLoadingFailed:
            return "请检查数据文件是否完整，或尝试重新启动应用"
        case .speechSynthesisFailed:
            return "请检查设备音频设置，确保音量未静音"
        case .databaseError, .dataError:
            return "请尝试重启应用，或清除应用数据后重新初始化"
        case .networkError:
            return "请检查网络连接是否正常"
        case .validationError:
            return "请检查输入数据是否正确"
        case .fileError:
            return "请检查文件是否存在且可访问"
        case .unknownError:
            return "请尝试重新启动应用"
        }
    }
} 
import Foundation

struct LocalizedTexts {
    
    // MARK: - Welcome Screen
    struct Welcome {
        static func appTitle(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "🧠 AI背单词App"
            case .english: return "🧠 AI Word Learning"
            }
        }
        
        static func appSubtitle(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "完整原型设计"
            case .english: return "Complete Prototype Design"
            }
        }
        
        static func appDescription(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "智能化个性化背单词学习应用"
            case .english: return "Intelligent Personalized Vocabulary Learning"
            }
        }
        
        static func startLearning(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "开始学习"
            case .english: return "Start Learning"
            }
        }
        
        static func languageSelection(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "选择语言"
            case .english: return "Choose Language"
            }
        }
        
        static func selectLanguagePrompt(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "请选择您的界面语言"
            case .english: return "Please choose your interface language"
            }
        }
    }
    
    // MARK: - Tab Bar
    struct TabBar {
        static func home(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "主页"
            case .english: return "Home"
            }
        }
        
        static func learning(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "学习"
            case .english: return "Learn"
            }
        }
        
        static func quiz(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "测试"
            case .english: return "Quiz"
            }
        }
        
        static func statistics(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "统计"
            case .english: return "Stats"
            }
        }
        
        static func settings(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "设置"
            case .english: return "Settings"
            }
        }
    }
    
    // MARK: - Common
    struct Common {
        static func confirm(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "确认"
            case .english: return "Confirm"
            }
        }
        
        static func cancel(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "取消"
            case .english: return "Cancel"
            }
        }
        
        static func done(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "完成"
            case .english: return "Done"
            }
        }
        
        static func next(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "下一步"
            case .english: return "Next"
            }
        }
        
        static func previous(language: UserSettings.AppLanguage) -> String {
            switch language {
            case .chinese: return "上一步"
            case .english: return "Previous"
            }
        }
    }
}
import Foundation

// MARK: - 词汇分类
enum VocabularyCategory: String, CaseIterable {
    // 国际考试
    case ielts = "IELTS"
    case toefl = "TOEFL"
    case gre = "GRE"
    case gmat = "GMAT"
    case sat = "SAT"
    case bec = "BEC"
    
    // 国内考试
    case cet4 = "CET4"
    case cet6 = "CET6"
    case tem4 = "Level4"
    case tem8 = "Level8"
    case kaoyan = "KaoYan"
    
    // 教材系列
    case pepPrimary = "PEPXiaoXue"
    case pepJunior = "PEPChuZhong"
    case pepSenior = "PEPGaoZhong"
    case beijingSenior = "BeiShiGaoZhong"
    case fltrpJunior = "WaiYanSheChuZhong"
    case generalJunior = "ChuZhong"
    case generalSenior = "GaoZhong"
    
    var displayName: String {
        switch self {
        // 国际考试
        case .ielts: return "雅思 (IELTS)"
        case .toefl: return "托福 (TOEFL)"
        case .gre: return "GRE"
        case .gmat: return "GMAT"
        case .sat: return "SAT"
        case .bec: return "商务英语 (BEC)"
        
        // 国内考试
        case .cet4: return "大学四级"
        case .cet6: return "大学六级"
        case .tem4: return "专业四级"
        case .tem8: return "专业八级"
        case .kaoyan: return "考研英语"
        
        // 教材系列
        case .pepPrimary: return "人教版小学"
        case .pepJunior: return "人教版初中"
        case .pepSenior: return "人教版高中"
        case .beijingSenior: return "北师大高中"
        case .fltrpJunior: return "外研社初中"
        case .generalJunior: return "初中通用"
        case .generalSenior: return "高中通用"
        }
    }
    
    var englishDisplayName: String {
        switch self {
        // 国际考试
        case .ielts: return "IELTS"
        case .toefl: return "TOEFL"
        case .gre: return "GRE"
        case .gmat: return "GMAT"
        case .sat: return "SAT"
        case .bec: return "Business English (BEC)"
        
        // 国内考试
        case .cet4: return "CET-4"
        case .cet6: return "CET-6"
        case .tem4: return "TEM-4"
        case .tem8: return "TEM-8"
        case .kaoyan: return "Postgraduate English"
        
        // 教材系列
        case .pepPrimary: return "PEP Primary School"
        case .pepJunior: return "PEP Junior High"
        case .pepSenior: return "PEP Senior High"
        case .beijingSenior: return "Beijing Normal Senior High"
        case .fltrpJunior: return "FLTRP Junior High"
        case .generalJunior: return "General Junior High"
        case .generalSenior: return "General Senior High"
        }
    }
    
    var description: String {
        switch self {
        // 国际考试
        case .ielts: return "国际英语语言测试系统"
        case .toefl: return "托福考试词汇"
        case .gre: return "美国研究生入学考试"
        case .gmat: return "研究生管理科入学考试"
        case .sat: return "美国高考"
        case .bec: return "剑桥商务英语证书"
        
        // 国内考试
        case .cet4: return "全国大学英语四级考试"
        case .cet6: return "全国大学英语六级考试"
        case .tem4: return "英语专业四级考试"
        case .tem8: return "英语专业八级考试"
        case .kaoyan: return "全国硕士研究生入学考试"
        
        // 教材系列
        case .pepPrimary: return "人教版小学英语教材"
        case .pepJunior: return "人教版初中英语教材"
        case .pepSenior: return "人教版高中英语教材"
        case .beijingSenior: return "北师大版高中英语教材"
        case .fltrpJunior: return "外研社初中英语教材"
        case .generalJunior: return "初中通用词汇"
        case .generalSenior: return "高中通用词汇"
        }
    }
    
    var icon: String {
        switch self {
        // 国际考试
        case .ielts, .toefl, .gre, .gmat, .sat, .bec:
            return "globe.americas"
        
        // 国内考试
        case .cet4, .cet6, .tem4, .tem8, .kaoyan:
            return "graduationcap"
        
        // 教材系列
        case .pepPrimary, .pepJunior, .pepSenior, .beijingSenior, .fltrpJunior, .generalJunior, .generalSenior:
            return "book"
        }
    }
    
    var difficulty: Int {
        switch self {
        // 教材系列
        case .pepPrimary: return 1
        case .generalJunior, .pepJunior, .fltrpJunior: return 2
        case .generalSenior, .pepSenior, .beijingSenior: return 3
        
        // 国内考试
        case .cet4: return 3
        case .cet6: return 4
        case .tem4: return 4
        case .tem8, .kaoyan: return 5
        
        // 国际考试
        case .bec: return 4
        case .ielts, .toefl: return 5
        case .sat: return 5
        case .gre, .gmat: return 6
        }
    }
    
    var wordCount: Int {
        switch self {
        case .ielts: return 4000
        case .toefl: return 4500
        case .gre: return 5000
        case .gmat: return 3000
        case .sat: return 3500
        case .bec: return 3000
        case .cet4: return 4000
        case .cet6: return 5500
        case .tem4: return 6000
        case .tem8: return 8000
        case .kaoyan: return 5500
        case .pepPrimary: return 800
        case .pepJunior: return 1600
        case .pepSenior: return 3500
        case .beijingSenior: return 3500
        case .fltrpJunior: return 1500
        case .generalJunior: return 1600
        case .generalSenior: return 3500
        }
    }
}

// MARK: - 词汇分组
enum VocabularyGroup: String, CaseIterable {
    case international = "international"
    case domestic = "domestic"
    case textbook = "textbook"
    
    var displayName: String {
        switch self {
        case .international: return "国际考试"
        case .domestic: return "国内考试"
        case .textbook: return "教材词汇"
        }
    }
    
    var englishDisplayName: String {
        switch self {
        case .international: return "International Exams"
        case .domestic: return "Domestic Exams"
        case .textbook: return "Textbook Vocabulary"
        }
    }
    
    var categories: [VocabularyCategory] {
        switch self {
        case .international:
            return [.ielts, .toefl, .gre, .gmat, .sat, .bec]
        case .domestic:
            return [.cet4, .cet6, .tem4, .tem8, .kaoyan]
        case .textbook:
            return [.pepPrimary, .pepJunior, .pepSenior, .beijingSenior, .fltrpJunior, .generalJunior, .generalSenior]
        }
    }
}

// MARK: - JSON 词汇模型
struct JSONWord: Codable {
    let word: String
    let translations: [Translation]
    let phrases: [Phrase]
    
    struct Translation: Codable {
        let translation: String
        let type: String
    }
    
    struct Phrase: Codable {
        let phrase: String
        let translation: String
    }
}
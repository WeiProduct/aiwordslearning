import Foundation

// MARK: - 模拟词汇数据提供者
class MockVocabularyDataProvider {
    
    static let shared = MockVocabularyDataProvider()
    
    private init() {}
    
    // MARK: - 获取模拟词汇数据
    func getMockWords(for category: VocabularyCategory) -> [JSONWord] {
        switch category {
        case .ielts:
            return getIELTSWords()
        case .toefl:
            return getTOEFLWords()
        case .cet4:
            return getCET4Words()
        case .cet6:
            return getCET6Words()
        default:
            return getGeneralWords(category: category)
        }
    }
    
    // MARK: - IELTS 词汇
    private func getIELTSWords() -> [JSONWord] {
        return [
            JSONWord(
                word: "abandon",
                translations: [.init(translation: "放弃，遗弃", type: "v")],
                phrases: [
                    .init(phrase: "abandon ship", translation: "弃船"),
                    .init(phrase: "with abandon", translation: "恣意地，放纵地")
                ]
            ),
            JSONWord(
                word: "accommodation",
                translations: [.init(translation: "住所，住宿", type: "n")],
                phrases: [
                    .init(phrase: "accommodation facilities", translation: "住宿设施"),
                    .init(phrase: "provide accommodation", translation: "提供住宿")
                ]
            ),
            JSONWord(
                word: "achieve",
                translations: [.init(translation: "达到，实现", type: "v")],
                phrases: [
                    .init(phrase: "achieve success", translation: "取得成功"),
                    .init(phrase: "achieve goals", translation: "实现目标")
                ]
            ),
            JSONWord(
                word: "acquire",
                translations: [.init(translation: "获得，学到", type: "v")],
                phrases: [
                    .init(phrase: "acquire knowledge", translation: "获得知识"),
                    .init(phrase: "acquire skills", translation: "学习技能")
                ]
            ),
            JSONWord(
                word: "adapt",
                translations: [.init(translation: "适应，改编", type: "v")],
                phrases: [
                    .init(phrase: "adapt to", translation: "适应"),
                    .init(phrase: "adapt from", translation: "改编自")
                ]
            )
        ]
    }
    
    // MARK: - TOEFL 词汇
    private func getTOEFLWords() -> [JSONWord] {
        return [
            JSONWord(
                word: "abstract",
                translations: [
                    .init(translation: "抽象的", type: "adj"),
                    .init(translation: "摘要", type: "n")
                ],
                phrases: [
                    .init(phrase: "abstract thinking", translation: "抽象思维"),
                    .init(phrase: "in the abstract", translation: "抽象地")
                ]
            ),
            JSONWord(
                word: "academic",
                translations: [.init(translation: "学术的", type: "adj")],
                phrases: [
                    .init(phrase: "academic achievement", translation: "学术成就"),
                    .init(phrase: "academic year", translation: "学年")
                ]
            ),
            JSONWord(
                word: "accelerate",
                translations: [.init(translation: "加速", type: "v")],
                phrases: [
                    .init(phrase: "accelerate growth", translation: "加速增长"),
                    .init(phrase: "accelerate the process", translation: "加快进程")
                ]
            ),
            JSONWord(
                word: "accessible",
                translations: [.init(translation: "可接近的，可获得的", type: "adj")],
                phrases: [
                    .init(phrase: "easily accessible", translation: "容易获得的"),
                    .init(phrase: "accessible to", translation: "可供...使用的")
                ]
            ),
            JSONWord(
                word: "acknowledge",
                translations: [.init(translation: "承认，感谢", type: "v")],
                phrases: [
                    .init(phrase: "acknowledge receipt", translation: "确认收到"),
                    .init(phrase: "acknowledge the fact", translation: "承认事实")
                ]
            )
        ]
    }
    
    // MARK: - CET4 词汇
    private func getCET4Words() -> [JSONWord] {
        return [
            JSONWord(
                word: "ability",
                translations: [.init(translation: "能力，才能", type: "n")],
                phrases: [
                    .init(phrase: "have the ability to", translation: "有能力做"),
                    .init(phrase: "ability to learn", translation: "学习能力")
                ]
            ),
            JSONWord(
                word: "absent",
                translations: [.init(translation: "缺席的，不在的", type: "adj")],
                phrases: [
                    .init(phrase: "be absent from", translation: "缺席"),
                    .init(phrase: "absent-minded", translation: "心不在焉的")
                ]
            ),
            JSONWord(
                word: "accept",
                translations: [.init(translation: "接受，认可", type: "v")],
                phrases: [
                    .init(phrase: "accept responsibility", translation: "承担责任"),
                    .init(phrase: "widely accepted", translation: "广泛接受的")
                ]
            ),
            JSONWord(
                word: "accident",
                translations: [.init(translation: "事故，意外", type: "n")],
                phrases: [
                    .init(phrase: "by accident", translation: "偶然地"),
                    .init(phrase: "traffic accident", translation: "交通事故")
                ]
            ),
            JSONWord(
                word: "accomplish",
                translations: [.init(translation: "完成，实现", type: "v")],
                phrases: [
                    .init(phrase: "accomplish a task", translation: "完成任务"),
                    .init(phrase: "accomplish goals", translation: "达成目标")
                ]
            )
        ]
    }
    
    // MARK: - CET6 词汇
    private func getCET6Words() -> [JSONWord] {
        return [
            JSONWord(
                word: "abolish",
                translations: [.init(translation: "废除，废止", type: "v")],
                phrases: [
                    .init(phrase: "abolish slavery", translation: "废除奴隶制"),
                    .init(phrase: "abolish the law", translation: "废除法律")
                ]
            ),
            JSONWord(
                word: "absurd",
                translations: [.init(translation: "荒谬的，可笑的", type: "adj")],
                phrases: [
                    .init(phrase: "absurd idea", translation: "荒谬的想法"),
                    .init(phrase: "utterly absurd", translation: "完全荒谬的")
                ]
            ),
            JSONWord(
                word: "abundant",
                translations: [.init(translation: "丰富的，充裕的", type: "adj")],
                phrases: [
                    .init(phrase: "abundant resources", translation: "丰富的资源"),
                    .init(phrase: "in abundance", translation: "大量地")
                ]
            ),
            JSONWord(
                word: "accelerate",
                translations: [.init(translation: "加速，促进", type: "v")],
                phrases: [
                    .init(phrase: "accelerate development", translation: "加速发展"),
                    .init(phrase: "accelerate the pace", translation: "加快步伐")
                ]
            ),
            JSONWord(
                word: "accumulate",
                translations: [.init(translation: "积累，积聚", type: "v")],
                phrases: [
                    .init(phrase: "accumulate wealth", translation: "积累财富"),
                    .init(phrase: "accumulate experience", translation: "积累经验")
                ]
            )
        ]
    }
    
    // MARK: - 通用词汇生成
    private func getGeneralWords(category: VocabularyCategory) -> [JSONWord] {
        // 为其他分类生成一些示例词汇
        let sampleWords = [
            ("book", "书", "n"),
            ("study", "学习", "v"),
            ("teacher", "老师", "n"),
            ("student", "学生", "n"),
            ("school", "学校", "n")
        ]
        
        return sampleWords.map { word, translation, type in
            JSONWord(
                word: word,
                translations: [.init(translation: translation, type: type)],
                phrases: []
            )
        }
    }
}

// MARK: - 词汇数据扩展
extension MockVocabularyDataProvider {
    
    // 检查分类是否有可用数据
    func hasDataForCategory(_ category: VocabularyCategory) -> Bool {
        // 模拟只有部分分类有数据
        switch category {
        case .ielts, .toefl, .cet4, .cet6, .gre, .gmat, .sat:
            return true
        case .tem4, .tem8, .kaoyan:
            return true
        case .pepPrimary, .pepJunior, .pepSenior:
            return true
        default:
            return false
        }
    }
    
    // 获取分类的词汇数量
    func getWordCount(for category: VocabularyCategory) -> Int {
        return getMockWords(for: category).count
    }
}
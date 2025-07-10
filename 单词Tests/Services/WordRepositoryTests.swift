//
//  WordRepositoryTests.swift
//  单词Tests
//
//  Created by Claude on 2025-06-28.
//

import XCTest
import SwiftData
@testable import 单词

final class WordRepositoryTests: XCTestCase {
    var repository: WordRepository!
    var modelContext: ModelContext!
    var container: ModelContainer!
    
    @MainActor
    override func setUpWithError() throws {
        let schema = Schema([Word.self, StudySession.self, UserProgress.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(container)
        repository = WordRepository(modelContext: modelContext)
    }
    
    override func tearDownWithError() throws {
        repository = nil
        modelContext = nil
        container = nil
    }
    
    @MainActor
    func testSaveAndFindWord() async throws {
        let word = createTestWord(english: "test", chinese: "测试")
        
        try await repository.save(word)
        
        let foundWord = try await repository.findById(word.id)
        XCTAssertNotNil(foundWord)
        XCTAssertEqual(foundWord?.english, "test")
        XCTAssertEqual(foundWord?.chinese, "测试")
    }
    
    @MainActor
    func testFindAllWords() async throws {
        let word1 = createTestWord(english: "hello", chinese: "你好")
        let word2 = createTestWord(english: "world", chinese: "世界")
        
        try await repository.save(word1)
        try await repository.save(word2)
        
        let allWords = try await repository.findAll()
        XCTAssertEqual(allWords.count, 2)
        XCTAssertTrue(allWords.contains { $0.english == "hello" })
        XCTAssertTrue(allWords.contains { $0.english == "world" })
    }
    
    @MainActor
    func testFindByDifficulty() async throws {
        let easyWord = createTestWord(english: "easy", chinese: "简单", difficulty: 1)
        let hardWord = createTestWord(english: "difficult", chinese: "困难", difficulty: 3)
        
        try await repository.save(easyWord)
        try await repository.save(hardWord)
        
        let easyWords = try await repository.findByDifficulty(1)
        let hardWords = try await repository.findByDifficulty(3)
        
        XCTAssertEqual(easyWords.count, 1)
        XCTAssertEqual(hardWords.count, 1)
        XCTAssertEqual(easyWords.first?.english, "easy")
        XCTAssertEqual(hardWords.first?.english, "difficult")
    }
    
    @MainActor
    func testFindByLearningStatus() async throws {
        let learnedWord = createTestWord(english: "learned", chinese: "已学", isLearned: true)
        let newWord = createTestWord(english: "new", chinese: "新的", isLearned: false)
        
        try await repository.save(learnedWord)
        try await repository.save(newWord)
        
        let learnedWords = try await repository.findByLearningStatus(true)
        let newWords = try await repository.findByLearningStatus(false)
        
        XCTAssertEqual(learnedWords.count, 1)
        XCTAssertEqual(newWords.count, 1)
        XCTAssertEqual(learnedWords.first?.english, "learned")
        XCTAssertEqual(newWords.first?.english, "new")
    }
    
    @MainActor
    func testSearchWords() async throws {
        let word1 = createTestWord(english: "apple", chinese: "苹果")
        let word2 = createTestWord(english: "application", chinese: "应用")
        let word3 = createTestWord(english: "banana", chinese: "香蕉")
        
        try await repository.save(word1)
        try await repository.save(word2)
        try await repository.save(word3)
        
        let searchResults = try await repository.search(query: "app")
        XCTAssertEqual(searchResults.count, 2)
        XCTAssertTrue(searchResults.contains { $0.english == "apple" })
        XCTAssertTrue(searchResults.contains { $0.english == "application" })
    }
    
    @MainActor
    func testDeleteWord() async throws {
        let word = createTestWord(english: "delete", chinese: "删除")
        
        try await repository.save(word)
        let countBefore = try await repository.count()
        XCTAssertEqual(countBefore, 1)
        
        try await repository.delete(word)
        let countAfter = try await repository.count()
        XCTAssertEqual(countAfter, 0)
    }
    
    @MainActor
    func testDeleteAll() async throws {
        let word1 = createTestWord(english: "first", chinese: "第一")
        let word2 = createTestWord(english: "second", chinese: "第二")
        
        try await repository.save(word1)
        try await repository.save(word2)
        
        let countBefore = try await repository.count()
        XCTAssertEqual(countBefore, 2)
        
        try await repository.deleteAll()
        let countAfter = try await repository.count()
        XCTAssertEqual(countAfter, 0)
    }
    
    private func createTestWord(
        english: String,
        chinese: String,
        difficulty: Int = 1,
        isLearned: Bool = false
    ) -> Word {
        return Word(
            english: english,
            chinese: chinese,
            pronunciation: "/\(english)/",
            partOfSpeech: "n.",
            example: "This is an example with \(english).",
            exampleTranslation: "这是一个包含\(chinese)的例句。",
            difficulty: difficulty,
            isLearned: isLearned
        )
    }
}
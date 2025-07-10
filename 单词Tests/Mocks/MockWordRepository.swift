//
//  MockWordRepository.swift
//  单词Tests
//
//  Created by Claude on 2025-06-28.
//

import Foundation
@testable import 单词

class MockWordRepository: WordRepositoryProtocol {
    private var words: [Word] = []
    var shouldThrowError = false
    var errorToThrow: Error = AppError.databaseError("Mock error")
    
    func findAll() async throws -> [Word] {
        if shouldThrowError { throw errorToThrow }
        return words
    }
    
    func findById(_ id: String) async throws -> Word? {
        if shouldThrowError { throw errorToThrow }
        return words.first { $0.id == id }
    }
    
    func findByDifficulty(_ difficulty: Int) async throws -> [Word] {
        if shouldThrowError { throw errorToThrow }
        return words.filter { $0.difficulty == difficulty }
    }
    
    func findByLearningStatus(_ isLearned: Bool) async throws -> [Word] {
        if shouldThrowError { throw errorToThrow }
        return words.filter { $0.isLearned == isLearned }
    }
    
    func findByFavoriteStatus(_ isFavorited: Bool) async throws -> [Word] {
        if shouldThrowError { throw errorToThrow }
        return words.filter { $0.isFavorited == isFavorited }
    }
    
    func findWordsForReview() async throws -> [Word] {
        if shouldThrowError { throw errorToThrow }
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return words.filter { word in
            word.isLearned && 
            (word.lastStudyDate == nil || word.lastStudyDate! <= oneDayAgo)
        }
    }
    
    func search(query: String) async throws -> [Word] {
        if shouldThrowError { throw errorToThrow }
        let lowercaseQuery = query.lowercased()
        return words.filter { word in
            word.english.lowercased().contains(lowercaseQuery) ||
            word.chinese.lowercased().contains(lowercaseQuery) ||
            word.partOfSpeech.lowercased().contains(lowercaseQuery)
        }
    }
    
    func save(_ word: Word) async throws {
        if shouldThrowError { throw errorToThrow }
        words.append(word)
    }
    
    func update(_ word: Word) async throws {
        if shouldThrowError { throw errorToThrow }
    }
    
    func delete(_ word: Word) async throws {
        if shouldThrowError { throw errorToThrow }
        words.removeAll { $0.id == word.id }
    }
    
    func deleteAll() async throws {
        if shouldThrowError { throw errorToThrow }
        words.removeAll()
    }
    
    func count() async throws -> Int {
        if shouldThrowError { throw errorToThrow }
        return words.count
    }
    
    func addWords(_ wordsToAdd: [Word]) {
        words.append(contentsOf: wordsToAdd)
    }
    
    func clear() {
        words.removeAll()
        shouldThrowError = false
    }
}
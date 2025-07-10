//
//  WordDataProviding.swift
//  单词
//
//  Created by Claude on 2025-06-28.
//

import Foundation

@MainActor
protocol WordDataProviding: ObservableObject {
    var isLoading: Bool { get }
    var cachedWords: [Word] { get }
    var lastCacheUpdate: Date? { get }
    
    func getAllWords() async throws -> [Word]
    func searchWords(query: String) async throws -> [Word]
    func getWordsByDifficulty(_ difficulty: WordDifficulty) async throws -> [Word]
    func getRandomWords(count: Int) async throws -> [Word]
    func updateWordProgress(_ word: Word, isCorrect: Bool) async throws
    func markWordAsLearned(_ word: Word) async throws
    func getWordsForReview() async throws -> [Word]
    func importWordsFromFile(fileName: String) async throws
    func clearCache()
}
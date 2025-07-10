//
//  WordRepository.swift
//  单词
//
//  Created by Claude on 2025-06-28.
//

import Foundation
import SwiftData

protocol WordRepositoryProtocol {
    func findAll() async throws -> [Word]
    func findById(_ id: PersistentIdentifier) async throws -> Word?
    func findByDifficulty(_ difficulty: Int) async throws -> [Word]
    func findByLearningStatus(_ isLearned: Bool) async throws -> [Word]
    func findByFavoriteStatus(_ isFavorited: Bool) async throws -> [Word]
    func findWordsForReview() async throws -> [Word]
    func search(query: String) async throws -> [Word]
    func save(_ word: Word) async throws
    func update(_ word: Word) async throws
    func delete(_ word: Word) async throws
    func deleteAll() async throws
    func count() async throws -> Int
}

@MainActor
class WordRepository: WordRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func findAll() async throws -> [Word] {
        let descriptor = FetchDescriptor<Word>(
            sortBy: [SortDescriptor(\.english)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func findById(_ id: PersistentIdentifier) async throws -> Word? {
        return modelContext.model(for: id) as? Word
    }
    
    func findByDifficulty(_ difficulty: Int) async throws -> [Word] {
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { $0.difficulty == difficulty },
            sortBy: [SortDescriptor(\.english)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func findByLearningStatus(_ isLearned: Bool) async throws -> [Word] {
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { $0.isLearned == isLearned },
            sortBy: [SortDescriptor(\.lastStudyDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func findByFavoriteStatus(_ isFavorited: Bool) async throws -> [Word] {
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { $0.isFavorited == isFavorited },
            sortBy: [SortDescriptor(\.english)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func findWordsForReview() async throws -> [Word] {
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { word in
                word.isLearned && 
                (word.lastStudyDate == nil || word.lastStudyDate! <= oneDayAgo)
            },
            sortBy: [SortDescriptor(\.lastStudyDate)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func search(query: String) async throws -> [Word] {
        // Since lowercased() is not supported in predicates, we'll do a case-sensitive search
        // or fetch all and filter in memory for better search experience
        let allWords = try await findAll()
        let lowercaseQuery = query.lowercased()
        
        return allWords.filter { word in
            word.english.lowercased().contains(lowercaseQuery) ||
            word.chinese.lowercased().contains(lowercaseQuery) ||
            word.partOfSpeech.lowercased().contains(lowercaseQuery)
        }
    }
    
    func save(_ word: Word) async throws {
        modelContext.insert(word)
        try modelContext.save()
    }
    
    func update(_ word: Word) async throws {
        try modelContext.save()
    }
    
    func delete(_ word: Word) async throws {
        modelContext.delete(word)
        try modelContext.save()
    }
    
    func deleteAll() async throws {
        try modelContext.delete(model: Word.self)
        try modelContext.save()
    }
    
    func count() async throws -> Int {
        let descriptor = FetchDescriptor<Word>()
        return try modelContext.fetchCount(descriptor)
    }
}
//
//  UserProgressRepository.swift
//  单词
//
//  Created by Claude on 2025-06-28.
//

import Foundation
import SwiftData

protocol UserProgressRepositoryProtocol {
    func findCurrent() async throws -> UserProgress?
    func save(_ progress: UserProgress) async throws
    func update(_ progress: UserProgress) async throws
    func delete(_ progress: UserProgress) async throws
    func reset() async throws
}

@MainActor
class UserProgressRepository: UserProgressRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func findCurrent() async throws -> UserProgress? {
        let descriptor = FetchDescriptor<UserProgress>()
        return try modelContext.fetch(descriptor).first
    }
    
    func save(_ progress: UserProgress) async throws {
        modelContext.insert(progress)
        try modelContext.save()
    }
    
    func update(_ progress: UserProgress) async throws {
        try modelContext.save()
    }
    
    func delete(_ progress: UserProgress) async throws {
        modelContext.delete(progress)
        try modelContext.save()
    }
    
    func reset() async throws {
        try modelContext.delete(model: UserProgress.self)
        let newProgress = UserProgress()
        modelContext.insert(newProgress)
        try modelContext.save()
    }
}
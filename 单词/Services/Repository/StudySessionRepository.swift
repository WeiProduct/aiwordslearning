//
//  StudySessionRepository.swift
//  单词
//
//  Created by Claude on 2025-06-28.
//

import Foundation
import SwiftData

protocol StudySessionRepositoryProtocol {
    func findAll() async throws -> [StudySession]
    func findById(_ id: PersistentIdentifier) async throws -> StudySession?
    func findByDateRange(from: Date, to: Date) async throws -> [StudySession]
    func findRecentSessions(limit: Int) async throws -> [StudySession]
    func save(_ session: StudySession) async throws
    func update(_ session: StudySession) async throws
    func delete(_ session: StudySession) async throws
    func deleteAll() async throws
    func getTotalStudyTime() async throws -> TimeInterval
    func getSessionCount() async throws -> Int
}

@MainActor
class StudySessionRepository: StudySessionRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func findAll() async throws -> [StudySession] {
        let descriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func findById(_ id: PersistentIdentifier) async throws -> StudySession? {
        return modelContext.model(for: id) as? StudySession
    }
    
    func findByDateRange(from: Date, to: Date) async throws -> [StudySession] {
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate { session in
                session.startTime >= from && session.startTime <= to
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func findRecentSessions(limit: Int) async throws -> [StudySession] {
        var descriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }
    
    func save(_ session: StudySession) async throws {
        modelContext.insert(session)
        try modelContext.save()
    }
    
    func update(_ session: StudySession) async throws {
        try modelContext.save()
    }
    
    func delete(_ session: StudySession) async throws {
        modelContext.delete(session)
        try modelContext.save()
    }
    
    func deleteAll() async throws {
        try modelContext.delete(model: StudySession.self)
        try modelContext.save()
    }
    
    func getTotalStudyTime() async throws -> TimeInterval {
        let sessions = try await findAll()
        return sessions.reduce(0) { total, session in
            if let endTime = session.endTime {
                return total + endTime.timeIntervalSince(session.startTime)
            }
            return total
        }
    }
    
    func getSessionCount() async throws -> Int {
        let descriptor = FetchDescriptor<StudySession>()
        return try modelContext.fetchCount(descriptor)
    }
}
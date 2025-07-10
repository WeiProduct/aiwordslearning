//
//  DIContainer.swift
//  单词
//
//  Created by Claude on 2025-06-28.
//

import Foundation
import SwiftData

protocol DIContainerProtocol {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func register<T>(_ type: T.Type, instance: T)
    func resolve<T>(_ type: T.Type) -> T?
    func resolveRequired<T>(_ type: T.Type) -> T
}

class DIContainer: DIContainerProtocol, ObservableObject {
    static let shared = DIContainer()
    
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    private let queue = DispatchQueue(label: "DIContainer", attributes: .concurrent)
    
    private init() {
        setupDefaultServices()
    }
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        queue.async(flags: .barrier) {
            self.factories[key] = factory
        }
    }
    
    func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        queue.async(flags: .barrier) {
            self.services[key] = instance
        }
    }
    
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        return queue.sync {
            if let service = services[key] as? T {
                return service
            }
            
            if let factory = factories[key] {
                let instance = factory() as? T
                services[key] = instance
                return instance
            }
            
            return nil
        }
    }
    
    func resolveRequired<T>(_ type: T.Type) -> T {
        guard let service = resolve(type) else {
            fatalError("无法解析服务: \(String(describing: type))")
        }
        return service
    }
    
    private func setupDefaultServices() {
        register(LoggerProtocol.self, instance: AppLogger.shared)
    }
    
    @MainActor
    func setupServices(with modelContext: ModelContext) {
        register(WordRepositoryProtocol.self) {
            // Since WordRepository is @MainActor, we need to create it synchronously
            // This will work because it's called from the main thread during app initialization
            return WordRepository(modelContext: modelContext)
        }
        
        register(StudySessionRepositoryProtocol.self) {
            return StudySessionRepository(modelContext: modelContext)
        }
        
        register(UserProgressRepositoryProtocol.self) {
            return UserProgressRepository(modelContext: modelContext)
        }
        
        register((any WordDataProviding).self) {
            let manager = WordDataManager()
            manager.setModelContext(modelContext)
            return manager
        }
        
        register((any SpeechProviding).self) {
            return SpeechManager() as any SpeechProviding
        }
        
        register((any LearningSessionProviding).self) {
            return LearningSessionManager(
                wordRepository: self.resolveRequired(WordRepositoryProtocol.self),
                sessionRepository: self.resolveRequired(StudySessionRepositoryProtocol.self),
                logger: self.resolveRequired(LoggerProtocol.self)
            )
        }
    }
}

extension DIContainer {
    func clear() {
        queue.async(flags: .barrier) {
            self.services.removeAll()
            self.factories.removeAll()
            self.setupDefaultServices()
        }
    }
    
    func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = String(describing: type)
        return queue.sync {
            return services[key] != nil || factories[key] != nil
        }
    }
}

@propertyWrapper
struct Injected<T> {
    private let container: DIContainer
    private let keyPath: String
    
    init(_ container: DIContainer = .shared) {
        self.container = container
        self.keyPath = String(describing: T.self)
    }
    
    var wrappedValue: T {
        return container.resolveRequired(T.self)
    }
}

@propertyWrapper
struct LazyInjected<T> {
    private let container: DIContainer
    private var cached: T?
    
    init(_ container: DIContainer = .shared) {
        self.container = container
    }
    
    var wrappedValue: T {
        mutating get {
            if cached == nil {
                cached = container.resolveRequired(T.self)
            }
            return cached!
        }
    }
}
//
//  MockLogger.swift
//  单词Tests
//
//  Created by Claude on 2025-06-28.
//

import Foundation
@testable import 单词

class MockLogger: LoggerProtocol {
    var loggedMessages: [(level: LogLevel, category: LogCategory, message: String)] = []
    
    func log(_ level: LogLevel, category: LogCategory, message: String, file: String, function: String, line: Int) {
        loggedMessages.append((level: level, category: category, message: message))
    }
    
    func debug(_ message: String, category: LogCategory, file: String, function: String, line: Int) {
        log(.debug, category: category, message: message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: LogCategory, file: String, function: String, line: Int) {
        log(.info, category: category, message: message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: LogCategory, file: String, function: String, line: Int) {
        log(.warning, category: category, message: message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: LogCategory, file: String, function: String, line: Int) {
        log(.error, category: category, message: message, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: LogCategory, file: String, function: String, line: Int) {
        log(.critical, category: category, message: message, file: file, function: function, line: line)
    }
    
    func clear() {
        loggedMessages.removeAll()
    }
    
    func hasLoggedMessage(containing text: String) -> Bool {
        return loggedMessages.contains { $0.message.contains(text) }
    }
    
    func loggedMessages(for level: LogLevel) -> [String] {
        return loggedMessages.filter { $0.level == level }.map { $0.message }
    }
    
    func loggedMessages(for category: LogCategory) -> [String] {
        return loggedMessages.filter { $0.category == category }.map { $0.message }
    }
}
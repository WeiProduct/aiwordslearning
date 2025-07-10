//
//  AppLogger.swift
//  单词
//
//  Created by Claude on 2025-06-28.
//

import Foundation
import os.log

enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }
}

enum LogCategory: String, CaseIterable {
    case general = "General"
    case database = "Database"
    case speech = "Speech"
    case ui = "UI"
    case network = "Network"
    case learning = "Learning"
    case performance = "Performance"
    
    var subsystem: String {
        return "com.wordlearning.app"
    }
}

protocol LoggerProtocol {
    func log(_ level: LogLevel, category: LogCategory, message: String, file: String, function: String, line: Int)
    func debug(_ message: String, category: LogCategory, file: String, function: String, line: Int)
    func info(_ message: String, category: LogCategory, file: String, function: String, line: Int)
    func warning(_ message: String, category: LogCategory, file: String, function: String, line: Int)
    func error(_ message: String, category: LogCategory, file: String, function: String, line: Int)
    func critical(_ message: String, category: LogCategory, file: String, function: String, line: Int)
}

class AppLogger: LoggerProtocol {
    static let shared = AppLogger()
    
    private let loggers: [LogCategory: Logger] = {
        var loggers: [LogCategory: Logger] = [:]
        for category in LogCategory.allCases {
            loggers[category] = Logger(subsystem: category.subsystem, category: category.rawValue)
        }
        return loggers
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    private let logQueue = DispatchQueue(label: "com.wordlearning.logger", qos: .utility)
    private var isLoggingEnabled: Bool {
        #if DEBUG
        return true
        #else
        return AppConstants.Logging.enableLogging
        #endif
    }
    
    private init() {}
    
    func log(_ level: LogLevel, category: LogCategory, message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isLoggingEnabled else { return }
        
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            let fileName = (file as NSString).lastPathComponent
            let timestamp = self.dateFormatter.string(from: Date())
            let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line)] \(function) - \(message)"
            
            if let logger = self.loggers[category] {
                logger.log(level: level.osLogType, "\(logMessage)")
            }
            
            self.writeToFile(level: level, category: category, message: logMessage)
        }
    }
    
    func debug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, category: category, message: message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, category: category, message: message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, category: category, message: message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, category: category, message: message, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.critical, category: category, message: message, file: file, function: function, line: line)
    }
    
    private func writeToFile(level: LogLevel, category: LogCategory, message: String) {
        guard AppConstants.Logging.writeToFile else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logFileURL = documentsPath.appendingPathComponent("app_logs.txt")
        
        let logEntry = "\(message)\n"
        
        if FileManager.default.fileExists(atPath: logFileURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(logEntry.data(using: .utf8) ?? Data())
                fileHandle.closeFile()
            }
        } else {
            try? logEntry.write(to: logFileURL, atomically: true, encoding: .utf8)
        }
        
        cleanOldLogsIfNeeded(logFileURL: logFileURL)
    }
    
    private func cleanOldLogsIfNeeded(logFileURL: URL) {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: logFileURL.path),
              let fileSize = attributes[.size] as? UInt64 else { return }
        
        let maxFileSize: UInt64 = 10 * 1024 * 1024 // 10MB
        
        if fileSize > maxFileSize {
            try? FileManager.default.removeItem(at: logFileURL)
        }
    }
}

extension AppLogger {
    func logError(_ error: Error, category: LogCategory = .general, context: String = "", file: String = #file, function: String = #function, line: Int = #line) {
        let errorMessage = context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)"
        self.error(errorMessage, category: category, file: file, function: function, line: line)
    }
    
    func logPerformance<T>(_ operation: String, category: LogCategory = .performance, block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        info("Performance: \(operation) took \(String(format: "%.3f", timeElapsed))s", category: category)
        
        return result
    }
    
    func logAsyncPerformance<T>(_ operation: String, category: LogCategory = .performance, block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        info("Async Performance: \(operation) took \(String(format: "%.3f", timeElapsed))s", category: category)
        
        return result
    }
}
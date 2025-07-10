//
//  ConfigurationManager.swift
//  单词
//
//  Created by Claude on 2025-06-28.
//

import Foundation
import SwiftUI

@MainActor
protocol ConfigurationManagerProtocol: ObservableObject {
    var environment: AppEnvironment { get }
    var isLoggingEnabled: Bool { get }
    var apiBaseURL: String { get }
    
    func loadConfiguration()
    func reloadConfiguration()
    func validateConfiguration() -> [ConfigurationError]
}

enum ConfigurationError: LocalizedError {
    case missingRequiredValue(String)
    case invalidValue(String, String)
    case fileNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredValue(let key):
            return "缺少必需的配置值: \(key)"
        case .invalidValue(let key, let value):
            return "无效的配置值 \(key): \(value)"
        case .fileNotFound(let fileName):
            return "找不到配置文件: \(fileName)"
        }
    }
}

@MainActor
class ConfigurationManager: ConfigurationManagerProtocol {
    static let shared = ConfigurationManager()
    
    @Published var environment: AppEnvironment
    @Published var isLoggingEnabled: Bool
    @Published var apiBaseURL: String
    
    private var customConfiguration: [String: Any] = [:]
    private let logger = AppLogger.shared
    
    private init() {
        self.environment = AppEnvironment.current
        self.isLoggingEnabled = AppEnvironment.current.enableLogging
        self.apiBaseURL = AppEnvironment.current.apiBaseURL
        
        loadConfiguration()
    }
    
    func loadConfiguration() {
        logger.info("开始加载应用配置", category: .general)
        
        loadFromBundle()
        loadFromUserDefaults()
        applyEnvironmentSpecificSettings()
        
        let errors = validateConfiguration()
        if !errors.isEmpty {
            logger.warning("配置验证发现问题: \(errors.map { $0.localizedDescription }.joined(separator: ", "))", category: .general)
        }
        
        logger.info("应用配置加载完成", category: .general)
    }
    
    func reloadConfiguration() {
        logger.info("重新加载应用配置", category: .general)
        customConfiguration.removeAll()
        loadConfiguration()
    }
    
    func validateConfiguration() -> [ConfigurationError] {
        var errors: [ConfigurationError] = []
        
        if apiBaseURL.isEmpty {
            errors.append(.missingRequiredValue("apiBaseURL"))
        }
        
        if let url = URL(string: apiBaseURL), !url.isValidURL {
            errors.append(.invalidValue("apiBaseURL", apiBaseURL))
        }
        
        return errors
    }
    
    private func loadFromBundle() {
        guard let path = Bundle.main.path(forResource: "Configuration", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            logger.debug("未找到Configuration.plist文件，使用默认配置", category: .general)
            return
        }
        
        customConfiguration.merge(plist) { _, new in new }
        logger.debug("从Bundle加载配置: \(plist.keys.joined(separator: ", "))", category: .general)
    }
    
    private func loadFromUserDefaults() {
        let userDefaults = UserDefaults.standard
        
        if let customApiURL = userDefaults.string(forKey: "CustomAPIBaseURL"), !customApiURL.isEmpty {
            apiBaseURL = customApiURL
            logger.debug("使用自定义API URL: \(customApiURL)", category: .general)
        }
        
        if userDefaults.object(forKey: "CustomLoggingEnabled") != nil {
            isLoggingEnabled = userDefaults.bool(forKey: "CustomLoggingEnabled")
            logger.debug("使用自定义日志设置: \(isLoggingEnabled)", category: .general)
        }
    }
    
    private func applyEnvironmentSpecificSettings() {
        switch environment {
        case .development:
            setupDevelopmentSettings()
        case .staging:
            setupStagingSettings()
        case .production:
            setupProductionSettings()
        }
    }
    
    private func setupDevelopmentSettings() {
        logger.debug("应用开发环境配置", category: .general)
    }
    
    private func setupStagingSettings() {
        logger.debug("应用测试环境配置", category: .general)
    }
    
    private func setupProductionSettings() {
        logger.debug("应用生产环境配置", category: .general)
    }
}

extension ConfigurationManager {
    func getValue<T>(for key: String, defaultValue: T) -> T {
        if let value = customConfiguration[key] as? T {
            return value
        }
        return defaultValue
    }
    
    func setValue<T>(_ value: T, for key: String) {
        customConfiguration[key] = value
        logger.debug("设置配置值 \(key): \(value)", category: .general)
    }
    
    func hasValue(for key: String) -> Bool {
        return customConfiguration[key] != nil
    }
    
    func removeValue(for key: String) {
        customConfiguration.removeValue(forKey: key)
        logger.debug("移除配置值: \(key)", category: .general)
    }
}

extension URL {
    var isValidURL: Bool {
        return scheme != nil && host != nil
    }
}

extension ConfigurationManager {
    var learningConfiguration: LearningConfiguration {
        LearningConfiguration(
            defaultDailyGoal: getValue(for: "defaultDailyGoal", defaultValue: AppConstants.Learning.defaultDailyGoal),
            defaultSessionSize: getValue(for: "defaultSessionSize", defaultValue: AppConstants.Learning.defaultSessionSize),
            masteryThreshold: getValue(for: "masteryThreshold", defaultValue: AppConstants.Learning.masteryThreshold),
            minLearningCount: getValue(for: "minLearningCount", defaultValue: AppConstants.Learning.minLearningCount)
        )
    }
    
    var uiConfiguration: UIConfiguration {
        UIConfiguration(
            animationDuration: getValue(for: "animationDuration", defaultValue: AppConstants.UI.animationDuration),
            cornerRadius: getValue(for: "cornerRadius", defaultValue: AppConstants.UI.cornerRadius),
            cardPadding: getValue(for: "cardPadding", defaultValue: AppConstants.UI.cardPadding),
            buttonHeight: getValue(for: "buttonHeight", defaultValue: AppConstants.UI.buttonHeight)
        )
    }
}

struct LearningConfiguration {
    let defaultDailyGoal: Int
    let defaultSessionSize: Int
    let masteryThreshold: Double
    let minLearningCount: Int
}

struct UIConfiguration {
    let animationDuration: Double
    let cornerRadius: CGFloat
    let cardPadding: CGFloat
    let buttonHeight: CGFloat
}
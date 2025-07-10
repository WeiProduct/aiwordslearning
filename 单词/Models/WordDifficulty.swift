//
//  WordDifficulty.swift
//  单词
//
//  Created by Claude on 2025-06-28.
//

import Foundation

enum WordDifficulty: Int, CaseIterable, Codable {
    case easy = 1
    case medium = 2
    case hard = 3
    case expert = 4
    
    var displayName: String {
        switch self {
        case .easy:
            return "简单"
        case .medium:
            return "中等"
        case .hard:
            return "困难"
        case .expert:
            return "专家"
        }
    }
    
    var color: String {
        switch self {
        case .easy:
            return "green"
        case .medium:
            return "blue"
        case .hard:
            return "orange"
        case .expert:
            return "red"
        }
    }
}
//
//  SpeechProviding.swift
//  单词
//
//  Created by Claude on 2025-06-28.
//

import Foundation
import AVFoundation

@MainActor
protocol SpeechProviding: ObservableObject {
    var isSpeaking: Bool { get }
    var currentRate: Double { get set }
    var currentVolume: Double { get set }
    var availableLanguages: [String] { get }
    
    func speak(text: String, language: String) async
    func stopSpeaking()
    func pauseSpeaking()
    func resumeSpeaking()
    func setVoice(for language: String) -> Bool
    func preloadVoice(for language: String) async -> Bool
}
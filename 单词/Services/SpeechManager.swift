import Foundation
import AVFoundation

@MainActor
class SpeechManager: NSObject, SpeechProviding {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    
    // SpeechProviding protocol properties
    var currentRate: Double = 0.5 {
        didSet {
            // Update rate for future utterances
        }
    }
    
    var currentVolume: Double = 1.0 {
        didSet {
            // Update volume for future utterances
        }
    }
    
    var availableLanguages: [String] {
        return AVSpeechSynthesisVoice.speechVoices().compactMap { $0.language }
    }
    
    override init() {
        super.init()
        
        // 设置音频会话
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("音频会话设置失败: \(error)")
        }
        
        // 设置代理来监听语音状态
        synthesizer.delegate = self
    }
    
    // MARK: - SpeechProviding Protocol Methods
    
    func speak(text: String, language: String) async {
        // 停止当前播放
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // 设置语言
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        
        // 设置语速、音调和音量
        utterance.rate = Float(currentRate)
        utterance.pitchMultiplier = 1.0
        utterance.volume = Float(currentVolume)
        
        // 播放语音
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    func pauseSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        }
    }
    
    func resumeSpeaking() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }
    
    func setVoice(for language: String) -> Bool {
        guard AVSpeechSynthesisVoice(language: language) != nil else {
            return false
        }
        return true
    }
    
    func preloadVoice(for language: String) async -> Bool {
        // AVSpeechSynthesizer doesn't have a preload method, so we just check if voice is available
        return setVoice(for: language)
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    func speak(text: String, language: String = "en-US") {
        Task {
            await speak(text: text, language: language)
        }
    }
    
    func speakWord(_ word: String) {
        speak(text: word, language: "en-US")
    }
    
    func speakChinese(_ text: String) {
        speak(text: text, language: "zh-CN")
    }
    
    func speakExample(_ example: String) {
        speak(text: example, language: "en-US")
    }
    
    func continueSpeaking() {
        resumeSpeaking()
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
} 
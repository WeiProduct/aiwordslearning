import SwiftUI

// MARK: - 可重用按钮组件
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var color: Color = .blue
    var isFullWidth: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .frame(maxWidth: isFullWidth ? .infinity : nil)
                .background(color)
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var color: Color = .gray
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(color.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 语音播放按钮组件
struct SpeechButton: View {
    let text: String
    let language: SpeechLanguage
    let speechManager: SpeechManager
    var size: ButtonSize = .medium
    var style: ButtonStyle = .primary
    
    enum ButtonSize {
        case small, medium, large
        
        var iconSize: Font {
            switch self {
            case .small: return .body
            case .medium: return .title2
            case .large: return .title
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 10
            case .large: return 14
            }
        }
    }
    
    enum ButtonStyle {
        case primary, secondary
        
        func color(for language: SpeechLanguage) -> Color {
            switch self {
            case .primary:
                return language == .english ? .blue : .orange
            case .secondary:
                return .gray
            }
        }
    }
    
    enum SpeechLanguage {
        case english, chinese, auto
        
        var code: String {
            switch self {
            case .english: return "en-US"
            case .chinese: return "zh-CN"
            case .auto: return "en-US" // 默认英文
            }
        }
        
        var icon: String {
            switch self {
            case .english: return "speaker.wave.2.fill"
            case .chinese: return "speaker.wave.1.fill"
            case .auto: return "speaker.wave.3.fill"
            }
        }
    }
    
    var body: some View {
        Button {
            speechManager.speak(text: text, language: language.code)
        } label: {
            Image(systemName: speechManager.isSpeaking ? "speaker.wave.3.fill" : language.icon)
                .font(size.iconSize)
                .foregroundColor(style.color(for: language))
                .padding(size.padding)
                .background(style.color(for: language).opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 进度条组件
struct CustomProgressView: View {
    let progress: Double
    let color: Color
    let height: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: height)
                    .opacity(0.3)
                    .foregroundColor(Color(.systemGray4))
                
                Rectangle()
                    .frame(width: min(CGFloat(progress) * geometry.size.width, geometry.size.width), height: height)
                    .foregroundColor(color)
                    .animation(.linear, value: progress)
            }
            .cornerRadius(height / 2)
        }
        .frame(height: height)
    }
}

// MARK: - 空状态视图组件
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let buttonAction: () -> Void
    var iconColor: Color = .gray
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            PrimaryButton(title: buttonTitle, action: buttonAction)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - 加载状态组件
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - 错误状态组件
struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("出现错误")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            PrimaryButton(
                title: "重试",
                action: retryAction,
                color: .orange
            )
            .frame(maxWidth: 200)
        }
        .padding()
    }
} 
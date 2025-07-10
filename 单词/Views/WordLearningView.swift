import SwiftUI
import SwiftData
import AVFoundation

struct WordLearningView: View {
    
    // MARK: - Dependencies
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var speechManager: SpeechManager
    @Query private var words: [Word]
    @Query private var userProgress: [UserProgress]
    
    // MARK: - State
    @State private var viewModel: WordLearningViewModel?
    
    var body: some View {
        NavigationView {
            Group {
                if let viewModel = viewModel {
                    if viewModel.isLoading {
                        LoadingView(message: "正在加载单词...")
                    } else if let errorMessage = viewModel.errorMessage {
                        ErrorView(
                            error: AppError.dataLoadingFailed(errorMessage),
                            retryAction: {
                                viewModel.configure(modelContext: modelContext, words: words)
                            }
                        )
                    } else if viewModel.hasValidSession {
                        learningContentView(viewModel: viewModel)
                    } else {
                        emptyStateView(viewModel: viewModel)
                    }
                } else {
                    LoadingView(message: "初始化中...")
                }
            }
            .navigationTitle("单词学习")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setupView()
            }
        }
    }
    
    // MARK: - Learning Content
    private func learningContentView(viewModel: WordLearningViewModel) -> some View {
        VStack(spacing: 0) {
            // 进度区域
            progressSection(viewModel: viewModel)
            
            // 主要内容
            ScrollView {
                VStack(spacing: AppConstants.UI.sectionSpacing) {
                    if let word = viewModel.currentWord {
                        EnhancedWordCard(
                            word: word,
                            showMeaning: Binding(
                                get: { viewModel.showMeaning },
                                set: { _ in }
                            ),
                            speechManager: speechManager
                        )
                        
                        controlButtonsSection(viewModel: viewModel)
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .onChange(of: viewModel.currentWordIndex) { _, _ in
            viewModel.handleWordIndexChange()
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showCompletionSheet },
            set: { _ in }
        )) {
            CompletionView(
                stats: viewModel.sessionStats,
                onContinue: {
                    viewModel.resetSession()
                }
            )
        }
    }
    
    // MARK: - Progress Section
    private func progressSection(viewModel: WordLearningViewModel) -> some View {
        VStack(spacing: 8) {
            CustomProgressView(
                progress: viewModel.progress,
                color: AppConstants.UI.Colors.primary,
                height: 6
            )
            .padding(.horizontal)
            
            HStack {
                Text("进度: \(viewModel.currentWordIndex)/\(viewModel.wordsToStudy.count)")
                    .font(AppConstants.UI.Typography.caption)
                    .foregroundColor(AppConstants.UI.Colors.secondary)
                
                Spacer()
                
                Text("AI智能学习")
                    .font(AppConstants.UI.Typography.caption)
                    .foregroundColor(AppConstants.UI.Colors.secondary)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Control Buttons
    private func controlButtonsSection(viewModel: WordLearningViewModel) -> some View {
        VStack(spacing: 16) {
            if !viewModel.showMeaning {
                PrimaryButton(
                    title: "显示含义",
                    action: viewModel.showWordMeaning,
                    color: AppConstants.UI.Colors.primary
                )
            } else {
                learningResultButtons(viewModel: viewModel)
            }
        }
    }
    
    private func learningResultButtons(viewModel: WordLearningViewModel) -> some View {
        HStack(spacing: 12) {
            PrimaryButton(
                title: "不认识",
                action: {
                    viewModel.markWordAsStudied(known: false)
                },
                color: AppConstants.UI.Colors.error
            )
            
            PrimaryButton(
                title: "认识",
                action: {
                    viewModel.markWordAsStudied(known: true)
                },
                color: AppConstants.UI.Colors.success
            )
        }
    }
    
    // MARK: - Empty State
    private func emptyStateView(viewModel: WordLearningViewModel) -> some View {
        EmptyStateView(
            icon: "checkmark.circle.fill",
            title: "太棒了！",
            subtitle: "你已经完成了今天的学习任务",
            buttonTitle: "开始新的学习",
            buttonAction: {
                viewModel.resetSession()
            },
            iconColor: AppConstants.UI.Colors.success
        )
    }
    
    // MARK: - Setup
    private func setupView() {
        if viewModel == nil {
            viewModel = WordLearningViewModel(speechManager: speechManager)
            viewModel?.configure(modelContext: modelContext, words: words)
        }
    }
}

// MARK: - Enhanced Word Card
struct EnhancedWordCard: View {
    let word: Word
    @Binding var showMeaning: Bool
    let speechManager: SpeechManager
    
    var body: some View {
        VStack(spacing: AppConstants.UI.sectionSpacing) {
            wordHeaderSection
            
            if showMeaning {
                Divider()
                meaningSection
                
                if !word.example.isEmpty {
                    exampleSection
                }
            }
        }
        .padding(AppConstants.UI.cardPadding)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private var wordHeaderSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(word.english)
                        .font(AppConstants.UI.Typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if !word.pronunciation.isEmpty && UserSettings.showPronunciation {
                        Text(word.pronunciation)
                            .font(AppConstants.UI.Typography.title)
                            .foregroundColor(AppConstants.UI.Colors.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    SpeechButton(
                        text: word.english,
                        language: .english,
                        speechManager: speechManager,
                        size: .large
                    )
                    
                    Text("播放")
                        .font(AppConstants.UI.Typography.caption)
                        .foregroundColor(AppConstants.UI.Colors.primary)
                }
            }
            
            if !word.partOfSpeech.isEmpty {
                HStack {
                    SecondaryButton(
                        title: word.partOfSpeech,
                        action: {},
                        color: AppConstants.UI.Colors.primary
                    )
                    
                    Spacer()
                    
                    DifficultyBadge(difficulty: word.difficulty)
                }
            }
        }
    }
    
    private var meaningSection: some View {
        HStack {
            Text(word.chinese)
                .font(AppConstants.UI.Typography.title)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            SpeechButton(
                text: word.chinese,
                language: .chinese,
                speechManager: speechManager,
                size: .medium
            )
        }
    }
    
    private var exampleSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("例句:")
                    .font(AppConstants.UI.Typography.headline)
                    .foregroundColor(AppConstants.UI.Colors.secondary)
                
                Spacer()
                
                SpeechButton(
                    text: word.example,
                    language: .english,
                    speechManager: speechManager,
                    size: .small
                )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(word.example)
                    .font(AppConstants.UI.Typography.body)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if !word.exampleTranslation.isEmpty {
                    Text(word.exampleTranslation)
                        .font(AppConstants.UI.Typography.body)
                        .foregroundColor(AppConstants.UI.Colors.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(AppConstants.UI.cornerRadius)
    }
}

// MARK: - Difficulty Badge
struct DifficultyBadge: View {
    let difficulty: Int
    
    private var difficultyColor: Color {
        switch difficulty {
        case 1: return AppConstants.UI.Colors.easyColor
        case 2: return AppConstants.UI.Colors.mediumColor
        case 3, 4, 5: return AppConstants.UI.Colors.hardColor
        default: return AppConstants.UI.Colors.mediumColor
        }
    }
    
    private var difficultyText: String {
        switch difficulty {
        case 1: return "简单"
        case 2: return "中等"
        case 3, 4, 5: return "困难"
        default: return "中等"
        }
    }
    
    var body: some View {
        Text(difficultyText)
            .font(AppConstants.UI.Typography.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(difficultyColor.opacity(0.1))
            .foregroundColor(difficultyColor)
            .cornerRadius(6)
    }
}

// MARK: - Enhanced Completion View
struct CompletionView: View {
    let stats: SessionStats
    let onContinue: () -> Void
    
    private var performanceIcon: String {
        if stats.accuracy >= 0.9 {
            return "star.fill"
        } else if stats.accuracy >= 0.7 {
            return "checkmark.circle.fill"
        } else {
            return "questionmark.circle.fill"
        }
    }
    
    private var performanceColor: Color {
        if stats.accuracy >= 0.9 {
            return .yellow
        } else if stats.accuracy >= 0.7 {
            return AppConstants.UI.Colors.success
        } else {
            return AppConstants.UI.Colors.warning
        }
    }
    
    private var performanceMessage: String {
        if stats.accuracy >= 0.9 {
            return "太棒了！"
        } else if stats.accuracy >= 0.7 {
            return "很好！"
        } else {
            return "继续努力！"
        }
    }
    
    var body: some View {
        VStack(spacing: AppConstants.UI.sectionSpacing) {
            Image(systemName: performanceIcon)
                .font(.system(size: 80))
                .foregroundColor(performanceColor)
            
            Text(performanceMessage)
                .font(AppConstants.UI.Typography.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Text("本次学习成果")
                    .font(AppConstants.UI.Typography.headline)
                    .foregroundColor(AppConstants.UI.Colors.secondary)
                
                HStack(spacing: 40) {
                    StatCard(
                        icon: "book.fill",
                        title: "学习单词",
                        value: "\(stats.wordsStudied)",
                        color: AppConstants.UI.Colors.primary
                    )
                    
                    StatCard(
                        icon: "clock.fill",
                        title: "学习时长",
                        value: stats.formattedTime,
                        color: AppConstants.UI.Colors.accent
                    )
                }
                
                StatCard(
                    icon: "percent",
                    title: "准确率",
                    value: String(format: "%.1f%%", stats.accuracy * 100),
                    color: performanceColor
                )
                .frame(maxWidth: 200)
            }
            
            PrimaryButton(
                title: "继续学习",
                action: onContinue,
                color: AppConstants.UI.Colors.primary
            )
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    WordLearningView()
        .modelContainer(for: [Word.self, UserProgress.self, StudySession.self], inMemory: true)
        .environmentObject(SpeechManager())
} 
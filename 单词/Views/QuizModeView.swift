import SwiftUI
import SwiftData
import AVFoundation

struct QuizModeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var speechManager: SpeechManager
    @Query private var words: [Word]
    @Query private var userProgress: [UserProgress]
    
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer = ""
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var correctAnswers = 0
    @State private var quizWords: [Word] = []
    @State private var currentOptions: [String] = []
    @State private var sessionStartTime = Date()
    @State private var showCompletionSheet = false
    @State private var hasAnswered = false
    
    let quizSize = 10
    
    var currentWord: Word? {
        guard !quizWords.isEmpty && currentQuestionIndex < quizWords.count else {
            return nil
        }
        return quizWords[currentQuestionIndex]
    }
    
    var progress: Double {
        guard !quizWords.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(quizWords.count)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 进度条
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                    .scaleEffect(x: 1, y: 4, anchor: .center)
                    .padding(.horizontal)
                
                // 进度和得分
                HStack {
                    Text("题目: \(currentQuestionIndex + 1)/\(quizWords.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("正确: \(correctAnswers)/\(currentQuestionIndex + (hasAnswered ? 1 : 0))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                if let word = currentWord {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 题目卡片
                            QuizQuestionCard(word: word, speechManager: speechManager)
                            
                            // 结果显示（移到选项上方）
                            if showResult {
                                resultSection
                            }
                            
                            // 下一题按钮（移到选项上方）
                            if showResult {
                                nextButton
                            }
                            
                            // 选项
                            optionsSection
                        }
                        .padding()
                    }
                } else {
                    emptyStateView
                }
                
                Spacer()
            }
            .navigationTitle("测试模式")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setupQuiz()
            }
            .onChange(of: currentQuestionIndex) { _, _ in
                // 切换到新问题时自动播放单词发音
                if let word = currentWord {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        speechManager.speakWord(word.english)
                    }
                }
            }
            .sheet(isPresented: $showCompletionSheet) {
                QuizCompletionView(
                    correctAnswers: correctAnswers,
                    totalQuestions: quizWords.count,
                    totalTime: Date().timeIntervalSince(sessionStartTime),
                    onRestart: {
                        setupQuiz()
                        showCompletionSheet = false
                    }
                )
            }
        }
    }
    
    private var optionsSection: some View {
        VStack(spacing: 12) {
            Text("选择正确的中文意思:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(currentOptions, id: \.self) { option in
                Button(action: {
                    if !hasAnswered {
                        selectAnswer(option)
                    }
                }) {
                    HStack {
                        Text(option)
                            .font(.body)
                            .foregroundColor(getOptionTextColor(option))
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        if hasAnswered {
                            if option == currentWord?.chinese {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else if option == selectedAnswer && !isCorrect {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(getOptionBackgroundColor(option))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(getOptionBorderColor(option), lineWidth: 2)
                    )
                }
                .disabled(hasAnswered)
            }
        }
    }
    
    private var resultSection: some View {
        VStack(spacing: 16) {
            // 回答结果提示
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(isCorrect ? .green : .red)
                
                Text(isCorrect ? "回答正确！" : "回答错误")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isCorrect ? .green : .red)
                
                Spacer()
            }
            
            // 显示正确答案（如果回答错误）
            if !isCorrect {
                HStack {
                    Text("正确答案: \(currentWord?.chinese ?? "")")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 播放正确答案发音
                    Button {
                        if let word = currentWord {
                            speechManager.speakChinese(word.chinese)
                        }
                    } label: {
                        Image(systemName: "speaker.wave.1.fill")
                            .font(.title3)
                            .foregroundColor(.orange)
                            .padding(8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            
            // 例句部分
            if let word = currentWord, !word.example.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        Text("例句:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // 播放例句按钮
                        Button {
                            speechManager.speakExample(word.example)
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(word.example)
                            .font(.body)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if !word.exampleTranslation.isEmpty {
                            Text(word.exampleTranslation)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: isCorrect ? .green.opacity(0.2) : .red.opacity(0.2), radius: 8, x: 0, y: 2)
        )
    }
    
    private var nextButton: some View {
        Button(action: {
            if currentQuestionIndex < quizWords.count - 1 {
                nextQuestion()
            } else {
                completeQuiz()
            }
        }) {
            HStack {
                Text(currentQuestionIndex < quizWords.count - 1 ? "下一题" : "完成测试")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Image(systemName: currentQuestionIndex < quizWords.count - 1 ? "arrow.right.circle.fill" : "checkmark.circle.fill")
                    .font(.title3)
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("暂无可测试的单词")
                .font(.title)
                .fontWeight(.bold)
            
            Text("请先学习一些单词再来测试")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: WordLearningView()) {
                Text("开始学习")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
    
    private func setupQuiz() {
        let learnedWords = words.filter { $0.isLearned }
        if learnedWords.count >= quizSize {
            quizWords = Array(learnedWords.shuffled().prefix(quizSize))
        } else {
            quizWords = Array(words.shuffled().prefix(min(quizSize, words.count)))
        }
        
        currentQuestionIndex = 0
        correctAnswers = 0
        sessionStartTime = Date()
        generateOptions()
        resetQuestionState()
        
        // 播放第一个单词的发音
        if let firstWord = quizWords.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                speechManager.speakWord(firstWord.english)
            }
        }
    }
    
    private func generateOptions() {
        guard let word = currentWord else { return }
        
        let allWords = words.filter { $0.english != word.english }
        let wrongOptions = Array(allWords.shuffled().prefix(3)).map { $0.chinese }
        
        var options = [word.chinese]
        options.append(contentsOf: wrongOptions)
        currentOptions = options.shuffled()
    }
    
    private func selectAnswer(_ answer: String) {
        selectedAnswer = answer
        isCorrect = answer == currentWord?.chinese
        hasAnswered = true
        
        if isCorrect {
            correctAnswers += 1
        }
        
        // 更新单词学习统计
        if let word = currentWord {
            word.learningCount += 1
            if isCorrect {
                word.correctCount += 1
            }
            word.lastStudyDate = Date()
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showResult = true
        }
        
        try? modelContext.save()
    }
    
    private func nextQuestion() {
        currentQuestionIndex += 1
        generateOptions()
        resetQuestionState()
    }
    
    private func resetQuestionState() {
        selectedAnswer = ""
        showResult = false
        isCorrect = false
        hasAnswered = false
    }
    
    private func completeQuiz() {
        // 停止当前播放
        speechManager.stopSpeaking()
        
        // 记录测试会话
        let session = StudySession(
            date: Date(),
            wordsStudied: quizWords.count,
            correctAnswers: correctAnswers,
            totalQuestions: quizWords.count,
            studyTime: Date().timeIntervalSince(sessionStartTime),
            sessionType: "quiz"
        )
        modelContext.insert(session)
        
        try? modelContext.save()
        showCompletionSheet = true
    }
    
    private func getOptionBackgroundColor(_ option: String) -> Color {
        if !hasAnswered {
            return Color(.systemGray6)
        }
        
        if option == currentWord?.chinese {
            return Color.green.opacity(0.2)
        } else if option == selectedAnswer && !isCorrect {
            return Color.red.opacity(0.2)
        } else {
            return Color(.systemGray6)
        }
    }
    
    private func getOptionTextColor(_ option: String) -> Color {
        if !hasAnswered {
            return .primary
        }
        
        if option == currentWord?.chinese {
            return .green
        } else if option == selectedAnswer && !isCorrect {
            return .red
        } else {
            return .secondary
        }
    }
    
    private func getOptionBorderColor(_ option: String) -> Color {
        if !hasAnswered {
            return .clear
        }
        
        if option == currentWord?.chinese {
            return .green
        } else if option == selectedAnswer && !isCorrect {
            return .red
        } else {
            return .clear
        }
    }
}

struct QuizQuestionCard: View {
    let word: Word
    let speechManager: SpeechManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("听音识义")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.1))
                .foregroundColor(.purple)
                .cornerRadius(20)
            
            Text("选择正确含义")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                HStack {
                    Text(word.english)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 播放按钮
                    Button {
                        speechManager.speakWord(word.english)
                    } label: {
                        Image(systemName: speechManager.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                            .padding(12)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if !word.pronunciation.isEmpty {
                    HStack {
                        Image(systemName: "speaker.wave.1")
                            .foregroundColor(.purple)
                        Text(word.pronunciation)
                            .font(.title2)
                            .foregroundColor(.purple)
                    }
                }
                
                if !word.partOfSpeech.isEmpty {
                    HStack {
                        Text(word.partOfSpeech)
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct QuizCompletionView: View {
    let correctAnswers: Int
    let totalQuestions: Int
    let totalTime: TimeInterval
    let onRestart: () -> Void
    
    private var formattedTime: String {
        let minutes = Int(totalTime) / 60
        let seconds = Int(totalTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var accuracy: Double {
        return totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) : 0.0
    }
    
    private var performanceIcon: String {
        if accuracy >= 0.9 {
            return "star.fill"
        } else if accuracy >= 0.7 {
            return "checkmark.circle.fill"
        } else {
            return "questionmark.circle.fill"
        }
    }
    
    private var performanceColor: Color {
        if accuracy >= 0.9 {
            return .yellow
        } else if accuracy >= 0.7 {
            return .green
        } else {
            return .orange
        }
    }
    
    private var performanceMessage: String {
        if accuracy >= 0.9 {
            return "太棒了！"
        } else if accuracy >= 0.7 {
            return "很好！"
        } else {
            return "继续努力！"
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: performanceIcon)
                .font(.system(size: 80))
                .foregroundColor(performanceColor)
            
            Text(performanceMessage)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Text("测试完成")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 40) {
                    VStack {
                        Text("\(correctAnswers)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("正确题数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(totalQuestions)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("总题数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text(formattedTime)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        Text("用时")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack {
                    Text(String(format: "%.1f%%", accuracy * 100))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(performanceColor)
                    Text("正确率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button("再次测试") {
                onRestart()
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.purple)
            .cornerRadius(12)
        }
        .padding()
    }
}

#Preview {
    QuizModeView()
        .modelContainer(for: [Word.self, UserProgress.self, StudySession.self], inMemory: true)
        .environmentObject(SpeechManager())
} 
import SwiftUI
import SwiftData
import Charts

struct ProgressStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProgress: [UserProgress]
    @Query private var sessions: [StudySession]
    @Query private var words: [Word]
    
    @State private var selectedTimeRange = TimeRange.week
    
    enum TimeRange: String, CaseIterable {
        case week = "本周"
        case month = "本月"
        case year = "今年"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 总体统计
                    overallStatsSection
                    
                    // 时间范围选择器
                    timeRangeSelector
                    
                    // 学习图表
                    studyChartSection
                    
                    // 今日学习详情
                    todayDetailsSection
                    
                    // 成就徽章
                    achievementsSection
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("学习统计")
        }
    }
    
    private var overallStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("学习概览")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            let progress = userProgress.first
            let totalLearned = progress?.totalWordsLearned ?? 0
            let currentStreak = progress?.currentStreak ?? 0
            let totalWords = words.count
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(
                    icon: "book.fill",
                    title: "累计学习",
                    value: "\(totalLearned)",
                    color: .blue
                )
                
                StatCard(
                    icon: "flame.fill",
                    title: "连续天数",
                    value: "\(currentStreak)",
                    color: .orange
                )
                
                StatCard(
                    icon: "target",
                    title: "学习进度",
                    value: "\(Int(Double(totalLearned) / Double(max(totalWords, 1)) * 100))%",
                    color: .green
                )
                
                StatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "今日学习",
                    value: "\(getTodayStudiedCount())",
                    color: .purple
                )
            }
        }
    }
    
    private var timeRangeSelector: some View {
        VStack(spacing: 16) {
            HStack {
                Text("学习趋势")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Picker("时间范围", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var studyChartSection: some View {
        VStack(spacing: 16) {
            // 学习数量图表
            studyCountChart
            
            // 正确率图表
            accuracyChart
        }
    }
    
    private var studyCountChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每日学习数量")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Chart(getChartData()) { item in
                BarMark(
                    x: .value("日期", item.date, unit: .day),
                    y: .value("单词数", item.wordsStudied)
                )
                .foregroundStyle(.blue.opacity(0.7))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var accuracyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习正确率")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Chart(getAccuracyData()) { item in
                LineMark(
                    x: .value("日期", item.date, unit: .day),
                    y: .value("正确率", item.accuracy)
                )
                .foregroundStyle(.green)
                .symbol(Circle().strokeBorder(lineWidth: 2))
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
            .chartYScale(domain: 0...1)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var todayDetailsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("今日学习")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            let todaySessions = getTodaySessions()
            let studiedCount = todaySessions.reduce(0) { $0 + $1.wordsStudied }
            let totalTime = todaySessions.reduce(0) { $0 + $1.studyTime }
            let avgAccuracy = todaySessions.isEmpty ? 0 : todaySessions.reduce(0) { $0 + $1.accuracy } / Double(todaySessions.count)
            
            HStack(spacing: 12) {
                DetailCard(
                    title: "已学单词",
                    value: "\(studiedCount)",
                    icon: "book.fill",
                    color: .blue
                )
                
                DetailCard(
                    title: "学习时长",
                    value: formatTime(totalTime),
                    icon: "clock.fill",
                    color: .green
                )
                
                DetailCard(
                    title: "平均正确率",
                    value: String(format: "%.0f%%", avgAccuracy * 100),
                    icon: "target",
                    color: .purple
                )
            }
        }
    }
    
    private var achievementsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("成就徽章")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            let progress = userProgress.first
            let totalLearned = progress?.totalWordsLearned ?? 0
            let currentStreak = progress?.currentStreak ?? 0
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                AchievementBadge(
                    title: "学习达人",
                    subtitle: "学习100个单词",
                    icon: "book.fill",
                    isUnlocked: totalLearned >= 100,
                    color: .blue
                )
                
                AchievementBadge(
                    title: "坚持不懈",
                    subtitle: "连续学习7天",
                    icon: "flame.fill",
                    isUnlocked: currentStreak >= 7,
                    color: .orange
                )
                
                AchievementBadge(
                    title: "测试高手",
                    subtitle: "测试正确率90%",
                    icon: "target",
                    isUnlocked: getHighestAccuracy() >= 0.9,
                    color: .green
                )
                
                AchievementBadge(
                    title: "每日目标",
                    subtitle: "完成每日任务",
                    icon: "checkmark.circle.fill",
                    isUnlocked: getTodayStudiedCount() >= (progress?.dailyGoal ?? 20),
                    color: .purple
                )
                
                AchievementBadge(
                    title: "词汇大师",
                    subtitle: "学习500个单词",
                    icon: "crown.fill",
                    isUnlocked: totalLearned >= 500,
                    color: .yellow
                )
                
                AchievementBadge(
                    title: "速度之王",
                    subtitle: "1分钟学习1个单词",
                    icon: "bolt.fill",
                    isUnlocked: checkSpeedAchievement(),
                    color: .red
                )
            }
        }
    }
    
    private func getChartData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        let daysToShow: Int
        
        switch selectedTimeRange {
        case .week:
            daysToShow = 7
        case .month:
            daysToShow = 30
        case .year:
            daysToShow = 365
        }
        
        var data: [ChartDataPoint] = []
        
        for i in 0..<daysToShow {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            let dayStart = calendar.startOfDay(for: date)
            
            let daySessions = sessions.filter { session in
                calendar.startOfDay(for: session.date) == dayStart
            }
            
            let wordsStudied = daySessions.reduce(0) { $0 + $1.wordsStudied }
            
            data.append(ChartDataPoint(date: date, wordsStudied: wordsStudied))
        }
        
        return data.reversed()
    }
    
    private func getAccuracyData() -> [AccuracyDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        let daysToShow = 7
        
        var data: [AccuracyDataPoint] = []
        
        for i in 0..<daysToShow {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            let dayStart = calendar.startOfDay(for: date)
            
            let daySessions = sessions.filter { session in
                calendar.startOfDay(for: session.date) == dayStart
            }
            
            let accuracy = daySessions.isEmpty ? 0 : daySessions.reduce(0) { $0 + $1.accuracy } / Double(daySessions.count)
            
            data.append(AccuracyDataPoint(date: date, accuracy: accuracy))
        }
        
        return data.reversed()
    }
    
    private func getTodaySessions() -> [StudySession] {
        let today = Calendar.current.startOfDay(for: Date())
        return sessions.filter { session in
            Calendar.current.startOfDay(for: session.date) == today
        }
    }
    
    private func getTodayStudiedCount() -> Int {
        return getTodaySessions().reduce(0) { $0 + $1.wordsStudied }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func getHighestAccuracy() -> Double {
        return sessions.map { $0.accuracy }.max() ?? 0.0
    }
    
    private func checkSpeedAchievement() -> Bool {
        // 检查是否有会话平均每分钟学习1个单词
        return sessions.contains { session in
            let wordsPerMinute = session.studyTime > 0 ? Double(session.wordsStudied) / (session.studyTime / 60) : 0
            return wordsPerMinute >= 1.0
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let wordsStudied: Int
}

struct AccuracyDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let accuracy: Double
}

struct DetailCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AchievementBadge: View {
    let title: String
    let subtitle: String
    let icon: String
    let isUnlocked: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isUnlocked ? color : .gray)
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isUnlocked ? .primary : .gray)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(isUnlocked ? color.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? color : .clear, lineWidth: 1)
        )
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    ProgressStatsView()
        .modelContainer(for: [Word.self, UserProgress.self, StudySession.self], inMemory: true)
} 
import SwiftUI
import SwiftData

struct SettingsView: View {
            @Environment(\.modelContext) private var modelContext
        @EnvironmentObject var wordDataManager: WordDataManager
    @Query private var userProgress: [UserProgress]
    
    @State private var notificationsEnabled = true
    @State private var dailyGoal = 20
    @State private var studyRemindersEnabled = true
    @State private var reminderTime = Date()
    @State private var soundEnabled = true
    @State private var showingResetAlert = false
    @State private var showingAbout = false
    @State private var showingVocabularySelection = false
    @State private var selectedVocabularyCategory: String?
    
    var body: some View {
        NavigationView {
            List {
                // 个人资料
                profileSection
                
                // 学习设置
                studySettingsSection
                
                // 通知设置
                notificationSettingsSection
                
                // 应用设置
                appSettingsSection
                
                // 数据管理
                dataManagementSection
                
                // 关于应用
                aboutSection
            }
            .navigationTitle("设置")
            .alert("重置数据", isPresented: $showingResetAlert) {
                Button("取消", role: .cancel) { }
                Button("确认重置", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("此操作将删除所有学习记录和进度，且无法恢复。确定要继续吗？")
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingVocabularySelection) {
                VocabularySelectionView()
            }
            .onAppear {
                loadSelectedVocabulary()
            }
        }
    }
    
    private var profileSection: some View {
        Section {
            HStack {
                // 头像
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Text("小明")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("小明")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let progress = userProgress.first {
                        Text("等级 \(progress.level) · 已学习 \(progress.totalWordsLearned) 个单词")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("连续学习 \(progress.currentStreak) 天")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        } header: {
            Text("个人资料")
        }
    }
    
    private var studySettingsSection: some View {
        Section {
            // 词汇选择
            Button(action: { showingVocabularySelection = true }) {
                HStack {
                    Image(systemName: "books.vertical.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Text("词汇库")
                    
                    Spacer()
                    
                    Text(getVocabularyCategoryName())
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .foregroundColor(.primary)
            
            // 每日目标
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("每日学习目标")
                
                Spacer()
                
                Stepper("\(dailyGoal) 个单词", value: $dailyGoal, in: 5...50, step: 5)
                    .labelsHidden()
                
                Text("\(dailyGoal)")
                    .foregroundColor(.secondary)
            }
            
            // 学习模式
            NavigationLink {
                StudyModeSettingsView()
            } label: {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("学习模式")
                    Spacer()
                    Text("卡片模式")
                        .foregroundColor(.secondary)
                }
            }
            
            // 难度设置
            NavigationLink {
                DifficultySettingsView()
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    Text("难度设置")
                    Spacer()
                    Text("自适应")
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("学习设置")
        }
        .onChange(of: dailyGoal) { newValue in
            updateDailyGoal(newValue)
        }
    }
    
    private var notificationSettingsSection: some View {
        Section {
            // 通知开关
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("推送通知")
                
                Spacer()
                
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
            }
            
            if notificationsEnabled {
                // 学习提醒
                HStack {
                    Image(systemName: "alarm")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Text("学习提醒")
                    
                    Spacer()
                    
                    Toggle("", isOn: $studyRemindersEnabled)
                        .labelsHidden()
                }
                
                if studyRemindersEnabled {
                    // 提醒时间
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        Text("提醒时间")
                        
                        Spacer()
                        
                        DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
            }
        } header: {
            Text("通知设置")
        } footer: {
            if notificationsEnabled {
                Text("系统将在设定时间提醒您进行单词学习")
            }
        }
    }
    
    private var appSettingsSection: some View {
        Section {
            // 声音效果
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("声音效果")
                
                Spacer()
                
                Toggle("", isOn: $soundEnabled)
                    .labelsHidden()
            }
            
            // 语言设置
            NavigationLink {
                LanguageSettingsView()
            } label: {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("语言")
                    Spacer()
                    Text("简体中文")
                        .foregroundColor(.secondary)
                }
            }
            
            // 主题设置
            NavigationLink {
                ThemeSettingsView()
            } label: {
                HStack {
                    Image(systemName: "paintbrush.fill")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    Text("主题")
                    Spacer()
                    Text("跟随系统")
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("应用设置")
        }
    }
    
    private var dataManagementSection: some View {
        Section {
            // 导出数据
            Button {
                exportData()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Text("导出学习数据")
                        .foregroundColor(.primary)
                }
            }
            
            // 导入数据
            Button {
                importData()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("导入数据")
                        .foregroundColor(.primary)
                }
            }
            
            // 重置数据
            Button {
                showingResetAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    Text("重置所有数据")
                        .foregroundColor(.red)
                }
            }
        } header: {
            Text("数据管理")
        } footer: {
            Text("导出功能可以备份您的学习进度")
        }
    }
    
    private var aboutSection: some View {
        Section {
            // 应用版本
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("版本")
                
                Spacer()
                
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            // 关于应用
            Button {
                showingAbout = true
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    Text("关于应用")
                        .foregroundColor(.primary)
                }
            }
            
            // 用户协议
            Link(destination: URL(string: "https://example.com/privacy")!) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("隐私政策")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 联系我们
            Link(destination: URL(string: "mailto:support@example.com")!) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    Text("联系我们")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("关于")
        }
    }
    
    private func updateDailyGoal(_ newGoal: Int) {
        if let progress = userProgress.first {
            progress.dailyGoal = newGoal
            try? modelContext.save()
        }
    }
    
    private func resetAllData() {
        // 删除所有数据
        try? modelContext.delete(model: Word.self)
        try? modelContext.delete(model: StudySession.self)
        try? modelContext.delete(model: UserProgress.self)
        
        // 重新初始化
        wordDataManager.setModelContext(modelContext)
        
        // 创建默认用户进度
        let progress = UserProgress()
        modelContext.insert(progress)
        
        try? modelContext.save()
    }
    
    private func exportData() {
        // 实现数据导出功能
        print("导出数据")
    }
    
    private func importData() {
        // 实现数据导入功能
        print("导入数据")
    }
    
    private func loadSelectedVocabulary() {
        selectedVocabularyCategory = UserDefaults.standard.string(forKey: "selectedVocabularyCategory")
    }
    
    private func getVocabularyCategoryName() -> String {
        guard let categoryString = selectedVocabularyCategory,
              let category = VocabularyCategory(rawValue: categoryString) else {
            return "默认词汇库"
        }
        return category.displayName
    }
}

// 占位视图
struct StudyModeSettingsView: View {
    var body: some View {
        Text("学习模式设置")
            .navigationTitle("学习模式")
    }
}

struct DifficultySettingsView: View {
    var body: some View {
        Text("难度设置")
            .navigationTitle("难度设置")
    }
}

struct LanguageSettingsView: View {
    var body: some View {
        Text("语言设置")
            .navigationTitle("语言")
    }
}

struct ThemeSettingsView: View {
    var body: some View {
        Text("主题设置")
            .navigationTitle("主题")
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App图标和名称
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("AI背单词App")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("完整原型设计")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    // 应用介绍
                    VStack(alignment: .leading, spacing: 16) {
                        Text("关于应用")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("AI背单词App是一款智能化的英语单词学习应用，采用科学的记忆曲线算法，为用户提供个性化的学习体验。")
                            .font(.body)
                        
                        Text("主要功能:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "book.fill", text: "智能单词学习")
                            FeatureRow(icon: "questionmark.circle.fill", text: "自适应测试")
                            FeatureRow(icon: "chart.bar.fill", text: "学习数据统计")
                            FeatureRow(icon: "heart.fill", text: "单词收藏管理")
                            FeatureRow(icon: "bell.fill", text: "学习提醒")
                        }
                    }
                    
                    // 版本信息
                    VStack(spacing: 8) {
                        Text("版本 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("© 2024 AI背单词App")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Word.self, UserProgress.self, StudySession.self], inMemory: true)
} 
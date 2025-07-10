//
//  ContentView.swift
//  单词
//
//  Created by weifu on 6/23/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProgress: [UserProgress]
    
    @State private var showWelcome = true
    
    var body: some View {
        Group {
            if showWelcome {
                WelcomeView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            // 检查是否为首次启动
            checkFirstLaunch()
        }
    }
    
    private func checkFirstLaunch() {
        // 如果用户进度存在，说明不是首次启动
        if let progress = userProgress.first, progress.totalWordsLearned > 0 {
            showWelcome = false
        }
        
        // 延迟3秒后自动进入主应用（仅在首次启动时）
        if showWelcome {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showWelcome = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Word.self, UserProgress.self, StudySession.self], inMemory: true)
}

//
//  __App.swift
//  单词
//
//  Created by weifu on 6/23/25.
//

import SwiftUI
import SwiftData

@main
struct 单词App: App {
    
    // 创建 SwiftData 模型容器
    let modelContainer: ModelContainer
    
    // 创建数据管理器
    @State private var wordDataManager = WordDataManager()
    
    // 创建语音管理器
    @StateObject private var speechManager = SpeechManager()
    
    init() {
        do {
            // 初始化模型容器
            modelContainer = try ModelContainer(for: Word.self, StudySession.self, UserProgress.self)
            print("SwiftData 容器初始化成功")
        } catch {
            print("无法初始化 SwiftData 容器: \(error)")
            fatalError("SwiftData initialization failed: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environmentObject(wordDataManager)
                .environmentObject(speechManager)
                .onAppear {
                    initializeApp()
                }
                .task {
                    // 异步初始化数据
                    await initializeData()
                }
        }
    }
    
    private func initializeApp() {
        print("应用启动初始化开始")
        
        // 设置数据管理器的模型上下文
        wordDataManager.setModelContext(modelContainer.mainContext)
        
        print("应用启动初始化完成")
    }
    
    private func initializeData() async {
        print("开始异步数据初始化")
        
        // 在后台线程初始化用户进度
        await MainActor.run {
            initializeUserProgressIfNeeded()
        }
        
        print("异步数据初始化完成")
    }
    
    private func initializeUserProgressIfNeeded() {
        let context = modelContainer.mainContext
        
        do {
            // 检查是否已有用户进度数据
            let descriptor = FetchDescriptor<UserProgress>()
            let existingProgress = try context.fetch(descriptor)
            
            if existingProgress.isEmpty {
                print("创建默认用户进度数据")
                let progress = UserProgress()
                context.insert(progress)
                try context.save()
                print("用户进度数据创建成功")
            } else {
                print("用户进度数据已存在：\(existingProgress.count) 条记录")
            }
        } catch {
            print("用户进度数据初始化失败：\(error)")
            // 创建最基本的用户进度
            let progress = UserProgress()
            context.insert(progress)
            do {
                try context.save()
                print("基本用户进度数据创建成功")
            } catch {
                print("基本用户进度数据创建也失败：\(error)")
            }
        }
    }
}

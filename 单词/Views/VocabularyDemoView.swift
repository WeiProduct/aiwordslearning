import SwiftUI

struct VocabularyDemoView: View {
    @State private var showVocabularySelection = false
    @State private var selectedCategory: VocabularyCategory? = nil
    @State private var currentLanguage = UserSettings.appLanguage
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 标题
                VStack(spacing: 8) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("词汇库演示")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("展示新的词汇选择功能")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // 当前选择
                VStack(spacing: 16) {
                    Text("当前词汇库")
                        .font(.headline)
                    
                    if let category = selectedCategory {
                        VStack(spacing: 8) {
                            Text(currentLanguage == .chinese ? category.displayName : category.englishDisplayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(category.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            HStack {
                                Label("\(category.wordCount) 词", systemImage: "text.book.closed")
                                Label("难度 \(category.difficulty)", systemImage: "star.fill")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        Text("未选择词汇库")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // 选择按钮
                Button(action: { showVocabularySelection = true }) {
                    Label("选择词汇库", systemImage: "books.vertical")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // 词汇分类预览
                VStack(alignment: .leading, spacing: 16) {
                    Text("可用词汇分类")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(VocabularyGroup.allCases, id: \.self) { group in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(currentLanguage == .chinese ? group.displayName : group.englishDisplayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(group.categories, id: \.self) { category in
                                                VocabularyMiniCard(
                                                    category: category,
                                                    isSelected: selectedCategory == category,
                                                    language: currentLanguage
                                                ) {
                                                    selectedCategory = category
                                                    UserDefaults.standard.set(category.rawValue, forKey: "selectedVocabularyCategory")
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("词汇库功能")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(currentLanguage == .chinese ? "切换语言" : "Switch Language") {
                        withAnimation {
                            currentLanguage = currentLanguage == .chinese ? .english : .chinese
                            UserSettings.appLanguage = currentLanguage
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showVocabularySelection) {
            VocabularySelectionView()
        }
        .onAppear {
            if let savedCategory = UserDefaults.standard.string(forKey: "selectedVocabularyCategory"),
               let category = VocabularyCategory(rawValue: savedCategory) {
                selectedCategory = category
            }
        }
    }
}

// MARK: - Mini Card View
struct VocabularyMiniCard: View {
    let category: VocabularyCategory
    let isSelected: Bool
    let language: UserSettings.AppLanguage
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(language == .chinese ? category.displayName : category.englishDisplayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text("\(category.wordCount)")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    VocabularyDemoView()
}
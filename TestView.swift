//
//  TestView.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import SwiftUI

struct TestView: View {
    @ObservedObject var viewModel: VerbQuizViewModel
    @ObservedObject var resultsManager: TestResultsManager
    @StateObject private var audioManager = AudioManager()
    @State private var showWhyPopup = false
    @State private var showTranslation = false
    @State private var showScoreAlert = false
    
    init(viewModel: VerbQuizViewModel, resultsManager: TestResultsManager) {
        self.viewModel = viewModel
        self.resultsManager = resultsManager
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    if viewModel.testQuestions.isEmpty {
                    // Start test screen
                    VStack(spacing: 32) {
                        Spacer()
                        
                        // Icon
                        Image("verbs")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.primary)
                        
                        // Title
                        Text("Verbs")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.top, 20)
                        
                        // Descriptive text
                        Text("Master Swedish verb conjugations with 10 random questions per round. Practice, review instant explanations, and level up. Lycka till!")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .foregroundColor(.primary)
                    
                        // Start new test button
                        Button(action: {
                            viewModel.startNewTest()
                        }) {
                            Text("Start new test")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        
                        // My previous tests button
                        Button(action: {
                            // Navigate to history with Verbs filter
                            NotificationCenter.default.post(name: NSNotification.Name("NavigateToHistory"), object: nil, userInfo: ["filter": "Verbs"])
                        }) {
                            Text("My previous tests")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                        
                        Spacer()
                    }
                    .padding()
                } else if let question = viewModel.currentQuestion, let verbData = viewModel.verbData {
                    // Main content with fixed spacing
                    VStack(spacing: 0) {
                        // Question progress indicator
                        ProgressIndicatorView(
                            currentIndex: viewModel.currentQuestionIndex,
                            totalCount: viewModel.testQuestions.count,
                            questionResults: viewModel.questionResults
                        )
                        .padding(.top, 20)
                        .padding(.bottom, 60)
                        .padding(.horizontal, 30)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentQuestionIndex)
                        
                        // Sentence
                        VStack(spacing: 12) {
                        ZStack(alignment: .trailing) {
                        SentenceView(
                            sentence: question.sentence,
                            answer: viewModel.selectedAnswerText,
                            isCorrect: viewModel.isCorrect,
                            showAnswer: viewModel.showFeedback,
                            correctAnswer: question.answer
                        )
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .padding([.leading, .top, .bottom])
                        .padding(.trailing, 50)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                            
                            // Audio button - small icon on the right inside the frame
                            Button(action: {
                                let sentenceWithAnswer = question.sentence.replacingOccurrences(of: "____", with: question.answer)
                                if viewModel.showFeedback {
                                    // After answering, play full sentence without beep
                                    audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: nil)
                                } else {
                                    // Before answering, play with beep
                                    audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: question.answer)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    audioManager.playAudio()
                                }
                            }) {
                                Image("audio-headphone")
                                    .resizable()
                                    .renderingMode(.template)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                                    .padding(8)
                            }
                            .disabled(!audioManager.isAudioReady || audioManager.isPlaying)
                            .opacity((audioManager.isAudioReady && !audioManager.isPlaying) ? 1.0 : 0.4)
                            .padding(.trailing, 8)

                        }
                        
                        // Translation - toggleable with eye icon, blurred when hidden
                        ZStack {
                            // Translation text - always present, blurred when hidden
                            translationText(question.translation, answer: question.answer)
                                .font(UIScreen.main.bounds.width >= 414 ? .caption : .subheadline) // Smaller on iPhone Plus
                                .italic()
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading)
                                .blur(radius: (showTranslation || viewModel.showFeedback) ? 0 : 8)
                            
                            // Toggle button with eye icon - positioned on the right
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        showTranslation.toggle()
                                    }
                                }) {
                                    Image(systemName: (showTranslation || viewModel.showFeedback) ? "eye" : "eye.slash")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.trailing)
                        }
                        .frame(height: 30) // Fixed height to prevent layout shift
                        .padding(.vertical, 2)
                    }
                    .padding(.horizontal)
                    
                    // Options
                    VStack(spacing: 15) {
                        ForEach(0..<question.options.count, id: \.self) { index in
                            Button(action: {
                                withAnimation {
                                    viewModel.selectAnswer(index)
                                }
                            }) {
                                ZStack {
                                    // Centered text
                                    Text(question.options[index])
                                        .font(.headline)
                                        .foregroundColor(buttonTextColor(for: index))
                                    
                                    // Icon on the right (when feedback is shown)
                                    if viewModel.showFeedback, let icon = iconName(for: index) {
                                        HStack {
                                            Spacer()
                                            Image(icon)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 20, height: 20)
                                                .padding(.trailing)
                                        }
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(buttonBackgroundColor(for: index))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(buttonBorderColor(for: index), lineWidth: 1)
                                )
                            }
                            .disabled(viewModel.showFeedback)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 50)
                    // Add bottom padding to reserve space for feedback
                    Spacer()
                        .frame(height: 80) // Fixed space for feedback section
                }
                .padding(.bottom, 80) // Reserve space at bottom for feedback overlay
                
                    
                    
                } else if viewModel.exercises.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("No questions available")
                            .font(.headline)
                        Text("Please ensure verbData.json is included in the app bundle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ProgressView("Loading questions...")
                }
            }
            
            // Feedback section - always present, positioned at bottom
                if viewModel.currentQuestion != nil {
                    VStack(spacing: 12) {
                        // Feedback message - fixed height
                        ZStack {
                            if viewModel.showFeedback {
                                if viewModel.isCorrect {
                                    HStack {
                                        Image("correct")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 20, height: 20)
                                        Text("Correct!")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.bottom, 8) // Add bottom padding
                                } else {
                                    HStack {
                                        Image("wrong")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 20, height: 20)
                                        Text("Incorrect!")
                                            .font(.headline)
                                            .foregroundColor(.red)
                                        
                                        Button(action: {
                                            showWhyPopup = true
                                        }) {
                                            Text("Why?")
                                                .font(.headline)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .cornerRadius(8)
                                        }
                                    }
                                    .padding(.bottom, 8) // Add bottom padding
                                }
                            }
                        }
                        .frame(height: 70) // Fixed height (increased to accommodate padding)
                        .opacity(viewModel.showFeedback ? 1.0 : 0.0)
                        
                        // Buttons - fixed height
                        ZStack {
                            if viewModel.showFeedback && viewModel.currentQuestionIndex == viewModel.testQuestions.count - 1 {
                                // Last question - show two buttons
                                HStack(spacing: 12) {
                                    Button(action: {
                                        withAnimation {
                                            viewModel.stopTest()
                                        }
                                    }) {
                                        Text("Close")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.gray)
                                            .cornerRadius(12)
                                    }
                                    
                                    Button(action: {
                                        withAnimation {
                                            viewModel.startNewTest()
                                        }
                                    }) {
                                        Text("New Test")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.blue)
                                            .cornerRadius(12)
                                    }
                                }
                                .onAppear {
                                    // Save result when buttons appear (last question answered)
                                    let result = TestResult(
                                        score: viewModel.currentScore,
                                        totalQuestions: viewModel.totalQuestions,
                                        testType: "Verbs",
                                        verbQuestions: viewModel.testQuestions,
                                        pronounQuestions: nil,
                                        questionResults: viewModel.questionResults
                                    )
                                    resultsManager.saveResult(result)
                                    // Show score alert
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        showScoreAlert = true
                                    }
                                }
                            } else {
                                // Not last question - show single button (always visible)
                                Button(action: {
                                    withAnimation {
                                        viewModel.nextQuestion()
                                    }
                                }) {
                                Text("Next")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(viewModel.showFeedback ? Color.blue : Color.gray)
                                    .cornerRadius(12)
                                }
                                .disabled(!viewModel.showFeedback)
                            }
                        }
                        .frame(height: 50) // Fixed height
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical)
            .navigationTitle("Verbs Test")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.testQuestions.isEmpty {
                        Button(action: {
                            viewModel.stopTest()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.red)
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .clipped()
            .id("TestView")
            .alert(isPresented: $showWhyPopup) {
                Alert(
                    title: Text("The correct answer is: \(viewModel.currentQuestion?.answer ?? "")"),
                    message: Text(viewModel.currentQuestion?.rule ?? ""),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Test Complete!", isPresented: $showScoreAlert) {
                Button("OK") {
                    showScoreAlert = false
                }
            } message: {
                let score = viewModel.currentScore
                let total = viewModel.totalQuestions
                guard total > 0 else {
                    return Text("Your score: \(score)/\(total)")
                        .fontWeight(.bold)
                }
                let percentage = Int((Double(score) / Double(total)) * 100)
                return Text("Your score: \(score)/\(total) (\(percentage)%)")
                    .fontWeight(.bold)
            }
                            .onChange(of: viewModel.currentQuestionIndex) {
                                audioManager.cleanupAudio()
                                showTranslation = false // Reset translation visibility for new question
                                if let question = viewModel.currentQuestion {
                                    let sentenceWithAnswer = question.sentence.replacingOccurrences(of: "____", with: question.answer)
                                    audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: question.answer)
                                }
                            }
                            .onChange(of: viewModel.testQuestions.count) {
                                // Generate audio when test starts (testQuestions becomes non-empty)
                                if !viewModel.testQuestions.isEmpty {
                                    audioManager.cleanupAudio()
                                    if let question = viewModel.currentQuestion {
                                        let sentenceWithAnswer = question.sentence.replacingOccurrences(of: "____", with: question.answer)
                                        audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: question.answer)
                                    }
                                }
                            }
                            .onAppear {
                                if let question = viewModel.currentQuestion {
                                    let sentenceWithAnswer = question.sentence.replacingOccurrences(of: "____", with: question.answer)
                                    audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: question.answer)
                                }
                            }
                            .onDisappear {
                                audioManager.cleanupAudio()
                            }
            .sheet(isPresented: $viewModel.showResults) {
                TestResultsView(
                    score: viewModel.currentScore,
                    totalQuestions: viewModel.totalQuestions,
                    onNewTest: {
                        viewModel.startNewTest()
                    },
                    onClose: {
                        viewModel.startNewTest() // Reset when closing
                    },
                    onSave: {
                        let result = TestResult(score: viewModel.currentScore, totalQuestions: viewModel.totalQuestions, testType: "Verbs")
                        resultsManager.saveResult(result)
                    }
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func buttonTextColor(for index: Int) -> Color {
        // Always use primary color - icons provide feedback
        return .primary
    }
    
    private func buttonBackgroundColor(for index: Int) -> Color {
        if viewModel.showFeedback {
            guard let question = viewModel.currentQuestion else {
                return Color(.systemGray6)
            }
            
            // Show light green background for correct answer
            if question.options[index] == question.answer {
                return Color.green.opacity(0.2) // Light green
            }
            // Show light red background for wrong selected answer
            else if !viewModel.isCorrect && index == viewModel.selectedAnswer {
                return Color.red.opacity(0.2) // Light red
            }
        }
        
        return Color(.systemGray6)
    }
    
    private func buttonBorderColor(for index: Int) -> Color {
        return Color.gray.opacity(0.3)
    }
    
    private func iconName(for index: Int) -> String? {
        guard let question = viewModel.currentQuestion else { return nil }
        
        if viewModel.isCorrect && index == viewModel.selectedAnswer {
            return "correct"
        } else if !viewModel.isCorrect {
            if index == viewModel.selectedAnswer {
                return "wrong"
            } else if question.options[index] == question.answer {
                return "correct"
            }
        }
        return nil
    }
    
    @ViewBuilder
    private func translationText(_ translation: String, answer: String) -> some View {
        // For verbs, the answer is an adjective form. We need to find the base form
        // and then find the corresponding English adjective in the translation
        let baseAdjective = viewModel.currentQuestion?.baseAdjective ?? ""
        
        // Try to find the English equivalent by looking at the position in the sentence
        // The answer appears where the blank is in the Swedish sentence
        let swedishParts = (viewModel.currentQuestion?.sentence ?? "").components(separatedBy: "____")
        let swedishBeforeBlank = swedishParts[0]
        
        // Count words before the blank in Swedish
        let wordsBeforeBlank = swedishBeforeBlank.split(separator: " ", omittingEmptySubsequences: true).count
        
        // Split translation into words
        let translationWords = translation.split(separator: " ", omittingEmptySubsequences: true)
        
        var result = Text("")
        var isFirst = true
        
        for (index, word) in translationWords.enumerated() {
            if !isFirst {
                result = result + Text(" ")
            }
            
            // Make the word at the same position as the blank bold
            if index == wordsBeforeBlank {
                result = result + Text(String(word))
                    .fontWeight(.bold)
            } else {
                result = result + Text(String(word))
            }
            isFirst = false
        }
        
        return result
    }
}

struct SentenceView: View {
    let sentence: String
    let answer: String?
    let isCorrect: Bool
    let showAnswer: Bool
    let correctAnswer: String?
    
    @State private var animateAnswer = false
    @Environment(\.colorScheme) var colorScheme
    
    // Fixed font size to prevent size changes - smaller on iPhone Plus devices
    private var fontSize: Font {
        let screenWidth = UIScreen.main.bounds.width
        return screenWidth >= 414 ? .body : .title3 // iPhone Plus and larger
    }
    
    // Check if device is iPhone Plus
    private var isIPhonePlus: Bool {
        UIScreen.main.bounds.width >= 414
    }
    
    // Line limit based on device
    private var lineLimit: Int {
        isIPhonePlus ? 2 : 1
    }
    
    var body: some View {
        let parts = sentence.components(separatedBy: "____")
        let trimmedParts = parts.map { $0.trimmingCharacters(in: .whitespaces) }
        
        if showAnswer, let _ = answer, let correctAnswer = correctAnswer, trimmedParts.count > 1 {
            // Replace ____ with the correct answer (always black)
            Group {
                if isIPhonePlus {
                    // On iPhone Plus, use Text that can wrap to 2 lines
                    let beforePart = trimmedParts[0].isEmpty ? "" : trimmedParts[0] + " "
                    let afterPart = trimmedParts.count > 1 && !trimmedParts[1].isEmpty ? " " + trimmedParts[1] : ""
                    Text(beforePart + correctAnswer + afterPart)
                        .font(fontSize)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    // On regular iPhones, use HStack (single line) with explicit space after answer
                    HStack(spacing: 4) {
                        if !trimmedParts[0].isEmpty {
                            Text(trimmedParts[0])
                                .font(fontSize)
                        }
                        
                        Text(correctAnswer)
                            .font(fontSize)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .fontWeight(.bold)
                            .scaleEffect(animateAnswer ? 1.0 : 0.3)
                            .offset(y: animateAnswer ? 0 : 30)
                            .opacity(animateAnswer ? 1.0 : 0.0)
                        
                        if trimmedParts.count > 1 && !trimmedParts[1].isEmpty {
                            Text(" ") // Explicit space after the answer
                                .font(fontSize)
                            Text(trimmedParts[1])
                                .font(fontSize)
                        }
                    }
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .id("\(sentence)-\(correctAnswer)-\(showAnswer)") // Force view refresh
            .onAppear {
                if !isIPhonePlus {
                    // Reset animation state (only for HStack version)
                    animateAnswer = false
                    // Trigger animation with a slight delay for better effect
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            animateAnswer = true
                        }
                    }
                }
            }
        } else if let correctAnswer = correctAnswer, trimmedParts.count > 1 {
            // Show sentence with ____ in place of the answer
                if isIPhonePlus {
                    // On iPhone Plus, use Text that can wrap to 2 lines (space after ____)
                    let afterBlank = trimmedParts.count > 1 && !trimmedParts[1].isEmpty ? " " + trimmedParts[1] : ""
                    Text(trimmedParts[0] + " ____" + afterBlank)
                        .font(fontSize)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    // On regular iPhones, use HStack (single line) with explicit space after ____
                    HStack(spacing: 4) {
                        if !trimmedParts[0].isEmpty {
                            Text(trimmedParts[0])
                                .font(fontSize)
                        }
                        
                        // Show ____ instead of blurred answer
                        Text("____")
                            .font(fontSize)
                            .foregroundColor(.primary)
                        
                        if trimmedParts.count > 1 && !trimmedParts[1].isEmpty {
                            Text(" ") // Explicit space after the blank
                                .font(fontSize)
                            Text(trimmedParts[1])
                                .font(fontSize)
                        }
                    }
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            // Fallback: Show original sentence with blank
            Text(sentence)
                .font(fontSize)
                .lineLimit(lineLimit)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct InstructionTextView: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(colorScheme == .dark ? .white : .secondary)
    }
}

struct ProgressIndicatorView: View {
    let currentIndex: Int
    let totalCount: Int
    let questionResults: [Int: Bool] // Not used in simple version, but kept for compatibility
    
    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex + 1) / Double(totalCount)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress text
            Text("\(currentIndex + 1)/\(totalCount) Questions")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Gray background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    // Blue progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    TestView(viewModel: VerbQuizViewModel(), resultsManager: TestResultsManager())
}

//
//  ReflexiveTestView.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import SwiftUI

struct ReflexiveTestView: View {
    @ObservedObject var viewModel: ReflexiveQuizViewModel
    @ObservedObject var resultsManager: TestResultsManager
    @StateObject private var audioManager = AudioManager()
    @State private var showWhyPopup = false
    @State private var showTranslation = false
    @State private var showScoreAlert = false
    
    init(viewModel: ReflexiveQuizViewModel, resultsManager: TestResultsManager) {
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
                        Text("Reflexiva pronomen")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.top, 20)
                        
                        // Descriptive text
                        Text("Master Swedish reflexive pronouns with 10 random questions per round. Practice, review instant explanations, and level up. Lycka till!")
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
                            NotificationCenter.default.post(name: NSNotification.Name("NavigateToHistory"), object: nil, userInfo: ["filter": "Reflexiva pronomen"])
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
                } else if let question = viewModel.currentQuestion, let _ = viewModel.reflexiveData {
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
                            
                            // Audio button
                            Button(action: {
                                let sentenceWithAnswer = question.sentence.replacingOccurrences(of: "____", with: question.answer)
                                if viewModel.showFeedback {
                                    audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: nil)
                                } else {
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
                        
                        // Translation
                        ZStack {
                            translationText(question.translation, answer: question.answer)
                                .font(UIScreen.main.bounds.width >= 414 ? .caption : .subheadline)
                                .italic()
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading)
                                .blur(radius: (showTranslation || viewModel.showFeedback) ? 0 : 8)
                            
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
                        .frame(height: 30)
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
                                    Text(question.options[index])
                                        .font(.headline)
                                        .foregroundColor(buttonTextColor(for: index))
                                    
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
                    Spacer()
                        .frame(height: 80)
                }
                .padding(.bottom, 80)
                
                } else if viewModel.exercises.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("No questions available")
                            .font(.headline)
                        Text("Please ensure reflexiveData.json is included in the app bundle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ProgressView("Loading questions...")
                }
            }
            
            // Feedback section
                if viewModel.currentQuestion != nil {
                    VStack(spacing: 12) {
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
                                    .padding(.bottom, 8)
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
                                    .padding(.bottom, 8)
                                }
                            }
                        }
                        .frame(height: 70)
                        .opacity(viewModel.showFeedback ? 1.0 : 0.0)
                        
                        ZStack {
                            if viewModel.showFeedback && viewModel.currentQuestionIndex == viewModel.testQuestions.count - 1 {
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
                                    let result = TestResult(
                                        score: viewModel.currentScore,
                                        totalQuestions: viewModel.totalQuestions,
                                        testType: "Reflexiva pronomen",
                                        verbQuestions: nil,
                                        pronounQuestions: nil,
                                        nounGenderQuestions: nil,
                                        reflexiveQuestions: viewModel.testQuestions,
                                        questionResults: viewModel.questionResults
                                    )
                                    resultsManager.saveResult(result)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        showScoreAlert = true
                                    }
                                }
                            } else {
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
                        .frame(height: 50)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical)
            .navigationTitle("Reflexiva pronomen")
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
            .id("ReflexiveTestView")
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
                showTranslation = false
                if let question = viewModel.currentQuestion {
                    let sentenceWithAnswer = question.sentence.replacingOccurrences(of: "____", with: question.answer)
                    audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: question.answer)
                }
            }
            .onChange(of: viewModel.testQuestions.count) {
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
                        viewModel.startNewTest()
                    },
                    onSave: {
                        let result = TestResult(score: viewModel.currentScore, totalQuestions: viewModel.totalQuestions, testType: "Reflexiva pronomen", verbQuestions: nil, pronounQuestions: nil, nounGenderQuestions: nil, reflexiveQuestions: viewModel.testQuestions)
                        resultsManager.saveResult(result)
                    }
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func buttonTextColor(for index: Int) -> Color {
        return .primary
    }
    
    private func buttonBackgroundColor(for index: Int) -> Color {
        if viewModel.showFeedback {
            guard let question = viewModel.currentQuestion else {
                return Color(.systemGray6)
            }
            
            if question.options[index] == question.answer {
                return Color.green.opacity(0.2)
            }
            else if !viewModel.isCorrect && index == viewModel.selectedAnswer {
                return Color.red.opacity(0.2)
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
        let swedishParts = (viewModel.currentQuestion?.sentence ?? "").components(separatedBy: "____")
        let swedishBeforeBlank = swedishParts[0]
        let wordsBeforeBlank = swedishBeforeBlank.split(separator: " ", omittingEmptySubsequences: true).count
        let translationWords = translation.split(separator: " ", omittingEmptySubsequences: true)
        
        var result = Text("")
        var isFirst = true
        
        for (index, word) in translationWords.enumerated() {
            if !isFirst {
                result = result + Text(" ")
            }
            
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

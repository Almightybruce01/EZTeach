//
//  MathMultiplicationGameView.swift
//  EZTeach
//
//  A unique multiplication game with an array/grid visual theme
//

import SwiftUI

struct MathMultiplicationGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var factor1 = 0
    @State private var factor2 = 0
    @State private var options: [Int] = []
    @State private var score = 0
    @State private var round = 0
    @State private var selected: Int?
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var gameOver = false
    @State private var streak = 0
    @State private var showGrid = true
    @State private var gridScale: CGFloat = 0.5
    
    private let totalRounds = 12
    private let gridColors: [Color] = [.orange, .pink, .cyan, .green, .purple, .yellow]
    
    private var correctAnswer: Int { factor1 * factor2 }
    
    var body: some View {
        ZStack {
            // Warm gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.85, blue: 0.7),
                    Color(red: 0.9, green: 0.8, blue: 0.65)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if gameOver {
                gameOverView
            } else {
                VStack(spacing: 20) {
                    headerView
                    
                    // Visual grid showing multiplication as area
                    gridVisualization
                    
                    // Question
                    questionView
                    
                    // Options
                    optionsView
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle(gameTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            generateQuestion()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("MULTIPLICATION")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                Text("Array Builder")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
            }
            
            Spacer()
            
            // Streak indicator
            if streak >= 2 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                    Text("\(streak)")
                }
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange)
                .cornerRadius(12)
            }
            
            VStack(alignment: .trailing) {
                Text("Round \(round + 1)/\(totalRounds)")
                    .font(.caption)
                    .foregroundColor(.brown.opacity(0.7))
                Text("\(score)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .orange.opacity(0.2), radius: 8, y: 4)
        )
    }
    
    private var gridVisualization: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(factor1) rows")
                    .font(.caption.bold())
                    .foregroundColor(.brown)
                Spacer()
                Text("\(factor2) columns")
                    .font(.caption.bold())
                    .foregroundColor(.brown)
            }
            .padding(.horizontal)
            
            // Grid of dots/squares
            VStack(spacing: 6) {
                ForEach(0..<factor1, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<factor2, id: \.self) { col in
                            let index = row * factor2 + col
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [gridColors[index % gridColors.count], gridColors[index % gridColors.count].opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: gridSize, height: gridSize)
                                .shadow(color: gridColors[index % gridColors.count].opacity(0.4), radius: 3)
                                .scaleEffect(showGrid ? 1.0 : 0.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6).delay(Double(index) * 0.02), value: showGrid)
                        }
                    }
                }
            }
            .scaleEffect(gridScale)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .orange.opacity(0.15), radius: 8, y: 4)
            )
        }
        .frame(height: 180)
    }
    
    private var gridSize: CGFloat {
        let maxDim = max(factor1, factor2)
        return max(16, min(32, 150 / CGFloat(maxDim)))
    }
    
    private var questionView: some View {
        HStack(spacing: 12) {
            numberBox(factor1, color: .pink)
            Text("×")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(.brown)
            numberBox(factor2, color: .cyan)
            Text("=")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(.brown)
            Text("?")
                .font(.system(size: 36, weight: .black))
                .foregroundColor(.orange)
                .frame(width: 60)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .orange.opacity(0.15), radius: 8, y: 4)
        )
    }
    
    private func numberBox(_ num: Int, color: Color) -> some View {
        Text("\(num)")
            .font(.system(size: 36, weight: .black))
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: 4, y: 2)
            )
    }
    
    private var optionsView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(options, id: \.self) { option in
                Button {
                    selectOption(option)
                } label: {
                    Text("\(option)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(optionTextColor(option))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(optionBgColor(option))
                                .shadow(color: .orange.opacity(0.2), radius: 6, y: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(optionBorderColor(option), lineWidth: 3)
                        )
                }
                .disabled(selected != nil)
                .scaleEffect(selected == option ? 1.05 : 1.0)
            }
        }
    }
    
    private func optionTextColor(_ option: Int) -> Color {
        if let sel = selected {
            if option == correctAnswer { return .white }
            if option == sel { return .white }
        }
        return .brown
    }
    
    private func optionBgColor(_ option: Int) -> Color {
        if let sel = selected {
            if option == correctAnswer { return .green }
            if option == sel && sel != correctAnswer { return .red.opacity(0.8) }
        }
        return .white
    }
    
    private func optionBorderColor(_ option: Int) -> Color {
        if let sel = selected {
            if option == correctAnswer { return .green }
            if option == sel && sel != correctAnswer { return .red }
        }
        return .orange.opacity(0.3)
    }
    
    private var gameOverView: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            Text("Multiplication Master!")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.brown)
            
            Text("Score: \(score)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.orange)
            
            // Stars based on performance
            HStack(spacing: 8) {
                ForEach(0..<starRating, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.title)
                        .foregroundColor(.yellow)
                }
                ForEach(0..<(3 - starRating), id: \.self) { _ in
                    Image(systemName: "star")
                        .font(.title)
                        .foregroundColor(.gray.opacity(0.4))
                }
            }
            
            HStack(spacing: 16) {
                Button {
                    resetGame()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Exit")
                        .font(.headline)
                        .foregroundColor(.brown)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.brown.opacity(0.3), lineWidth: 2)
                        )
                }
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.98, green: 0.95, blue: 0.9))
                .shadow(radius: 20)
        )
        .padding()
    }
    
    private var starRating: Int {
        let percentage = Double(score) / Double(totalRounds * 15)
        if percentage >= 0.8 { return 3 }
        if percentage >= 0.5 { return 2 }
        if percentage >= 0.3 { return 1 }
        return 0
    }
    
    private func generateQuestion() {
        factor1 = Int.random(in: 2...6)
        factor2 = Int.random(in: 2...6)
        selected = nil
        showResult = false
        showGrid = false
        
        // Generate options
        var opts = Set<Int>()
        opts.insert(correctAnswer)
        while opts.count < 4 {
            let offset = Int.random(in: -5...5)
            let wrong = correctAnswer + offset
            if wrong > 0 && wrong != correctAnswer {
                opts.insert(wrong)
            }
        }
        options = Array(opts).shuffled()
        
        // Animate grid appearance
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            gridScale = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showGrid = true
        }
    }
    
    private func selectOption(_ option: Int) {
        selected = option
        showResult = true
        isCorrect = option == correctAnswer
        
        if isCorrect {
            streak += 1
            score += 10 + (streak >= 3 ? 5 : 0)
            GameAudioService.shared.playCorrect()
        } else {
            streak = 0
            GameAudioService.shared.playWrong()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            round += 1
            if round >= totalRounds {
                gameOver = true
                GameLeaderboardService.shared.saveScore(gameId: gameId, score: score)
            } else {
                withAnimation {
                    gridScale = 0.5
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    generateQuestion()
                }
            }
        }
    }
    
    private func resetGame() {
        score = 0
        round = 0
        streak = 0
        gameOver = false
        generateQuestion()
    }
}

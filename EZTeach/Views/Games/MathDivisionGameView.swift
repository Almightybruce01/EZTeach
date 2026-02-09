//
//  MathDivisionGameView.swift
//  EZTeach
//
//  A division game with a "sharing/grouping" visual theme
//

import SwiftUI

struct MathDivisionGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var total = 0
    @State private var divisor = 0
    @State private var options: [Int] = []
    @State private var selected: Int?
    @State private var score = 0
    @State private var round = 0
    @State private var gameOver = false
    @State private var streak = 0
    @State private var showGroups = false
    @State private var itemPositions: [CGPoint] = []
    
    private let totalRounds = 12
    private var correctAnswer: Int { total / divisor }
    
    private let itemEmojis = ["🍎", "🍊", "🍋", "🍇", "🍓", "🍒", "🥝", "🍑"]
    @State private var currentEmoji = "🍎"
    
    var body: some View {
        ZStack {
            // Fresh gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.98, blue: 0.95),
                    Color(red: 0.9, green: 0.95, blue: 0.9)
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
                    
                    // Visual sharing representation
                    sharingVisualization
                        .frame(height: 200)
                    
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
                Text("DIVISION")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                Text("Fair Share")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.2, green: 0.35, blue: 0.2))
            }
            
            Spacer()
            
            if streak >= 2 {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                    Text("\(streak)x")
                }
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.green)
                .cornerRadius(12)
            }
            
            VStack(alignment: .trailing) {
                Text("Round \(round + 1)/\(totalRounds)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(score)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .green.opacity(0.15), radius: 8, y: 4)
        )
    }
    
    private var sharingVisualization: some View {
        VStack(spacing: 12) {
            Text("Share \(total) \(currentEmoji) equally among \(divisor) groups")
                .font(.subheadline.bold())
                .foregroundColor(Color(red: 0.2, green: 0.35, blue: 0.2))
            
            if showGroups {
                // Show grouped items
                HStack(spacing: 16) {
                    ForEach(0..<divisor, id: \.self) { groupIndex in
                        VStack(spacing: 4) {
                            // Group container
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .frame(width: groupWidth, height: 80)
                                    .shadow(color: .green.opacity(0.2), radius: 5)
                                
                                // Items in this group
                                VStack(spacing: 2) {
                                    ForEach(0..<min(correctAnswer, 4), id: \.self) { _ in
                                        Text(currentEmoji)
                                            .font(.system(size: correctAnswer > 3 ? 16 : 22))
                                    }
                                    if correctAnswer > 4 {
                                        Text("...")
                                            .font(.caption)
                                    }
                                }
                            }
                            
                            Text("Group \(groupIndex + 1)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            } else {
                // Show all items together
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .green.opacity(0.15), radius: 8)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: min(total, 6)), spacing: 4) {
                        ForEach(0..<total, id: \.self) { _ in
                            Text(currentEmoji)
                                .font(.system(size: total > 12 ? 18 : 24))
                        }
                    }
                    .padding()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.green.opacity(0.1))
        )
    }
    
    private var groupWidth: CGFloat {
        let maxWidth: CGFloat = 280
        return min(60, maxWidth / CGFloat(divisor))
    }
    
    private var questionView: some View {
        HStack(spacing: 12) {
            Text("\(total)")
                .font(.system(size: 40, weight: .black))
                .foregroundColor(.green)
            
            Text("÷")
                .font(.system(size: 40, weight: .black))
                .foregroundColor(Color(red: 0.2, green: 0.35, blue: 0.2))
            
            Text("\(divisor)")
                .font(.system(size: 40, weight: .black))
                .foregroundColor(.orange)
            
            Text("=")
                .font(.system(size: 40, weight: .black))
                .foregroundColor(Color(red: 0.2, green: 0.35, blue: 0.2))
            
            Text("?")
                .font(.system(size: 40, weight: .black))
                .foregroundColor(.purple)
                .frame(minWidth: 50)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .green.opacity(0.15), radius: 8, y: 4)
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
                                .shadow(color: .green.opacity(0.15), radius: 6, y: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(optionBorderColor(option), lineWidth: 2)
                        )
                }
                .disabled(selected != nil)
            }
        }
    }
    
    private func optionTextColor(_ option: Int) -> Color {
        if let sel = selected {
            if option == correctAnswer { return .white }
            if option == sel { return .white }
        }
        return Color(red: 0.2, green: 0.35, blue: 0.2)
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
        return .green.opacity(0.3)
    }
    
    private var gameOverView: some View {
        VStack(spacing: 24) {
            Text("🎉")
                .font(.system(size: 60))
            
            Text("Division Master!")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(Color(red: 0.2, green: 0.35, blue: 0.2))
            
            Text("Score: \(score)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.green)
            
            HStack(spacing: 8) {
                ForEach(0..<starRating, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.title)
                        .foregroundColor(.yellow)
                }
                ForEach(0..<(3 - starRating), id: \.self) { _ in
                    Image(systemName: "star")
                        .font(.title)
                        .foregroundColor(.gray.opacity(0.3))
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
                    .background(Color.green)
                    .cornerRadius(12)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Exit")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(12)
                }
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
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
        // Generate division problems that result in whole numbers
        let possibleDivisors = [2, 3, 4, 5]
        divisor = possibleDivisors.randomElement()!
        let quotient = Int.random(in: 2...6)
        total = divisor * quotient
        
        currentEmoji = itemEmojis.randomElement()!
        selected = nil
        showGroups = false
        
        // Generate options
        var opts = Set<Int>()
        opts.insert(correctAnswer)
        while opts.count < 4 {
            let offset = Int.random(in: -2...2)
            let wrong = correctAnswer + offset
            if wrong > 0 && wrong != correctAnswer {
                opts.insert(wrong)
            }
        }
        options = Array(opts).shuffled()
    }
    
    private func selectOption(_ option: Int) {
        selected = option
        let isCorrect = option == correctAnswer
        
        // Show grouped visualization
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showGroups = true
        }
        
        if isCorrect {
            streak += 1
            score += 10 + (streak >= 3 ? 5 : 0)
            GameAudioService.shared.playCorrect()
        } else {
            streak = 0
            GameAudioService.shared.playWrong()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            round += 1
            if round >= totalRounds {
                gameOver = true
                GameLeaderboardService.shared.saveScore(gameId: gameId, score: score)
            } else {
                generateQuestion()
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

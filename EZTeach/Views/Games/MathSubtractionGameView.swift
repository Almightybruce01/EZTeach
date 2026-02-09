//
//  MathSubtractionGameView.swift
//  EZTeach
//
//  A unique subtraction game with a "falling blocks" visual theme
//

import SwiftUI

struct MathSubtractionGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var total = 0
    @State private var subtract = 0
    @State private var userAnswer = ""
    @State private var score = 0
    @State private var round = 0
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var blocks: [BlockItem] = []
    @State private var removedBlocks: Set<Int> = []
    @State private var gameOver = false
    @State private var streak = 0
    
    private let totalRounds = 12
    
    struct BlockItem: Identifiable {
        let id: Int
        let color: Color
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.1, blue: 0.25),
                    Color(red: 0.25, green: 0.15, blue: 0.35)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if gameOver {
                gameOverView
            } else {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Visual blocks
                    blocksView
                        .frame(height: 200)
                    
                    // Question
                    questionView
                    
                    // Number pad
                    numberPadView
                    
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
                Text("SUBTRACTION")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.purple.opacity(0.8))
                Text("Block Breaker")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Round \(round + 1)/\(totalRounds)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(score)")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private var blocksView: some View {
        VStack(spacing: 8) {
            Text("You have \(total) blocks. Take away \(subtract).")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            blocksGrid
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.3))
                )
        }
    }
    
    private var blocksGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(blocks) { block in
                blockCell(block)
            }
        }
    }
    
    private func blockCell(_ block: BlockItem) -> some View {
        let isRemoved = removedBlocks.contains(block.id)
        let fillColor: Color = isRemoved ? Color.gray.opacity(0.3) : block.color
        let shadowRadius: CGFloat = isRemoved ? 0 : 5
        let scale: CGFloat = isRemoved ? 0.5 : 1.0
        let blockOpacity: Double = isRemoved ? 0.3 : 1.0
        
        return RoundedRectangle(cornerRadius: 8)
            .fill(fillColor)
            .frame(width: 40, height: 40)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: block.color.opacity(0.5), radius: shadowRadius)
            .scaleEffect(scale)
            .opacity(blockOpacity)
    }
    
    private var questionView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Text("\(total)")
                    .font(.system(size: 48, weight: .black))
                    .foregroundColor(.cyan)
                
                Text("-")
                    .font(.system(size: 48, weight: .black))
                    .foregroundColor(.white)
                
                Text("\(subtract)")
                    .font(.system(size: 48, weight: .black))
                    .foregroundColor(.red)
                
                Text("=")
                    .font(.system(size: 48, weight: .black))
                    .foregroundColor(.white)
                
                Text(userAnswer.isEmpty ? "?" : userAnswer)
                    .font(.system(size: 48, weight: .black))
                    .foregroundColor(showResult ? (isCorrect ? .green : .red) : .yellow)
                    .frame(minWidth: 60)
            }
            
            if showResult {
                Text(isCorrect ? "Correct! 🎉" : "The answer is \(total - subtract)")
                    .font(.headline)
                    .foregroundColor(isCorrect ? .green : .orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            showResult
                            ? (isCorrect ? Color.green : Color.red).opacity(0.5)
                            : Color.purple.opacity(0.3),
                            lineWidth: 2
                        )
                )
        )
    }
    
    private var numberPadView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { num in
                    numberButton(num)
                }
            }
            HStack(spacing: 12) {
                ForEach(6...9, id: \.self) { num in
                    numberButton(num)
                }
                numberButton(0)
            }
            HStack(spacing: 12) {
                Button {
                    if !userAnswer.isEmpty {
                        userAnswer.removeLast()
                    }
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 50)
                        .background(Color.red.opacity(0.6))
                        .cornerRadius(12)
                }
                
                Button {
                    checkAnswer()
                } label: {
                    Text("CHECK")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(width: 140, height: 50)
                        .background(
                            LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(12)
                }
                .disabled(userAnswer.isEmpty || showResult)
            }
        }
    }
    
    private func numberButton(_ num: Int) -> some View {
        Button {
            if userAnswer.count < 3 && !showResult {
                userAnswer += "\(num)"
            }
        } label: {
            Text("\(num)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(colors: [.purple, .purple.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(12)
        }
    }
    
    private var gameOverView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Game Complete!")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(.white)
            
            Text("Final Score: \(score)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.yellow)
            
            HStack(spacing: 16) {
                Button {
                    resetGame()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Play Again")
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
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(12)
                }
            }
        }
        .padding(40)
        .background(Color.black.opacity(0.8))
        .cornerRadius(24)
    }
    
    private func generateQuestion() {
        total = Int.random(in: 5...15)
        subtract = Int.random(in: 1...(total - 1))
        userAnswer = ""
        showResult = false
        removedBlocks = []
        
        let colors: [Color] = [.cyan, .pink, .orange, .green, .purple, .yellow]
        blocks = (0..<total).map { BlockItem(id: $0, color: colors.randomElement()!) }
    }
    
    private func checkAnswer() {
        let correct = total - subtract
        isCorrect = Int(userAnswer) == correct
        showResult = true
        
        if isCorrect {
            streak += 1
            score += 10 + (streak * 2)
            GameAudioService.shared.playCorrect()
            
            // Animate removing blocks
            for i in 0..<subtract {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                    withAnimation(.spring()) {
                        _ = removedBlocks.insert(i)
                    }
                }
            }
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

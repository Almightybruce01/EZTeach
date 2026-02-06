//
//  SudokuGameView.swift
//  EZTeach
//

import SwiftUI

struct SudokuGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var grid: [[Int?]] = Array(repeating: Array(repeating: nil, count: 4), count: 4)
    @State private var fixed: [[Bool]] = Array(repeating: Array(repeating: false, count: 4), count: 4)
    @State private var selected: (Int, Int)? = nil
    @State private var moves = 0
    @State private var gameWon = false
    @State private var startTime = Date()
    
    var body: some View {
        ZStack {
            ZenGardenBackground()
            mainContent
        }
        .overlay { winOverlay }
        .navigationTitle(gameTitle)
        .onAppear { 
            GameAudioService.shared.playStart()
            setupGame() 
        }
    }

    private var mainContent: some View {
        VStack(spacing: 24) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.pink)
                Text("Zen Sudoku")
                    .font(.headline.bold())
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                Spacer()
                Text("Moves: \(moves)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.3))
            }
            .padding()
            .background(Color.white.opacity(0.7))
            .cornerRadius(16)

            gridView
            numberPadView
            Button {
                setupGame()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("New Puzzle")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.pink.opacity(0.7))
                .cornerRadius(12)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var gridView: some View {
        VStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { col in
                        SudokuCell(
                            value: grid[row][col],
                            isFixed: fixed[row][col],
                            isSelected: selected?.0 == row && selected?.1 == col
                        ) {
                            if !fixed[row][col] {
                                selected = (row, col)
                            }
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(EZTeachColors.tronCyan.opacity(0.5), lineWidth: 2)
        )
    }

    @ViewBuilder
    private var numberPadView: some View {
        if let (r, c) = selected, !fixed[r][c] {
            HStack(spacing: 12) {
                ForEach(1...4, id: \.self) { n in
                    Button {
                        grid[r][c] = n
                        moves += 1
                        selected = nil
                        checkWin()
                    } label: {
                        Text("\(n)")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(EZTeachColors.tronCyan.opacity(0.3))
                            .cornerRadius(12)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var winOverlay: some View {
        if gameWon {
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(.pink)
                Text("Inner Peace!")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(.pink)
                Text("\(moves) moves")
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                Button {
                    setupGame()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Find Balance Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(LinearGradient(colors: [.pink, .purple.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(12)
                }
            }
            .padding(40)
            .background(Color.white.opacity(0.95))
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.pink, lineWidth: 2))
            .shadow(radius: 20)
        }
    }
    
    private func setupGame() {
        gameWon = false
        moves = 0
        selected = nil
        grid = [
            [1, 2, nil, nil],
            [nil, nil, 1, 2],
            [2, nil, nil, 1],
            [nil, 1, 2, nil]
        ]
        fixed = grid.map { $0.map { $0 != nil } }
    }
    
    private func checkWin() {
        for row in 0..<4 {
            for col in 0..<4 {
                if grid[row][col] == nil { return }
            }
        }
        gameWon = true
        let time = Date().timeIntervalSince(startTime)
        GameLeaderboardService.shared.saveScore(gameId: gameId, score: max(0, 100 - moves), timeSeconds: time)
    }
}

struct SudokuCell: View {
    let value: Int?
    let isFixed: Bool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(value.map { "\($0)" } ?? "")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(isFixed ? Color(red: 0.5, green: 0.3, blue: 0.2) : Color(red: 0.3, green: 0.2, blue: 0.1))
                .frame(width: 64, height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.pink.opacity(0.3) : Color.white.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.pink : Color(red: 0.7, green: 0.6, blue: 0.5), lineWidth: isSelected ? 2 : 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

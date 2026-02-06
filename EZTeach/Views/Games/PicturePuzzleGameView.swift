//
//  PicturePuzzleGameView.swift
//  EZTeach
//

import SwiftUI

struct PicturePuzzleGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var tiles: [Int] = []
    @State private var emptyIndex = 15
    @State private var moves = 0
    @State private var gameWon = false
    @State private var startTime = Date()
    
    private let symbols = ["star.fill", "heart.fill", "bolt.fill", "flag.fill", "leaf.fill", "flame.fill", "drop.fill", "snowflake", "moon.fill", "sun.max.fill", "cloud.fill", "burst.fill", "sparkles", "crown.fill", "star.circle.fill", "circle"]
    
    var body: some View {
        ZStack {
            SafariBackground()
            
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "binoculars.fill")
                        .foregroundColor(.brown)
                    Text("Safari Puzzle")
                        .font(.headline.bold())
                        .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.1))
                    Spacer()
                    Text("Moves: \(moves)")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(16)
                .padding(.horizontal)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(0..<16, id: \.self) { i in
                        if tiles[i] < 15 {
                            Button {
                                tryMove(i)
                            } label: {
                                Image(systemName: symbols[tiles[i]])
                                    .font(.system(size: 28))
                                    .foregroundColor(.orange)
                                    .frame(width: 70, height: 70)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.95, green: 0.9, blue: 0.8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.brown.opacity(0.6), lineWidth: 2)
                                            )
                                            .shadow(color: .brown.opacity(0.3), radius: 4)
                                    )
                            }
                            .buttonStyle(.plain)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.brown.opacity(0.2))
                                .frame(width: 70, height: 70)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.3))
                .cornerRadius(20)
                .padding(.horizontal)
                
                Button {
                    setupGame()
                } label: {
                    HStack {
                        Image(systemName: "shuffle")
                        Text("Shuffle")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(LinearGradient(colors: [.orange, .brown], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(12)
                }
            }
            .overlay {
                if gameWon {
                    VStack(spacing: 20) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("SAFARI MASTER!")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.brown)
                        Text("\(moves) moves")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.1))
                        Button {
                            setupGame()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("New Adventure")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(LinearGradient(colors: [.orange, .brown], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(12)
                        }
                    }
                    .padding(40)
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(24)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.brown, lineWidth: 3))
                    .shadow(color: .brown.opacity(0.3), radius: 10)
                }
            }
        }
        .navigationTitle(gameTitle)
        .onAppear { setupGame() }
    }
    
    private func setupGame() {
        gameWon = false
        moves = 0
        tiles = Array(0..<16)
        repeat {
            tiles.shuffle()
            emptyIndex = tiles.firstIndex(of: 15) ?? 15
        } while !isSolvable()
    }
    
    private func isSolvable() -> Bool {
        var inv = 0
        let arr = tiles.filter { $0 != 15 }
        for i in 0..<arr.count {
            for j in (i+1)..<arr.count {
                if arr[i] > arr[j] { inv += 1 }
            }
        }
        let emptyRow = emptyIndex / 4
        return (inv + emptyRow) % 2 == 0
    }
    
    private func tryMove(_ i: Int) {
        let row = i / 4, col = i % 4
        let emptyRow = emptyIndex / 4, emptyCol = emptyIndex % 4
        if (row == emptyRow && abs(col - emptyCol) == 1) || (col == emptyCol && abs(row - emptyRow) == 1) {
            tiles.swapAt(i, emptyIndex)
            emptyIndex = i
            moves += 1
            checkWin()
        }
    }
    
    private func checkWin() {
        for i in 0..<15 {
            if tiles[i] != i { return }
        }
        gameWon = true
        let time = Date().timeIntervalSince(startTime)
        GameLeaderboardService.shared.saveScore(gameId: gameId, score: max(0, 100 - moves), timeSeconds: time)
    }
}

//
//  RunAndQuizGameView.swift
//  EZTeach
//
//  Runner-style game: move forward, stop at checkpoints, answer questions.
//

import SwiftUI

struct RunAndQuizGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var position: CGFloat = 0
    @State private var checkpoint = 0
    @State private var showQuestion = false
    @State private var question = ""
    @State private var options: [String] = []
    @State private var correctAnswer = ""
    @State private var selected: String?
    @State private var score = 0
    @State private var isRunning = true
    
    private let checkpoints: [(CGFloat, String, [String])] = [
        (0.2, "2 + 3 = ?", ["4", "5", "6"]),
        (0.4, "What color is the sky?", ["Green", "Blue", "Red"]),
        (0.6, "Opposite of hot?", ["Cold", "Warm", "Wet"]),
        (0.8, "5 - 2 = ?", ["2", "3", "4"]),
        (1.0, "How many legs does a dog have?", ["2", "3", "4"])
    ]
    
    private let rainbowColors: [Color] = [.red, .orange, .yellow, .green, .blue]
    
    var body: some View {
        ZStack {
            // Rainbow Adventure Background
            LinearGradient(
                colors: [
                    Color(red: 0.5, green: 0.8, blue: 1),
                    Color(red: 0.7, green: 0.9, blue: 1),
                    Color(red: 0.9, green: 0.95, blue: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Decorative clouds
            VStack {
                HStack {
                    CloudDecor()
                        .offset(x: -30, y: 20)
                    Spacer()
                    CloudDecor()
                        .offset(x: 40, y: 50)
                }
                Spacer()
            }
            
            // Grass at bottom
            VStack {
                Spacer()
                Rectangle()
                    .fill(LinearGradient(colors: [Color(red: 0.3, green: 0.7, blue: 0.3), Color(red: 0.2, green: 0.5, blue: 0.2)], startPoint: .top, endPoint: .bottom))
                    .frame(height: 60)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "rainbow")
                        .foregroundColor(.purple)
                    Text("Rainbow Run")
                        .font(.headline.bold())
                        .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.5))
                    Spacer()
                    Text("Score: \(score)")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(.purple)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(16)
                .padding(.horizontal)
                
                GeometryReader { geo in
                    let w = geo.size.width
                    ZStack(alignment: .leading) {
                        // Rainbow track
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(colors: [.red.opacity(0.3), .orange.opacity(0.3), .yellow.opacity(0.3), .green.opacity(0.3), .blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple], startPoint: .leading, endPoint: .trailing),
                                        lineWidth: 3
                                    )
                            )
                            .padding(.horizontal, 20)
                        
                        // Checkpoint flags
                        ForEach(0..<5, id: \.self) { i in
                            VStack(spacing: 2) {
                                Image(systemName: i < checkpoint ? "star.fill" : "flag.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(i < checkpoint ? .yellow : rainbowColors[i])
                            }
                            .offset(x: 24 + (w - 88) * CGFloat(i) / 4, y: 0)
                        }
                        
                        // Running character
                        Image(systemName: "figure.run")
                            .font(.system(size: 44))
                            .foregroundColor(.purple)
                            .shadow(color: .purple.opacity(0.5), radius: 4)
                            .offset(x: 16 + (w - 72) * position, y: 0)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .padding(.vertical, 20)
                
                if showQuestion {
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.purple)
                            Text("Challenge!")
                                .font(.headline)
                                .foregroundColor(.purple)
                        }
                        
                        Text(question)
                            .font(.title2.bold())
                            .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.4))
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        ForEach(options, id: \.self) { opt in
                            Button {
                                if selected == nil {
                                    selected = opt
                                    if opt == correctAnswer {
                                        score += 20
                                        GameAudioService.shared.playCorrect()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                            advancePastCheckpoint()
                                        }
                                    } else {
                                        GameAudioService.shared.playWrong()
                                    }
                                }
                            } label: {
                                Text(opt)
                                    .font(.headline)
                                    .foregroundColor(selected == nil ? Color(red: 0.3, green: 0.2, blue: 0.4) : (opt == correctAnswer ? .white : (opt == selected ? .red.opacity(0.8) : .gray)))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(opt == correctAnswer && selected != nil ? Color.green : (opt == selected && opt != correctAnswer ? Color.red.opacity(0.3) : Color.white.opacity(0.9)))
                                            .shadow(color: .purple.opacity(0.2), radius: 4)
                                    )
                            }
                            .disabled(selected != nil)
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: .purple.opacity(0.2), radius: 16, y: 8)
                    )
                    .padding(.horizontal, 20)
                } else if isRunning {
                    VStack(spacing: 16) {
                        Text("Tap to run to the next flag!")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.4))
                        
                        Button {
                            runForward()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "hare.fill")
                                Text("Run!")
                                    .font(.headline.bold())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .pink, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: .purple.opacity(0.4), radius: 8)
                        }
                    }
                    .padding(.top, 40)
                } else {
                    VStack(spacing: 24) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        Text("RAINBOW CHAMPION!")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.purple)
                        Text("Score: \(score)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.4))
                    }
                    .padding(40)
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 4
                            )
                    )
                }
                
                Spacer()
            }
        }
        .navigationTitle(gameTitle)
        .onAppear {
            GameAudioService.shared.playStart()
            GameAudioService.shared.speakInstructions("Tap Run to move. Stop at each flag to answer a question.")
        }
    }
    
    private func runForward() {
        let nextPos = checkpoint < checkpoints.count ? checkpoints[checkpoint].0 : 1.0
        withAnimation(.easeInOut(duration: 0.6)) {
            position = nextPos
        }
        if checkpoint < checkpoints.count {
            let c = checkpoints[checkpoint]
            question = c.1
            correctAnswer = c.2[0]
            options = c.2.shuffled()
            selected = nil
            showQuestion = true
        } else {
            isRunning = false
        }
    }
    
    private func advancePastCheckpoint() {
        showQuestion = false
        checkpoint += 1
        if checkpoint < checkpoints.count {
            isRunning = true
        } else {
            isRunning = false
        }
    }
}

// MARK: - Cloud Decoration
private struct CloudDecor: View {
    var body: some View {
        HStack(spacing: -10) {
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 40, height: 40)
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 60, height: 60)
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 50, height: 50)
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 35, height: 35)
        }
    }
}

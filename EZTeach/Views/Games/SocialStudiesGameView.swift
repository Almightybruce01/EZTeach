//
//  SocialStudiesGameView.swift
//  EZTeach
//

import SwiftUI

struct SocialStudiesGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    private var qa: [(String, String)] {
        switch gameId {
        case "ss_map": return [("Capital of USA?", "Washington D.C."), ("Capital of France?", "Paris"), ("Largest continent?", "Asia"), ("Currency of Japan?", "Yen"), ("How many continents?", "7")]
        case "ss_timeline": return [("1776", "Declaration"), ("1865", "Civil War end"), ("1969", "Moon landing"), ("2001", "9/11"), ("1492", "Columbus")]
        case "ss_culture": return [("Language", "Communication"), ("Food", "Culture"), ("Music", "Art"), ("Holidays", "Traditions")]
        case "ss_government": return [("President", "Leader"), ("Congress", "Makes laws"), ("Courts", "Judge laws"), ("Vote", "Democracy")]
        case "ss_economics": return [("Supply", "Amount"), ("Demand", "Want"), ("Money", "Trade"), ("Jobs", "Work")]
        case "ss_geography": return [("Equator", "Middle"), ("North Pole", "Cold"), ("Ocean", "Water"), ("Mountain", "High")]
        case "ss_history": return [("George Washington", "First President"), ("Rosa Parks", "Bus"), ("MLK", "Dream"), ("Abraham Lincoln", "Emancipation")]
        case "ss_civics": return [("Rights", "Freedoms"), ("Laws", "Rules"), ("Citizen", "Member"), ("Constitution", "Document")]
        case "ss_community": return [("Doctor", "Health"), ("Teacher", "School"), ("Firefighter", "Fires"), ("Police", "Safety")]
        case "ss_landmarks": return [("Statue of Liberty", "NY"), ("Eiffel Tower", "Paris"), ("Pyramids", "Egypt"), ("Great Wall", "China")]
        default: return [("Capital of USA?", "Washington D.C."), ("Capital of France?", "Paris"), ("Largest continent?", "Asia")]
        }
    }
    @State private var question = ""
    @State private var correctAnswer = ""
    @State private var options: [String] = []
    @State private var score = 0
    @State private var round = 0
    @State private var showResult = false
    @State private var selected: String? = nil
    @State private var gameOver = false
    
    var body: some View {
        ZStack {
            AncientEgyptBackground()
            
            VStack(spacing: 24) {
                HStack {
                    Image(systemName: "building.columns.fill")
                        .foregroundColor(.orange)
                    Text("Ancient Explorer")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Text("Score: \(score)")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(16)
                .padding(.horizontal)
                
                if !gameOver {
                    VStack(spacing: 24) {
                        // Question scroll
                        VStack(spacing: 8) {
                            Image(systemName: "scroll.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.orange)
                            Text(question)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        ForEach(options, id: \.self) { opt in
                            Button {
                                if selected == nil {
                                    selected = opt
                                    showResult = true
                                    if opt == correctAnswer {
                                        score += 20
                                        GameAudioService.shared.playCorrect()
                                    } else {
                                        GameAudioService.shared.playWrong()
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        nextQuestion()
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "seal.fill")
                                        .foregroundColor(.yellow.opacity(0.7))
                                    Text(opt)
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(showResult && opt == correctAnswer ? Color.green.opacity(0.4) : (showResult && opt == selected && opt != correctAnswer ? Color.red.opacity(0.4) : Color.brown.opacity(0.5)))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.7), lineWidth: 2))
                                )
                            }
                            .disabled(showResult)
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 24) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        Text("PHARAOH OF KNOWLEDGE!")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.orange)
                        Text("Score: \(score)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        Button {
                            resetGame()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Explore Again")
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .background(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(12)
                        }
                    }
                    .padding(40)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(24)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.orange, lineWidth: 3))
                }
                
                Spacer()
            }
            .padding(.top, 20)
        }
        .navigationTitle(gameTitle)
        .onAppear {
            GameAudioService.shared.playStart()
            GameAudioService.shared.speakInstructions("Choose the correct answer for each question.")
            nextQuestion()
        }
    }
    
    private func nextQuestion() {
        round += 1
        showResult = false
        selected = nil
        if round > 5 {
            gameOver = true
            GameLeaderboardService.shared.saveScore(gameId: gameId, score: score)
        } else {
            let idx = (round - 1) % qa.count
            let pair = qa[idx]
            question = pair.0
            correctAnswer = pair.1
            var opts = [pair.1]
            let others = qa.map { $0.1 }.filter { $0 != pair.1 }.shuffled().prefix(2)
            opts.append(contentsOf: others)
            options = opts.shuffled()
        }
    }
    
    private func resetGame() {
        score = 0
        round = 0
        gameOver = false
        nextQuestion()
    }
}

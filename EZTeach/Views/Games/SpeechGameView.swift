//
//  SpeechGameView.swift
//  EZTeach
//

import SwiftUI

struct SpeechGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    private var phrases: [String] {
        switch gameId {
        case "speech_tongue_twister":
            return [
                "She sells seashells by the seashore.",
                "How much wood would a woodchuck chuck?",
                "Peter Piper picked a peck of pickled peppers.",
                "Fuzzy Wuzzy was a bear. Fuzzy Wuzzy had no hair.",
                "Red lorry, yellow lorry.",
                "Unique New York. New York's unique.",
                "Six sleek swans swam swiftly southward.",
                "Betty bought a bit of butter but the butter was bitter."
            ]
        case "speech_pronunciation":
            return [
                "Say: THink, THank, THree (tongue between teeth)",
                "Say: Red, Read, Led (R and L sounds)",
                "Say: Ship, Sheep (short i vs long e)",
                "Say: Bat, Pat, Cat (b, p, k)",
                "Say: Sink, Think (s vs th)"
            ]
        case "speech_rhythm":
            return [
                "Clap the beat: TA-ta TA-ta TA-ta TA-ta",
                "Clap: ONE-two-three ONE-two-three (waltz)",
                "Say with rhythm: I like to play. I like to play.",
                "Stamp and clap: STAMP-clap-clap STAMP-clap-clap"
            ]
        default:
            return [
                "She sells seashells by the seashore.",
                "Peter Piper picked a peck of pickled peppers.",
                "How much wood would a woodchuck chuck?"
            ]
        }
    }
    @State private var currentPhrase = ""
    @State private var practiced = false
    
    var body: some View {
        ZStack {
            EnchantedForestBackground()
            
            VStack(spacing: 32) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(.green)
                    Text("Enchanted Speech")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(16)
                
                VStack(spacing: 16) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green.opacity(0.8))
                    
                    Text(currentPhrase)
                        .font(.title2.weight(.medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 20)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(16)
                }
                
                Text("Say it 3 times clearly!")
                    .font(.subheadline.bold())
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.5), radius: 4)
                
                Button {
                    practiced = true
                    GameAudioService.shared.playCorrect()
                    GameLeaderboardService.shared.saveScore(gameId: gameId, score: 10)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        currentPhrase = phrases.randomElement() ?? phrases[0]
                        practiced = false
                    }
                } label: {
                    HStack {
                        Image(systemName: practiced ? "checkmark.circle.fill" : "mic.fill")
                        Text(practiced ? "Well Done!" : "I Practiced!")
                    }
                    .font(.headline.bold())
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.5), radius: 8)
                }
                .padding(.horizontal, 40)
            }
            .padding(.top, 60)
        }
        .navigationTitle(gameTitle)
        .onAppear {
            GameAudioService.shared.playStart()
            GameAudioService.shared.speakInstructions("Practice saying the phrase clearly. Tap I Practiced when done.")
            currentPhrase = phrases.randomElement() ?? phrases[0]
        }
    }
}

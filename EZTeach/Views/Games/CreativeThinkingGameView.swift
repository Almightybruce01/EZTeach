//
//  CreativeThinkingGameView.swift
//  EZTeach
//

import SwiftUI

struct CreativeThinkingGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    private var prompts: [String] {
        switch gameId {
        case "creative_story_starter": return [
            "If you could have any superpower, what would it be and why?",
            "Invent a new animal. What does it look like and where does it live?",
            "What would happen if it rained candy?",
            "Design a new planet. What is special about it?",
            "If you could talk to animals, what would you ask them?",
            "Write the first paragraph of a story about a lost key."
        ]
        case "creative_what_if": return [
            "What if you could fly? Where would you go first?",
            "What if dogs could talk? What would they say?",
            "What if school was underwater? Describe a day.",
            "What if you found a door to another world?",
            "What if you could live in any time period?"
        ]
        case "creative_riddles": return [
            "I have keys but no locks. I have space but no room. What am I? (Keyboard)",
            "Write your own riddle. What is the answer?",
            "I speak without a mouth. I hear without ears. What am I? (Echo)",
            "Create a riddle about an animal.",
            "What has hands but cannot clap? (Clock)"
        ]
        case "creative_analogies": return [
            "Hot is to cold as day is to ____",
            "Bird is to nest as dog is to ____",
            "Create your own analogy.",
            "Pen is to write as fork is to ____",
            "Book is to read as song is to ____"
        ]
        case "creative_inventions": return [
            "Invent a machine that helps with homework.",
            "Design a gadget for your bedroom.",
            "Create something that makes mornings easier.",
            "Invent a tool for the playground.",
            "Design a device that helps animals."
        ]
        case "creative_brainstorm": return [
            "List 10 uses for a paper clip.",
            "How could we make recess more fun?",
            "Ways to help the environment.",
            "Ideas for a class party.",
            "How to make friends at a new school."
        ]
        default: return [
            "If you could have any superpower, what would it be and why?",
            "Invent a new animal. What does it look like?",
            "What would happen if it rained candy?",
            "Design a new planet.",
            "If you could talk to animals, what would you ask?"
        ]
        }
    }
    @State private var currentPrompt = ""
    @State private var userResponse = ""
    @State private var round = 0
    @State private var completed = false
    
    var body: some View {
        ZStack {
            ArtStudioBackground()
            
            VStack(spacing: 24) {
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .foregroundColor(.purple)
                    Text("Creative Studio")
                        .font(.headline.bold())
                        .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.4))
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Prompt card
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.yellow)
                    Text(currentPrompt)
                        .font(.title3.weight(.medium))
                        .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.3))
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(16)
                .shadow(color: .purple.opacity(0.2), radius: 8)
                .padding(.horizontal, 24)
                
                TextEditor(text: $userResponse)
                    .scrollContentBackground(.hidden)
                    .font(.body)
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.25))
                    .padding()
                    .frame(minHeight: 150)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: 3
                                    )
                            )
                    )
                    .padding(.horizontal, 24)
                
                Button {
                    if completed {
                        newPrompt()
                    } else {
                        completed = true
                        GameAudioService.shared.playCorrect()
                        GameLeaderboardService.shared.saveScore(gameId: gameId, score: min(100, 20 + userResponse.count / 2))
                    }
                } label: {
                    HStack {
                        Image(systemName: completed ? "arrow.right.circle.fill" : "paintbrush.pointed.fill")
                        Text(completed ? "Next Inspiration" : "Create!")
                    }
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(colors: [.purple, .pink, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(16)
                    .shadow(color: .purple.opacity(0.4), radius: 8)
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 20)
        }
        .navigationTitle(gameTitle)
        .onAppear {
            GameAudioService.shared.playStart()
            GameAudioService.shared.speakInstructions("Read the prompt. Write your answer. Tap Submit when done.")
            newPrompt()
        }
    }
    
    private func newPrompt() {
        round += 1
        currentPrompt = prompts[(round - 1) % prompts.count]
        userResponse = ""
        completed = false
    }
}

//
//  ReadingWordGameView.swift
//  EZTeach
//

import SwiftUI

struct ReadingWordGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    /// Words by difficulty: K-1 (3–4 letters), 2–3 (4–5), 4+ (5–7)
    private static let wordsByLevel: [[String]] = [
        ["CAT", "DOG", "RUN", "BIG", "RED", "SUN", "FUN", "TOP", "HAT", "MAP", "BAT", "SIT", "HOP", "LOG", "BUG", "BED", "CUP", "FAN", "HAM", "JAM", "MAN", "NET", "PEN", "RAT", "TEN", "WET", "BOX", "FIX", "MIX", "SIX", "BAG", "BUS", "CAP", "CAR", "DAD", "DAY", "EGG", "EYE", "FAR", "FAT", "FIT", "GAP", "GAS", "HOT", "JOB", "KEY", "LEG", "LIP", "LOT", "MOM", "MUD", "NAV", "OAK", "OAR", "OAT", "OIL", "OWL", "PET", "PIE", "PIT", "RUB", "RUG", "SAT", "SAW", "SEA", "SKY", "SOB", "SOD", "TAG", "TAN", "TAR", "TEA", "TIN", "TIP", "TOE", "TOW", "TOY", "TUG", "USA", "VAN", "WAR", "WAX", "WAY", "WEB", "WIG", "WIN", "YAM", "YAP", "YEN", "YEW", "YOU", "ZAP"],
        ["BOOK", "FISH", "JUMP", "FROG", "STAR", "TREE", "MOON", "BEAR", "BIRD", "FIRE", "GAME", "HAND", "KITE", "LION", "NEST", "PLAN", "RAIN", "SAND", "TIME", "WAVE", "FALL", "GOLD", "HUNT", "MELT", "PAIN", "REST", "SOAP", "TALE", "WEST", "ZERO", "BRAN", "COIN", "DRUM", "EELS", "GLAD", "ABLE", "ACID", "AGED", "ALSO", "ARCH", "ARMS", "ARTS", "AUTO", "AWAY", "BABY", "BACK", "BALL", "BAND", "BANK", "BASE", "BASK", "BEAM", "BEAT", "BEEN", "BELL", "BELT", "BEND", "BEST", "BIKE", "BILL", "BIND", "BIRD", "BITE", "BLOW", "BLUE", "BOAT", "BODY", "BOLD", "BOLT", "BOMB", "BOND", "BONE", "BOOK", "BOOM", "BOOT", "BORE", "BORN", "BOSS", "BOTH", "BOWL", "BOYS", "BRAD", "BRAG", "BRAN", "BRAS", "BRAT", "BRAY", "BRED", "BREW", "BRIG", "BRIM", "BROW", "BUDS", "BUFF", "BUGS", "BULB", "BULK", "BULL", "BUMP", "BUNS", "BUOY", "BURN", "BURR", "BURY", "BUSH", "BUST", "BUSY", "BUZZ", "CAFE", "CAGE", "CAKE", "CALF", "CALL", "CALM", "CAME"],
        ["BRAVE", "CLOUD", "DREAM", "EARTH", "FIELD", "GHOST", "HEART", "IDEAS", "JEWEL", "KNIFE", "LIGHT", "MAGIC", "NIGHT", "OCEAN", "PEACE", "QUEST", "RIVER", "STORM", "THINK", "UNITY", "VOICE", "WATER", "YOUNG", "ZEBRA", "BLADE", "CRANE", "DROVE", "ELBOW", "FLAME", "GRASP", "ABOUT", "ABOVE", "ADOPT", "ADULT", "AFTER", "AGAIN", "AGENT", "AGREE", "AHEAD", "ALARM", "ALBUM", "ALERT", "ALIKE", "ALIVE", "ALLOW", "ALONE", "ALONG", "ALPHA", "ALTER", "AMONG", "ANGER", "ANGLE", "ANGRY", "APART", "APPLE", "APPLY", "ARENA", "ARGUE", "ARISE", "ARRAY", "ARTSY", "ASIDE", "ASSET", "AUDIO", "AVOID", "AWARD", "AWARE", "BADLY", "BAKER", "BASES", "BASIC", "BASIN", "BASIS", "BEACH", "BEGAN", "BEGIN", "BEGUN", "BEING", "BELOW", "BENCH", "BILLY", "BIRTH", "BLACK", "BLADE", "BLAME", "BLANK", "BLAST", "BLAZE", "BLEED", "BLESS", "BLIND", "BLOCK", "BLOOD", "BLOWN", "BOARD", "BOAST", "BOOTH", "BOUND", "BRAIN", "BRAND", "BRASS", "BRAVE", "BREAD", "BREAK", "BREED", "BRICK", "BRIDE", "BRIEF", "BRING", "BROAD", "BROKE", "BROOD", "BROOM", "BROTH", "BROWN", "BUILD", "BUILT", "BUNCH", "BURST", "BUYER", "CABLE", "CALCI", "CALIF", "CARRY", "CATCH", "CAUSE", "CHAIN", "CHAIR", "CHART", "CHASE", "CHEAP", "CHECK", "CHEST", "CHIEF", "CHILD", "CHINA", "CHORD", "CIVIC", "CIVIL", "CLAIM", "CLASS", "CLEAN", "CLEAR", "CLERK", "CLICK", "CLIMB", "CLOCK"]
    ]
    private var words: [String] {
        let all = Self.wordsByLevel.flatMap { $0 }
        return all
    }
    @State private var currentWord = ""
    @State private var shuffledChars: [String] = []
    @State private var selectedChars: [String] = []
    @State private var score = 0
    @State private var round = 0
    @State private var correct = false
    @State private var showResult = false
    @State private var gameOver = false
    
    private let roundsPerGame = 15
    
    private var accentColor: Color { EZTeachColors.softPurple }
    
    var body: some View {
        ZStack {
            MagicalLibraryBackground()
            
            VStack(spacing: 24) {
                HStack(spacing: 12) {
                    Image(systemName: "wand.and.stars")
                        .font(.title2)
                        .foregroundColor(.purple)
                    Text("Magical Library")
                        .font(.headline.bold())
                        .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.4))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Score: \(score)")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundColor(.purple)
                        Text("\(round)/\(roundsPerGame)")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .purple.opacity(0.2), radius: 6, y: 2)
                .padding(.horizontal)
                
                if !gameOver {
                    VStack(spacing: 24) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text("Cast the Spell:")
                                .font(.headline)
                                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.4))
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                        }
                        
                        Text(selectedChars.joined())
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundColor(.purple)
                            .frame(minHeight: 60)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(16)
                            .shadow(color: .purple.opacity(0.3), radius: 8)
                        
                        HStack(spacing: 12) {
                            ForEach(shuffledChars.indices, id: \.self) { idx in
                                if idx < shuffledChars.count {
                                    let ch = shuffledChars[idx]
                                    Button {
                                        selectChar(ch)
                                    } label: {
                                        Text(ch)
                                            .font(.system(size: 28, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .frame(width: 50, height: 50)
                                            .background(
                                                LinearGradient(colors: [.purple, .indigo], startPoint: .top, endPoint: .bottom)
                                            )
                                            .cornerRadius(12)
                                            .shadow(color: .purple.opacity(0.4), radius: 4)
                                    }
                                }
                            }
                        }
                        
                        if showResult {
                            HStack {
                                Image(systemName: correct ? "checkmark.seal.fill" : "xmark.circle.fill")
                                Text(correct ? "Spell Cast!" : "Try Again!")
                            }
                            .font(.title2.bold())
                            .foregroundColor(correct ? .green : .red)
                        }
                        
                        Button {
                            clearSelection()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Clear")
                            }
                            .font(.caption)
                            .foregroundColor(.purple)
                        }
                    }
                } else {
                    VStack(spacing: 24) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                        Text("MASTER WIZARD!")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.purple)
                        Text("Score: \(score)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.4))
                        Button {
                            resetGame()
                        } label: {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("New Spells")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(12)
                        }
                    }
                    .padding(40)
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(24)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.purple, lineWidth: 3))
                }
                
                Spacer()
            }
            .padding(.top, 20)
        }
        .navigationTitle(gameTitle)
        .onAppear {
            GameAudioService.shared.playStart()
            GameAudioService.shared.speakInstructions("Spell the word. Tap the letters in order.")
            nextRound()
        }
    }
    
    private func selectChar(_ ch: String) {
        selectedChars.append(ch)
        if selectedChars.count == currentWord.count {
            checkAnswer()
        }
    }
    
    private func clearSelection() {
        selectedChars = []
        showResult = false
    }
    
    private func checkAnswer() {
        let answer = selectedChars.joined()
        correct = answer == currentWord
        if correct {
            score += 10
            showResult = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                nextRound()
            }
        } else {
            GameAudioService.shared.playWrong()
            showResult = true
        }
    }
    
    private func nextRound() {
        round += 1
        selectedChars = []
        showResult = false
        if round > roundsPerGame {
            gameOver = true
            GameLeaderboardService.shared.saveScore(gameId: gameId, score: score)
        } else {
            currentWord = words.randomElement() ?? "CAT"
            shuffledChars = currentWord.map { String($0) }.shuffled()
        }
    }
    
    private func resetGame() {
        score = 0
        round = 0
        gameOver = false
        nextRound()
    }
}

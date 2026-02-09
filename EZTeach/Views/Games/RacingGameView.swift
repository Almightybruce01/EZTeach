//
//  RacingGameView.swift
//  EZTeach
//
//  A fun racing game where answering questions correctly makes your car go faster!
//

import SwiftUI

struct RacingGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var playerPosition: CGFloat = 0
    @State private var opponentPosition: CGFloat = 0
    @State private var currentQuestion = ""
    @State private var correctAnswer = ""
    @State private var options: [String] = []
    @State private var selected: String?
    @State private var score = 0
    @State private var questionsAnswered = 0
    @State private var gameOver = false
    @State private var playerWon = false
    @State private var showCountdown = true
    @State private var countdown = 3
    @State private var carBounce: CGFloat = 0
    @State private var opponentSpeed: Double = 0.8
    @State private var streak = 0
    @State private var showBoost = false
    @State private var roadOffset: CGFloat = 0
    
    private let totalQuestions = 10
    private let trackLength: CGFloat = 1.0
    
    // Questions based on game type
    private var questions: [(question: String, answer: String, options: [String])] {
        switch gameId {
        case "reading_reading_race": return [
            ("What rhymes with 'cat'?", "hat", ["dog", "hat", "run", "big"]),
            ("What is the opposite of 'hot'?", "cold", ["warm", "cold", "sunny", "fast"]),
            ("Which word means 'happy'?", "joyful", ["sad", "joyful", "angry", "tired"]),
            ("What comes after 'A, B, C'?", "D", ["E", "D", "F", "G"]),
            ("Which is a color?", "blue", ["jump", "blue", "fast", "loud"]),
            ("What rhymes with 'run'?", "sun", ["moon", "star", "sun", "sky"]),
            ("Which word means 'big'?", "large", ["small", "tiny", "large", "short"]),
            ("What is the opposite of 'up'?", "down", ["left", "right", "down", "across"]),
            ("Which word starts with 'S'?", "sun", ["moon", "sun", "cat", "dog"]),
            ("What rhymes with 'day'?", "play", ["night", "play", "dark", "light"])
        ]
        case "math_race": return [
            ("5 + 3 = ?", "8", ["6", "7", "8", "9"]),
            ("10 - 4 = ?", "6", ["5", "6", "7", "8"]),
            ("2 × 3 = ?", "6", ["4", "5", "6", "7"]),
            ("12 ÷ 4 = ?", "3", ["2", "3", "4", "5"]),
            ("7 + 8 = ?", "15", ["14", "15", "16", "17"]),
            ("20 - 7 = ?", "13", ["12", "13", "14", "15"]),
            ("4 × 5 = ?", "20", ["18", "19", "20", "21"]),
            ("15 ÷ 3 = ?", "5", ["4", "5", "6", "7"]),
            ("9 + 6 = ?", "15", ["14", "15", "16", "17"]),
            ("18 - 9 = ?", "9", ["8", "9", "10", "11"])
        ]
        default: return [
            ("What sound does a cat make?", "meow", ["woof", "meow", "moo", "oink"]),
            ("How many legs does a dog have?", "4", ["2", "4", "6", "8"]),
            ("What color is the sky?", "blue", ["red", "blue", "green", "yellow"]),
            ("Which animal can fly?", "bird", ["fish", "bird", "dog", "cat"]),
            ("What do fish live in?", "water", ["air", "water", "sand", "grass"]),
            ("How many days in a week?", "7", ["5", "6", "7", "8"]),
            ("What do you use to write?", "pencil", ["fork", "pencil", "cup", "shoe"]),
            ("Which is the largest?", "elephant", ["ant", "cat", "elephant", "mouse"]),
            ("What season comes after winter?", "spring", ["summer", "spring", "fall", "winter"]),
            ("What is 1 + 1?", "2", ["1", "2", "3", "4"])
        ]
        }
    }
    
    @State private var shuffledQuestions: [(question: String, answer: String, options: [String])] = []
    
    var body: some View {
        ZStack {
            // Racing track background
            RacingTrackBackground(roadOffset: $roadOffset)
            
            if showCountdown {
                countdownView
            } else if gameOver {
                gameOverView
            } else {
                gameplayView
            }
        }
        .navigationTitle(gameTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            shuffledQuestions = questions.shuffled()
            loadQuestion()
            startCountdown()
        }
    }
    
    // MARK: - Countdown View
    private var countdownView: some View {
        VStack(spacing: 20) {
            Text("GET READY!")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)
            
            Text("\(countdown)")
                .font(.system(size: 100, weight: .black))
                .foregroundColor(.yellow)
                .shadow(color: .orange, radius: 20)
            
            Text("Answer fast to speed up!")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(40)
        .background(Color.black.opacity(0.7))
        .cornerRadius(24)
    }
    
    // MARK: - Gameplay View
    private var gameplayView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("🏎️ \(gameTitle)")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    HStack {
                        Text("Q: \(questionsAnswered)/\(totalQuestions)")
                            .font(.caption)
                        if streak >= 2 {
                            Text("🔥 Streak: \(streak)")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Text("Score: \(score)")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.yellow)
            }
            .padding()
            .background(Color.black.opacity(0.6))
            
            // Racing track
            GeometryReader { geo in
                ZStack {
                    // Track lanes
                    VStack(spacing: 0) {
                        // Your lane
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                            
                            // Finish line
                            HStack {
                                Spacer()
                                Rectangle()
                                    .fill(LinearGradient(
                                        colors: [.white, .black, .white, .black, .white],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ))
                                    .frame(width: 20)
                            }
                            
                            // Your car
                            HStack(spacing: 0) {
                                Spacer()
                                    .frame(width: (geo.size.width - 80) * playerPosition)
                                PlayerCarView(color: .blue, boost: showBoost)
                                    .offset(y: carBounce)
                            }
                        }
                        .frame(height: 80)
                        
                        // Lane divider
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 4)
                        
                        // Opponent lane
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                            
                            // Opponent car
                            HStack(spacing: 0) {
                                Spacer()
                                    .frame(width: (geo.size.width - 80) * opponentPosition)
                                OpponentCarView(color: .red)
                            }
                        }
                        .frame(height: 80)
                    }
                }
            }
            .frame(height: 170)
            .background(Color.gray.opacity(0.2))
            
            // Progress indicator
            HStack {
                Text("START")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                Text("FINISH")
                    .font(.caption2.bold())
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.5))
            
            Spacer()
            
            // Question area
            VStack(spacing: 20) {
                Text(currentQuestion)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .shadow(color: .black, radius: 4)
                
                // Options grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            selectAnswer(option)
                        } label: {
                            Text(option)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(buttonColor(for: option))
                                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                        }
                        .disabled(selected != nil)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.7), Color.black.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    // MARK: - Game Over View
    private var gameOverView: some View {
        VStack(spacing: 24) {
            if playerWon {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                Text("YOU WIN!")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.yellow)
            } else {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                Text("RACE OVER!")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)
            }
            
            Text("Final Score: \(score)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                Button {
                    resetGame()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Race Again")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.yellow)
                    .cornerRadius(12)
                }
                
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Exit")
                    }
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
        .background(Color.black.opacity(0.85))
        .cornerRadius(24)
    }
    
    // MARK: - Helper Functions
    private func buttonColor(for option: String) -> Color {
        if let sel = selected {
            if option == correctAnswer {
                return .green
            } else if option == sel {
                return .red
            }
        }
        return Color.blue.opacity(0.8)
    }
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer.invalidate()
                withAnimation {
                    showCountdown = false
                }
                startOpponentMovement()
                startCarBounce()
            }
        }
    }
    
    private func startCarBounce() {
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            carBounce = -3
        }
    }
    
    private func startOpponentMovement() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if gameOver { timer.invalidate(); return }
            
            withAnimation(.linear(duration: 0.1)) {
                opponentPosition += 0.008 * opponentSpeed
                roadOffset -= 5
            }
            
            if opponentPosition >= 1.0 {
                timer.invalidate()
                endGame(playerWins: false)
            }
        }
    }
    
    private func loadQuestion() {
        if questionsAnswered >= totalQuestions || questionsAnswered >= shuffledQuestions.count {
            endGame(playerWins: playerPosition >= opponentPosition)
            return
        }
        
        let q = shuffledQuestions[questionsAnswered]
        currentQuestion = q.question
        correctAnswer = q.answer
        options = q.options.shuffled()
        selected = nil
    }
    
    private func selectAnswer(_ answer: String) {
        selected = answer
        questionsAnswered += 1
        
        if answer == correctAnswer {
            streak += 1
            let points = 10 + (streak * 2)
            score += points
            
            // Move player forward
            let boost = 0.1 + (CGFloat(streak) * 0.02)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                playerPosition = min(1.0, playerPosition + boost)
                showBoost = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showBoost = false
            }
            
            GameAudioService.shared.playCorrect()
        } else {
            streak = 0
            GameAudioService.shared.playWrong()
        }
        
        // Check for win
        if playerPosition >= 1.0 {
            endGame(playerWins: true)
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            loadQuestion()
        }
    }
    
    private func endGame(playerWins: Bool) {
        gameOver = true
        playerWon = playerWins
        GameLeaderboardService.shared.saveScore(gameId: gameId, score: score)
        if playerWins {
            GameAudioService.shared.playCorrect()
        }
    }
    
    private func resetGame() {
        playerPosition = 0
        opponentPosition = 0
        score = 0
        questionsAnswered = 0
        streak = 0
        gameOver = false
        playerWon = false
        showCountdown = true
        countdown = 3
        shuffledQuestions = questions.shuffled()
        loadQuestion()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startCountdown()
        }
    }
}

// MARK: - Racing Track Background
struct RacingTrackBackground: View {
    @Binding var roadOffset: CGFloat
    
    var body: some View {
        ZStack {
            // Sky gradient
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.8),
                    Color(red: 0.5, green: 0.7, blue: 0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Clouds
            VStack {
                HStack {
                    RacingCloudShape()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 80, height: 40)
                        .offset(x: 50, y: 30)
                    Spacer()
                    RacingCloudShape()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 100, height: 50)
                        .offset(x: -30, y: 50)
                }
                Spacer()
            }
            
            // Ground
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.green.opacity(0.6))
                    .frame(height: 200)
            }
        }
        .ignoresSafeArea()
    }
}

struct RacingCloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: 0, y: rect.height * 0.3, width: rect.width * 0.5, height: rect.height * 0.7))
        path.addEllipse(in: CGRect(x: rect.width * 0.25, y: 0, width: rect.width * 0.5, height: rect.height * 0.8))
        path.addEllipse(in: CGRect(x: rect.width * 0.5, y: rect.height * 0.2, width: rect.width * 0.5, height: rect.height * 0.8))
        return path
    }
}

// MARK: - Car Views
struct PlayerCarView: View {
    let color: Color
    let boost: Bool
    
    var body: some View {
        ZStack {
            // Boost flames
            if boost {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        Ellipse()
                            .fill(LinearGradient(colors: [.yellow, .orange, .red], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 15, height: 8)
                    }
                }
                .offset(x: -35)
            }
            
            // Car body
            ZStack {
                // Main body
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 60, height: 30)
                
                // Windows
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.cyan.opacity(0.6))
                    .frame(width: 25, height: 15)
                    .offset(x: 5, y: -2)
                
                // Wheels
                HStack(spacing: 35) {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 14, height: 14)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 14, height: 14)
                }
                .offset(y: 12)
                
                // Number
                Text("1")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: -15)
            }
        }
    }
}

struct OpponentCarView: View {
    let color: Color
    
    var body: some View {
        ZStack {
            // Car body
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 60, height: 30)
            
            // Windows
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.cyan.opacity(0.6))
                .frame(width: 25, height: 15)
                .offset(x: 5, y: -2)
            
            // Wheels
            HStack(spacing: 35) {
                Circle()
                    .fill(Color.black)
                    .frame(width: 14, height: 14)
                Circle()
                    .fill(Color.black)
                    .frame(width: 14, height: 14)
            }
            .offset(y: 12)
            
            // Number
            Text("2")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .offset(x: -15)
        }
    }
}

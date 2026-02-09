//
//  MathFractionsGameView.swift
//  EZTeach
//
//  A fractions game with pie chart / pizza visual representations
//

import SwiftUI

struct MathFractionsGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var numerator = 1
    @State private var denominator = 4
    @State private var questionType: QuestionType = .identify
    @State private var options: [String] = []
    @State private var correctAnswer = ""
    @State private var selected: String?
    @State private var score = 0
    @State private var round = 0
    @State private var gameOver = false
    @State private var streak = 0
    @State private var pieRotation: Double = 0
    
    enum QuestionType: CaseIterable {
        case identify  // What fraction is shaded?
        case compare   // Which is bigger?
        case equivalent // Which is equal?
    }
    
    private let totalRounds = 10
    
    var body: some View {
        ZStack {
            // Warm pizza-themed background
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.95, blue: 0.9),
                    Color(red: 0.98, green: 0.92, blue: 0.85)
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
                    
                    // Pie visualization
                    pieVisualization
                        .frame(height: 220)
                    
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
            startPieAnimation()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("FRACTIONS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.red)
                Text("Pizza Party 🍕")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.4, green: 0.25, blue: 0.15))
            }
            
            Spacer()
            
            if streak >= 2 {
                Text("🔥 \(streak)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            
            VStack(alignment: .trailing) {
                Text("Q \(round + 1)/\(totalRounds)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(score)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .red.opacity(0.15), radius: 8, y: 4)
        )
    }
    
    private var pieVisualization: some View {
        VStack(spacing: 12) {
            pizzaView
                .rotationEffect(.degrees(pieRotation))
            
            Text("\(numerator) out of \(denominator) slices")
                .font(.subheadline.bold())
                .foregroundColor(Color(red: 0.4, green: 0.25, blue: 0.15))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .orange.opacity(0.2), radius: 10, y: 5)
        )
    }
    
    private var pizzaView: some View {
        ZStack {
            pizzaBase
            pizzaSlices
            sliceLines
            centerDot
            toppingDots
        }
    }
    
    private var pizzaBase: some View {
        ZStack {
            // Pizza base / plate
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 180, height: 180)
            
            // Pizza crust
            Circle()
                .fill(Color(red: 0.85, green: 0.65, blue: 0.4))
                .frame(width: 170, height: 170)
            
            // Pizza sauce (full)
            Circle()
                .fill(Color(red: 0.85, green: 0.3, blue: 0.2))
                .frame(width: 155, height: 155)
        }
    }
    
    private var pizzaSlices: some View {
        let sliceAngle = 360.0 / Double(denominator)
        return ForEach(0..<denominator, id: \.self) { index in
            let startAngle = Angle.degrees(Double(index) * sliceAngle - 90)
            let endAngle = Angle.degrees(Double(index + 1) * sliceAngle - 90)
            let fillColor = index < numerator ? Color.yellow.opacity(0.8) : Color.clear
            PieSlice(startAngle: startAngle, endAngle: endAngle)
                .fill(fillColor)
                .frame(width: 155, height: 155)
        }
    }
    
    private var sliceLines: some View {
        let sliceAngle = 360.0 / Double(denominator)
        let lineColor = Color(red: 0.4, green: 0.25, blue: 0.15)
        return ForEach(0..<denominator, id: \.self) { index in
            Rectangle()
                .fill(lineColor)
                .frame(width: 2, height: 77)
                .offset(y: -38)
                .rotationEffect(.degrees(Double(index) * sliceAngle))
        }
    }
    
    private var centerDot: some View {
        Circle()
            .fill(Color(red: 0.4, green: 0.25, blue: 0.15))
            .frame(width: 8, height: 8)
    }
    
    private var toppingDots: some View {
        let sliceAngle = 360.0 / Double(denominator)
        return ForEach(0..<numerator, id: \.self) { index in
            let angle = Double(index) * sliceAngle + (sliceAngle / 2) - 90
            let xOffset = 50 * cos(angle * .pi / 180)
            let yOffset = 50 * sin(angle * .pi / 180)
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 12, height: 12)
                .offset(x: xOffset, y: yOffset)
        }
    }
    
    private var questionView: some View {
        VStack(spacing: 8) {
            Text(questionText)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.4, green: 0.25, blue: 0.15))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.15))
        )
    }
    
    private var questionText: String {
        switch questionType {
        case .identify:
            return "What fraction of the pizza is highlighted?"
        case .compare:
            return "Which fraction is larger?"
        case .equivalent:
            return "Which fraction equals \(numerator)/\(denominator)?"
        }
    }
    
    private var optionsView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(options, id: \.self) { option in
                Button {
                    selectOption(option)
                } label: {
                    Text(option)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(optionTextColor(option))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(optionBgColor(option))
                                .shadow(color: .orange.opacity(0.15), radius: 6, y: 3)
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
    
    private func optionTextColor(_ option: String) -> Color {
        if let sel = selected {
            if option == correctAnswer { return .white }
            if option == sel { return .white }
        }
        return Color(red: 0.4, green: 0.25, blue: 0.15)
    }
    
    private func optionBgColor(_ option: String) -> Color {
        if let sel = selected {
            if option == correctAnswer { return .green }
            if option == sel && sel != correctAnswer { return .red.opacity(0.8) }
        }
        return .white
    }
    
    private func optionBorderColor(_ option: String) -> Color {
        if let sel = selected {
            if option == correctAnswer { return .green }
            if option == sel && sel != correctAnswer { return .red }
        }
        return .orange.opacity(0.3)
    }
    
    private var gameOverView: some View {
        VStack(spacing: 24) {
            Text("🍕")
                .font(.system(size: 60))
            
            Text("Fraction Master!")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(Color(red: 0.4, green: 0.25, blue: 0.15))
            
            Text("Score: \(score)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.orange)
            
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
                    .background(Color.orange)
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
        let percentage = Double(score) / Double(totalRounds * 10)
        if percentage >= 0.8 { return 3 }
        if percentage >= 0.5 { return 2 }
        if percentage >= 0.3 { return 1 }
        return 0
    }
    
    private func startPieAnimation() {
        withAnimation(.easeInOut(duration: 0.5)) {
            pieRotation = 0
        }
    }
    
    private func generateQuestion() {
        questionType = .identify  // Keep it simple for now
        
        let denominators = [2, 3, 4, 6, 8]
        denominator = denominators.randomElement()!
        numerator = Int.random(in: 1..<denominator)
        
        correctAnswer = "\(numerator)/\(denominator)"
        selected = nil
        
        // Generate wrong options
        var opts = Set<String>()
        opts.insert(correctAnswer)
        while opts.count < 4 {
            let wrongNum = Int.random(in: 1..<denominator + 2)
            let wrongDen = denominator + Int.random(in: -1...1)
            if wrongDen > 1 && wrongNum > 0 && wrongNum < wrongDen {
                let wrong = "\(wrongNum)/\(wrongDen)"
                if wrong != correctAnswer {
                    opts.insert(wrong)
                }
            }
        }
        options = Array(opts).shuffled()
        
        // Animate pie
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            pieRotation = 360
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pieRotation = 0
        }
    }
    
    private func selectOption(_ option: String) {
        selected = option
        let isCorrect = option == correctAnswer
        
        if isCorrect {
            streak += 1
            score += 10 + (streak >= 3 ? 5 : 0)
            GameAudioService.shared.playCorrect()
        } else {
            streak = 0
            GameAudioService.shared.playWrong()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
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

// MARK: - Pie Slice Shape
struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        
        return path
    }
}

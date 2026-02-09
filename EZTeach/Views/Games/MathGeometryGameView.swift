//
//  MathGeometryGameView.swift
//  EZTeach
//
//  A geometry-focused game with shape identification and properties
//

import SwiftUI

struct MathGeometryGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentQuestion: GeometryQuestion?
    @State private var selectedAnswer: String?
    @State private var score = 0
    @State private var round = 0
    @State private var gameOver = false
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var shapeRotation: Double = 0
    @State private var shapeScale: CGFloat = 1.0
    
    private let totalRounds = 10
    
    struct GeometryQuestion {
        let shape: ShapeType
        let questionText: String
        let correctAnswer: String
        let options: [String]
    }
    
    enum ShapeType: String, CaseIterable {
        case triangle, square, rectangle, circle, pentagon, hexagon, oval, diamond
        
        var sides: Int {
            switch self {
            case .triangle: return 3
            case .square, .rectangle, .diamond: return 4
            case .pentagon: return 5
            case .hexagon: return 6
            case .circle, .oval: return 0
            }
        }
        
        var color: Color {
            switch self {
            case .triangle: return .orange
            case .square: return .blue
            case .rectangle: return .green
            case .circle: return .red
            case .pentagon: return .purple
            case .hexagon: return .pink
            case .oval: return .cyan
            case .diamond: return .yellow
            }
        }
    }
    
    private let questions: [GeometryQuestion] = [
        GeometryQuestion(shape: .triangle, questionText: "How many sides does a triangle have?", correctAnswer: "3", options: ["2", "3", "4", "5"]),
        GeometryQuestion(shape: .square, questionText: "What is this shape called?", correctAnswer: "Square", options: ["Circle", "Square", "Triangle", "Rectangle"]),
        GeometryQuestion(shape: .circle, questionText: "How many corners does a circle have?", correctAnswer: "0", options: ["0", "1", "2", "4"]),
        GeometryQuestion(shape: .rectangle, questionText: "A rectangle has ___ sides", correctAnswer: "4", options: ["2", "3", "4", "6"]),
        GeometryQuestion(shape: .pentagon, questionText: "How many sides does a pentagon have?", correctAnswer: "5", options: ["4", "5", "6", "7"]),
        GeometryQuestion(shape: .hexagon, questionText: "What shape has 6 sides?", correctAnswer: "Hexagon", options: ["Pentagon", "Hexagon", "Octagon", "Square"]),
        GeometryQuestion(shape: .diamond, questionText: "What is another name for this shape?", correctAnswer: "Rhombus", options: ["Square", "Rhombus", "Triangle", "Circle"]),
        GeometryQuestion(shape: .oval, questionText: "An oval is like a stretched ___", correctAnswer: "Circle", options: ["Square", "Triangle", "Circle", "Rectangle"]),
        GeometryQuestion(shape: .triangle, questionText: "What shape has 3 corners?", correctAnswer: "Triangle", options: ["Circle", "Square", "Triangle", "Pentagon"]),
        GeometryQuestion(shape: .square, questionText: "All sides of a square are ___", correctAnswer: "Equal", options: ["Different", "Equal", "Curved", "Missing"])
    ]
    
    var body: some View {
        ZStack {
            // Soft gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.9, green: 0.95, blue: 1.0),
                    Color(red: 0.85, green: 0.9, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating shapes in background
            GeometryBackgroundShapes()
            
            if gameOver {
                gameOverView
            } else if let question = currentQuestion {
                VStack(spacing: 24) {
                    headerView
                    
                    // Shape display
                    shapeView(question.shape)
                        .frame(height: 180)
                    
                    // Question
                    Text(question.questionText)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.25, blue: 0.35))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Options
                    optionsGrid(question)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle(gameTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadQuestion()
            startShapeAnimation()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("GEOMETRY")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue.opacity(0.7))
                Text("Shape Quest")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.2, green: 0.25, blue: 0.35))
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Text("Q \(round + 1)/\(totalRounds)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(score)")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .blue.opacity(0.1), radius: 8, y: 4)
        )
    }
    
    private func shapeView(_ shape: ShapeType) -> some View {
        ZStack {
            // Glow effect
            shapeFilledView(shape, opacity: 0.3)
                .blur(radius: 20)
                .frame(width: 130, height: 130)
            
            // Main shape
            shapeGradientView(shape)
                .frame(width: 120, height: 120)
                .overlay(
                    shapeStrokeView(shape)
                        .frame(width: 120, height: 120)
                )
                .shadow(color: shape.color.opacity(0.4), radius: 10, y: 5)
                .rotationEffect(.degrees(shapeRotation))
                .scaleEffect(shapeScale)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
    }
    
    @ViewBuilder
    private func shapeFilledView(_ shape: ShapeType, opacity: Double) -> some View {
        let color = shape.color.opacity(opacity)
        switch shape {
        case .triangle:
            GeometryTriangle().fill(color)
        case .square:
            Rectangle().fill(color)
        case .rectangle:
            RoundedRectangle(cornerRadius: 4).fill(color).scaleEffect(x: 1.3, y: 0.8)
        case .circle:
            Circle().fill(color)
        case .pentagon:
            GeometryPentagon().fill(color)
        case .hexagon:
            GeometryHexagon().fill(color)
        case .oval:
            Ellipse().fill(color)
        case .diamond:
            GeometryDiamond().fill(color)
        }
    }
    
    @ViewBuilder
    private func shapeGradientView(_ shape: ShapeType) -> some View {
        let gradient = LinearGradient(
            colors: [shape.color, shape.color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        switch shape {
        case .triangle:
            GeometryTriangle().fill(gradient)
        case .square:
            Rectangle().fill(gradient)
        case .rectangle:
            RoundedRectangle(cornerRadius: 4).fill(gradient).scaleEffect(x: 1.3, y: 0.8)
        case .circle:
            Circle().fill(gradient)
        case .pentagon:
            GeometryPentagon().fill(gradient)
        case .hexagon:
            GeometryHexagon().fill(gradient)
        case .oval:
            Ellipse().fill(gradient)
        case .diamond:
            GeometryDiamond().fill(gradient)
        }
    }
    
    @ViewBuilder
    private func shapeStrokeView(_ shape: ShapeType) -> some View {
        let strokeStyle = Color.white.opacity(0.5)
        switch shape {
        case .triangle:
            GeometryTriangle().stroke(strokeStyle, lineWidth: 3)
        case .square:
            Rectangle().stroke(strokeStyle, lineWidth: 3)
        case .rectangle:
            RoundedRectangle(cornerRadius: 4).stroke(strokeStyle, lineWidth: 3).scaleEffect(x: 1.3, y: 0.8)
        case .circle:
            Circle().stroke(strokeStyle, lineWidth: 3)
        case .pentagon:
            GeometryPentagon().stroke(strokeStyle, lineWidth: 3)
        case .hexagon:
            GeometryHexagon().stroke(strokeStyle, lineWidth: 3)
        case .oval:
            Ellipse().stroke(strokeStyle, lineWidth: 3)
        case .diamond:
            GeometryDiamond().stroke(strokeStyle, lineWidth: 3)
        }
    }
    
    private func optionsGrid(_ question: GeometryQuestion) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(question.options, id: \.self) { option in
                Button {
                    selectOption(option, correctAnswer: question.correctAnswer)
                } label: {
                    Text(option)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(optionTextColor(option, correct: question.correctAnswer))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(optionBgColor(option, correct: question.correctAnswer))
                                .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(optionBorderColor(option, correct: question.correctAnswer), lineWidth: 2)
                        )
                }
                .disabled(selectedAnswer != nil)
            }
        }
    }
    
    private func optionTextColor(_ option: String, correct: String) -> Color {
        if let sel = selectedAnswer {
            if option == correct { return .white }
            if option == sel { return .white }
        }
        return Color(red: 0.2, green: 0.25, blue: 0.35)
    }
    
    private func optionBgColor(_ option: String, correct: String) -> Color {
        if let sel = selectedAnswer {
            if option == correct { return .green }
            if option == sel && sel != correct { return .red.opacity(0.8) }
        }
        return .white
    }
    
    private func optionBorderColor(_ option: String, correct: String) -> Color {
        if let sel = selectedAnswer {
            if option == correct { return .green }
            if option == sel && sel != correct { return .red }
        }
        return .blue.opacity(0.2)
    }
    
    private var gameOverView: some View {
        VStack(spacing: 24) {
            // Animated shapes
            HStack(spacing: 20) {
                ForEach([ShapeType.triangle, .square, .circle], id: \.rawValue) { shape in
                    shapeFilledView(shape, opacity: 1.0)
                        .frame(width: 40, height: 40)
                }
            }
            
            Text("Geometry Master!")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 0.2, green: 0.25, blue: 0.35))
            
            Text("Score: \(score)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.blue)
            
            // Stars
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
                        Text("Play Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.blue)
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
                .fill(.ultraThickMaterial)
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
    
    private func startShapeAnimation() {
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            shapeRotation = 10
        }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            shapeScale = 1.05
        }
    }
    
    private func loadQuestion() {
        if round < questions.count {
            currentQuestion = questions[round]
            selectedAnswer = nil
            showResult = false
        }
    }
    
    private func selectOption(_ option: String, correctAnswer: String) {
        selectedAnswer = option
        isCorrect = option == correctAnswer
        showResult = true
        
        if isCorrect {
            score += 10
            GameAudioService.shared.playCorrect()
        } else {
            GameAudioService.shared.playWrong()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            round += 1
            if round >= totalRounds || round >= questions.count {
                gameOver = true
                GameLeaderboardService.shared.saveScore(gameId: gameId, score: score)
            } else {
                loadQuestion()
            }
        }
    }
    
    private func resetGame() {
        score = 0
        round = 0
        gameOver = false
        loadQuestion()
    }
}

// MARK: - Custom Shapes for Geometry Game
struct GeometryTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct GeometryPentagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        for i in 0..<5 {
            let angle = (CGFloat(i) * 72 - 90) * .pi / 180
            let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            if i == 0 { path.move(to: point) }
            else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

struct GeometryHexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        for i in 0..<6 {
            let angle = (CGFloat(i) * 60 - 90) * .pi / 180
            let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            if i == 0 { path.move(to: point) }
            else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

struct GeometryDiamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Background Shapes
struct GeometryBackgroundShapes: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .offset(x: geo.size.width * 0.1, y: geo.size.height * 0.1)
                
                GeometryTriangle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .offset(x: geo.size.width * 0.7, y: geo.size.height * 0.15)
                
                Rectangle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .offset(x: geo.size.width * 0.8, y: geo.size.height * 0.7)
                
                GeometryHexagon()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 70, height: 70)
                    .offset(x: geo.size.width * 0.1, y: geo.size.height * 0.75)
            }
        }
    }
}

//
//  GameThemedBackgrounds.swift
//  EZTeach
//
//  Animated themed backgrounds for each game - making every game feel like its own unique world.
//

import SwiftUI

// MARK: - Medieval Castle Theme (Math Games)
struct MedievalCastleBackground: View {
    @State private var torchFlicker = false
    @State private var cloudOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Sky gradient
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.1, blue: 0.3),
                    Color(red: 0.3, green: 0.2, blue: 0.4),
                    Color(red: 0.5, green: 0.3, blue: 0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Floating clouds
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "cloud.fill")
                    .font(.system(size: 60 + CGFloat(i * 20)))
                    .foregroundColor(.white.opacity(0.15))
                    .offset(x: cloudOffset + CGFloat(i * 100) - 150, y: CGFloat(i * 40) - 100)
            }
            
            // Castle silhouette at bottom
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    CastleTower(height: 120)
                    Rectangle().fill(Color.black.opacity(0.8)).frame(width: 60, height: 80)
                    CastleTower(height: 150)
                    Rectangle().fill(Color.black.opacity(0.8)).frame(width: 80, height: 90)
                    CastleTower(height: 100)
                }
                .padding(.bottom, -20)
            }
            
            // Floating torch flames
            ForEach(0..<4, id: \.self) { i in
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                    .opacity(torchFlicker ? 0.6 : 1.0)
                    .scaleEffect(torchFlicker ? 1.1 : 0.9)
                    .offset(x: CGFloat(i * 90) - 140, y: 200)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                cloudOffset = 300
            }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                torchFlicker = true
            }
        }
    }
}

struct CastleTower: View {
    let height: CGFloat
    var body: some View {
        VStack(spacing: 0) {
            // Battlements
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle().fill(Color.black.opacity(0.85)).frame(width: 10, height: 15)
                }
            }
            Rectangle().fill(Color.black.opacity(0.8)).frame(width: 50, height: height)
        }
    }
}

// MARK: - Jungle Theme (Memory Match)
struct JungleBackground: View {
    @State private var leafSway: CGFloat = 0
    @State private var monkeySwing: CGFloat = 0
    @State private var birdFly: CGFloat = -100
    
    var body: some View {
        ZStack {
            // Jungle gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.3, blue: 0.1),
                    Color(red: 0.2, green: 0.5, blue: 0.2),
                    Color(red: 0.15, green: 0.4, blue: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Hanging vines
            ForEach(0..<6, id: \.self) { i in
                VineShape()
                    .stroke(Color.green.opacity(0.6), lineWidth: 3)
                    .frame(width: 30, height: 200)
                    .rotationEffect(.degrees(Double(leafSway) * (i % 2 == 0 ? 1 : -1)))
                    .offset(x: CGFloat(i * 70) - 170, y: -200)
            }
            
            // Swinging monkey
            Image(systemName: "hare.fill")
                .font(.system(size: 40))
                .foregroundColor(.brown)
                .rotationEffect(.degrees(monkeySwing))
                .offset(x: 80, y: -100)
            
            // Flying bird
            Image(systemName: "bird.fill")
                .font(.system(size: 28))
                .foregroundColor(.red)
                .offset(x: birdFly, y: -180)
            
            // Bottom foliage
            VStack {
                Spacer()
                HStack(spacing: -10) {
                    ForEach(0..<8, id: \.self) { i in
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 50 + CGFloat(i % 3) * 15))
                            .foregroundColor(Color.green.opacity(0.7))
                            .rotationEffect(.degrees(Double(i * 30)))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                leafSway = 8
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                monkeySwing = 20
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                birdFly = 400
            }
        }
    }
}

struct VineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: 0))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.height),
            control1: CGPoint(x: rect.minX, y: rect.height * 0.3),
            control2: CGPoint(x: rect.maxX, y: rect.height * 0.7)
        )
        return path
    }
}

// MARK: - Ocean/Underwater Theme (Pattern Game)
struct UnderwaterBackground: View {
    @State private var bubbleOffset: CGFloat = 0
    @State private var fishSwim: CGFloat = -100
    @State private var wavePhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Deep ocean gradient
            LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.2, blue: 0.4),
                    Color(red: 0.0, green: 0.3, blue: 0.5),
                    Color(red: 0.0, green: 0.15, blue: 0.35)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Light rays from surface
            ForEach(0..<5, id: \.self) { i in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 30, height: 300)
                    .rotationEffect(.degrees(Double(i * 8) - 16))
                    .offset(x: CGFloat(i * 50) - 100, y: -150)
            }
            
            // Bubbles rising
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: CGFloat(8 + i % 4 * 4))
                    .offset(
                        x: CGFloat(i * 35) - 180,
                        y: 300 - bubbleOffset - CGFloat(i * 20)
                    )
            }
            
            // Swimming fish
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.caption)
                Circle().frame(width: 4)
            }
            .foregroundColor(.orange)
            .offset(x: fishSwim, y: 50)
            
            Image(systemName: "fish.fill")
                .font(.system(size: 32))
                .foregroundColor(.yellow.opacity(0.8))
                .offset(x: -fishSwim - 50, y: -50)
            
            // Seaweed at bottom
            VStack {
                Spacer()
                HStack(spacing: 20) {
                    ForEach(0..<6, id: \.self) { i in
                        SeaweedShape()
                            .fill(Color.green.opacity(0.6))
                            .frame(width: 20, height: 80 + CGFloat(i % 3) * 30)
                            .offset(x: sin(wavePhase + CGFloat(i)) * 5)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                bubbleOffset = 600
            }
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                fishSwim = 400
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                wavePhase = .pi * 2
            }
        }
    }
}

struct SeaweedShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.midX + 5, y: 0),
            control1: CGPoint(x: rect.minX, y: rect.height * 0.6),
            control2: CGPoint(x: rect.maxX, y: rect.height * 0.3)
        )
        return path
    }
}

// MARK: - Space Theme (Science Games)
struct SpaceBackground: View {
    @State private var starTwinkle = false
    @State private var planetRotate: CGFloat = 0
    @State private var shootingStar: CGFloat = -200
    
    var body: some View {
        ZStack {
            // Deep space
            Color.black
            
            // Stars
            ForEach(0..<40, id: \.self) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: CGFloat(1 + i % 3))
                    .opacity(starTwinkle && i % 3 == 0 ? 0.4 : 1.0)
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -400...400)
                    )
            }
            
            // Nebula glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: 100, y: -150)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .offset(x: -120, y: 100)
            
            // Planet
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.orange, Color.red.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Ellipse()
                        .stroke(Color.orange.opacity(0.6), lineWidth: 3)
                        .frame(width: 90, height: 20)
                        .rotationEffect(.degrees(20))
                )
                .rotationEffect(.degrees(planetRotate))
                .offset(x: -100, y: -200)
            
            // Shooting star
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 60, height: 2)
                .rotationEffect(.degrees(-45))
                .offset(x: shootingStar, y: -shootingStar - 100)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                starTwinkle = true
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                planetRotate = 360
            }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false).delay(2)) {
                shootingStar = 400
            }
        }
    }
}

// MARK: - Ancient Egypt Theme (Social Studies)
struct AncientEgyptBackground: View {
    @State private var sandDrift: CGFloat = 0
    @State private var sunGlow = false
    
    var body: some View {
        ZStack {
            // Desert sky
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.7, blue: 0.4),
                    Color(red: 1.0, green: 0.85, blue: 0.6),
                    Color(red: 0.9, green: 0.75, blue: 0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Sun
            Circle()
                .fill(Color.yellow)
                .frame(width: 80, height: 80)
                .shadow(color: .orange, radius: sunGlow ? 40 : 20)
                .offset(x: 100, y: -250)
            
            // Pyramids
            VStack {
                Spacer()
                ZStack(alignment: .bottom) {
                    PyramidShape()
                        .fill(Color(red: 0.85, green: 0.7, blue: 0.45))
                        .frame(width: 180, height: 140)
                        .offset(x: -60)
                    
                    PyramidShape()
                        .fill(Color(red: 0.8, green: 0.65, blue: 0.4))
                        .frame(width: 140, height: 110)
                        .offset(x: 80)
                    
                    PyramidShape()
                        .fill(Color(red: 0.75, green: 0.6, blue: 0.35))
                        .frame(width: 100, height: 80)
                        .offset(x: 160)
                }
                
                // Sand dunes
                Rectangle()
                    .fill(Color(red: 0.9, green: 0.8, blue: 0.55))
                    .frame(height: 60)
            }
            
            // Drifting sand particles
            ForEach(0..<15, id: \.self) { i in
                Circle()
                    .fill(Color(red: 0.9, green: 0.8, blue: 0.5).opacity(0.4))
                    .frame(width: 4)
                    .offset(x: sandDrift + CGFloat(i * 30) - 200, y: CGFloat(i * 20) + 100)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                sandDrift = 400
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                sunGlow = true
            }
        }
    }
}

struct PyramidShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Enchanted Forest Theme (Speech)
struct EnchantedForestBackground: View {
    @State private var fireflyGlow = false
    @State private var fireflyOffset: [CGPoint] = (0..<8).map { _ in
        CGPoint(x: CGFloat.random(in: -150...150), y: CGFloat.random(in: -300...200))
    }
    
    var body: some View {
        ZStack {
            // Misty forest gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.2),
                    Color(red: 0.15, green: 0.25, blue: 0.2),
                    Color(red: 0.1, green: 0.2, blue: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Tree silhouettes
            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: -20) {
                    ForEach(0..<5, id: \.self) { i in
                        TreeShape()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 80, height: 150 + CGFloat(i % 3) * 40)
                    }
                }
            }
            
            // Fireflies
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 6, height: 6)
                    .shadow(color: .yellow, radius: fireflyGlow ? 10 : 4)
                    .opacity(fireflyGlow && i % 2 == 0 ? 1 : 0.5)
                    .offset(x: fireflyOffset[i].x, y: fireflyOffset[i].y)
            }
            
            // Mist
            ForEach(0..<3, id: \.self) { i in
                Ellipse()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 40)
                    .offset(y: CGFloat(i * 100) + 50)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                fireflyGlow = true
            }
        }
    }
}

struct TreeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Trunk
        let trunkWidth = rect.width * 0.2
        path.addRect(CGRect(
            x: rect.midX - trunkWidth/2,
            y: rect.height * 0.6,
            width: trunkWidth,
            height: rect.height * 0.4
        ))
        // Foliage triangles
        for i in 0..<3 {
            let y = CGFloat(i) * rect.height * 0.25
            let width = rect.width * (1 - CGFloat(i) * 0.2)
            path.move(to: CGPoint(x: rect.midX, y: y))
            path.addLine(to: CGPoint(x: rect.midX + width/2, y: y + rect.height * 0.35))
            path.addLine(to: CGPoint(x: rect.midX - width/2, y: y + rect.height * 0.35))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Japanese Zen Garden Theme (Sudoku)
struct ZenGardenBackground: View {
    @State private var petalsFall: CGFloat = -100
    @State private var ripple: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Soft gradient
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.92, blue: 0.88),
                    Color(red: 0.9, green: 0.85, blue: 0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Sand pattern lines
            ForEach(0..<12, id: \.self) { i in
                SandRippleLine()
                    .stroke(Color(red: 0.8, green: 0.75, blue: 0.65), lineWidth: 1)
                    .frame(height: 20)
                    .offset(y: CGFloat(i * 50) - 200)
            }
            
            // Cherry blossom petals falling
            ForEach(0..<15, id: \.self) { i in
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.pink.opacity(0.7))
                    .rotationEffect(.degrees(Double(i * 45)))
                    .offset(
                        x: CGFloat(i * 30) - 180 + sin(petalsFall / 50 + CGFloat(i)) * 20,
                        y: petalsFall + CGFloat(i * 40)
                    )
            }
            
            // Stone in pond
            VStack {
                Spacer()
                ZStack {
                    // Water ripples
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            .frame(width: 60 + ripple + CGFloat(i * 30))
                    }
                    // Stone
                    Ellipse()
                        .fill(Color.gray)
                        .frame(width: 40, height: 25)
                }
                .offset(x: -80, y: -80)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                petalsFall = 800
            }
            withAnimation(.easeOut(duration: 3).repeatForever(autoreverses: false)) {
                ripple = 50
            }
        }
    }
}

struct SandRippleLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        for x in stride(from: 0, to: rect.width, by: 20) {
            path.addQuadCurve(
                to: CGPoint(x: x + 20, y: rect.midY),
                control: CGPoint(x: x + 10, y: rect.midY - 8)
            )
        }
        return path
    }
}

// MARK: - Peaceful Meadow Theme (Calm Games)
struct PeacefulMeadowBackground: View {
    @State private var butterflyX: CGFloat = -100
    @State private var cloudDrift: CGFloat = 0
    @State private var grassSway: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Sky
            LinearGradient(
                colors: [
                    Color(red: 0.6, green: 0.8, blue: 1.0),
                    Color(red: 0.85, green: 0.92, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Clouds
            ForEach(0..<4, id: \.self) { i in
                CloudShape()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 100, height: 40)
                    .offset(x: cloudDrift + CGFloat(i * 100) - 180, y: CGFloat(i * 30) - 250)
            }
            
            // Sun
            Circle()
                .fill(Color.yellow.opacity(0.9))
                .frame(width: 60, height: 60)
                .offset(x: 120, y: -280)
            
            // Butterfly
            Image(systemName: "ladybug.fill")
                .font(.system(size: 24))
                .foregroundColor(.red)
                .offset(x: butterflyX, y: sin(butterflyX / 30) * 30 - 100)
            
            // Grass and flowers
            VStack {
                Spacer()
                ZStack(alignment: .bottom) {
                    // Grass
                    HStack(spacing: 2) {
                        ForEach(0..<30, id: \.self) { i in
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: 8, height: 40 + CGFloat(i % 5) * 10)
                                .rotationEffect(.degrees(Double(grassSway) * (i % 2 == 0 ? 1 : -1)))
                        }
                    }
                    
                    // Flowers
                    HStack(spacing: 40) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: "flower.fill")
                                .font(.system(size: 20))
                                .foregroundColor([Color.red, .yellow, .pink, .orange, .purple][i % 5])
                                .offset(y: -30)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                butterflyX = 400
            }
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                cloudDrift = 300
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                grassSway = 5
            }
        }
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: 0, y: rect.height * 0.3, width: rect.width * 0.5, height: rect.height * 0.7))
        path.addEllipse(in: CGRect(x: rect.width * 0.25, y: 0, width: rect.width * 0.5, height: rect.height * 0.8))
        path.addEllipse(in: CGRect(x: rect.width * 0.5, y: rect.height * 0.2, width: rect.width * 0.5, height: rect.height * 0.8))
        return path
    }
}

// MARK: - Art Studio Theme (Creative Thinking)
struct ArtStudioBackground: View {
    @State private var splatterScale: [CGFloat] = Array(repeating: 1.0, count: 8)
    @State private var rainbowOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Canvas background
            Color(red: 0.98, green: 0.96, blue: 0.94)
            
            // Paint splatters
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(paintColors[i % paintColors.count])
                    .frame(width: 60 + CGFloat(i * 10))
                    .scaleEffect(splatterScale[i])
                    .offset(
                        x: CGFloat([-120, 80, -60, 140, -150, 100, 20, -100][i]),
                        y: CGFloat([-200, -150, 50, -80, 100, 180, -250, 120][i])
                    )
            }
            
            // Rainbow arc
            RainbowArc()
                .stroke(
                    AngularGradient(
                        colors: [.red, .orange, .yellow, .green, .blue, .purple, .red],
                        center: .bottom
                    ),
                    lineWidth: 15
                )
                .frame(width: 300, height: 150)
                .opacity(0.5)
                .offset(y: -200 + rainbowOffset)
            
            // Pencils/brushes at bottom
            VStack {
                Spacer()
                HStack(spacing: 15) {
                    ForEach(0..<6, id: \.self) { i in
                        Capsule()
                            .fill(paintColors[i])
                            .frame(width: 12, height: 80)
                            .rotationEffect(.degrees(Double(i - 3) * 8))
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            for i in 0..<8 {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 1.5...2.5))
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.2)
                ) {
                    splatterScale[i] = CGFloat.random(in: 0.8...1.2)
                }
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                rainbowOffset = 30
            }
        }
    }
    
    private var paintColors: [Color] {
        [.red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan]
    }
}

struct RainbowArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        return path
    }
}

// MARK: - Safari Theme (Picture Puzzle)
struct SafariBackground: View {
    @State private var animalWalk: CGFloat = -150
    @State private var sunPulse = false
    
    var body: some View {
        ZStack {
            // Savanna gradient
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.75, blue: 0.5),
                    Color(red: 0.85, green: 0.7, blue: 0.4),
                    Color(red: 0.75, green: 0.6, blue: 0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Sun
            Circle()
                .fill(Color.orange)
                .frame(width: 70, height: 70)
                .scaleEffect(sunPulse ? 1.1 : 1.0)
                .offset(x: 100, y: -250)
            
            // Acacia tree silhouette
            VStack {
                Spacer()
                HStack {
                    AcaciaTree()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 120, height: 180)
                        .offset(x: -80)
                    Spacer()
                }
            }
            
            // Walking animals
            HStack(spacing: 20) {
                Image(systemName: "hare.fill")
                    .font(.system(size: 30))
                Image(systemName: "tortoise.fill")
                    .font(.system(size: 25))
            }
            .foregroundColor(.brown.opacity(0.8))
            .offset(x: animalWalk, y: 200)
            
            // Grass at bottom
            VStack {
                Spacer()
                HStack(spacing: 1) {
                    ForEach(0..<40, id: \.self) { i in
                        Rectangle()
                            .fill(Color(red: 0.6, green: 0.5, blue: 0.2))
                            .frame(width: 6, height: 20 + CGFloat(i % 4) * 8)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                animalWalk = 400
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                sunPulse = true
            }
        }
    }
}

struct AcaciaTree: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Trunk
        let trunkWidth = rect.width * 0.1
        path.addRect(CGRect(
            x: rect.midX - trunkWidth/2,
            y: rect.height * 0.4,
            width: trunkWidth,
            height: rect.height * 0.6
        ))
        // Canopy - flat top umbrella shape
        path.addEllipse(in: CGRect(
            x: 0,
            y: 0,
            width: rect.width,
            height: rect.height * 0.5
        ))
        return path
    }
}

// MARK: - Magical Library Theme (Reading/Words)
struct MagicalLibraryBackground: View {
    @State private var bookFloat: [CGFloat] = Array(repeating: 0, count: 5)
    @State private var sparkle = false
    
    var body: some View {
        ZStack {
            // Warm library gradient
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.15, blue: 0.1),
                    Color(red: 0.35, green: 0.25, blue: 0.15),
                    Color(red: 0.25, green: 0.18, blue: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Floating books
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 30 + CGFloat(i * 5)))
                    .foregroundColor([.red, .blue, .green, .purple, .orange][i].opacity(0.7))
                    .rotationEffect(.degrees(Double(i * 15) - 30))
                    .offset(
                        x: CGFloat(i * 60) - 120,
                        y: bookFloat[i] + CGFloat(i * 30) - 100
                    )
            }
            
            // Sparkles
            ForEach(0..<12, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat(8 + i % 4 * 4)))
                    .foregroundColor(.yellow)
                    .opacity(sparkle && i % 2 == 0 ? 1 : 0.3)
                    .offset(
                        x: CGFloat([-100, 80, -60, 120, -140, 40, 100, -80, 60, -120, 140, 0][i]),
                        y: CGFloat([-200, -100, 50, -150, 100, -50, 150, 0, -180, 80, -80, 120][i])
                    )
            }
            
            // Bookshelf at bottom
            VStack {
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<12, id: \.self) { i in
                        Rectangle()
                            .fill([Color.red, .blue, .green, .brown, .purple, .orange][i % 6].opacity(0.8))
                            .frame(width: 20, height: 60 + CGFloat(i % 4) * 10)
                    }
                }
                .padding(.horizontal)
                Rectangle()
                    .fill(Color.brown.opacity(0.9))
                    .frame(height: 20)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            for i in 0..<5 {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 2...4))
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.3)
                ) {
                    bookFloat[i] = CGFloat.random(in: -20...20)
                }
            }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                sparkle = true
            }
        }
    }
}

// MARK: - Knight's Kingdom Theme (Sentence Builder)
struct KnightsKingdomBackground: View {
    @State private var dragonFly: CGFloat = 400
    @State private var flagWave: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Sky
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.5, blue: 0.7),
                    Color(red: 0.6, green: 0.65, blue: 0.8),
                    Color(red: 0.5, green: 0.55, blue: 0.65)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Flying dragon
            Image(systemName: "bird.fill")
                .font(.system(size: 40))
                .foregroundColor(.red.opacity(0.8))
                .scaleEffect(x: -1, y: 1)
                .offset(x: dragonFly, y: -200)
            
            // Castle
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    KingdomTower(height: 140, hasFlag: true, flagWave: flagWave)
                    Rectangle().fill(Color.gray.opacity(0.9)).frame(width: 80, height: 100)
                        .overlay(
                            Rectangle()
                                .fill(Color.brown)
                                .frame(width: 30, height: 50)
                                .offset(y: 25)
                        )
                    KingdomTower(height: 160, hasFlag: true, flagWave: flagWave)
                    Rectangle().fill(Color.gray.opacity(0.9)).frame(width: 60, height: 80)
                    KingdomTower(height: 120, hasFlag: false, flagWave: flagWave)
                }
            }
            
            // Shields decoration
            HStack(spacing: 100) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.red)
                Image(systemName: "shield.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }
            .offset(y: -50)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                dragonFly = -400
            }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                flagWave = 15
            }
        }
    }
}

struct KingdomTower: View {
    let height: CGFloat
    let hasFlag: Bool
    let flagWave: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            if hasFlag {
                // Flag
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.brown)
                        .frame(width: 3, height: 30)
                    Image(systemName: "flag.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .rotationEffect(.degrees(flagWave))
                }
            }
            // Cone top
            PyramidShape()
                .fill(Color.red.opacity(0.8))
                .frame(width: 50, height: 30)
            // Tower body
            Rectangle()
                .fill(Color.gray)
                .frame(width: 40, height: height)
                .overlay(
                    VStack(spacing: 20) {
                        ForEach(0..<Int(height / 40), id: \.self) { _ in
                            Rectangle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 15, height: 20)
                        }
                    }
                )
        }
    }
}

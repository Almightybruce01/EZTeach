//
//  SceneIllustrationView.swift
//  EZTeach
//
//  Rich, multi-layered scene illustrations for picture book pages.
//  Replaces single emoji with full illustrated scenes using SwiftUI shapes,
//  SF Symbols, gradients, and contextual decorations.
//

import SwiftUI

// MARK: - Main Scene Illustration View
struct SceneIllustrationView: View {
    let emoji: String
    let sceneDescription: String
    let storyText: String
    let accentColor: Color
    let nightMode: Bool
    
    // Detect scene environment from text keywords
    private var sceneType: SceneType {
        let lower = (storyText + " " + sceneDescription).lowercased()
        if lower.contains("rain") || lower.contains("storm") || lower.contains("thunder") { return .rainy }
        if lower.contains("night") || lower.contains("moon") || lower.contains("dark") || lower.contains("bed") || lower.contains("sleep") || lower.contains("dream") { return .night }
        if lower.contains("ocean") || lower.contains("sea") || lower.contains("water") || lower.contains("swim") || lower.contains("fish") || lower.contains("boat") || lower.contains("sail") { return .ocean }
        if lower.contains("forest") || lower.contains("tree") || lower.contains("wood") || lower.contains("jungle") || lower.contains("leaf") || lower.contains("garden") { return .forest }
        if lower.contains("snow") || lower.contains("winter") || lower.contains("cold") || lower.contains("ice") || lower.contains("frost") { return .snowy }
        if lower.contains("space") || lower.contains("star") || lower.contains("galaxy") || lower.contains("planet") || lower.contains("rocket") { return .space }
        if lower.contains("house") || lower.contains("room") || lower.contains("home") || lower.contains("kitchen") || lower.contains("inside") || lower.contains("door") { return .indoors }
        if lower.contains("school") || lower.contains("class") || lower.contains("learn") || lower.contains("teacher") { return .school }
        if lower.contains("city") || lower.contains("street") || lower.contains("town") || lower.contains("build") { return .city }
        if lower.contains("mountain") || lower.contains("hill") || lower.contains("climb") { return .mountain }
        if lower.contains("farm") || lower.contains("barn") || lower.contains("cow") || lower.contains("chicken") { return .farm }
        if lower.contains("beach") || lower.contains("sand") || lower.contains("wave") { return .beach }
        return .sunny
    }
    
    // Detect mood/emotion
    private var mood: SceneMood {
        let lower = (storyText + " " + sceneDescription).lowercased()
        if lower.contains("happy") || lower.contains("joy") || lower.contains("laugh") || lower.contains("fun") || lower.contains("love") || lower.contains("smile") { return .happy }
        if lower.contains("sad") || lower.contains("cry") || lower.contains("lone") || lower.contains("miss") { return .sad }
        if lower.contains("scare") || lower.contains("afraid") || lower.contains("fear") || lower.contains("dark") { return .scared }
        if lower.contains("angry") || lower.contains("mad") || lower.contains("upset") || lower.contains("yell") || lower.contains("scream") { return .angry }
        if lower.contains("surprise") || lower.contains("wow") || lower.contains("amaz") || lower.contains("wonder") { return .surprised }
        if lower.contains("brave") || lower.contains("hero") || lower.contains("strong") || lower.contains("adventure") { return .brave }
        if lower.contains("calm") || lower.contains("peace") || lower.contains("quiet") || lower.contains("gentle") { return .calm }
        return .neutral
    }
    
    // Secondary SF Symbol decorations based on text
    private var decorationSymbols: [String] {
        let lower = (storyText + " " + sceneDescription).lowercased()
        var symbols: [String] = []
        // Nature
        if lower.contains("flower") || lower.contains("bloom") { symbols.append("camera.macro") }
        if lower.contains("butterfly") { symbols.append("ladybug.fill") }
        if lower.contains("bird") || lower.contains("fly") { symbols.append("bird.fill") }
        if lower.contains("bee") || lower.contains("bug") { symbols.append("ant.fill") }
        if lower.contains("leaf") || lower.contains("leaves") { symbols.append("leaf.fill") }
        if lower.contains("cloud") { symbols.append("cloud.fill") }
        if lower.contains("sun") || lower.contains("bright") { symbols.append("sun.max.fill") }
        if lower.contains("rainbow") { symbols.append("rainbow") }
        // Weather
        if lower.contains("rain") { symbols.append("cloud.rain.fill") }
        if lower.contains("snow") { symbols.append("snowflake") }
        if lower.contains("wind") { symbols.append("wind") }
        // Objects
        if lower.contains("book") || lower.contains("read") { symbols.append("book.fill") }
        if lower.contains("music") || lower.contains("sing") || lower.contains("song") { symbols.append("music.note") }
        if lower.contains("heart") || lower.contains("love") { symbols.append("heart.fill") }
        if lower.contains("star") || lower.contains("sparkle") { symbols.append("sparkles") }
        if lower.contains("ball") || lower.contains("play") { symbols.append("figure.play") }
        if lower.contains("food") || lower.contains("eat") || lower.contains("cake") || lower.contains("cookie") { symbols.append("fork.knife") }
        if lower.contains("hat") { symbols.append("tshirt.fill") }
        if lower.contains("crown") || lower.contains("king") || lower.contains("queen") { symbols.append("crown.fill") }
        // People
        if lower.contains("friend") || lower.contains("together") { symbols.append("person.2.fill") }
        if lower.contains("family") || lower.contains("mama") || lower.contains("papa") || lower.contains("dad") || lower.contains("mom") { symbols.append("figure.2.and.child.holdinghands") }
        
        // Always include at least one decoration
        if symbols.isEmpty {
            symbols.append("sparkle")
        }
        return Array(symbols.prefix(4))
    }
    
    var body: some View {
        ZStack {
            // Layer 1: Sky / Environment background
            sceneBackground
            
            // Layer 2: Ground / floor element
            groundElement
            
            // Layer 3: Floating decorations
            decorations
            
            // Layer 4: Main character/emoji (large, centered)
            mainCharacter
            
            // Layer 5: Scene description caption
            if !sceneDescription.isEmpty {
                VStack {
                    Spacer()
                    Text(sceneDescription)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(nightMode ? .white.opacity(0.85) : Color(red: 0.25, green: 0.2, blue: 0.15))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(nightMode ? Color.black.opacity(0.5) : Color.white.opacity(0.85))
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        )
                        .padding(.bottom, 16)
                }
            }
            
            // Layer 6: Mood particles
            moodParticles
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [accentColor.opacity(0.4), accentColor.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: accentColor.opacity(0.2), radius: 10, y: 5)
    }
    
    // MARK: - Scene Background
    @ViewBuilder
    private var sceneBackground: some View {
        switch sceneType {
        case .rainy:
            LinearGradient(colors: [Color(red: 0.45, green: 0.52, blue: 0.6), Color(red: 0.55, green: 0.6, blue: 0.68)], startPoint: .top, endPoint: .bottom)
        case .night:
            LinearGradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.25), Color(red: 0.15, green: 0.15, blue: 0.35)], startPoint: .top, endPoint: .bottom)
        case .ocean:
            LinearGradient(colors: [Color(red: 0.4, green: 0.7, blue: 0.9), Color(red: 0.2, green: 0.45, blue: 0.7)], startPoint: .top, endPoint: .bottom)
        case .forest:
            LinearGradient(colors: [Color(red: 0.55, green: 0.75, blue: 0.55), Color(red: 0.3, green: 0.55, blue: 0.3)], startPoint: .top, endPoint: .bottom)
        case .snowy:
            LinearGradient(colors: [Color(red: 0.85, green: 0.9, blue: 0.95), Color(red: 0.75, green: 0.82, blue: 0.9)], startPoint: .top, endPoint: .bottom)
        case .space:
            LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.05, blue: 0.25)], startPoint: .top, endPoint: .bottom)
        case .indoors:
            LinearGradient(colors: [Color(red: 0.92, green: 0.87, blue: 0.78), Color(red: 0.85, green: 0.78, blue: 0.68)], startPoint: .top, endPoint: .bottom)
        case .school:
            LinearGradient(colors: [Color(red: 0.88, green: 0.92, blue: 0.98), Color(red: 0.8, green: 0.85, blue: 0.95)], startPoint: .top, endPoint: .bottom)
        case .city:
            LinearGradient(colors: [Color(red: 0.75, green: 0.82, blue: 0.9), Color(red: 0.6, green: 0.65, blue: 0.75)], startPoint: .top, endPoint: .bottom)
        case .mountain:
            LinearGradient(colors: [Color(red: 0.6, green: 0.75, blue: 0.9), Color(red: 0.5, green: 0.65, blue: 0.55)], startPoint: .top, endPoint: .bottom)
        case .farm:
            LinearGradient(colors: [Color(red: 0.65, green: 0.82, blue: 0.95), Color(red: 0.55, green: 0.75, blue: 0.45)], startPoint: .top, endPoint: .bottom)
        case .beach:
            LinearGradient(colors: [Color(red: 0.55, green: 0.8, blue: 0.95), Color(red: 0.9, green: 0.85, blue: 0.7)], startPoint: .top, endPoint: .bottom)
        case .sunny:
            LinearGradient(colors: [
                accentColor.opacity(0.35),
                accentColor.opacity(0.15),
                Color(red: 0.95, green: 0.92, blue: 0.85)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    // MARK: - Ground Element
    @ViewBuilder
    private var groundElement: some View {
        VStack {
            Spacer()
            switch sceneType {
            case .ocean, .beach:
                // Waves
                ZStack {
                    WaveShape(offset: 0)
                        .fill(Color(red: 0.2, green: 0.5, blue: 0.75).opacity(0.5))
                        .frame(height: 60)
                    WaveShape(offset: 20)
                        .fill(Color(red: 0.25, green: 0.55, blue: 0.8).opacity(0.3))
                        .frame(height: 50)
                }
            case .forest, .farm:
                // Grass
                HillShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.35, green: 0.6, blue: 0.25), Color(red: 0.25, green: 0.5, blue: 0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 70)
            case .snowy:
                HillShape()
                    .fill(Color.white.opacity(0.9))
                    .frame(height: 60)
            case .mountain:
                MountainShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.5, green: 0.55, blue: 0.5), Color(red: 0.35, green: 0.4, blue: 0.35)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 100)
            case .indoors:
                // Floor
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.7, green: 0.6, blue: 0.45), Color(red: 0.6, green: 0.5, blue: 0.35)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 40)
            case .city:
                // Buildings silhouette
                CitylineShape()
                    .fill(Color(red: 0.3, green: 0.32, blue: 0.38).opacity(0.6))
                    .frame(height: 80)
            case .school:
                Rectangle()
                    .fill(Color(red: 0.75, green: 0.72, blue: 0.65))
                    .frame(height: 30)
            case .night:
                // Dark ground
                Rectangle()
                    .fill(Color(red: 0.08, green: 0.08, blue: 0.12))
                    .frame(height: 35)
            default:
                // Simple grass line
                HillShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.45, green: 0.7, blue: 0.35), Color(red: 0.35, green: 0.6, blue: 0.28)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 50)
            }
        }
    }
    
    // MARK: - Main Character (Emoji)
    private var mainCharacter: some View {
        VStack(spacing: 0) {
            // Glow behind character
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.25), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Text(emoji)
                    .font(.system(size: 72))
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
            }
            .offset(y: -10)
        }
    }
    
    // MARK: - Floating Decorations
    private var decorations: some View {
        GeometryReader { geo in
            ForEach(Array(decorationSymbols.enumerated()), id: \.offset) { index, symbol in
                let positions: [(x: CGFloat, y: CGFloat)] = [
                    (0.15, 0.18), (0.85, 0.15), (0.12, 0.72), (0.88, 0.7)
                ]
                let pos = positions[index % positions.count]
                let size: CGFloat = [16, 14, 18, 12][index % 4]
                
                Image(systemName: symbol)
                    .font(.system(size: size))
                    .foregroundStyle(decorationColor(for: symbol))
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                    .position(x: geo.size.width * pos.x, y: geo.size.height * pos.y)
                    .opacity(0.7)
            }
            
            // Scene-specific ambient elements
            if sceneType == .night || sceneType == .space {
                ForEach(0..<8, id: \.self) { i in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 2...5), height: CGFloat.random(in: 2...5))
                        .position(
                            x: CGFloat(((i * 47 + 23) % Int(geo.size.width))),
                            y: CGFloat(((i * 31 + 11) % Int(geo.size.height * 0.5)))
                        )
                        .opacity(Double.random(in: 0.4...0.9))
                }
            }
            
            if sceneType == .rainy {
                ForEach(0..<12, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 2, height: 12)
                        .rotationEffect(.degrees(-15))
                        .position(
                            x: CGFloat(((i * 29 + 7) % Int(geo.size.width))),
                            y: CGFloat(((i * 23 + 15) % Int(geo.size.height * 0.7)))
                        )
                }
            }
            
            if sceneType == .snowy {
                ForEach(0..<10, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: CGFloat(((i * 3 + 2) % 5) + 3))
                        .position(
                            x: CGFloat(((i * 37 + 13) % Int(geo.size.width))),
                            y: CGFloat(((i * 29 + 5) % Int(geo.size.height * 0.8)))
                        )
                }
            }
        }
    }
    
    // MARK: - Mood Particles
    private var moodParticles: some View {
        GeometryReader { geo in
            switch mood {
            case .happy:
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: CGFloat(8 + (i % 3) * 4)))
                        .foregroundColor(.yellow.opacity(0.6))
                        .position(
                            x: CGFloat(((i * 53 + 20) % Int(geo.size.width))),
                            y: CGFloat(((i * 41 + 30) % Int(geo.size.height * 0.6)))
                        )
                }
            case .sad:
                ForEach(0..<4, id: \.self) { i in
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.blue.opacity(0.35))
                        .position(
                            x: CGFloat(((i * 47 + 30) % Int(geo.size.width))),
                            y: CGFloat(((i * 37 + 20) % Int(geo.size.height * 0.5)))
                        )
                }
            case .brave:
                ForEach(0..<4, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: CGFloat(8 + (i % 3) * 3)))
                        .foregroundColor(.orange.opacity(0.5))
                        .position(
                            x: CGFloat(((i * 49 + 15) % Int(geo.size.width))),
                            y: CGFloat(((i * 39 + 25) % Int(geo.size.height * 0.5)))
                        )
                }
            case .surprised:
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "burst.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow.opacity(0.4))
                        .position(
                            x: CGFloat(((i * 61 + 40) % Int(geo.size.width))),
                            y: CGFloat(((i * 43 + 10) % Int(geo.size.height * 0.4)))
                        )
                }
            default:
                EmptyView()
            }
        }
    }
    
    // MARK: - Helpers
    
    private func decorationColor(for symbol: String) -> Color {
        switch symbol {
        case "heart.fill": return .red
        case "sun.max.fill": return .yellow
        case "leaf.fill": return .green
        case "camera.macro": return .pink
        case "music.note": return .purple
        case "sparkles", "sparkle": return .yellow
        case "snowflake": return .cyan
        case "cloud.fill", "cloud.rain.fill": return .gray
        case "bird.fill": return Color(red: 0.5, green: 0.35, blue: 0.2)
        case "crown.fill": return .yellow
        case "star.fill": return .orange
        default: return accentColor
        }
    }
}

// MARK: - Scene Types
enum SceneType {
    case sunny, rainy, night, ocean, forest, snowy, space
    case indoors, school, city, mountain, farm, beach
}

enum SceneMood {
    case happy, sad, scared, angry, surprised, brave, calm, neutral
}

// MARK: - Custom Shapes

struct WaveShape: Shape {
    let offset: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        let waveCount = 4
        let waveWidth = rect.width / CGFloat(waveCount)
        for i in 0..<waveCount {
            let startX = CGFloat(i) * waveWidth
            path.addQuadCurve(
                to: CGPoint(x: startX + waveWidth / 2, y: rect.midY - 8 + offset * 0.2),
                control: CGPoint(x: startX + waveWidth / 4, y: rect.minY + offset * 0.3)
            )
            path.addQuadCurve(
                to: CGPoint(x: startX + waveWidth, y: rect.midY),
                control: CGPoint(x: startX + waveWidth * 3 / 4, y: rect.maxY - offset * 0.2)
            )
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct HillShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.35, y: rect.minY + 5),
            control: CGPoint(x: rect.width * 0.15, y: rect.minY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.65, y: rect.minY + 10),
            control: CGPoint(x: rect.width * 0.5, y: rect.minY + 15)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.width * 0.85, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct MountainShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.15, y: rect.height * 0.5))
        path.addLine(to: CGPoint(x: rect.width * 0.3, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.width * 0.45, y: rect.height * 0.4))
        path.addLine(to: CGPoint(x: rect.width * 0.6, y: rect.height * 0.15))
        path.addLine(to: CGPoint(x: rect.width * 0.75, y: rect.height * 0.45))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct CitylineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        // Building outlines
        let buildings: [(x: CGFloat, width: CGFloat, height: CGFloat)] = [
            (0, 0.12, 0.6), (0.12, 0.08, 0.45), (0.2, 0.1, 0.8),
            (0.3, 0.07, 0.5), (0.37, 0.13, 0.7), (0.5, 0.09, 0.55),
            (0.59, 0.11, 0.9), (0.7, 0.08, 0.5), (0.78, 0.1, 0.65),
            (0.88, 0.12, 0.45)
        ]
        for b in buildings {
            let bx = rect.width * b.x
            let bw = rect.width * b.width
            let bh = rect.height * b.height
            path.addRect(CGRect(x: bx, y: rect.maxY - bh, width: bw, height: bh))
        }
        path.closeSubpath()
        return path
    }
}

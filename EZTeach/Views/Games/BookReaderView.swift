//
//  BookReaderView.swift
//  EZTeach
//
//  Animated book reader with page-turning, covers, and fluent read-aloud.
//

import SwiftUI

struct BookReaderView: View {
    let item: ReadingItem
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var showCover = true
    @State private var isTurningPage = false
    
    private var pages: [String] {
        // Use chapters array whenever it has multiple entries (picture books, chapter books, short stories)
        if item.chapters.count > 1 {
            return item.chapters
        }
        let text = item.fullText.isEmpty ? item.summary : item.fullText
        return splitIntoPages(text, charsPerPage: 400)
    }
    
    private var genreColor: Color {
        switch item.genre {
        case .fiction: return EZTeachColors.softPurple
        case .nonfiction: return EZTeachColors.brightTeal
        case .scifi: return EZTeachColors.softBlue
        case .history: return EZTeachColors.softOrange
        case .mystery: return EZTeachColors.textDark
        case .adventure: return EZTeachColors.tronGreen
        case .fantasy: return EZTeachColors.lightCoral
        case .poetry: return EZTeachColors.warmYellow
        case .biography: return EZTeachColors.softOrange
        }
    }
    
    var body: some View {
        ZStack {
            EZTeachColors.lightAppealGradient.ignoresSafeArea()
            
            if showCover {
                BookCoverView(item: item, genreColor: genreColor) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showCover = false
                    }
                }
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(genreColor)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text(item.title)
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(EZTeachColors.textDark)
                                .lineLimit(1)
                            Text("Page \(currentPage + 1) of \(pages.count)")
                                .font(.caption2)
                                .foregroundColor(EZTeachColors.textMutedLight)
                        }
                        
                        Spacer()
                        
                        Button {
                            GameAudioService.shared.speakFluently(pages[currentPage])
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title3)
                                .foregroundColor(genreColor)
                        }
                    }
                    .padding()
                    
                    // Progress bar
                    GeometryReader { geo in
                        Rectangle()
                            .fill(genreColor.opacity(0.2))
                            .frame(height: 4)
                            .overlay(alignment: .leading) {
                                Rectangle()
                                    .fill(genreColor)
                                    .frame(width: geo.size.width * CGFloat(currentPage + 1) / CGFloat(max(pages.count, 1)))
                                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                            }
                    }
                    .frame(height: 4)
                    
                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            BookPageView(
                                text: pages[i],
                                pageNum: i + 1,
                                totalPages: pages.count,
                                genreColor: genreColor
                            )
                            .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    .animation(.easeInOut(duration: 0.35), value: currentPage)
                    .onChange(of: currentPage) { _, newVal in
                        GameAudioService.shared.stopSpeaking()
                        GameAudioService.shared.speakFluently(pages[newVal])
                    }
                    
                    HStack(spacing: 24) {
                        Spacer()
                        if currentPage > 0 {
                            Button { currentPage -= 1 } label: {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(genreColor)
                            }
                        }
                        if currentPage < pages.count - 1 {
                            Button { currentPage += 1 } label: {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(genreColor)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
        .onAppear {
            if !showCover && !pages.isEmpty {
                GameAudioService.shared.speakFluently(pages[0])
            }
        }
    }
    
    private func splitIntoPages(_ text: String, charsPerPage: Int) -> [String] {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        var result: [String] = []
        var current = ""
        for s in sentences {
            let added = current.isEmpty ? s : current + ". " + s
            if added.count > charsPerPage && !current.isEmpty {
                result.append(current + ".")
                current = s
            } else {
                current = added
            }
        }
        if !current.isEmpty { result.append(current) }
        return result.isEmpty ? [text] : result
    }
}

struct BookCoverView: View {
    let item: ReadingItem
    let genreColor: Color
    let onOpen: () -> Void
    @State private var iconScale: CGFloat = 1.0
    @State private var coverRotation: Double = 0
    @State private var isHovering = false
    @State private var sparklePhase: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Book pages visible from side
                HStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 1) {
                        ForEach(0..<12) { _ in
                            Rectangle()
                                .fill(Color(red: 0.95, green: 0.93, blue: 0.88))
                                .frame(height: 2)
                        }
                    }
                    .frame(width: 16, height: 240)
                    .offset(x: 6)
                }
                
                // 3D Book cover
                ZStack {
                    // Back cover
                    RoundedRectangle(cornerRadius: 8)
                        .fill(genreColor.opacity(0.6))
                        .frame(width: 200, height: 280)
                        .offset(x: 5, y: 4)
                    
                    // Main cover with 3D flip
                    ZStack {
                        // Cover base
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [genreColor, genreColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Texture overlay
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.25), .clear, .black.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Spine shadow
                        HStack {
                            LinearGradient(
                                colors: [.black.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 20)
                            Spacer()
                        }
                        
                        // Cover content
                        VStack(spacing: 16) {
                            // Topic illustration
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 90, height: 90)
                                
                                Image(systemName: item.coverSymbol)
                                    .font(.system(size: 44, weight: .medium))
                                    .foregroundColor(.white.opacity(0.95))
                                    .scaleEffect(iconScale)
                            }
                            
                            Text(item.title)
                                .font(.system(size: 18, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .padding(.horizontal)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                            
                            Text(item.author)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        // Gold decorative border
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                LinearGradient(
                                    colors: [.yellow.opacity(0.7), .orange.opacity(0.5), .yellow.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .padding(8)
                    }
                    .frame(width: 200, height: 280)
                    .rotation3DEffect(
                        .degrees(coverRotation),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .leading,
                        perspective: 0.3
                    )
                }
                
                // Sparkles
                ForEach(0..<4) { i in
                    Image(systemName: "sparkle")
                        .font(.caption)
                        .foregroundColor(.yellow.opacity(0.7))
                        .offset(
                            x: cos(sparklePhase + Double(i) * .pi / 2) * 110,
                            y: sin(sparklePhase + Double(i) * .pi / 2) * 150
                        )
                        .opacity(isHovering ? 1 : 0)
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 15, y: 8)
            .scaleEffect(isHovering ? 1.02 : 1.0)
            
            VStack(spacing: 12) {
                Text("Tap to open")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Image(systemName: "hand.tap.fill")
                    .font(.title)
                    .foregroundColor(genreColor)
                    .offset(y: isHovering ? -5 : 5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.5)) {
                coverRotation = -120
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onOpen()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                iconScale = 1.08
                isHovering = true
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                sparklePhase = .pi * 2
            }
        }
    }
}

struct BookPageView: View {
    let text: String
    let pageNum: Int
    let totalPages: Int
    let genreColor: Color
    
    // Get illustration symbol based on text content
    private var pageIllustration: String {
        let lowered = text.lowercased()
        // Nature & Weather
        if lowered.contains("sun") || lowered.contains("bright") { return "sun.max.fill" }
        if lowered.contains("moon") || lowered.contains("night") { return "moon.stars.fill" }
        if lowered.contains("star") || lowered.contains("twinkle") { return "star.fill" }
        if lowered.contains("cloud") || lowered.contains("sky") { return "cloud.fill" }
        if lowered.contains("rain") || lowered.contains("drop") { return "cloud.rain.fill" }
        if lowered.contains("rainbow") { return "rainbow" }
        if lowered.contains("snow") || lowered.contains("cold") { return "snowflake" }
        if lowered.contains("wind") { return "wind" }
        if lowered.contains("flower") || lowered.contains("garden") { return "camera.macro" }
        if lowered.contains("tree") || lowered.contains("forest") { return "tree.fill" }
        if lowered.contains("leaf") || lowered.contains("leaves") { return "leaf.fill" }
        if lowered.contains("water") || lowered.contains("ocean") || lowered.contains("sea") { return "water.waves" }
        if lowered.contains("mountain") { return "mountain.2.fill" }
        // Animals
        if lowered.contains("bird") || lowered.contains("fly") { return "bird.fill" }
        if lowered.contains("fish") { return "fish.fill" }
        if lowered.contains("cat") || lowered.contains("kitten") { return "cat.fill" }
        if lowered.contains("dog") || lowered.contains("puppy") { return "dog.fill" }
        if lowered.contains("bear") { return "pawprint.fill" }
        if lowered.contains("rabbit") || lowered.contains("bunny") { return "hare.fill" }
        if lowered.contains("butterfly") { return "ladybug.fill" }
        if lowered.contains("bee") { return "ant.fill" }
        // Numbers & Learning
        if lowered.contains("one") || lowered.contains("1") { return "1.circle.fill" }
        if lowered.contains("two") || lowered.contains("2") { return "2.circle.fill" }
        if lowered.contains("three") || lowered.contains("3") { return "3.circle.fill" }
        if lowered.contains("four") || lowered.contains("4") { return "4.circle.fill" }
        if lowered.contains("five") || lowered.contains("5") { return "5.circle.fill" }
        if lowered.contains("six") || lowered.contains("6") { return "6.circle.fill" }
        if lowered.contains("seven") || lowered.contains("7") { return "7.circle.fill" }
        if lowered.contains("eight") || lowered.contains("8") { return "8.circle.fill" }
        if lowered.contains("nine") || lowered.contains("9") { return "9.circle.fill" }
        if lowered.contains("ten") || lowered.contains("10") { return "10.circle.fill" }
        // Shapes
        if lowered.contains("circle") || lowered.contains("round") { return "circle.fill" }
        if lowered.contains("square") { return "square.fill" }
        if lowered.contains("triangle") { return "triangle.fill" }
        if lowered.contains("heart") || lowered.contains("love") { return "heart.fill" }
        // Space
        if lowered.contains("rocket") || lowered.contains("space") { return "airplane" }
        if lowered.contains("planet") { return "globe.americas.fill" }
        if lowered.contains("galaxy") || lowered.contains("comet") { return "sparkles" }
        // Emotions & Actions
        if lowered.contains("happy") || lowered.contains("smile") || lowered.contains("joy") { return "face.smiling.fill" }
        if lowered.contains("sad") || lowered.contains("cry") { return "cloud.rain.fill" }
        if lowered.contains("sleep") || lowered.contains("dream") || lowered.contains("rest") { return "moon.zzz.fill" }
        if lowered.contains("breathe") || lowered.contains("calm") { return "wind" }
        if lowered.contains("run") || lowered.contains("play") { return "figure.run" }
        if lowered.contains("jump") || lowered.contains("hop") { return "figure.jumprope" }
        // Objects
        if lowered.contains("book") || lowered.contains("read") { return "book.fill" }
        if lowered.contains("hat") { return "tshirt.fill" }
        if lowered.contains("ball") { return "basketball.fill" }
        if lowered.contains("house") || lowered.contains("home") { return "house.fill" }
        if lowered.contains("car") || lowered.contains("truck") { return "car.fill" }
        if lowered.contains("boat") || lowered.contains("ship") { return "ferry.fill" }
        if lowered.contains("puzzle") { return "puzzlepiece.fill" }
        if lowered.contains("music") || lowered.contains("song") || lowered.contains("sing") { return "music.note" }
        // People
        if lowered.contains("friend") || lowered.contains("together") { return "person.2.fill" }
        if lowered.contains("family") { return "figure.2.and.child.holdinghands" }
        if lowered.contains("teacher") || lowered.contains("school") { return "graduationcap.fill" }
        // Default based on page number for variety
        let defaults = ["sparkles", "star.fill", "heart.fill", "sun.max.fill", "moon.fill", "leaf.fill", "cloud.fill", "rainbow"]
        return defaults[pageNum % defaults.count]
    }
    
    // Get illustration color based on content
    private var illustrationColor: Color {
        let lowered = text.lowercased()
        if lowered.contains("red") { return .red }
        if lowered.contains("blue") { return .blue }
        if lowered.contains("green") { return .green }
        if lowered.contains("yellow") || lowered.contains("sun") { return .yellow }
        if lowered.contains("orange") { return .orange }
        if lowered.contains("purple") { return .purple }
        if lowered.contains("pink") { return .pink }
        return genreColor
    }
    
    var body: some View {
        ZStack {
            // Book page layers (stacked pages effect)
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.96 - Double(i) * 0.02, green: 0.94 - Double(i) * 0.02, blue: 0.9 - Double(i) * 0.02))
                    .offset(x: CGFloat(3 - i) * 2, y: CGFloat(3 - i) * 2)
            }
            
            // Main page
            ZStack {
                // Paper texture with warm cream color
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.99, green: 0.97, blue: 0.94),
                                Color(red: 0.96, green: 0.94, blue: 0.90)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Page edge shadow (left side for book feel)
                HStack {
                    LinearGradient(
                        colors: [.black.opacity(0.06), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 25)
                    Spacer()
                }
                
                // Content - Picture Book Style Layout
                VStack(spacing: 0) {
                    // ILLUSTRATION AREA (top 50% of page)
                    ZStack {
                        // Soft background for illustration
                        RoundedRectangle(cornerRadius: 16)
                            .fill(illustrationColor.opacity(0.08))
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                        
                        // Decorative border for illustration
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(illustrationColor.opacity(0.2), lineWidth: 2)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                        
                        // Main illustration
                        VStack(spacing: 12) {
                            // Large central icon
                            ZStack {
                                // Glow effect
                                Circle()
                                    .fill(illustrationColor.opacity(0.15))
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 20)
                                
                                // Icon background
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [illustrationColor.opacity(0.3), illustrationColor.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: pageIllustration)
                                    .font(.system(size: 54, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [illustrationColor, illustrationColor.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: illustrationColor.opacity(0.3), radius: 8)
                            }
                            
                            // Decorative sparkles around illustration
                            HStack(spacing: 20) {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 12))
                                    .foregroundColor(illustrationColor.opacity(0.5))
                                Image(systemName: "sparkle")
                                    .font(.system(size: 16))
                                    .foregroundColor(illustrationColor.opacity(0.7))
                                Image(systemName: "sparkle")
                                    .font(.system(size: 12))
                                    .foregroundColor(illustrationColor.opacity(0.5))
                            }
                        }
                        .padding(.top, 30)
                    }
                    .frame(maxHeight: .infinity)
                    
                    // TEXT AREA (bottom portion)
                    VStack(spacing: 16) {
                        // Decorative divider
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(genreColor.opacity(0.3))
                                .frame(width: 30, height: 2)
                            Image(systemName: "book.fill")
                                .font(.system(size: 10))
                                .foregroundColor(genreColor.opacity(0.5))
                            Rectangle()
                                .fill(genreColor.opacity(0.3))
                                .frame(width: 30, height: 2)
                        }
                        
                        // Story text - large, readable, centered for picture books
                        Text(text)
                            .font(.system(size: 22, weight: .medium, design: .serif))
                            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                            .lineSpacing(8)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .minimumScaleFactor(0.7)
                        
                        Spacer(minLength: 8)
                        
                        // Page number with decorative elements
                        HStack {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 8))
                                .foregroundColor(genreColor.opacity(0.4))
                                .rotationEffect(.degrees(-45))
                            Text("— \(pageNum) —")
                                .font(.system(size: 13, weight: .medium, design: .serif))
                                .foregroundColor(genreColor.opacity(0.6))
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 8))
                                .foregroundColor(genreColor.opacity(0.4))
                                .rotationEffect(.degrees(45))
                        }
                        .padding(.bottom, 16)
                    }
                    .frame(maxHeight: .infinity)
                }
                
                // Corner fold effect
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        PageCornerFold(color: genreColor)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .shadow(color: .black.opacity(0.15), radius: 15, y: 8)
        .padding(.horizontal, 16)
    }
}

// MARK: - Page Corner Fold Effect
struct PageCornerFold: View {
    let color: Color
    
    var body: some View {
        ZStack {
            // Fold triangle
            Triangle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.92, green: 0.9, blue: 0.86), Color(red: 0.85, green: 0.82, blue: 0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 30, height: 30)
            
            // Shadow under fold
            Triangle()
                .fill(Color.black.opacity(0.1))
                .frame(width: 30, height: 30)
                .offset(x: -2, y: -2)
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

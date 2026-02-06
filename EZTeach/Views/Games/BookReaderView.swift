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
        if item.bookType == .chapterBook && !item.chapters.isEmpty {
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
                        Text("\(currentPage + 1) / \(pages.count)")
                            .font(.caption)
                            .foregroundColor(EZTeachColors.textMutedLight)
                    }
                    .padding()
                    
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
                        Button {
                            GameAudioService.shared.speakFluently(pages[currentPage])
                        } label: {
                            Label("Read aloud", systemImage: "speaker.wave.2.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(genreColor)
                        }
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
    
    var body: some View {
        ZStack {
            // Book page layers (stacked pages effect)
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.96 - Double(i) * 0.02, green: 0.94 - Double(i) * 0.02, blue: 0.9 - Double(i) * 0.02))
                    .offset(x: CGFloat(3 - i) * 2, y: CGFloat(3 - i) * 2)
            }
            
            // Main page
            ZStack {
                // Paper texture
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.98, green: 0.96, blue: 0.92))
                
                // Page edge shadow (left side for book feel)
                HStack {
                    LinearGradient(
                        colors: [.black.opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 30)
                    Spacer()
                }
                
                // Subtle page lines
                VStack(spacing: 28) {
                    ForEach(0..<10) { _ in
                        Rectangle()
                            .fill(genreColor.opacity(0.03))
                            .frame(height: 1)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 60)
                
                // Content
                VStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text(text)
                                .font(.system(size: 17, design: .serif))
                                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                                .lineSpacing(10)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                    }
                    
                    // Page number
                    Text("— \(pageNum) —")
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 16)
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
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        .padding(.horizontal, 20)
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

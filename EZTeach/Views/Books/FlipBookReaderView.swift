//
//  FlipBookReaderView.swift
//  EZTeach
//
//  Immersive book reader with 3D page flip animations and topic illustrations.
//

import SwiftUI

// MARK: - Main Flip Book Reader
struct FlipBookReaderView: View {
    let book: GutendexBook
    @Environment(\.dismiss) private var dismiss
    @State private var pages: [String] = []
    @State private var currentPage = 0
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showCover = true
    @State private var flipDirection: FlipDirection = .forward
    @State private var isFlipping = false
    
    private var bookColor: Color {
        colorForSubject(book.subjects.first ?? book.title)
    }
    
    var body: some View {
        ZStack {
            // Warm reading background
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.94, blue: 0.88),
                    Color(red: 0.92, green: 0.88, blue: 0.82)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Decorative bookshelf shadow
            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brown.opacity(0.3), Color.brown.opacity(0.1), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: 100)
            }
            .ignoresSafeArea()
            
            if isLoading {
                LoadingBookView(bookColor: bookColor)
            } else if let err = errorMessage {
                BookErrorView(message: err, onDismiss: { dismiss() })
            } else if showCover {
                AnimatedBookCover(
                    book: book,
                    bookColor: bookColor,
                    onOpen: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showCover = false
                        }
                    }
                )
            } else {
                bookContentView
            }
        }
        .onAppear { fetchContent() }
    }
    
    // MARK: - Book Content View
    private var bookContentView: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(bookColor)
                }
                
                Spacer()
                
                Text(book.title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Text("Page \(currentPage + 1) of \(pages.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Book with pages
            ZStack {
                // Book base/shadow
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.brown.opacity(0.2))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: 8, y: 8)
                    .padding(.horizontal, 20)
                
                // Main book container
                HStack(spacing: 0) {
                    // Left page (previous)
                    ZStack {
                        BookPageBackground(isLeft: true, color: bookColor)
                        
                        if currentPage > 0 {
                            BookPageContent(
                                text: pages[currentPage - 1],
                                pageNumber: currentPage,
                                isLeft: true
                            )
                        } else {
                            // Inside cover
                            VStack(spacing: 16) {
                                Image(systemName: iconForSubject(book.subjects.first ?? ""))
                                    .font(.system(size: 40))
                                    .foregroundColor(bookColor.opacity(0.5))
                                Text(book.title)
                                    .font(.headline)
                                    .foregroundColor(bookColor)
                                    .multilineTextAlignment(.center)
                                Text(book.authors.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .onTapGesture {
                        if currentPage > 0 && !isFlipping {
                            flipPage(direction: .backward)
                        }
                    }
                    
                    // Spine
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [bookColor.opacity(0.3), bookColor.opacity(0.5), bookColor.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 12)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0)
                    
                    // Right page (current)
                    ZStack {
                        BookPageBackground(isLeft: false, color: bookColor)
                        
                        BookPageContent(
                            text: pages[currentPage],
                            pageNumber: currentPage + 1,
                            isLeft: false
                        )
                    }
                    .rotation3DEffect(
                        .degrees(isFlipping && flipDirection == .forward ? -90 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .leading,
                        perspective: 0.5
                    )
                    .onTapGesture {
                        if currentPage < pages.count - 1 && !isFlipping {
                            flipPage(direction: .forward)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: .infinity)
            
            // Bottom controls
            HStack(spacing: 32) {
                Button {
                    if currentPage > 0 && !isFlipping {
                        flipPage(direction: .backward)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left.circle.fill")
                        Text("Previous")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(currentPage > 0 ? bookColor : .gray)
                }
                .disabled(currentPage == 0 || isFlipping)
                
                Button {
                    GameAudioService.shared.speakFluently(pages[currentPage])
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(bookColor)
                        .padding(12)
                        .background(Circle().fill(bookColor.opacity(0.15)))
                }
                
                Button {
                    if currentPage < pages.count - 1 && !isFlipping {
                        flipPage(direction: .forward)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Next")
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(currentPage < pages.count - 1 ? bookColor : .gray)
                }
                .disabled(currentPage == pages.count - 1 || isFlipping)
            }
            .padding()
            .background(Color.white.opacity(0.8))
        }
    }
    
    // MARK: - Page Flip Animation
    private func flipPage(direction: FlipDirection) {
        flipDirection = direction
        isFlipping = true
        
        // Play page turn sound
        GameAudioService.shared.playTap()
        
        withAnimation(.easeInOut(duration: 0.4)) {
            if direction == .forward {
                currentPage += 1
            } else {
                currentPage -= 1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isFlipping = false
        }
    }
    
    // MARK: - Fetch Content
    private func fetchContent() {
        guard var urlString = book.textUrl else {
            errorMessage = "No text available for this book."
            isLoading = false
            return
        }
        if urlString.hasPrefix("http://") && urlString.contains("gutenberg") {
            urlString = urlString.replacingOccurrences(of: "http://", with: "https://")
        }
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid book URL."
            isLoading = false
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, err in
            DispatchQueue.main.async {
                isLoading = false
                if let err = err {
                    errorMessage = err.localizedDescription
                    return
                }
                guard let data = data,
                      let str = String(data: data, encoding: .utf8) else {
                    errorMessage = "Could not load book content."
                    return
                }
                let startRange = str.range(of: "*** START OF")
                let endRange = str.range(of: "*** END OF")
                let start = startRange?.upperBound ?? str.startIndex
                let end = endRange?.lowerBound ?? str.endIndex
                let content = String(str[start..<end])
                    .replacingOccurrences(of: "\r\n", with: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                pages = splitIntoPages(content, wordsPerPage: 150)
            }
        }.resume()
    }
    
    private func splitIntoPages(_ text: String, wordsPerPage: Int) -> [String] {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var result: [String] = []
        var current: [String] = []
        
        for word in words {
            current.append(word)
            if current.count >= wordsPerPage {
                result.append(current.joined(separator: " "))
                current = []
            }
        }
        if !current.isEmpty {
            result.append(current.joined(separator: " "))
        }
        return result.isEmpty ? ["No content available."] : result
    }
}

// MARK: - Flip Direction
enum FlipDirection {
    case forward, backward
}

// MARK: - Animated Book Cover
struct AnimatedBookCover: View {
    let book: GutendexBook
    let bookColor: Color
    let onOpen: () -> Void
    
    @State private var coverRotation: Double = 0
    @State private var isHovering = false
    @State private var sparkleOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 32) {
            // 3D Book with cover
            ZStack {
                // Book pages (visible from side)
                HStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 1) {
                        ForEach(0..<15) { _ in
                            Rectangle()
                                .fill(Color(red: 0.95, green: 0.93, blue: 0.88))
                                .frame(height: 2)
                        }
                    }
                    .frame(width: 20, height: 280)
                    .offset(x: 8)
                }
                
                // Book cover with 3D effect
                ZStack {
                    // Back cover shadow
                    RoundedRectangle(cornerRadius: 8)
                        .fill(bookColor.opacity(0.5))
                        .frame(width: 200, height: 280)
                        .offset(x: 6, y: 4)
                    
                    // Main cover
                    ZStack {
                        // Cover background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [bookColor, bookColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Cover texture overlay
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear, .black.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Spine highlight
                        HStack {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.black.opacity(0.3), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 20)
                            Spacer()
                        }
                        
                        // Cover content
                        VStack(spacing: 20) {
                            // Topic illustration
                            TopicIllustration(
                                subject: book.subjects.first ?? book.title,
                                color: .white
                            )
                            .frame(width: 80, height: 80)
                            
                            Text(book.title)
                                .font(.system(size: 18, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .padding(.horizontal, 16)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                            
                            Text(book.authors.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                        }
                        .padding(.vertical, 24)
                        
                        // Gold border
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                LinearGradient(
                                    colors: [.yellow.opacity(0.8), .orange.opacity(0.6), .yellow.opacity(0.8)],
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
                
                // Sparkle effect
                ForEach(0..<5) { i in
                    Image(systemName: "sparkle")
                        .font(.caption)
                        .foregroundColor(.yellow.opacity(0.8))
                        .offset(
                            x: CGFloat.random(in: -100...100),
                            y: CGFloat.random(in: -140...140) + sparkleOffset
                        )
                        .opacity(isHovering ? 1 : 0)
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isHovering = true
                }
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    sparkleOffset = 20
                }
            }
            
            // Open prompt
            VStack(spacing: 12) {
                Text("Tap to open")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Image(systemName: "hand.tap.fill")
                    .font(.title)
                    .foregroundColor(bookColor)
                    .offset(y: isHovering ? -5 : 5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            // Animate cover opening
            withAnimation(.easeOut(duration: 0.5)) {
                coverRotation = -120
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onOpen()
            }
        }
    }
}

// MARK: - Topic Illustration
struct TopicIllustration: View {
    let subject: String
    let color: Color
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(color.opacity(0.2))
            
            // Multiple layered icons for richness
            Image(systemName: iconForSubject(subject))
                .font(.system(size: 36, weight: .light))
                .foregroundColor(color.opacity(0.5))
                .offset(x: 4, y: 4)
            
            Image(systemName: iconForSubject(subject))
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(color)
        }
    }
}

// MARK: - Book Page Background
struct BookPageBackground: View {
    let isLeft: Bool
    let color: Color
    
    var body: some View {
        ZStack {
            // Paper texture
            RoundedRectangle(cornerRadius: isLeft ? UnevenRoundedRectangle.init(cornerRadii: .init(topLeading: 4, bottomLeading: 4, bottomTrailing: 0, topTrailing: 0)).cornerSize.width : 4)
                .fill(Color(red: 0.98, green: 0.96, blue: 0.92))
            
            // Page edge shadow
            HStack {
                if !isLeft {
                    LinearGradient(
                        colors: [.black.opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                }
                Spacer()
                if isLeft {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                }
            }
            
            // Subtle lines
            VStack(spacing: 24) {
                ForEach(0..<12) { _ in
                    Rectangle()
                        .fill(color.opacity(0.05))
                        .frame(height: 1)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
        }
    }
}

// MARK: - Book Page Content
struct BookPageContent: View {
    let text: String
    let pageNumber: Int
    let isLeft: Bool
    
    var body: some View {
        VStack {
            ScrollView {
                Text(text)
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .lineSpacing(8)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
            }
            
            Text("\(pageNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 12)
        }
    }
}

// MARK: - Loading Book View
struct LoadingBookView: View {
    let bookColor: Color
    @State private var rotation: Double = 0
    @State private var pageFlip: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Book shape
                RoundedRectangle(cornerRadius: 8)
                    .fill(bookColor)
                    .frame(width: 80, height: 100)
                    .shadow(color: .black.opacity(0.2), radius: 8)
                
                // Animated pages
                ForEach(0..<3) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: 60, height: 80)
                        .rotation3DEffect(
                            .degrees(pageFlip + Double(i * 30)),
                            axis: (x: 0, y: 1, z: 0),
                            anchor: .leading
                        )
                        .opacity(0.8)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    pageFlip = 180
                }
            }
            
            Text("Loading your book...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ProgressView()
                .tint(bookColor)
        }
    }
}

// MARK: - Book Error View
struct BookErrorView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 60))
                .foregroundColor(.red.opacity(0.6))
            
            Text("Couldn't open book")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                onDismiss()
            } label: {
                Text("Go Back")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Helper Functions
func iconForSubject(_ subject: String) -> String {
    let s = subject.lowercased()
    
    if s.contains("adventure") || s.contains("travel") { return "map.fill" }
    if s.contains("animal") || s.contains("dog") || s.contains("cat") { return "pawprint.fill" }
    if s.contains("science") || s.contains("physics") || s.contains("chemistry") { return "atom" }
    if s.contains("space") || s.contains("astronomy") || s.contains("star") { return "sparkles" }
    if s.contains("ocean") || s.contains("sea") || s.contains("fish") { return "fish.fill" }
    if s.contains("love") || s.contains("romance") { return "heart.fill" }
    if s.contains("mystery") || s.contains("detective") { return "magnifyingglass" }
    if s.contains("horror") || s.contains("ghost") { return "moon.stars.fill" }
    if s.contains("fantasy") || s.contains("magic") || s.contains("wizard") { return "wand.and.stars" }
    if s.contains("history") || s.contains("war") || s.contains("ancient") { return "building.columns.fill" }
    if s.contains("nature") || s.contains("plant") || s.contains("garden") { return "leaf.fill" }
    if s.contains("music") || s.contains("song") { return "music.note" }
    if s.contains("art") || s.contains("paint") { return "paintpalette.fill" }
    if s.contains("cook") || s.contains("food") || s.contains("recipe") { return "fork.knife" }
    if s.contains("sport") || s.contains("game") { return "sportscourt.fill" }
    if s.contains("child") || s.contains("kid") || s.contains("fairy") { return "sparkles" }
    if s.contains("poetry") || s.contains("poem") { return "text.quote" }
    if s.contains("philosophy") || s.contains("think") { return "brain.head.profile" }
    if s.contains("religion") || s.contains("bible") || s.contains("faith") { return "sun.max.fill" }
    if s.contains("biography") || s.contains("life") { return "person.fill" }
    if s.contains("fiction") { return "book.fill" }
    
    return "book.closed.fill"
}

func colorForSubject(_ subject: String) -> Color {
    let s = subject.lowercased()
    
    if s.contains("adventure") || s.contains("travel") { return Color(red: 0.2, green: 0.5, blue: 0.3) }
    if s.contains("animal") { return Color(red: 0.6, green: 0.4, blue: 0.2) }
    if s.contains("science") { return Color(red: 0.2, green: 0.4, blue: 0.6) }
    if s.contains("space") || s.contains("astronomy") { return Color(red: 0.3, green: 0.2, blue: 0.5) }
    if s.contains("ocean") || s.contains("sea") { return Color(red: 0.1, green: 0.4, blue: 0.6) }
    if s.contains("love") || s.contains("romance") { return Color(red: 0.7, green: 0.3, blue: 0.4) }
    if s.contains("mystery") { return Color(red: 0.3, green: 0.3, blue: 0.4) }
    if s.contains("horror") { return Color(red: 0.2, green: 0.15, blue: 0.2) }
    if s.contains("fantasy") || s.contains("magic") { return Color(red: 0.5, green: 0.3, blue: 0.6) }
    if s.contains("history") { return Color(red: 0.5, green: 0.35, blue: 0.2) }
    if s.contains("nature") { return Color(red: 0.3, green: 0.5, blue: 0.3) }
    if s.contains("poetry") { return Color(red: 0.6, green: 0.4, blue: 0.5) }
    if s.contains("child") || s.contains("fairy") { return Color(red: 0.5, green: 0.6, blue: 0.8) }
    
    return Color(red: 0.4, green: 0.3, blue: 0.25)
}

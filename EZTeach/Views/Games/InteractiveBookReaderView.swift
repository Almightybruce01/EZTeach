//
//  InteractiveBookReaderView.swift
//  EZTeach
//
//  Tap-to-reveal interactive books.
//

import SwiftUI

struct InteractiveBookReaderView: View {
    let item: ReadingItem
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var revealedIds: Set<String> = []
    @State private var showCover = true
    
    private var pages: [InteractivePage] {
        item.interactivePages.isEmpty
            ? [InteractivePage(id: "def", text: item.fullText.isEmpty ? item.summary : item.fullText, tapTargets: [])]
            : item.interactivePages
    }
    
    private var genreColor: Color { EZTeachColors.brightTeal }
    
    var body: some View {
        ZStack {
            EZTeachColors.lightAppealGradient.ignoresSafeArea()
            
            if showCover {
                BookCoverView(item: item, genreColor: genreColor) {
                    withAnimation(.easeInOut(duration: 0.5)) { showCover = false }
                }
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(genreColor)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap.fill")
                                .font(.caption2)
                            Text("Interactive")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(genreColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(genreColor.opacity(0.15))
                        .cornerRadius(12)
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text(item.title)
                                .font(.caption2.weight(.medium))
                                .foregroundColor(EZTeachColors.textDark)
                                .lineLimit(1)
                            Text("Page \(currentPage + 1) of \(pages.count)")
                                .font(.caption2)
                                .foregroundColor(EZTeachColors.textMutedLight)
                        }
                    }
                    .padding()
                    
                    // Progress bar
                    GeometryReader { geo in
                        Rectangle()
                            .fill(genreColor.opacity(0.15))
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
                        ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                            InteractivePageView(
                                page: page,
                                revealedIds: $revealedIds,
                                genreColor: genreColor
                            )
                            .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .onChange(of: currentPage) { _, _ in
                        GameAudioService.shared.stopSpeaking()
                    }
                    
                    HStack {
                        if currentPage > 0 {
                            Button { currentPage -= 1 } label: {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(genreColor)
                            }
                        }
                        Spacer()
                        Button {
                            GameAudioService.shared.speakFluently(pages[currentPage].text)
                        } label: {
                            Label("Read aloud", systemImage: "speaker.wave.2.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(genreColor)
                        }
                        Spacer()
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
    }
}

struct InteractivePageView: View {
    let page: InteractivePage
    @Binding var revealedIds: Set<String>
    let genreColor: Color
    
    private var allRevealed: Bool {
        page.tapTargets.allSatisfy { revealedIds.contains($0.id) }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Story text with large, friendly font
                Text(page.text)
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundColor(EZTeachColors.textDark)
                    .lineSpacing(8)
                
                if !page.tapTargets.isEmpty {
                    // Instruction
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                            .font(.caption)
                        Text(page.tapTargets.count == 1 ? "Tap to discover:" : "Tap each one to discover:")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(genreColor)
                    .padding(.top, 4)
                    
                    // Tap targets
                    VStack(spacing: 14) {
                        ForEach(page.tapTargets) { target in
                            let isRevealed = revealedIds.contains(target.id)
                            Button {
                                _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    revealedIds.insert(target.id)
                                }
                                GameAudioService.shared.speakFluently(target.hiddenText)
                                GameAudioService.shared.playTap()
                            } label: {
                                HStack(spacing: 12) {
                                    // Icon
                                    ZStack {
                                        Circle()
                                            .fill(isRevealed ? genreColor : genreColor.opacity(0.15))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: isRevealed ? "checkmark" : "hand.tap.fill")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(isRevealed ? .white : genreColor)
                                    }
                                    
                                    // Text
                                    VStack(alignment: .leading, spacing: 4) {
                                        if isRevealed {
                                            Text(target.hiddenText)
                                                .font(.system(size: 16, weight: .medium, design: .serif))
                                                .foregroundColor(EZTeachColors.textDark)
                                                .multilineTextAlignment(.leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                        } else {
                                            Text("Tap to discover!")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(genreColor)
                                            Text("Something amazing is hiding here...")
                                                .font(.caption)
                                                .foregroundColor(EZTeachColors.textMutedLight)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if !isRevealed {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(genreColor.opacity(0.6))
                                    }
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(isRevealed ? genreColor.opacity(0.1) : Color.white)
                                        .shadow(color: isRevealed ? .clear : genreColor.opacity(0.15), radius: 6, y: 3)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(isRevealed ? genreColor.opacity(0.3) : genreColor.opacity(0.2), lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(isRevealed ? 1.0 : 1.0)
                        }
                    }
                    
                    // Completion indicator
                    if allRevealed && page.tapTargets.count > 1 {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("All discovered! Swipe to continue →")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(genreColor)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .padding(24)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.99, green: 0.97, blue: 0.94))
                .shadow(color: .black.opacity(0.1), radius: 16, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(genreColor.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}


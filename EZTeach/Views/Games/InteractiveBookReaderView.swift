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
                        Text("Interactive")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(genreColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(genreColor.opacity(0.2))
                            .cornerRadius(12)
                        Spacer()
                        Text("\(currentPage + 1) / \(pages.count)")
                            .font(.caption)
                            .foregroundColor(EZTeachColors.textMutedLight)
                    }
                    .padding()
                    
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
    }
}

struct InteractivePageView: View {
    let page: InteractivePage
    @Binding var revealedIds: Set<String>
    let genreColor: Color
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(page.text)
                    .font(.title3)
                    .foregroundColor(EZTeachColors.textDark)
                    .lineSpacing(8)
                
                if !page.tapTargets.isEmpty {
                    Text("Tap to discover:")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(genreColor)
                    
                    VStack(spacing: 12) {
                        ForEach(page.tapTargets) { target in
                            Button {
                                _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    revealedIds.insert(target.id)
                                }
                                GameAudioService.shared.speakFluently(target.hiddenText)
                                GameAudioService.shared.playTap()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: revealedIds.contains(target.id) ? "checkmark.circle.fill" : "hand.tap.fill")
                                        .foregroundColor(revealedIds.contains(target.id) ? genreColor : .gray)
                                    Text(revealedIds.contains(target.id) ? target.hiddenText : "Tap me!")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(revealedIds.contains(target.id) ? EZTeachColors.textDark : genreColor)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(revealedIds.contains(target.id) ? genreColor.opacity(0.15) : Color.white.opacity(0.8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(genreColor.opacity(revealedIds.contains(target.id) ? 0.5 : 0.3), lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(EZTeachColors.cardWhite)
                .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(genreColor.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}


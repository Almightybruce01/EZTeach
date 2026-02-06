//
//  ReadingsByLevelView.swift
//  EZTeach
//
//  Fiction, non-fiction, sci-fi, history by reading level. Read-aloud support.
//

import SwiftUI

enum ReadingGenre: String, CaseIterable, Identifiable {
    case fiction = "Fiction"
    case nonfiction = "Non-Fiction"
    case scifi = "Sci-Fi"
    case history = "History"
    case mystery = "Mystery"
    case adventure = "Adventure"
    case fantasy = "Fantasy"
    case poetry = "Poetry"
    case biography = "Biography"
    var id: String { rawValue }
}

enum BookType: String, CaseIterable, Identifiable {
    case pictureBook = "Picture Book"
    case chapterBook = "Chapter Book"
    case shortStory = "Short Story"
    case interactive = "Interactive"
    var id: String { rawValue }
}

struct ReadingLevel: Identifiable {
    let id: Int
    let name: String
    let grades: String
    static let levels: [ReadingLevel] = [
        .init(id: 1, name: "Level 1", grades: "K–1"),
        .init(id: 2, name: "Level 2", grades: "2"),
        .init(id: 3, name: "Level 3", grades: "3"),
        .init(id: 4, name: "Level 4", grades: "4"),
        .init(id: 5, name: "Level 5", grades: "5"),
        .init(id: 6, name: "Level 6", grades: "6–8"),
        .init(id: 7, name: "Level 7", grades: "9–12")
    ]
}

struct ReadingItem: Identifiable {
    let id: String
    let title: String
    let author: String
    let genre: ReadingGenre
    let level: Int
    let summary: String
    let fullText: String
    let bookType: BookType
    /// For chapter books: array of chapter texts
    let chapters: [String]
    /// SF Symbol for book cover
    let coverSymbol: String
    /// Interactive: tap-to-reveal, choices
    let isInteractive: Bool
    /// For interactive books: pages with tap targets
    let interactivePages: [InteractivePage]
    
    init(id: String, title: String, author: String, genre: ReadingGenre, level: Int, summary: String, fullText: String, bookType: BookType = .shortStory, chapters: [String] = [], coverSymbol: String? = nil, isInteractive: Bool = false, interactivePages: [InteractivePage] = []) {
        self.id = id
        self.title = title
        self.author = author
        self.genre = genre
        self.level = level
        self.summary = summary
        self.fullText = fullText
        self.bookType = bookType
        self.chapters = chapters.isEmpty ? [fullText] : chapters
        self.coverSymbol = coverSymbol ?? Self.defaultCover(for: genre)
        self.isInteractive = isInteractive
        self.interactivePages = interactivePages
    }
    
    private static func defaultCover(for genre: ReadingGenre) -> String {
        switch genre {
        case .fiction: return "book.fill"
        case .nonfiction: return "leaf.fill"
        case .scifi: return "sparkles"
        case .history: return "building.columns.fill"
        case .mystery: return "magnifyingglass"
        case .adventure: return "map.fill"
        case .fantasy: return "wand.and.stars"
        case .poetry: return "quote.bubble.fill"
        case .biography: return "person.crop.circle.fill"
        }
    }
}

struct InteractivePage: Identifiable {
    let id: String
    let text: String
    let tapTargets: [InteractiveTapTarget]
}

struct InteractiveTapTarget: Identifiable {
    let id: String
    let hiddenText: String
    let position: Int
}

struct ReadingsByLevelView: View {
    let gradeLevel: Int
    @State private var searchText = ""
    @State private var selectedGenre: ReadingGenre = .fiction
    @State private var selectedBookType: BookType?
    @State private var selectedLevel: Int
    @State private var sampleReadings: [ReadingItem] = []
    
    init(gradeLevel: Int) {
        self.gradeLevel = gradeLevel
        let def: Int
        switch gradeLevel {
        case 0, 1: def = 1
        case 2: def = 2
        case 3: def = 3
        case 4: def = 4
        case 5: def = 5
        case 6, 7, 8: def = 6
        default: def = min(7, max(1, gradeLevel))
        }
        _selectedLevel = State(initialValue: def)
    }
    
    var body: some View {
        ZStack {
            EZTeachColors.lightAppealGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("READINGS BY LEVEL")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(EZTeachColors.textMutedLight)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(EZTeachColors.softPurple)
                        TextField("Search by title or author...", text: $searchText)
                            .foregroundColor(EZTeachColors.textDark)
                            .autocorrectionDisabled()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(EZTeachColors.cardWhite)
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(EZTeachColors.softPurple.opacity(0.3), lineWidth: 1)
                    )
                    
                    Text("Categories")
                        .font(.caption)
                        .foregroundColor(EZTeachColors.textMutedLight)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            Button {
                                selectedBookType = selectedBookType == .interactive ? nil : .interactive
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "hand.tap.fill")
                                    Text("Interactive")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selectedBookType == .interactive ? .white : EZTeachColors.textDark)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedBookType == .interactive ? EZTeachColors.brightTeal : Color.white.opacity(0.8))
                                .cornerRadius(20)
                                .shadow(color: selectedBookType == .interactive ? EZTeachColors.brightTeal.opacity(0.3) : .clear, radius: 6)
                            }
                            .buttonStyle(.plain)
                            ForEach(ReadingGenre.allCases) { g in
                                Button {
                                    selectedGenre = g
                                    if selectedBookType == .interactive { selectedBookType = nil }
                                } label: {
                                    Text(g.rawValue)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(selectedGenre == g ? .white : EZTeachColors.textDark)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedGenre == g ? EZTeachColors.softPurple : Color.white.opacity(0.8))
                                        .cornerRadius(20)
                                        .shadow(color: selectedGenre == g ? EZTeachColors.softPurple.opacity(0.3) : .clear, radius: 6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Book type")
                            .font(.caption)
                            .foregroundColor(EZTeachColors.textMutedLight)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                Button {
                                    selectedBookType = nil
                                } label: {
                                    Text("All")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(selectedBookType == nil ? .white : EZTeachColors.textDark)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedBookType == nil ? EZTeachColors.lightCoral : Color.white.opacity(0.8))
                                        .cornerRadius(16)
                                }
                                .buttonStyle(.plain)
                                ForEach(BookType.allCases) { bt in
                                    Button {
                                        selectedBookType = bt
                                    } label: {
                                        Text(bt.rawValue)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(selectedBookType == bt ? .white : EZTeachColors.textDark)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedBookType == bt ? EZTeachColors.lightCoral : Color.white.opacity(0.8))
                                            .cornerRadius(16)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Text("Level")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Picker("Level", selection: $selectedLevel) {
                        ForEach(ReadingLevel.levels) { l in
                            Text("\(l.name) (\(l.grades))").tag(l.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(EZTeachColors.softPurple)
                    
                    if sampleReadings.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 48))
                                .foregroundColor(EZTeachColors.tronPink.opacity(0.6))
                            Text(!searchText.trimmingCharacters(in: .whitespaces).isEmpty ? "No books match your search" : "Try a different level or genre")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(!searchText.trimmingCharacters(in: .whitespaces).isEmpty ? "Try different keywords or tap a category above." : "Tap the read-aloud button on any card to hear the story.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    } else {
                        ForEach(sampleReadings) { r in
                            NavigationLink {
                                if r.isInteractive {
                                    InteractiveBookReaderView(item: r)
                                } else {
                                    BookReaderView(item: r)
                                }
                            } label: {
                                ReadingCard(item: r)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Readings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadSample() }
        .onChange(of: selectedGenre) { _, _ in loadSample() }
        .onChange(of: selectedLevel) { _, _ in loadSample() }
        .onChange(of: searchText) { _, _ in loadSample() }
        .onChange(of: selectedBookType) { _, _ in loadSample() }
    }
    
    private func loadSample() {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty {
            var searchResults = ReadingContentLibrary.search(query: q)
            searchResults = searchResults.filter { $0.genre == selectedGenre }
            if searchResults.isEmpty { searchResults = ReadingContentLibrary.search(query: q) }
            if let bt = selectedBookType {
                searchResults = bt == .interactive ? searchResults.filter { $0.isInteractive } : searchResults.filter { $0.bookType == bt }
            }
            sampleReadings = searchResults
        } else if selectedBookType == .interactive {
            sampleReadings = ReadingContentLibrary.interactiveBooks.filter { abs($0.level - selectedLevel) <= 1 }
            if sampleReadings.isEmpty { sampleReadings = ReadingContentLibrary.interactiveBooks }
        } else {
            sampleReadings = ReadingContentLibrary.filter(genre: selectedGenre, level: selectedLevel, bookType: selectedBookType)
        }
    }
}

struct ReadingCard: View {
    let item: ReadingItem
    @State private var selectedChapter = 0
    
    private var textToRead: String {
        if item.bookType == .chapterBook && !item.chapters.isEmpty {
            return item.chapters[selectedChapter]
        }
        return item.fullText.isEmpty ? item.summary : item.fullText
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
        HStack(spacing: 16) {
            BookCoverThumb(symbol: item.coverSymbol, color: genreColor)
            VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(EZTeachColors.textDark)
                    HStack(spacing: 8) {
                        Text(item.bookType.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(genreColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(genreColor.opacity(0.2))
                            .cornerRadius(6)
                        Text(item.genre.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(EZTeachColors.textMutedLight)
                    }
                }
                Spacer()
                Button {
                    GameAudioService.shared.speakFluently(textToRead)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundColor(genreColor)
                }
            }
            Text(item.author)
                .font(.caption)
                .foregroundColor(EZTeachColors.textMutedLight)
            if item.bookType == .chapterBook && item.chapters.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<item.chapters.count, id: \.self) { i in
                            Button {
                                selectedChapter = i
                            } label: {
                                Text("Ch \(i + 1)")
                                    .font(.caption)
                                    .foregroundColor(selectedChapter == i ? .white : EZTeachColors.textDark)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(selectedChapter == i ? genreColor : Color.white.opacity(0.6))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                Text(item.chapters[selectedChapter])
                    .font(.subheadline)
                    .foregroundColor(EZTeachColors.textDark)
                    .lineLimit(6)
            }
            Text(item.summary)
                .font(.subheadline)
                .foregroundColor(EZTeachColors.textMutedLight)
                .lineLimit(3)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(EZTeachColors.cardWhite)
                .shadow(color: .black.opacity(0.06), radius: 10, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(genreColor.opacity(0.3), lineWidth: 1)
        )
    }
}

struct BookCoverThumb: View {
    let symbol: String
    let color: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.9), color.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 76)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

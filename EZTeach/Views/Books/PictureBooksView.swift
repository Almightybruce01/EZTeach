//
//  PictureBooksView.swift
//  EZTeach
//
//  Browse and read 100 classic picture books
//

import SwiftUI

struct PictureBooksView: View {
    @State private var searchText = ""
    @State private var selectedCategory: PictureBookCategory?
    @State private var selectedLevel: PictureBook.ReadingLevel?
    @State private var selectedBook: PictureBook?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Search bar
                    searchBar
                    
                    // Filter pills
                    filterSection
                    
                    // Featured section
                    if searchText.isEmpty && selectedCategory == nil && selectedLevel == nil {
                        featuredSection
                    }
                    
                    // Books grid
                    booksSection
                }
                .padding(.bottom, 40)
            }
            .background(Color(red: 0.97, green: 0.95, blue: 0.93))
            .navigationTitle("Picture Books")
            .preferredColorScheme(.light)
            .fullScreenCover(item: $selectedBook) { book in
                PictureBookReaderView(book: book)
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search books, authors...", text: $searchText)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Reading Level Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PictureBook.ReadingLevel.allCases, id: \.self) { level in
                        FilterPillView(
                            title: level.rawValue,
                            isSelected: selectedLevel == level,
                            color: level.color
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                if selectedLevel == level {
                                    selectedLevel = nil
                                } else {
                                    selectedLevel = level
                                    selectedCategory = nil
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Category Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PictureBookCategory.allCases, id: \.self) { category in
                        CategoryPillView(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                if selectedCategory == category {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category
                                    selectedLevel = nil
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Featured Section
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                Text("Featured Books")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(PictureBooksLibrary.featured) { book in
                        FeaturedBookCard(book: book) {
                            selectedBook = book
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Books Section
    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(filteredBooks.count) Books")
                    .font(.headline)
                Spacer()
                Text(sectionTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(filteredBooks) { book in
                    BookGridCard(book: book) {
                        selectedBook = book
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Filtered Books
    private var filteredBooks: [PictureBook] {
        var books = PictureBooksLibrary.allBooks
        
        if !searchText.isEmpty {
            books = PictureBooksLibrary.search(searchText)
        } else if let category = selectedCategory {
            books = PictureBooksLibrary.books(for: category)
        } else if let level = selectedLevel {
            books = PictureBooksLibrary.books(for: level)
        }
        
        return books
    }
    
    private var sectionTitle: String {
        if !searchText.isEmpty {
            return "Search Results"
        } else if let category = selectedCategory {
            return category.rawValue
        } else if let level = selectedLevel {
            return level.rawValue
        }
        return "All Books"
    }
}

// MARK: - Filter Pill View
struct FilterPillView: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.15))
                .cornerRadius(20)
        }
    }
}

// MARK: - Category Pill View
struct CategoryPillView: View {
    let category: PictureBookCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(isSelected ? .white : category.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? category.color : category.color.opacity(0.15))
            .cornerRadius(20)
        }
    }
}

// MARK: - Featured Book Card
struct FeaturedBookCard: View {
    let book: PictureBook
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Cover
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [book.coverColor, book.coverColor.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 180)
                    
                    // Subtle shine (not white wash)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 180)
                    
                    Text(book.coverEmoji)
                        .font(.system(size: 60))
                    
                    // Reading level badge
                    VStack {
                        Spacer()
                        HStack {
                            Text(book.readingLevel.rawValue)
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(book.readingLevel.color)
                                .cornerRadius(8)
                            Spacer()
                        }
                        .padding(8)
                    }
                }
                .shadow(color: book.coverColor.opacity(0.3), radius: 8, y: 4)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(width: 140, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Book Grid Card
struct BookGridCard: View {
    let book: PictureBook
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Cover
                ZStack {
                    // Solid vibrant book cover
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [book.coverColor, book.coverColor.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(3/4, contentMode: .fit)
                    
                    // Subtle shine effect (NOT white overlay)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(3/4, contentMode: .fit)
                    
                    VStack(spacing: 8) {
                        Text(book.coverEmoji)
                            .font(.system(size: 44))
                        
                        Text(book.title)
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 8)
                    }
                }
                .shadow(color: book.coverColor.opacity(0.35), radius: 6, y: 3)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack {
                        Image(systemName: book.category.icon)
                            .font(.caption2)
                            .foregroundColor(book.category.color)
                        
                        Text("\(book.pages) pages")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(book.readingLevel.rawValue)
                            .font(.caption2.bold())
                            .foregroundColor(book.readingLevel.color)
                    }
                }
            }
            .padding(12)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Picture Book Reader View
struct PictureBookReaderView: View {
    let book: PictureBook
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var showInfo = false
    @State private var readAloud = false
    @State private var fontSize: CGFloat = 20
    @State private var nightMode = false
    @State private var storyPages: [StoryPage] = []
    
    var body: some View {
        ZStack {
            // Background — always use a single gradient (no if/else branching)
            LinearGradient(
                colors: nightMode
                    ? [Color.black, Color.black]
                    : [book.coverColor.opacity(0.15), Color(red: 0.97, green: 0.95, blue: 0.92), book.coverColor.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if storyPages.isEmpty {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading story...")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))
                }
            } else {
                VStack(spacing: 0) {
                    // Header
                    header
                    
                    // Progress bar
                    GeometryReader { geo in
                        Rectangle()
                            .fill(book.coverColor.opacity(0.2))
                            .frame(height: 4)
                            .overlay(alignment: .leading) {
                                Rectangle()
                                    .fill(book.coverColor)
                                    .frame(width: geo.size.width * CGFloat(currentPage + 1) / CGFloat(max(storyPages.count, 1)))
                            }
                    }
                    .frame(height: 4)
                    
                    // Page content
                    TabView(selection: $currentPage) {
                        ForEach(Array(storyPages.enumerated()), id: \.offset) { index, page in
                            pageView(page)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onChange(of: currentPage) { _, _ in
                        // Auto-read on page swipe
                        if readAloud {
                            speakPage()
                        }
                    }
                    
                    // Bottom controls
                    bottomControls
                }
            }
        }
        .onAppear {
            if storyPages.isEmpty {
                storyPages = generateStory(for: book)
            }
        }
        .sheet(isPresented: $showInfo) {
            bookInfoSheet
        }
        .preferredColorScheme(nightMode ? .dark : .light)
    }
    
    // Fixed dark/light text colors
    private var textColor: Color {
        nightMode ? .white : Color(red: 0.15, green: 0.12, blue: 0.1)
    }
    private var subtextColor: Color {
        nightMode ? .white.opacity(0.7) : Color(red: 0.45, green: 0.42, blue: 0.4)
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(subtextColor)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(book.title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                
                Text("Page \(currentPage + 1) of \(storyPages.count)")
                    .font(.caption2)
                    .foregroundColor(subtextColor)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button {
                    readAloud.toggle()
                    if readAloud {
                        speakPage()
                    } else {
                        GameAudioService.shared.stopSpeaking()
                    }
                } label: {
                    Image(systemName: readAloud ? "speaker.wave.3.fill" : "speaker.wave.2")
                        .font(.title3)
                        .foregroundColor(readAloud ? book.coverColor : subtextColor)
                }
                
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(subtextColor)
                }
            }
        }
        .padding()
        .background(
            nightMode
                ? Color.black.opacity(0.85)
                : book.coverColor.opacity(0.08)
        )
    }
    
    // MARK: - Page View
    private func pageView(_ page: StoryPage) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Full scene illustration
                SceneIllustrationView(
                    emoji: page.illustration,
                    sceneDescription: page.sceneDescription,
                    storyText: page.text + (page.dialogue ?? ""),
                    accentColor: book.coverColor,
                    nightMode: nightMode
                )
                .padding(.horizontal)
                
                // Story text
                VStack(alignment: .leading, spacing: 16) {
                    Text(page.text)
                        .font(.system(size: fontSize, weight: .medium, design: .serif))
                        .foregroundColor(textColor)
                        .lineSpacing(8)
                        .multilineTextAlignment(.center)
                    
                    if let dialogue = page.dialogue {
                        Text("\"\(dialogue)\"")
                            .font(.system(size: fontSize + 2, weight: .semibold, design: .serif))
                            .foregroundColor(nightMode ? book.coverColor : book.coverColor.opacity(0.9))
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(book.coverColor.opacity(nightMode ? 0.15 : 0.08))
                            )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        HStack(spacing: 40) {
            // Previous
            Button {
                if currentPage > 0 {
                    withAnimation(.spring(response: 0.4)) {
                        currentPage -= 1
                    }
                    if readAloud { speakPage() }
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(currentPage > 0 ? book.coverColor : .gray.opacity(0.3))
            }
            .disabled(currentPage == 0)
            
            // Page dots
            HStack(spacing: 6) {
                ForEach(0..<min(storyPages.count, 12), id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? book.coverColor : .gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            // Next
            Button {
                if currentPage < storyPages.count - 1 {
                    withAnimation(.spring(response: 0.4)) {
                        currentPage += 1
                    }
                    if readAloud { speakPage() }
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(currentPage < storyPages.count - 1 ? book.coverColor : .gray.opacity(0.3))
            }
            .disabled(currentPage >= storyPages.count - 1)
        }
        .padding()
        .background(
            nightMode
                ? Color.black.opacity(0.85)
                : book.coverColor.opacity(0.08)
        )
    }
    
    // MARK: - Book Info Sheet
    private var bookInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Cover
                    HStack {
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(book.coverColor)
                                .frame(width: 120, height: 160)
                            Text(book.coverEmoji)
                                .font(.system(size: 50))
                        }
                        .shadow(color: book.coverColor.opacity(0.3), radius: 10, y: 5)
                        Spacer()
                    }
                    
                    // Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(book.title)
                            .font(.title2.weight(.bold))
                        
                        Text("By \(book.author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if book.illustrator != book.author {
                            Text("Illustrated by \(book.illustrator)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        Text(book.description)
                            .font(.body)
                        
                        Divider()
                        
                        HStack(spacing: 24) {
                            InfoItem(icon: "book.pages", label: "Pages", value: "\(book.pages)")
                            InfoItem(icon: "person.2", label: "Ages", value: book.ageRange)
                            InfoItem(icon: "graduationcap", label: "Level", value: book.readingLevel.rawValue)
                        }
                    }
                    .padding()
                    
                    // Reading settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reading Settings")
                            .font(.headline)
                        
                        // Font size
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Font Size")
                                .font(.subheadline)
                            
                            HStack {
                                Text("A")
                                    .font(.caption)
                                Slider(value: $fontSize, in: 14...32, step: 2)
                                    .tint(book.coverColor)
                                Text("A")
                                    .font(.title)
                            }
                        }
                        
                        // Night mode
                        Toggle(isOn: $nightMode) {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(.indigo)
                                Text("Night Mode")
                            }
                        }
                        .tint(book.coverColor)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationTitle("About This Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showInfo = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Speak Page
    private func speakPage() {
        guard currentPage < storyPages.count else { return }
        let page = storyPages[currentPage]
        var text = page.text
        if let dialogue = page.dialogue {
            text += " \(dialogue)"
        }
        GameAudioService.shared.speakFluently(text)
    }
    
    // MARK: - Generate Story
    private func generateStory(for book: PictureBook) -> [StoryPage] {
        // Generate story pages based on book type
        // This creates engaging 8-12 page stories with plot and illustrations
        
        var pages: [StoryPage] = []
        
        // Get story content based on book ID
        let storyContent = getStoryContent(for: book)
        
        for content in storyContent {
            pages.append(StoryPage(
                illustration: content.emoji,
                sceneDescription: content.scene,
                text: content.text,
                dialogue: content.dialogue
            ))
        }
        
        return pages
    }
    
    private func getStoryContent(for book: PictureBook) -> [(emoji: String, scene: String, text: String, dialogue: String?)] {
        // Return pre-written story content for each book
        // This is a simplified version - in production, these would be complete stories
        
        switch book.id {
        case "seuss1": // Cat in the Hat
            return [
                ("🌧️", "A rainy day", "The sun did not shine. It was too wet to play. So we sat in the house all that cold, cold wet day.", nil),
                ("👧👦", "Two bored children", "I sat there with Sally. We sat there, we two. And I said, 'How I wish we had something to do!'", nil),
                ("🐱", "BUMP!", "Then something went BUMP! How that bump made us jump! We looked and we saw him step in on the mat.", "I am the Cat in the Hat!"),
                ("🎩", "The cat's tricks", "And then he said, 'Look at me now! With a cup and a cake on the top of my hat!'", nil),
                ("🐟", "The fish warns", "The fish in the pot was not happy at all. 'He should not be here! Tell him to go away!'", nil),
                ("📦", "Thing One and Thing Two", "Out of the box came two things blue. And the cat said, 'Meet Thing One and Thing Two!'", nil),
                ("🪁", "Chaos in the house", "The things flew kites in the house! They knocked down the cake and the cup and the books!", nil),
                ("🧹", "Cleaning up", "Then the cat came back with a new machine. He picked up all the things with amazing speed.", nil),
                ("🚗", "Mother returns", "And then our mother walked in the door. And she asked, 'What did you do today?'", nil),
                ("🤫", "The secret", "Should we tell her what happened? What would you do if your mother asked you?", nil)
            ]
            
        case "pete1": // Pete the Cat White Shoes
            return [
                ("👟", "Pete's new shoes", "Pete the Cat was walking down the street in his brand new white shoes.", "I love my white shoes!"),
                ("🍓", "Strawberries", "Pete stepped in a large pile of strawberries. What color did his shoes turn? Red!", nil),
                ("🎵", "Still singing", "Did Pete cry? Goodness no! He kept walking along and singing his song.", "I love my red shoes!"),
                ("🫐", "Blueberries", "Pete stepped in a pile of blueberries! What color did his shoes turn? Blue!", nil),
                ("🎶", "Still groovy", "Did Pete cry? Goodness no! He kept on walking along and singing his song.", "I love my blue shoes!"),
                ("💩", "Mud puddle", "Pete stepped in a big pile of mud! What color did his shoes turn? Brown!", nil),
                ("😎", "Still cool", "Did Pete cry? Goodness no! He kept on singing because it's all good!", "I love my brown shoes!"),
                ("💧", "Water bucket", "Then Pete stepped in a bucket of water and all the colors washed away!", nil),
                ("⚪", "Back to white", "His shoes were white again! And Pete sang his song.", "I love my white shoes!"),
                ("💙", "The moral", "The moral of the story is: No matter what you step in, keep walking along and singing your song. Because it's all good!", nil)
            ]
            
        case "carle1": // Very Hungry Caterpillar
            return [
                ("🌙", "A tiny egg", "In the light of the moon, a little egg lay on a leaf.", nil),
                ("☀️", "Pop!", "One Sunday morning the warm sun came up, and pop! Out of the egg came a tiny and very hungry caterpillar.", nil),
                ("🍎", "Monday", "On Monday he ate through one apple. But he was still hungry.", nil),
                ("🍐🍐", "Tuesday", "On Tuesday he ate through two pears. But he was still hungry.", nil),
                ("🍓🍓🍓", "Wednesday", "On Wednesday he ate through three plums. But he was still hungry.", nil),
                ("🍓🍓🍓🍓", "Thursday", "On Thursday he ate through four strawberries. But he was still hungry.", nil),
                ("🍊🍊🍊🍊🍊", "Friday", "On Friday he ate through five oranges. But he was still hungry.", nil),
                ("🍕🎂🧁", "Saturday", "On Saturday he ate through cake, ice cream, pickle, cheese, salami... and that night he had a stomach ache!", nil),
                ("🍃", "Feeling better", "On Sunday he ate through one nice green leaf. And after that he felt much better.", nil),
                ("🐛", "Big and fat", "He wasn't a little caterpillar anymore. He was a big, fat caterpillar!", nil),
                ("🏠", "Cocoon", "He built a small house called a cocoon around himself. He stayed inside for two weeks.", nil),
                ("🦋", "Beautiful butterfly", "Then he nibbled a hole and pushed his way out. He was a beautiful butterfly!", nil)
            ]
            
        case "classic2": // Where the Wild Things Are
            return [
                ("👦", "Max in his wolf suit", "The night Max wore his wolf suit and made mischief of one kind and another.", nil),
                ("😠", "Sent to bed", "His mother called him 'WILD THING!' And Max said 'I'll eat you up!' So he was sent to bed without eating anything.", nil),
                ("🌳", "Forest grows", "That very night in Max's room a forest grew and grew until the ceiling hung with vines and the walls became the world all around.", nil),
                ("⛵", "Private boat", "And an ocean tumbled by with a private boat for Max. He sailed off through night and day.", nil),
                ("🏝️", "Wild things", "He sailed to where the wild things are. They roared their terrible roars and gnashed their terrible teeth.", nil),
                ("👁️", "Be still!", "But Max said 'BE STILL!' and tamed them with the magic trick of staring into their yellow eyes without blinking once.", nil),
                ("👑", "King of all", "They made him king of all wild things.", "Let the wild rumpus start!"),
                ("💃", "Wild rumpus", "They danced and swung from trees under the moon. The wild rumpus lasted all night.", nil),
                ("😔", "Lonely", "But Max was lonely and wanted to be where someone loved him best of all.", nil),
                ("🏠", "Going home", "So he waved goodbye and sailed back to his very own room. And there his supper was waiting for him. And it was still hot.", nil)
            ]
            
        case "seuss2": // Green Eggs and Ham
            return [
                ("🧑", "Sam-I-Am", "Sam-I-Am wanted his friend to try something new. Green eggs and ham!", nil),
                ("🍳", "The offer", "Do you like green eggs and ham?", "I do not like them, Sam-I-Am. I do not like green eggs and ham."),
                ("🏠", "In the house?", "Would you eat them in a house? Would you eat them with a mouse?", "I would not eat them in a house. I would not eat them with a mouse."),
                ("📦", "In a box?", "Would you eat them in a box? Would you eat them with a fox?", "Not in a box. Not with a fox. I would not, could not, Sam-I-Am!"),
                ("🚗", "In a car?", "Would you, could you, in a car? Eat them, eat them, here they are!", "I would not, could not, in a car!"),
                ("🌲", "In a tree?", "Would you, could you, in a tree? Try them and you may, you see!", "I would not, could not in a tree. Let me be! Let me be!"),
                ("🚂", "On a train?", "You do not like them, so you say. Try them, try them, and you may!", "Not on a train! Not in the rain! Not in a box, not with a fox!"),
                ("🌊", "In the dark?", "Would you eat them in the dark? Would you eat them in the park?", "I would not eat them in the dark. I would not eat them in the park!"),
                ("😋", "Try them!", "Sam would not give up. He asked one more time: Just try them and you'll see!", nil),
                ("🎉", "I like them!", "Sam-I-Am! I DO like green eggs and ham! I do! I like them! Thank you, Sam-I-Am!", nil)
            ]
            
        case "seuss4": // The Lorax
            return [
                ("🌳", "Truffula Trees", "At the far end of town, beautiful Truffula Trees grew. Their tufts were soft as silk.", nil),
                ("🧑‍🔧", "The Once-ler", "A young man called the Once-ler came along and chopped down a tree to make a Thneed.", nil),
                ("🟠", "The Lorax appears", "From the stump popped a strange creature. 'I am the Lorax. I speak for the trees!'", nil),
                ("🏭", "The factory", "But the Once-ler didn't listen. He built a factory and chopped more and more trees.", nil),
                ("🐟", "The animals suffer", "The Bar-ba-loots had no fruit. The Swomee-Swans couldn't sing. The Humming-Fish couldn't swim.", nil),
                ("😢", "The last tree", "The Lorax lifted himself away through a hole in the sky. He left behind just one word: UNLESS.", nil),
                ("🌱", "The seed", "The Once-ler finally understood. He gave away his last Truffula seed.", nil),
                ("💚", "A new beginning", "Someone planted the seed. A tiny tree began to grow.", nil),
                ("🌳", "Hope returns", "With care and protection, the Truffula Trees could come back. The animals could come home.", nil),
                ("🌍", "The message", "UNLESS someone like you cares a whole awful lot, nothing is going to get better. It's not.", nil)
            ]
            
        case "classic1": // Goodnight Moon
            return [
                ("🌙", "The great green room", "In the great green room there was a telephone, and a red balloon.", nil),
                ("🐄", "On the wall", "And a picture of the cow jumping over the moon.", nil),
                ("🐻", "Little bears", "And there were three little bears sitting on chairs.", nil),
                ("🐱", "Kittens and mittens", "And two little kittens and a pair of mittens.", nil),
                ("🏠", "Little house", "A little toy house and a young mouse.", nil),
                ("🌙", "Goodnight moon", "Goodnight room. Goodnight moon. Goodnight cow jumping over the moon.", nil),
                ("💡", "Goodnight light", "Goodnight light. Goodnight red balloon.", nil),
                ("🐻", "Goodnight bears", "Goodnight bears. Goodnight chairs.", nil),
                ("🐱", "Goodnight kittens", "Goodnight kittens. Goodnight mittens.", nil),
                ("⭐", "Goodnight stars", "Goodnight stars. Goodnight air. Goodnight noises everywhere.", nil)
            ]
            
        case "classic3": // The Giving Tree
            return [
                ("🌳", "The tree and the boy", "Once there was a tree, and she loved a little boy.", nil),
                ("🍎", "Happy times", "Every day the boy would gather her leaves and make crowns. He would climb her trunk and eat her apples.", nil),
                ("💤", "The boy grew", "But time went by. And the boy grew older. And the tree was often alone.", nil),
                ("💰", "Money", "I need money, said the boy. Take my apples and sell them, said the tree.", nil),
                ("🏠", "A house", "I need a house, said the boy. Cut my branches and build one, said the tree.", nil),
                ("⛵", "A boat", "I want to sail away, said the boy. Cut down my trunk and make a boat, said the tree.", nil),
                ("🪵", "Just a stump", "The tree had nothing left. She was just an old stump. But the boy came back.", nil),
                ("👴", "An old man", "I don't need much anymore, said the old man. Just a quiet place to sit and rest.", nil),
                ("🪵", "Come sit", "Well, said the tree, an old stump is good for sitting and resting. Come, boy, sit down.", nil),
                ("❤️", "Happy", "And the boy did. And the tree was happy.", nil)
            ]
            
        case "classic6": // The Rainbow Fish
            return [
                ("🐟", "The Rainbow Fish", "Deep in the ocean lived a fish covered in beautiful shiny scales of every color.", nil),
                ("✨", "So beautiful", "He was the most beautiful fish in the entire ocean. Everyone called him Rainbow Fish.", nil),
                ("😔", "No friends", "But Rainbow Fish was proud. He would not play with the other fish. He swam alone.", nil),
                ("🐠", "A request", "A little blue fish swam up. 'Rainbow Fish, can I have one of your shiny scales?' he asked.", nil),
                ("😤", "The refusal", "Rainbow Fish said NO! 'They are MY scales!' The little fish swam away sadly.", nil),
                ("🐙", "The wise octopus", "The wise octopus said, 'Give away your scales. You will not be as beautiful, but you will be happy.'", nil),
                ("🤔", "Thinking", "Rainbow Fish thought about it. He was beautiful but so lonely.", nil),
                ("💝", "Sharing", "He gave the little blue fish one shiny scale. The little fish was so happy!", nil),
                ("🐟", "More sharing", "One by one, Rainbow Fish gave away his scales. Soon every fish had one.", nil),
                ("😊", "True happiness", "Rainbow Fish had just one shiny scale left. But he had something better—friends. And he was the happiest fish in the sea.", nil)
            ]
            
        case "classic5": // Chicka Chicka Boom Boom
            return [
                ("🌴", "The dare", "A told B, and B told C: I'll meet you at the top of the coconut tree!", nil),
                ("🅰️", "Up they go", "Chicka chicka boom boom! Will there be enough room?", nil),
                ("📝", "More letters", "D E F G H I J K L M N O P climbed up the coconut tree!", nil),
                ("🌴", "Getting crowded", "Chicka chicka boom boom! Will there be enough room?", nil),
                ("📝", "Even more", "Q R S T U V W X Y Z, the whole alphabet up the tree!", nil),
                ("💥", "CRASH!", "The coconut tree bent and WHOOSH! Down came the whole alphabet!", nil),
                ("🤕", "Oh no!", "A got stubbed, B got bruised, C got clumped, D got dumped!", nil),
                ("👨‍👩‍👧‍👦", "Help arrives", "Mamas and papas came to help. They picked up every letter.", nil),
                ("🌙", "Nighttime", "The moon came out and the sun went down. The letters went to bed.", nil),
                ("🅰️", "Dare again!", "But wait! A couldn't sleep. He snuck back to the tree. 'I'll beat you to the top!' Chicka chicka BOOM BOOM!", nil)
            ]
            
        case "mo1": // Don't Let the Pigeon Drive the Bus!
            return [
                ("🚌", "The bus driver", "The bus driver had to leave for a little while. He asked YOU to watch things.", nil),
                ("🐦", "The pigeon", "A pigeon walked up. He looked at the bus. He looked at you.", "Hey, can I drive the bus?"),
                ("🙅", "No!", "The bus driver said not to let the pigeon drive the bus. So you said NO.", nil),
                ("😇", "I'll be careful", "The pigeon said, 'I'll be careful! I promise!' But the answer was still NO.", nil),
                ("😢", "Pigeon begs", "'PLEASE? I'll be your best friend!' The pigeon begged and begged.", nil),
                ("😤", "Getting mad", "The pigeon got upset. 'LET ME DRIVE THE BUS!!!' he screamed, turning red.", nil),
                ("😫", "Tantrum!", "The pigeon threw a huge tantrum! He jumped up and down and flapped his wings!", nil),
                ("😞", "Giving up", "Finally, the pigeon calmed down. 'I never get to do anything,' he sighed.", nil),
                ("🚌", "Driver returns", "The bus driver came back. 'Thanks for watching things!' he said.", nil),
                ("🚚", "A new idea", "Then a big truck drove by. The pigeon's eyes grew wide. 'Hey... can I drive THAT?'", nil)
            ]
            
        case "classic15": // The Little Engine That Could
            return [
                ("🚂", "The happy train", "A little train carried toys and good food over the mountain for children on the other side.", nil),
                ("😟", "Broken down", "But the train broke down! All the toys and food were stuck!", nil),
                ("🚂", "Asking for help", "A shiny new engine came by. 'Will you help us?' But the big engine said, 'I'm too important!'", nil),
                ("🚂", "Another train", "A big strong engine came by. 'Will you help us?' But he said, 'I'm too tired!'", nil),
                ("🚂", "The little engine", "Then a little blue engine came along. She was small. Very small.", nil),
                ("🤔", "Can she do it?", "The toys asked, 'Can you pull us over the mountain?' The little engine had never been over the mountain before.", nil),
                ("💪", "I think I can", "But she said, 'I think I can. I think I can. I think I can!'", nil),
                ("⛰️", "Up the mountain", "She pulled and pulled. The mountain was so steep! 'I think I can, I think I can, I THINK I CAN!'", nil),
                ("🎉", "Over the top!", "She made it to the top! Then down the other side she rolled happily.", "I thought I could! I thought I could!"),
                ("👧👦", "Happy children", "The children on the other side got their toys and food. All because a little engine believed in herself!", nil)
            ]
            
        case "feel1": // The Color Monster
            return [
                ("👾", "Mixed up", "The Color Monster woke up feeling strange. All his feelings were tangled up inside!", nil),
                ("🟡", "Happiness", "Let's sort them out! Happiness is yellow, like the sun. It's warm and bright and makes you want to laugh!", nil),
                ("🔵", "Sadness", "Sadness is blue, like a rainy day. It's heavy and quiet. It's okay to feel blue sometimes.", nil),
                ("🔴", "Anger", "Anger is red, like fire! It burns hot inside and makes you want to stomp and yell!", nil),
                ("⚫", "Fear", "Fear is dark, like the shadows. It makes you feel small and want to hide.", nil),
                ("🟢", "Calm", "Calm is green, like a peaceful forest. It's gentle and quiet, like taking a deep breath.", nil),
                ("💗", "Love", "And love is pink! It's warm and cozy, like a hug from someone special.", nil),
                ("🫙", "Sorting", "The Color Monster put each feeling in its own jar. Yellow for happy. Blue for sad. Red for angry.", nil),
                ("😊", "All better", "Now every feeling had its own place! The Color Monster felt much better.", nil),
                ("🌈", "All feelings", "Remember: all your feelings are important. Every color matters. And it's okay to feel them all!", nil)
            ]
            
        case "stem1": // Rosie Revere, Engineer
            return [
                ("👧", "Rosie", "Rosie Revere loved to build things. Gizmos and gadgets and doohickeys too!", nil),
                ("🔧", "Inventions", "She collected bits and pieces—cheese sticks, clothespins, and old neckties—and turned them into amazing inventions!", nil),
                ("🤫", "A secret", "But Rosie kept her inventions hidden. She was afraid people would laugh at her.", nil),
                ("👵", "Great-great-aunt Rose", "One day, her great-great-aunt Rose came to visit. She had always dreamed of flying!", nil),
                ("✈️", "The flying machine", "Rosie wanted to make Aunt Rose's dream come true. She built a fantastic flying machine!", nil),
                ("🚀", "It flew!", "The machine zoomed into the sky! It soared and swooped! Aunt Rose laughed with joy!", nil),
                ("💥", "It crashed", "Then the machine sputtered and crashed. Rosie wanted to cry. She had failed!", nil),
                ("👵", "Aunt Rose laughs", "But Aunt Rose was laughing! 'You did it! It FLEW! You're amazing, Rosie!'", nil),
                ("💡", "The lesson", "Rosie realized that the only true failure is when you quit. A crash just means you try again!", nil),
                ("🔧", "Keep building", "Rosie Revere never hid her inventions again. She kept building, kept failing, and kept getting better!", nil)
            ]
            
        case "div4": // Hair Love
            return [
                ("👧🏿", "Zuri", "Zuri loved her hair. It was big and beautiful and could do amazing things!", nil),
                ("💇", "Special day", "Today was a special day. Zuri wanted her hair to look extra perfect.", nil),
                ("👨🏿", "Daddy helps", "Daddy said he would help. But Daddy had never done hair before!", nil),
                ("📺", "Watching videos", "Daddy watched videos on how to do hair. He gathered combs, clips, and water.", nil),
                ("😬", "First try", "The first try was... not great. The ponytail was lopsided. Zuri giggled.", nil),
                ("🔄", "Try again", "They tried again. And again. Daddy's big hands were learning something new.", nil),
                ("👑", "Getting closer", "Slowly, Daddy figured it out. Twist here, pin there, spritz with water.", nil),
                ("💕", "Working together", "Zuri helped guide Daddy's hands. Together, they were a team!", nil),
                ("✨", "Beautiful!", "When they finished, Zuri looked in the mirror. Her hair was PERFECT!", nil),
                ("❤️", "Love", "Daddy gave Zuri a big hug. It wasn't just about the hair. It was about love.", nil)
            ]
            
        default:
            // Category-specific story based on book theme
            return generateCategoryStory(for: book)
        }
    }
    
    private func generateCategoryStory(for book: PictureBook) -> [(emoji: String, scene: String, text: String, dialogue: String?)] {
        let emoji = book.coverEmoji
        let title = book.title
        
        switch book.category {
        case .animals:
            return [
                (emoji, "Meet our friend", "This is a story about \(title). Every animal has a special place in our wonderful world.", nil),
                ("🌅", "Morning time", "When the sun rises, our animal friend wakes up and stretches. It's a brand new day!", nil),
                (emoji, "Breakfast", "Time for breakfast! Our friend searches for something yummy to eat.", nil),
                ("🌿", "In nature", "The world is full of amazing sights—tall trees, flowing rivers, and colorful flowers.", nil),
                ("👀", "Curious", "Our animal friend is curious about everything! What's that sound? What's that smell?", nil),
                ("🐾", "A new friend", "Along the way, our friend meets another animal. They sniff and say hello!", "Want to play?"),
                ("🎮", "Playing", "The two friends play together. They chase, they hide, they tumble in the grass!", nil),
                ("🌧️", "A challenge", "Dark clouds roll in. Rain begins to fall! Where should they hide?", nil),
                ("🏡", "Safe and warm", "They find a cozy shelter and wait for the rain to pass. Friends keep each other safe.", nil),
                ("🌈", "Rainbow", "The rain stops and a beautiful rainbow appears! What a perfect ending to a perfect day.", nil),
                ("🌙", "Goodnight", "As the stars come out, our animal friend curls up to sleep. Tomorrow will be another adventure!", nil),
                ("❤️", "The end", "Every creature, big or small, is important and loved. Just like you! The End.", nil)
            ]
            
        case .adventure:
            return [
                (emoji, "The adventure begins", "In the story of \(title), a brave hero is about to go on the most exciting adventure!", nil),
                ("🗺️", "The map", "With a map in hand and courage in heart, our hero sets off into the unknown.", nil),
                ("🌲", "Into the wild", "The path leads through tall trees and over mossy rocks. Every step brings something new.", nil),
                ("🤔", "A puzzle", "A tricky puzzle blocks the way! Our hero must think carefully to solve it.", nil),
                ("💡", "An idea!", "With a clever idea, the puzzle is solved! Sometimes the answer is simpler than you think.", nil),
                ("⛰️", "The mountain", "A tall mountain stands ahead. It looks impossible to climb. But impossible is just a word!", nil),
                ("💪", "Climbing", "Step by step, handhold by handhold, our hero climbs higher and higher!", nil),
                ("🏔️", "The top!", "At the very top, the view is breathtaking! The whole world stretches out below.", nil),
                ("🎁", "The treasure", "And there it is—the treasure! Not gold or jewels, but something far more valuable.", nil),
                ("📖", "The real treasure", "The real treasure was the courage to try, the friends made along the way, and the memories that last forever.", nil),
                ("🏠", "Heading home", "Our hero heads home, tired but proud. Adventures change us for the better.", nil),
                ("⭐", "The end", "Remember: the greatest adventure is believing in yourself! The End.", nil)
            ]
            
        case .friendship:
            return [
                (emoji, "A story of friendship", "\(title) is a story about something everyone needs: a true friend.", nil),
                ("🏫", "Two friends", "Two friends who are very different from each other. But that's what makes them special!", nil),
                ("😊", "Good times", "They do everything together—laughing, playing, and sharing their favorite snacks.", nil),
                ("⚡", "An argument", "But one day, they have a disagreement. Words are said that shouldn't have been said.", nil),
                ("😔", "Feeling sad", "Both friends feel terrible. The world seems gray without each other.", nil),
                ("💭", "Thinking", "Each one thinks about the other. They remember all the good times they shared.", nil),
                ("🚶", "Taking a step", "One friend decides to be brave. They walk over to say the hardest word: 'I'm sorry.'", nil),
                ("🤝", "Making up", "The other friend smiles. 'I'm sorry too.' Sometimes saying sorry is the bravest thing you can do.", nil),
                ("🤗", "Hugs", "They hug and promise to always talk things out, even when it's hard.", nil),
                ("🎉", "Celebrating", "They celebrate by doing their favorite activity together. Friendship is the best!", nil),
                ("🌟", "Stronger", "Their friendship is now even stronger than before. Challenges made it grow.", nil),
                ("💝", "The end", "True friends forgive, understand, and love each other no matter what. The End.", nil)
            ]
            
        case .emotions:
            return [
                (emoji, "Feelings", "\(title) teaches us something important about feelings.", nil),
                ("😊", "Happy", "Sometimes we feel happy! Happy is bright like sunshine. We smile and laugh and want to dance!", nil),
                ("😢", "Sad", "Sometimes we feel sad. Sad feels heavy, like a rain cloud. And that's perfectly okay.", nil),
                ("😠", "Angry", "Sometimes we feel angry. Angry is hot like fire! We want to stomp and shout!", nil),
                ("😨", "Scared", "Sometimes we feel scared. Scared makes us feel small. We want someone to hold our hand.", nil),
                ("😮", "Surprised", "Sometimes we feel surprised! Our eyes go wide and we say 'WOW!'", nil),
                ("🫂", "Talking helps", "The best thing about feelings is that we can talk about them. Sharing helps us feel better.", nil),
                ("🧘", "Deep breaths", "When feelings are big, we can take deep breaths. In through the nose, out through the mouth.", nil),
                ("👨‍👩‍👧", "People who care", "There are always people who care about us and want to help when feelings are hard.", nil),
                ("🌈", "All feelings matter", "Every feeling is real. Every feeling matters. Every feeling is part of being human.", nil),
                ("💪", "Being brave", "Being brave doesn't mean having no feelings. It means feeling them and being kind to yourself.", nil),
                ("❤️", "The end", "You are wonderful just the way you feel! The End.", nil)
            ]
            
        case .bedtime:
            return [
                (emoji, "Getting sleepy", "\(title) is the perfect story for when the stars come out.", nil),
                ("🌅", "The day is done", "The sun has finished its journey across the sky. It's painting the clouds orange and pink.", nil),
                ("🛁", "Bath time", "Warm water and bubbles wash away the day's adventures.", nil),
                ("👕", "Pajamas", "Soft, cozy pajamas feel so good. Like being wrapped in a warm cloud.", nil),
                ("🪥", "Brush brush", "Time to brush our teeth! Sparkly clean and fresh for dreaming.", nil),
                ("📚", "Story time", "Snuggled up with a favorite book. The best part of the day!", nil),
                ("🧸", "Stuffed friends", "Teddy bears and stuffed animals all lined up, ready to keep us safe all night.", nil),
                ("💡", "Lights low", "The lights get dim. The room gets cozy. Shadows make gentle shapes on the wall.", nil),
                ("🌙", "The moon", "The moon peeks through the window. It says goodnight with its gentle glow.", nil),
                ("⭐", "Stars", "Stars twinkle like tiny diamonds in the sky. Each one watching over you.", nil),
                ("😴", "Drifting off", "Eyes get heavy. Breathing gets slow. Sweet dreams are coming...", nil),
                ("💤", "The end", "Goodnight, wonderful you. Tomorrow will be another amazing day. Sweet dreams. The End.", nil)
            ]
            
        default: // counting, alphabet, nature, humor, rhyming, diversity, science, family, fantasy
            return [
                (emoji, title, "Welcome to the wonderful world of \(title)! Let's explore together.", nil),
                ("🌅", "A beautiful day", "It was a beautiful morning, perfect for learning and discovery!", nil),
                (emoji, "Something special", "Something special was waiting to be found. Can you guess what it was?", nil),
                ("🔍", "Exploring", "With curious eyes and an open heart, the adventure of discovery began!", nil),
                ("😲", "Wow!", "So many amazing things to see! The world is full of wonder.", nil),
                ("🤔", "A question", "A big question popped up. Sometimes the best discoveries start with a question!", nil),
                ("💡", "The answer", "The answer came in the most unexpected way. That's how learning works!", nil),
                ("👋", "Sharing", "The best part of learning something new is sharing it with others!", "Look what I discovered!"),
                ("🎨", "Creating", "With new knowledge comes the power to create something wonderful.", nil),
                ("🌟", "Growing", "Every day we learn, we grow a little bit more. Like a seed becoming a flower.", nil),
                (emoji, "Remember", "\(title) teaches us that the world is full of amazing things to discover.", nil),
                ("❤️", "The end", "Keep asking questions, keep exploring, and never stop being curious! The End.", nil)
            ]
        }
    }
}

// MARK: - Story Page Model
struct StoryPage: Identifiable {
    let id = UUID()
    let illustration: String
    let sceneDescription: String
    let text: String
    let dialogue: String?
}

// MARK: - Info Item
struct InfoItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    PictureBooksView()
}

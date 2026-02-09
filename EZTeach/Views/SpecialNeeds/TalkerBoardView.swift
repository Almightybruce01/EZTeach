//
//  TalkerBoardView.swift
//  EZTeach
//
//  AAC (Augmentative and Alternative Communication) Board for Special Needs
//  Features: Emoji + Photo cards with words, text-to-speech, teacher-editable,
//  multiple voices, speed control, quick phrases, haptic feedback
//

import SwiftUI
import AVFoundation
import PhotosUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

// MARK: - Talker Card Model
struct TalkerCard: Identifiable, Codable {
    let id: String
    var word: String
    var imageUrl: String?
    var localImageData: Data?
    var category: TalkerCategory
    var order: Int
    var backgroundColor: String
    var isActive: Bool

    static func fromDocument(_ doc: DocumentSnapshot) -> TalkerCard? {
        guard let data = doc.data() else { return nil }
        return TalkerCard(
            id: doc.documentID,
            word: data["word"] as? String ?? "",
            imageUrl: data["imageUrl"] as? String,
            localImageData: nil,
            category: TalkerCategory(rawValue: data["category"] as? String ?? "") ?? .core,
            order: data["order"] as? Int ?? 0,
            backgroundColor: data["backgroundColor"] as? String ?? "blue",
            isActive: data["isActive"] as? Bool ?? true
        )
    }
}

enum TalkerCategory: String, Codable, CaseIterable {
    case core = "Core Words"
    case feelings = "Feelings"
    case people = "People"
    case actions = "Actions"
    case food = "Food"
    case animals = "Animals"
    case places = "Places"
    case things = "Things"
    case bodyParts = "Body Parts"
    case colors = "Colors"
    case numbers = "Numbers"
    case weather = "Weather"
    case school = "School"
    case questions = "Questions"
    case responses = "Responses"
    case quickPhrases = "Quick Phrases"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .core: return "star.fill"
        case .feelings: return "heart.fill"
        case .people: return "person.2.fill"
        case .actions: return "figure.walk"
        case .food: return "fork.knife"
        case .animals: return "pawprint.fill"
        case .places: return "map.fill"
        case .things: return "cube.fill"
        case .bodyParts: return "hand.raised.fill"
        case .colors: return "paintpalette.fill"
        case .numbers: return "number"
        case .weather: return "cloud.sun.fill"
        case .school: return "graduationcap.fill"
        case .questions: return "questionmark.circle.fill"
        case .responses: return "bubble.left.fill"
        case .quickPhrases: return "text.bubble.fill"
        case .custom: return "plus.circle.fill"
        }
    }

    var defaultColor: String {
        switch self {
        case .core: return "yellow"
        case .feelings: return "pink"
        case .people: return "blue"
        case .actions: return "green"
        case .food: return "orange"
        case .animals: return "brown"
        case .places: return "purple"
        case .things: return "gray"
        case .bodyParts: return "teal"
        case .colors: return "indigo"
        case .numbers: return "red"
        case .weather: return "blue"
        case .school: return "purple"
        case .questions: return "teal"
        case .responses: return "indigo"
        case .quickPhrases: return "green"
        case .custom: return "brown"
        }
    }
}

// MARK: - Emoji Map (no model migration needed)
struct TalkerEmoji {
    static let map: [String: String] = [
        // Core Words
        "I": "🙋", "want": "👉", "need": "🙏", "help": "🆘", "more": "➕",
        "done": "✅", "yes": "👍", "no": "👎", "please": "🥺", "thank you": "💖",
        "go": "🟢", "stop": "🛑", "hi": "👋", "bye": "👋", "sorry": "😔",
        "like": "❤️", "don't like": "💔", "mine": "🫵",

        // Feelings
        "happy": "😊", "sad": "😢", "mad": "😡", "scared": "😨", "tired": "😴",
        "sick": "🤒", "hungry": "🤤", "thirsty": "💧", "cold": "🥶", "hot": "🥵",
        "excited": "🤩", "bored": "😐", "worried": "😟", "shy": "🫣",
        "proud": "😤", "confused": "😕", "silly": "🤪", "love": "🥰",

        // People
        "mom": "👩", "dad": "👨", "teacher": "👩‍🏫", "friend": "👫", "me": "🧑",
        "you": "👤", "grandma": "👵", "grandpa": "👴", "brother": "👦", "sister": "👧",
        "baby": "👶", "family": "👨‍👩‍👧‍👦", "doctor": "👨‍⚕️", "nurse": "👩‍⚕️",

        // Actions
        "eat": "🍽️", "drink": "🥤", "play": "🎮", "read": "📖", "write": "✍️",
        "sit": "🪑", "stand": "🧍", "walk": "🚶", "run": "🏃", "sleep": "😴",
        "sing": "🎤", "dance": "💃", "draw": "🎨", "cook": "👨‍🍳", "clean": "🧹",
        "hug": "🤗", "listen": "👂", "look": "👀", "think": "🤔", "jump": "⬆️",
        "swim": "🏊", "climb": "🧗", "throw": "🤾", "catch": "🫴",
        "open": "📂", "close": "📁", "push": "👐", "pull": "🤏",

        // Food
        "water": "💧", "milk": "🥛", "juice": "🧃", "snack": "🍿", "lunch": "🥪",
        "breakfast": "🥞", "apple": "🍎", "cookie": "🍪", "pizza": "🍕", "sandwich": "🥪",
        "banana": "🍌", "chicken": "🍗", "rice": "🍚", "pasta": "🍝", "ice cream": "🍦",
        "cake": "🎂", "cheese": "🧀", "bread": "🍞", "cereal": "🥣", "egg": "🥚",
        "fish": "🐟", "soup": "🍲", "salad": "🥗", "chocolate": "🍫",

        // Animals
        "dog": "🐕", "cat": "🐱", "bird": "🐦", "fish ": "🐠", "rabbit": "🐰",
        "horse": "🐴", "cow": "🐄", "pig": "🐷", "chicken ": "🐔", "duck": "🦆",
        "bear": "🐻", "lion": "🦁", "elephant": "🐘", "monkey": "🐒", "frog": "🐸",
        "butterfly": "🦋", "turtle": "🐢", "snake": "🐍", "dinosaur": "🦕",

        // Places
        "home": "🏠", "school": "🏫", "park": "🌳", "store": "🏪", "hospital": "🏥",
        "library": "📚", "playground": "🛝", "bathroom": "🚻", "outside": "🌤️",
        "car": "🚗", "bus": "🚌", "restaurant": "🍴", "church": "⛪", "gym": "🏋️",

        // Things
        "ball": "⚽", "book": "📕", "phone": "📱", "toy": "🧸", "tv": "📺",
        "computer": "💻", "tablet": "📱", "bed": "🛏️", "chair": "🪑", "table": "🪑",
        "shoes": "👟", "hat": "🧢", "shirt": "👕", "pants": "👖", "backpack": "🎒",
        "cup": "🥤", "plate": "🍽️", "spoon": "🥄", "fork": "🍴", "blanket": "🛌",

        // Body Parts
        "head": "🗣️", "eyes": "👀", "ears": "👂", "nose": "👃", "mouth": "👄",
        "hand": "✋", "feet": "🦶", "tummy": "🫃", "arm": "💪", "leg": "🦵",
        "teeth": "🦷", "hair": "💇", "finger": "☝️",

        // Colors
        "red": "🔴", "blue": "🔵", "green": "🟢", "yellow": "🟡", "orange ": "🟠",
        "purple": "🟣", "pink": "💗", "black": "⚫", "white": "⚪", "brown ": "🟤",

        // Numbers
        "1": "1️⃣", "2": "2️⃣", "3": "3️⃣", "4": "4️⃣", "5": "5️⃣",
        "6": "6️⃣", "7": "7️⃣", "8": "8️⃣", "9": "9️⃣", "10": "🔟",

        // Weather
        "sunny": "☀️", "rainy": "🌧️", "snowy": "❄️", "windy": "💨", "cloudy": "☁️",
        "stormy": "⛈️",

        // School
        "pencil": "✏️", "paper": "📄", "crayon": "🖍️", "scissors": "✂️", "glue": "🧴",
        "desk": "🪑", "whiteboard": "🖼️", "homework": "📝", "test": "📋",
        "recess": "🛝", "lunch ": "🍱", "art": "🎨", "music": "🎵", "gym ": "🏀",

        // Questions
        "what": "❓", "where": "📍", "when": "⏰", "who": "👤", "why": "🤷",
        "how": "🔧", "can I": "🙋", "is it": "🔎",

        // Responses
        "okay": "👌", "wait": "⏳", "later": "🕐", "now": "⚡", "again": "🔄",
        "all done": "🏁", "my turn": "🙋", "your turn": "👉",

        // Quick Phrases
        "I want": "🙋👉", "I need": "🙋🙏", "I feel": "🙋💭", "I'm hungry": "🙋🤤",
        "I'm thirsty": "🙋💧", "I'm tired": "🙋😴", "I need help": "🙋🆘",
        "more please": "➕🥺", "I don't know": "🤷",
        "can I go": "🙋🚶", "I love you": "🙋❤️", "I'm sorry": "🙋😔",
        "let's play": "🎉🎮", "read to me": "📖👂", "good morning": "☀️👋",
        "good night": "🌙👋", "thank you so much": "💖✨"
    ]

    static func emoji(for word: String) -> String {
        return map[word.lowercased()] ?? map[word] ?? "💬"
    }
}

// MARK: - Talker Board Model
struct TalkerBoard: Identifiable, Codable {
    let id: String
    let schoolId: String
    let studentId: String?
    let studentName: String?
    var name: String
    var cards: [TalkerCard]
    var gridColumns: Int
    var createdBy: String
    var createdAt: Date
    var updatedAt: Date

    static func fromDocument(_ doc: DocumentSnapshot) -> TalkerBoard? {
        guard let data = doc.data() else { return nil }

        let cardsData = data["cards"] as? [[String: Any]] ?? []
        let cards = cardsData.compactMap { cardData -> TalkerCard? in
            guard let word = cardData["word"] as? String else { return nil }
            return TalkerCard(
                id: cardData["id"] as? String ?? UUID().uuidString,
                word: word,
                imageUrl: cardData["imageUrl"] as? String,
                localImageData: nil,
                category: TalkerCategory(rawValue: cardData["category"] as? String ?? "") ?? .core,
                order: cardData["order"] as? Int ?? 0,
                backgroundColor: cardData["backgroundColor"] as? String ?? "blue",
                isActive: cardData["isActive"] as? Bool ?? true
            )
        }

        return TalkerBoard(
            id: doc.documentID,
            schoolId: data["schoolId"] as? String ?? "",
            studentId: data["studentId"] as? String,
            studentName: data["studentName"] as? String,
            name: data["name"] as? String ?? "Talker Board",
            cards: cards,
            gridColumns: data["gridColumns"] as? Int ?? 4,
            createdBy: data["createdBy"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Main Talker View
struct TalkerBoardView: View {
    let schoolId: String
    let userRole: String
    let studentId: String?
    let studentName: String?

    @Environment(\.dismiss) var dismiss
    @State private var currentBoard: TalkerBoard?
    @State private var boards: [TalkerBoard] = []
    @State private var selectedCategory: TalkerCategory?
    @State private var isEditing = false
    @State private var showingAddCard = false
    @State private var showingBoardSettings = false
    @State private var selectedCards: [TalkerCard] = []
    @State private var isLoading = true
    @State private var speechRate: Float = 0.42
    @State private var showVoiceSettings = false

    private let synthesizer = AVSpeechSynthesizer()
    private let db = Firestore.firestore()
    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    var canEdit: Bool {
        userRole != "student" && userRole != "parent"
    }

    var filteredCards: [TalkerCard] {
        guard let board = currentBoard else { return [] }
        let activeCards = board.cards.filter { $0.isActive }
        if let cat = selectedCategory {
            return activeCards.filter { $0.category == cat }
        }
        return activeCards.sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sentenceStrip
                categoryPicker
                cardsGrid
            }
            .background(
                LinearGradient(colors: [Color(white: 0.08), Color(white: 0.03)],
                               startPoint: .top, endPoint: .bottom)
            )
            .navigationTitle(currentBoard?.name ?? "Talker Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Voice settings
                        Button {
                            showVoiceSettings = true
                        } label: {
                            Image(systemName: "waveform.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.cyan)
                        }

                        if canEdit {
                            Menu {
                                Button {
                                    showingAddCard = true
                                } label: {
                                    Label("Add Card", systemImage: "plus.rectangle")
                                }
                                Button {
                                    isEditing.toggle()
                                } label: {
                                    Label(isEditing ? "Done Editing" : "Edit Cards", systemImage: "pencil")
                                }
                                Button {
                                    showingBoardSettings = true
                                } label: {
                                    Label("Board Settings", systemImage: "gearshape")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddCard) {
                AddTalkerCardView(schoolId: schoolId, boardId: currentBoard?.id ?? "") { newCard in
                    currentBoard?.cards.append(newCard)
                    saveBoard()
                }
            }
            .sheet(isPresented: $showingBoardSettings) {
                if let board = currentBoard {
                    TalkerBoardSettingsView(board: board) { updatedBoard in
                        currentBoard = updatedBoard
                        saveBoard()
                    }
                }
            }
            .sheet(isPresented: $showVoiceSettings) {
                voiceSettingsSheet
            }
            .onAppear { loadOrCreateBoard() }
        }
    }

    // MARK: - Voice Settings Sheet
    private var voiceSettingsSheet: some View {
        NavigationStack {
            Form {
                Section("Speech Speed") {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "tortoise.fill")
                                .foregroundColor(.orange)
                            Slider(value: $speechRate, in: 0.1...0.7, step: 0.05)
                                .tint(.cyan)
                            Image(systemName: "hare.fill")
                                .foregroundColor(.green)
                        }
                        Text(speedLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Test") {
                    Button {
                        speakWord("Hello, how are you today?")
                    } label: {
                        Label("Test Voice", systemImage: "speaker.wave.3.fill")
                    }
                }

                Section("Tips") {
                    Label("Tap a card to hear and add to sentence", systemImage: "hand.tap.fill")
                    Label("Tap Speak to read the whole sentence", systemImage: "speaker.wave.3.fill")
                    Label("Tap the backspace to undo the last word", systemImage: "delete.left.fill")
                }
            }
            .navigationTitle("Voice Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showVoiceSettings = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var speedLabel: String {
        if speechRate < 0.25 { return "Very Slow" }
        if speechRate < 0.4 { return "Slow" }
        if speechRate < 0.5 { return "Normal" }
        if speechRate < 0.6 { return "Fast" }
        return "Very Fast"
    }

    // MARK: - Sentence Strip
    private var sentenceStrip: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if selectedCards.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .font(.title2)
                                .foregroundColor(.cyan.opacity(0.5))
                            Text("Tap cards to build a sentence")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        ForEach(Array(selectedCards.enumerated()), id: \.element.id) { idx, card in
                            MiniCardView(card: card, index: idx) {
                                withAnimation(.spring(response: 0.25)) {
                                    if let index = selectedCards.firstIndex(where: { $0.id == card.id }) {
                                        selectedCards.remove(at: index)
                                    }
                                }
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCards.count)
            }
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .fill(LinearGradient(colors: [.cyan.opacity(0.15), .purple.opacity(0.1)],
                                                 startPoint: .leading, endPoint: .trailing))
                    )
            )

            // Sentence Actions
            if !selectedCards.isEmpty {
                HStack(spacing: 16) {
                    // Speak button
                    Button {
                        haptic.impactOccurred()
                        speakSentence()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "speaker.wave.3.fill")
                                .symbolEffect(.variableColor.iterative.dimInactiveLayers)
                            Text("Speak")
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(
                                LinearGradient(colors: [.green, .cyan],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                        )
                        .shadow(color: .green.opacity(0.4), radius: 6, y: 2)
                    }

                    // Clear
                    Button {
                        withAnimation { selectedCards.removeAll() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                            Text("Clear")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.red.opacity(0.7)))
                    }

                    // Backspace
                    Button {
                        if !selectedCards.isEmpty {
                            let _ = withAnimation { selectedCards.removeLast() }
                        }
                    } label: {
                        Image(systemName: "delete.left.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.vertical, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Category Picker
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All button
                Button {
                    selectedCategory = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.2x2.fill")
                        Text("All")
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            selectedCategory == nil
                                ? AnyShapeStyle(LinearGradient(colors: [.white, .gray.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(Color.gray.opacity(0.25))
                        )
                    )
                    .foregroundColor(selectedCategory == nil ? .black : .white)
                }

                ForEach(TalkerCategory.allCases, id: \.rawValue) { category in
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(
                                selectedCategory == category
                                    ? AnyShapeStyle(colorFor(category.defaultColor).gradient)
                                    : AnyShapeStyle(Color.gray.opacity(0.25))
                            )
                        )
                        .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(white: 0.06))
    }

    // MARK: - Cards Grid
    private var cardsGrid: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        .scaleEffect(1.5)
                    Text("Loading board...")
                        .foregroundColor(.gray)
                }
                .padding(.top, 100)
            } else if filteredCards.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "rectangle.on.rectangle.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No cards in this category")
                        .font(.headline)
                        .foregroundColor(.gray)
                    if canEdit {
                        Text("Tap + to add new cards")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .padding(.top, 80)
            } else {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: currentBoard?.gridColumns ?? 4)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredCards) { card in
                        TalkerCardView(
                            card: card,
                            isEditing: isEditing,
                            onTap: {
                                if !isEditing {
                                    haptic.impactOccurred()
                                    speakWord(card.word)
                                    withAnimation(.spring(response: 0.25)) {
                                        selectedCards.append(card)
                                    }
                                }
                            },
                            onDelete: { deleteCard(card) },
                            onDuplicate: { duplicateCard(card) }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Speech
    private func speakWord(_ word: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = speechRate
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.05
        synthesizer.speak(utterance)
    }

    private func speakSentence() {
        let sentence = selectedCards.map { $0.word }.joined(separator: " ")
        speakWord(sentence)
    }

    // MARK: - Data Operations
    private func loadOrCreateBoard() {
        isLoading = true
        var query: Query = db.collection("talkerBoards").whereField("schoolId", isEqualTo: schoolId)
        if let sid = studentId {
            query = query.whereField("studentId", isEqualTo: sid)
        }
        query.getDocuments(source: .default) { snap, _ in
            if let doc = snap?.documents.first,
               let board = TalkerBoard.fromDocument(doc) {
                currentBoard = board
            } else {
                createDefaultBoard()
            }
            isLoading = false
        }
    }

    private func createDefaultBoard() {
        let defaultCards = createDefaultCards()
        let board = TalkerBoard(
            id: UUID().uuidString,
            schoolId: schoolId,
            studentId: studentId,
            studentName: studentName,
            name: studentName != nil ? "\(studentName!)'s Talker" : "Class Talker",
            cards: defaultCards,
            gridColumns: 4,
            createdBy: Auth.auth().currentUser?.uid ?? "",
            createdAt: Date(),
            updatedAt: Date()
        )
        currentBoard = board
        saveBoard()
    }

    private func createDefaultCards() -> [TalkerCard] {
        var cards: [TalkerCard] = []
        var order = 0

        func add(_ words: [String], cat: TalkerCategory, color: String) {
            for word in words {
                cards.append(TalkerCard(id: UUID().uuidString, word: word, imageUrl: nil, localImageData: nil,
                                        category: cat, order: order, backgroundColor: color, isActive: true))
                order += 1
            }
        }

        add(["I", "want", "need", "help", "more", "done", "yes", "no", "please", "thank you", "go", "stop", "hi", "bye", "sorry", "like", "don't like", "mine"],
            cat: .core, color: "yellow")
        add(["happy", "sad", "mad", "scared", "tired", "sick", "hungry", "thirsty", "cold", "hot", "excited", "bored", "worried", "shy", "proud", "confused", "silly", "love"],
            cat: .feelings, color: "pink")
        add(["mom", "dad", "teacher", "friend", "me", "you", "grandma", "grandpa", "brother", "sister", "baby", "family"],
            cat: .people, color: "blue")
        add(["eat", "drink", "play", "read", "write", "sit", "stand", "walk", "run", "sleep", "sing", "dance", "draw", "cook", "clean", "hug", "listen", "look", "think", "jump"],
            cat: .actions, color: "green")
        add(["water", "milk", "juice", "snack", "lunch", "breakfast", "apple", "cookie", "pizza", "sandwich", "banana", "chicken", "rice", "pasta", "ice cream", "cake", "cheese", "bread"],
            cat: .food, color: "orange")
        add(["dog", "cat", "bird", "rabbit", "horse", "cow", "pig", "duck", "bear", "lion", "elephant", "monkey", "frog", "butterfly", "turtle", "dinosaur"],
            cat: .animals, color: "brown")
        add(["home", "school", "park", "store", "hospital", "library", "playground", "bathroom", "outside", "car", "bus"],
            cat: .places, color: "purple")
        add(["ball", "book", "phone", "toy", "tv", "computer", "bed", "shoes", "hat", "shirt", "backpack", "cup", "blanket"],
            cat: .things, color: "gray")
        add(["head", "eyes", "ears", "nose", "mouth", "hand", "feet", "tummy", "arm", "leg", "teeth", "hair", "finger"],
            cat: .bodyParts, color: "teal")
        add(["red", "blue", "green", "yellow", "purple", "pink", "black", "white"],
            cat: .colors, color: "indigo")
        add(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"],
            cat: .numbers, color: "red")
        add(["sunny", "rainy", "snowy", "windy", "cloudy", "stormy"],
            cat: .weather, color: "blue")
        add(["pencil", "paper", "crayon", "scissors", "desk", "homework", "recess", "art", "music"],
            cat: .school, color: "purple")
        add(["what", "where", "when", "who", "why", "how", "can I", "is it"],
            cat: .questions, color: "teal")
        add(["okay", "wait", "later", "now", "again", "all done", "my turn", "your turn"],
            cat: .responses, color: "indigo")
        add(["I want", "I need", "I feel", "I'm hungry", "I'm thirsty", "I'm tired", "I need help",
             "more please", "I don't know", "can I go", "I love you", "I'm sorry",
             "let's play", "read to me", "good morning", "good night", "thank you so much"],
            cat: .quickPhrases, color: "green")

        return cards
    }

    private func saveBoard() {
        guard let board = currentBoard else { return }
        let boardData: [String: Any] = [
            "schoolId": board.schoolId,
            "studentId": board.studentId ?? "",
            "studentName": board.studentName ?? "",
            "name": board.name,
            "cards": board.cards.map { card -> [String: Any] in
                [
                    "id": card.id,
                    "word": card.word,
                    "imageUrl": card.imageUrl ?? "",
                    "category": card.category.rawValue,
                    "order": card.order,
                    "backgroundColor": card.backgroundColor,
                    "isActive": card.isActive
                ]
            },
            "gridColumns": board.gridColumns,
            "createdBy": board.createdBy,
            "createdAt": Timestamp(date: board.createdAt),
            "updatedAt": Timestamp(date: Date())
        ]
        db.collection("talkerBoards").document(board.id).setData(boardData)
    }

    private func deleteCard(_ card: TalkerCard) {
        currentBoard?.cards.removeAll { $0.id == card.id }
        saveBoard()
    }

    private func duplicateCard(_ card: TalkerCard) {
        let newCard = TalkerCard(
            id: UUID().uuidString,
            word: card.word,
            imageUrl: card.imageUrl,
            localImageData: card.localImageData,
            category: card.category,
            order: (currentBoard?.cards.count ?? 0),
            backgroundColor: card.backgroundColor,
            isActive: true
        )
        currentBoard?.cards.append(newCard)
        saveBoard()
    }

    func colorFor(_ name: String) -> Color {
        switch name {
        case "yellow": return .yellow
        case "pink": return .pink
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "gray": return .gray
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        case "red": return .red
        default: return .blue
        }
    }
}

// MARK: - Talker Card View (Upgraded with Emoji + Picture)
struct TalkerCardView: View {
    let card: TalkerCard
    let isEditing: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    @State private var isPressed = false

    var cardColor: Color {
        switch card.backgroundColor {
        case "yellow": return .yellow
        case "pink": return .pink
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "gray": return .gray
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        case "red": return .red
        default: return .blue
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    isPressed = false
                }
                onTap()
            } label: {
                VStack(spacing: 4) {
                    // Image, Emoji, or Symbol
                    if let urlString = card.imageUrl, !urlString.isEmpty, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            default:
                                emojiView(for: card.word)
                            }
                        }
                        .frame(height: 52)
                    } else {
                        emojiView(for: card.word)
                            .frame(height: 52)
                    }

                    // Word
                    Text(card.word)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardColor.gradient)
                        .shadow(color: cardColor.opacity(isPressed ? 0.2 : 0.5), radius: isPressed ? 2 : 6, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.88 : 1.0)
            }

            // Edit overlay
            if isEditing {
                Menu {
                    Button { onDuplicate() } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    Button(role: .destructive) { onDelete() } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .background(Circle().fill(.black.opacity(0.6)))
                }
                .padding(4)
            }
        }
    }

    @ViewBuilder
    private func emojiView(for word: String) -> some View {
        let emoji = TalkerEmoji.emoji(for: word)
        Text(emoji)
            .font(.system(size: 36))
    }
}

// MARK: - Mini Card View (for sentence strip)
struct MiniCardView: View {
    let card: TalkerCard
    let index: Int
    let onRemove: () -> Void

    var cardColor: Color {
        switch card.backgroundColor {
        case "yellow": return .yellow
        case "pink": return .pink
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "gray": return .gray
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        case "red": return .red
        default: return .blue
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(TalkerEmoji.emoji(for: card.word))
                .font(.system(size: 22))
            Text(card.word)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardColor.gradient)
        )
        .overlay(alignment: .topTrailing) {
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .offset(x: 4, y: -4)
        }
    }
}

// MARK: - Add Card View
struct AddTalkerCardView: View {
    let schoolId: String
    let boardId: String
    let onSave: (TalkerCard) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var word = ""
    @State private var category: TalkerCategory = .custom
    @State private var backgroundColor = "blue"
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false

    let colors = ["yellow", "pink", "blue", "green", "orange", "purple", "gray", "teal", "indigo", "brown", "red"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Word") {
                    TextField("Enter word or phrase", text: $word)
                        .font(.title3)
                }

                // Live preview
                if !word.isEmpty {
                    Section("Preview") {
                        HStack {
                            Spacer()
                            VStack(spacing: 6) {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Text(TalkerEmoji.emoji(for: word))
                                        .font(.system(size: 40))
                                }
                                Text(word)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(colorFor(backgroundColor).gradient)
                            )
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(TalkerCategory.allCases, id: \.rawValue) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.rawValue)
                            }
                            .tag(cat)
                        }
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                backgroundColor = color
                            } label: {
                                Circle()
                                    .fill(colorFor(color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(backgroundColor == color ? Color.white : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Image (Optional)") {
                    if let image = selectedImage {
                        HStack {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                            Spacer()
                            Button("Remove") { selectedImage = nil }
                                .foregroundColor(.red)
                        }
                    } else {
                        Button {
                            showingImagePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                Text("Add Photo")
                            }
                        }
                    }

                    Text("If no photo is added, an emoji will be shown.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let card = TalkerCard(
                            id: UUID().uuidString,
                            word: word,
                            imageUrl: nil,
                            localImageData: selectedImage?.jpegData(compressionQuality: 0.8),
                            category: category,
                            order: 999,
                            backgroundColor: backgroundColor,
                            isActive: true
                        )
                        onSave(card)
                        dismiss()
                    }
                    .disabled(word.isEmpty)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }

    private func colorFor(_ name: String) -> Color {
        switch name {
        case "yellow": return .yellow
        case "pink": return .pink
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "gray": return .gray
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        case "red": return .red
        default: return .blue
        }
    }
}

// MARK: - Board Settings View
struct TalkerBoardSettingsView: View {
    let board: TalkerBoard
    let onSave: (TalkerBoard) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var gridColumns: Int = 4

    var body: some View {
        NavigationStack {
            Form {
                Section("Board Name") {
                    TextField("Name", text: $name)
                }

                Section("Grid Layout") {
                    Picker("Columns", selection: $gridColumns) {
                        ForEach(2...6, id: \.self) { col in
                            Text("\(col) columns").tag(col)
                        }
                    }

                    HStack {
                        ForEach(2...6, id: \.self) { col in
                            Button {
                                gridColumns = col
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: "square.grid.\(min(col, 3))x\(min(col, 3)).fill")
                                        .font(.title2)
                                    Text("\(col)")
                                        .font(.caption2)
                                }
                                .foregroundColor(gridColumns == col ? .blue : .gray)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }

                Section("Statistics") {
                    LabeledContent("Total Cards", value: "\(board.cards.count)")
                    LabeledContent("Active Cards", value: "\(board.cards.filter { $0.isActive }.count)")
                    LabeledContent("Categories Used", value: "\(Set(board.cards.map { $0.category }).count)")
                    LabeledContent("Created", value: board.createdAt.formatted(date: .abbreviated, time: .omitted))
                }
            }
            .navigationTitle("Board Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedBoard = board
                        updatedBoard.name = name
                        updatedBoard.gridColumns = gridColumns
                        onSave(updatedBoard)
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = board.name
                gridColumns = board.gridColumns
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

//
//  EZLearningGamesHubView.swift
//  EZTeach
//
//  EZLearningGames - Tron futuristic neon aesthetic
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EZLearningGamesHubView: View {
    var gradeLevel: Int = 0
    @State private var searchText = ""
    @State private var searchCategoryFilter: GameCategory?
    
    private var searchResults: [(GameItem, GameCategory)] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return [] }
        let matches = GameCategory.allGamesWithCategory.filter {
            $0.0.name.lowercased().contains(q)
        }
        if let cat = searchCategoryFilter {
            return matches.filter { $0.1 == cat }
        }
        return matches
    }
    
    var body: some View {
        ZStack {
            EZTeachColors.lightAppealGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Text("EZLearning")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(EZTeachColors.gamesAccentGradient)
                            .shadow(color: EZTeachColors.brightTeal.opacity(0.4), radius: 12)
                        
                        Text("LEVEL UP YOUR LEARNING")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .tracking(4)
                            .foregroundColor(EZTeachColors.textMutedLight)
                        
                        if gradeLevel > 0 {
                            Text("Suggested for Grade \(GradeUtils.label(gradeLevel))")
                                .font(.caption)
                                .foregroundColor(EZTeachColors.textMutedLight)
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(EZTeachColors.brightTeal)
                            TextField("Search games by name...", text: $searchText)
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
                                .stroke(EZTeachColors.brightTeal.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        GameAudioSettingsBar()
                    }
                    .padding(.top, 20)
                    
                    if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        GameSearchResultsView(
                            results: searchResults,
                            searchCategoryFilter: $searchCategoryFilter,
                            gradeLevel: gradeLevel
                        )
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(GameCategory.allCases, id: \.self) { cat in
                                NavigationLink(value: cat) {
                                    TronCategoryCard(category: cat)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationDestination(for: GameCategory.self) { cat in
                GameCategoryListView(category: cat, gradeLevel: gradeLevel)
            }
        }
    }
}

struct GameSearchResultsView: View {
    let results: [(GameItem, GameCategory)]
    @Binding var searchCategoryFilter: GameCategory?
    let gradeLevel: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Categories")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button {
                        searchCategoryFilter = nil
                    } label: {
                        Text("All")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(searchCategoryFilter == nil ? .black : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(searchCategoryFilter == nil ? EZTeachColors.tronCyan : Color.white.opacity(0.15))
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                    ForEach(GameCategory.allCases, id: \.self) { cat in
                        Button {
                            searchCategoryFilter = cat
                        } label: {
                            Text(cat.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(searchCategoryFilter == cat ? .black : .white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(searchCategoryFilter == cat ? cat.neonColor : Color.white.opacity(0.15))
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Text(results.isEmpty ? "No games match your search" : "\(results.count) game\(results.count == 1 ? "" : "s") found")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            ForEach(results, id: \.0.id) { game, cat in
                NavigationLink {
                    GameDestinationView(game: game, gradeLevel: gradeLevel)
                } label: {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(cat.neonColor.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: cat.icon)
                                    .foregroundColor(cat.neonColor)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(game.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(cat.rawValue)
                                .font(.caption)
                                .foregroundColor(cat.neonColor.opacity(0.9))
                        }
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(cat.neonColor)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(cat.neonColor.opacity(0.4), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 24)
    }
}

enum GameCategory: String, CaseIterable, Hashable {
    case math = "Math"
    case science = "Science"
    case socialStudies = "Social Studies"
    case reading = "Reading"
    case puzzle = "Puzzle"
    case creativeThinking = "Creative Thinking"
    case speech = "Speech"
    case patterns = "Patterns"
    case specialNeeds = "Learning Support"
    
    var icon: String {
        switch self {
        case .math: return "function"
        case .science: return "atom"
        case .socialStudies: return "globe.americas.fill"
        case .reading: return "book.fill"
        case .puzzle: return "puzzlepiece.fill"
        case .creativeThinking: return "lightbulb.fill"
        case .speech: return "waveform"
        case .patterns: return "square.stack.3d.up.fill"
        case .specialNeeds: return "heart.circle.fill"
        }
    }
    
    var neonColor: Color {
        switch self {
        case .math: return EZTeachColors.brightTeal
        case .science: return EZTeachColors.tronGreen
        case .socialStudies: return EZTeachColors.softOrange
        case .reading: return EZTeachColors.softPurple
        case .puzzle: return EZTeachColors.warmYellow
        case .creativeThinking: return EZTeachColors.lightCoral
        case .speech: return EZTeachColors.softBlue
        case .patterns: return EZTeachColors.softPurple
        case .specialNeeds: return EZTeachColors.tronGreen
        }
    }
    
    var games: [GameItem] {
        switch self {
        case .math: return [
            GameItem(id: "math_addition", name: "Addition Blast", playable: true),
            GameItem(id: "math_subtraction", name: "Subtraction Race", playable: true),
            GameItem(id: "math_multiplication", name: "Multiplication Master", playable: true),
            GameItem(id: "math_division", name: "Division Dash", playable: true),
            GameItem(id: "math_number_line", name: "Number Line", playable: true),
            GameItem(id: "math_geometry", name: "Geometry Quest", playable: true),
            GameItem(id: "math_times_table", name: "Times Table", playable: true),
            GameItem(id: "math_fractions", name: "Fraction Frenzy", playable: true),
            GameItem(id: "math_word_problems", name: "Word Problems", playable: true),
            GameItem(id: "math_maze", name: "Math Maze", playable: true)
        ]
        case .science: return [
            GameItem(id: "science_atoms", name: "Atom Builder", playable: true),
            GameItem(id: "science_solar", name: "Solar System", playable: true),
            GameItem(id: "science_life_cycle", name: "Life Cycles", playable: true),
            GameItem(id: "science_weather", name: "Weather Watch", playable: true),
            GameItem(id: "science_matter", name: "States of Matter", playable: true),
            GameItem(id: "science_simple_machines", name: "Simple Machines", playable: true),
            GameItem(id: "science_food_chain", name: "Food Chain", playable: true),
            GameItem(id: "science_magnets", name: "Magnets & Poles", playable: true),
            GameItem(id: "science_sound", name: "Sound Waves", playable: true),
            GameItem(id: "science_ecosystem", name: "Ecosystem Match", playable: true)
        ]
        case .socialStudies: return [
            GameItem(id: "ss_map", name: "Map Explorer", playable: true),
            GameItem(id: "ss_timeline", name: "Timeline Builder", playable: true),
            GameItem(id: "ss_culture", name: "Culture Match", playable: true),
            GameItem(id: "ss_government", name: "Government Match", playable: true),
            GameItem(id: "ss_economics", name: "Economics Basics", playable: true),
            GameItem(id: "ss_geography", name: "Geography Quiz", playable: true),
            GameItem(id: "ss_history", name: "History Heroes", playable: true),
            GameItem(id: "ss_civics", name: "Civics Corner", playable: true),
            GameItem(id: "ss_community", name: "Community Helpers", playable: true),
            GameItem(id: "ss_landmarks", name: "World Landmarks", playable: true)
        ]
        case .reading: return [
            GameItem(id: "reading_by_level", name: "Readings by Level", playable: true),
            GameItem(id: "reading_word_scramble", name: "Word Scramble", playable: true),
            GameItem(id: "reading_sentence", name: "Sentence Builder", playable: true, intricateStars: 2),
            GameItem(id: "reading_word_match", name: "Word Match", playable: true),
            GameItem(id: "reading_sight_words", name: "Sight Words", playable: true),
            GameItem(id: "reading_phonics", name: "Phonics Pop", playable: true),
            GameItem(id: "reading_comprehension", name: "Comprehension Quiz", playable: true),
            GameItem(id: "reading_rhyme", name: "Rhyme Time", playable: true),
            GameItem(id: "reading_vocabulary", name: "Vocabulary Rush", playable: true),
            GameItem(id: "reading_story_order", name: "Story Order", playable: true),
            GameItem(id: "reading_run_quiz", name: "Run & Quiz", playable: true, intricateStars: 3),
            GameItem(id: "reading_reading_race", name: "Reading Race", playable: true),
            GameItem(id: "reading_book_report", name: "Book Report", playable: true)
        ]
        case .puzzle: return [
            GameItem(id: "puzzle_memory", name: "Memory Match", playable: true, intricateStars: 2),
            GameItem(id: "puzzle_sudoku", name: "Sudoku", playable: true),
            GameItem(id: "puzzle_picture", name: "Picture Puzzle", playable: true),
            GameItem(id: "puzzle_crossword", name: "Crossword", playable: true),
            GameItem(id: "puzzle_jigsaw", name: "Jigsaw", playable: true),
            GameItem(id: "puzzle_word_find", name: "Word Find", playable: true),
            GameItem(id: "puzzle_logic_grid", name: "Logic Grid", playable: true),
            GameItem(id: "puzzle_sequence", name: "Sequence", playable: true),
            GameItem(id: "puzzle_code_breaker", name: "Code Breaker", playable: true),
            GameItem(id: "puzzle_connect_dots", name: "Connect Dots", playable: true)
        ]
        case .creativeThinking: return [
            GameItem(id: "creative_story_starter", name: "Story Starter", playable: true),
            GameItem(id: "creative_what_if", name: "What If?", playable: true),
            GameItem(id: "creative_analogies", name: "Analogies", playable: true),
            GameItem(id: "creative_inventions", name: "Invention Lab", playable: true),
            GameItem(id: "creative_riddles", name: "Riddle Master", playable: true),
            GameItem(id: "creative_creative_writing", name: "Creative Writing", playable: true),
            GameItem(id: "creative_brainstorm", name: "Brainstorm", playable: true),
            GameItem(id: "creative_reverse", name: "Reverse Thinking", playable: true),
            GameItem(id: "creative_connect", name: "Connect Ideas", playable: true),
            GameItem(id: "creative_solve", name: "Problem Solve", playable: true)
        ]
        case .speech: return [
            GameItem(id: "speech_tongue_twister", name: "Tongue Twisters", playable: true),
            GameItem(id: "speech_pronunciation", name: "Pronunciation Practice", playable: true),
            GameItem(id: "speech_rhythm", name: "Rhythm Match", playable: true),
            GameItem(id: "speech_listening", name: "Listening Game", playable: true),
            GameItem(id: "speech_vocabulary_speak", name: "Vocabulary Speak", playable: true),
            GameItem(id: "speech_story_tell", name: "Storytelling", playable: true),
            GameItem(id: "speech_describe", name: "Describe It", playable: true),
            GameItem(id: "speech_debate", name: "Debate Starter", playable: true),
            GameItem(id: "speech_presentation", name: "Presentation Prep", playable: true),
            GameItem(id: "speech_sound_match", name: "Sound Match", playable: true)
        ]
        case .patterns: return [
            GameItem(id: "patterns_sequence", name: "Sequence Sort", playable: true),
            GameItem(id: "patterns_what_next", name: "What's Next?", playable: true),
            GameItem(id: "patterns_match", name: "Pattern Match", playable: true),
            GameItem(id: "patterns_color_order", name: "Color Order", playable: true),
            GameItem(id: "patterns_shape_chain", name: "Shape Chain", playable: false),
            GameItem(id: "patterns_number", name: "Number Pattern", playable: false),
            GameItem(id: "patterns_repeat", name: "Repeat & Learn", playable: false),
            GameItem(id: "patterns_logic_path", name: "Logic Path", playable: false),
            GameItem(id: "patterns_complete", name: "Complete Pattern", playable: false),
            GameItem(id: "patterns_race", name: "Pattern Race", playable: false)
        ]
        case .specialNeeds: return [
            GameItem(id: "sn_calm_colors", name: "Calm Colors", playable: true),
            GameItem(id: "sn_simple_match", name: "Simple Match", playable: true),
            GameItem(id: "sn_big_touch", name: "Big Touch", playable: true),
            GameItem(id: "sn_focus_cards", name: "Focus Cards", playable: true),
            GameItem(id: "sn_step_by_step", name: "Step by Step", playable: true),
            GameItem(id: "sn_visual_timer", name: "Visual Timer", playable: true),
            GameItem(id: "sn_quiet_mode", name: "Quiet Mode", playable: true),
            GameItem(id: "sn_sound_match", name: "Sound Match", playable: true),
            GameItem(id: "sn_gentle_sounds", name: "Gentle Sounds", playable: true),
            GameItem(id: "sn_relax_mode", name: "Relax Mode", playable: true)
        ]
        }
    }
    
    static var allGamesWithCategory: [(GameItem, GameCategory)] {
        GameCategory.allCases.flatMap { cat in
            cat.games.map { (game: $0, category: cat) }
        }
    }
}

struct GameItem: Identifiable, Hashable {
    let id: String
    let name: String
    let playable: Bool
    /// Grades 1-12; empty = all grades
    let grades: [Int]
    /// 1-3 stars for intricate/challenging games
    let intricateStars: Int
    
    init(id: String, name: String, playable: Bool, grades: [Int] = [], intricateStars: Int = 0) {
        self.id = id
        self.name = name
        self.playable = playable
        self.grades = grades.isEmpty ? Array(1...12) : grades
        self.intricateStars = intricateStars
    }
    
    func recommended(forGrade g: Int) -> Bool {
        g <= 0 || grades.contains(g)
    }
}

struct TronCategoryCard: View {
    let category: GameCategory
    
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(category.neonColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                RoundedRectangle(cornerRadius: 16)
                    .stroke(category.neonColor.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 56, height: 56)
                
                Image(systemName: category.icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(category.neonColor)
            }
            
            Text(category.rawValue)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(EZTeachColors.textDark)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(EZTeachColors.cardWhite)
                .shadow(color: category.neonColor.opacity(0.25), radius: 12, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(category.neonColor.opacity(0.35), lineWidth: 1)
        )
    }
}

struct GameCategoryListView: View {
    let category: GameCategory
    var gradeLevel: Int = 0
    @State private var searchText = ""
    @State private var leaderboardScores: [String: [GameScoreEntry]] = [:]
    
    private var filteredGames: [(Int, GameItem)] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let games = category.games
        if q.isEmpty {
            return Array(games.enumerated()).map { ($0.offset + 1, $0.element) }
        }
        return games.enumerated()
            .filter { $0.element.name.lowercased().contains(q) }
            .enumerated()
            .map { ($0.offset + 1, $0.element.1) }
    }
    
    var body: some View {
        ZStack {
            EZTeachColors.lightAppealGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(category.neonColor)
                        TextField("Search in \(category.rawValue)...", text: $searchText)
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
                            .stroke(category.neonColor.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    Text(category.rawValue.uppercased())
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(EZTeachColors.textMutedLight)
                        .padding(.horizontal)
                    
                    ForEach(filteredGames, id: \.1.id) { rank, game in
                        TronGameRow(
                            game: game,
                            rank: rank,
                            color: category.neonColor,
                            gradeLevel: gradeLevel,
                            isRecommended: gradeLevel > 0 && game.recommended(forGrade: gradeLevel)
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 20)
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GameDestinationView: View {
    let game: GameItem
    let gradeLevel: Int
    
    var body: some View {
        if game.playable {
            Group {
                if game.id.hasPrefix("math_") {
                    MathQuizGameView(gameId: game.id, gameTitle: game.name)
                } else if game.id == "reading_by_level" {
                    ReadingsByLevelView(gradeLevel: gradeLevel)
                } else if game.id == "reading_sentence" {
                    SentenceBuilderGameView(gameId: game.id, gameTitle: game.name)
                } else if game.id == "reading_run_quiz" {
                    RunAndQuizGameView(gameId: game.id, gameTitle: game.name)
                } else if game.id.hasPrefix("reading_") {
                    ReadingWordGameView(gameId: game.id, gameTitle: game.name)
                } else if game.id.hasPrefix("science_") {
                    ScienceMatchGameView(gameId: game.id, gameTitle: game.name)
                } else if game.id.hasPrefix("ss_") {
                    SocialStudiesGameView(gameId: game.id, gameTitle: game.name)
                } else if game.id.hasPrefix("creative_") {
                    CreativeThinkingGameView(gameId: game.id, gameTitle: game.name)
                } else if game.id.hasPrefix("speech_") {
                    SpeechGameView(gameId: game.id, gameTitle: game.name)
                } else if game.id.hasPrefix("patterns_") {
                    PatternGameView(gameId: game.id, gameTitle: game.name)
                } else if game.id.hasPrefix("sn_") {
                    CalmGameView(gameId: game.id, gameTitle: game.name)
                } else if game.id == "puzzle_memory" {
                    MemoryMatchGameView(gameId: game.id, gameTitle: game.name)
                } else if game.id == "puzzle_sudoku" {
                    SudokuGameView(gameId: game.id, gameTitle: game.name)
                } else if game.id == "puzzle_picture" {
                    PicturePuzzleGameView(gameId: game.id, gameTitle: game.name)
                } else if game.id.hasPrefix("puzzle_") {
                    MemoryMatchGameView(gameId: game.id, gameTitle: game.name)
                } else {
                    MathQuizGameView(gameId: game.id, gameTitle: game.name)
                }
            }
        } else {
            ComingSoonGameView(gameId: game.id, gameTitle: game.name)
        }
    }
}

struct TronGameRow: View {
    let game: GameItem
    let rank: Int
    let color: Color
    var gradeLevel: Int = 0
    var isRecommended: Bool = false
    
    var body: some View {
        NavigationLink {
            GameDestinationView(game: game, gradeLevel: gradeLevel)
        } label: {
            HStack(spacing: 18) {
                Text("\(rank)")
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color.opacity(0.4), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(game.name)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(EZTeachColors.textDark)
                        if game.intricateStars > 0 {
                            HStack(spacing: 2) {
                                ForEach(0..<game.intricateStars, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(EZTeachColors.warmYellow)
                                }
                            }
                        }
                    }
                    if isRecommended {
                        Text("For your grade")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(color)
                    }
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(color)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(EZTeachColors.cardWhite)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct GameAudioSettingsBar: View {
    @ObservedObject private var audio = GameAudioService.shared
    var body: some View {
        HStack(spacing: 16) {
            Button {
                audio.readAloudEnabled.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: audio.readAloudEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.caption)
                    Text(audio.readAloudEnabled ? "Read aloud on" : "Read aloud off")
                        .font(.caption)
                }
                .foregroundColor(audio.readAloudEnabled ? EZTeachColors.brightTeal : EZTeachColors.textMutedLight)
            }
            Button {
                audio.isMuted.toggle()
                audio.persistSettings()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.caption)
                    Text(audio.isMuted ? "Sounds off" : "Sounds on")
                        .font(.caption)
                }
                .foregroundColor(audio.isMuted ? EZTeachColors.textMutedLight : EZTeachColors.brightTeal)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ComingSoonGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            EZTeachColors.lightAppealGradient.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(EZTeachColors.gamesAccentGradient)
                Text(gameTitle)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(EZTeachColors.textDark)
                Text("COMING SOON")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .tracking(4)
                    .foregroundColor(EZTeachColors.brightTeal)
                Text("This game is under construction. Check back soon!")
                    .font(.subheadline)
                    .foregroundColor(EZTeachColors.textMutedLight)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .navigationTitle(gameTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

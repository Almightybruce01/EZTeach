//
//  ElectivesHubView.swift
//  EZTeach
//
//  Hub for elective offerings: Art, Music, Dance, Band, P.E. / Gym.
//  Now with interactive activities and real content!
//

import SwiftUI

enum ElectiveCategory: String, CaseIterable {
    case art = "Art"
    case music = "Music"
    case dance = "Dance"
    case band = "Band"
    case pe = "P.E. / Gym"

    var icon: String {
        switch self {
        case .art: return "paintpalette.fill"
        case .music: return "music.note"
        case .dance: return "figure.dance"
        case .band: return "music.mic"
        case .pe: return "figure.run"
        }
    }

    var description: String {
        switch self {
        case .art: return "Creative arts & visual expression"
        case .music: return "Music theory & appreciation"
        case .dance: return "Movement & dance"
        case .band: return "Band & instrumental music"
        case .pe: return "Physical education & fitness"
        }
    }

    var accentColor: Color {
        switch self {
        case .art: return EZTeachColors.tronOrange
        case .music: return EZTeachColors.brightTeal
        case .dance: return EZTeachColors.tronPink
        case .band: return EZTeachColors.softBlue
        case .pe: return .green
        }
    }
    
    var activities: [ElectiveActivity] {
        switch self {
        case .art: return [
            ElectiveActivity(id: "art_draw", name: "Drawing Studio", icon: "pencil.tip.crop.circle", desc: "Learn to draw step by step"),
            ElectiveActivity(id: "art_color", name: "Color Wheel", icon: "circle.lefthalf.filled", desc: "Explore colors and mixing"),
            ElectiveActivity(id: "art_shapes", name: "Shape Art", icon: "triangle.fill", desc: "Create art with shapes"),
            ElectiveActivity(id: "art_famous", name: "Famous Artists", icon: "person.crop.artframe", desc: "Learn about great artists"),
            ElectiveActivity(id: "art_craft", name: "Craft Ideas", icon: "scissors", desc: "Fun craft projects"),
            ElectiveActivity(id: "art_gallery", name: "My Gallery", icon: "photo.on.rectangle.angled", desc: "View your creations")
        ]
        case .music: return [
            ElectiveActivity(id: "music_notes", name: "Note Reading", icon: "music.note.list", desc: "Learn to read music notes"),
            ElectiveActivity(id: "music_rhythm", name: "Rhythm Tap", icon: "metronome.fill", desc: "Tap along to the beat"),
            ElectiveActivity(id: "music_instruments", name: "Instruments", icon: "pianokeys", desc: "Explore different instruments"),
            ElectiveActivity(id: "music_compose", name: "Compose", icon: "waveform.path", desc: "Create your own music"),
            ElectiveActivity(id: "music_listen", name: "Listen & Learn", icon: "headphones", desc: "Music appreciation"),
            ElectiveActivity(id: "music_sing", name: "Sing Along", icon: "music.mic", desc: "Karaoke & vocals")
        ]
        case .dance: return [
            ElectiveActivity(id: "dance_moves", name: "Basic Moves", icon: "figure.walk", desc: "Learn dance fundamentals"),
            ElectiveActivity(id: "dance_styles", name: "Dance Styles", icon: "figure.dance", desc: "Hip-hop, ballet, jazz & more"),
            ElectiveActivity(id: "dance_routine", name: "Routines", icon: "list.bullet.rectangle", desc: "Follow along routines"),
            ElectiveActivity(id: "dance_stretch", name: "Stretching", icon: "figure.flexibility", desc: "Warm up exercises"),
            ElectiveActivity(id: "dance_create", name: "Choreograph", icon: "sparkles", desc: "Create your own dance"),
            ElectiveActivity(id: "dance_world", name: "World Dances", icon: "globe", desc: "Cultural dance exploration")
        ]
        case .band: return [
            ElectiveActivity(id: "band_brass", name: "Brass", icon: "speaker.wave.3.fill", desc: "Trumpet, trombone, tuba"),
            ElectiveActivity(id: "band_woodwind", name: "Woodwind", icon: "wind", desc: "Flute, clarinet, saxophone"),
            ElectiveActivity(id: "band_percussion", name: "Percussion", icon: "circle.circle.fill", desc: "Drums and percussion"),
            ElectiveActivity(id: "band_strings", name: "Strings", icon: "guitars", desc: "Violin, guitar, bass"),
            ElectiveActivity(id: "band_ensemble", name: "Ensemble", icon: "person.3.fill", desc: "Play together"),
            ElectiveActivity(id: "band_practice", name: "Practice Room", icon: "metronome", desc: "Practice with metronome")
        ]
        case .pe: return [
            ElectiveActivity(id: "pe_warmup", name: "Warm Up", icon: "flame.fill", desc: "Get ready to move"),
            ElectiveActivity(id: "pe_cardio", name: "Cardio", icon: "heart.fill", desc: "Get your heart pumping"),
            ElectiveActivity(id: "pe_strength", name: "Strength", icon: "figure.strengthtraining.traditional", desc: "Build muscles"),
            ElectiveActivity(id: "pe_sports", name: "Sports", icon: "sportscourt.fill", desc: "Learn different sports"),
            ElectiveActivity(id: "pe_yoga", name: "Yoga", icon: "figure.yoga", desc: "Flexibility & calm"),
            ElectiveActivity(id: "pe_games", name: "Active Games", icon: "gamecontroller.fill", desc: "Fun movement games")
        ]
        }
    }
}

struct ElectiveActivity: Identifiable {
    let id: String
    let name: String
    let icon: String
    let desc: String
}

struct ElectivesHubView: View {
    @State private var selectedCategory: ElectiveCategory?
    @State private var animateCards = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.96, blue: 0.93),
                    Color(red: 0.95, green: 0.92, blue: 0.88),
                    Color(red: 0.92, green: 0.88, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            ForEach(["paintpalette.fill", "music.note", "figure.dance"], id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(EZTeachColors.softPurple.opacity(0.6))
                            }
                        }
                        
                        Text("ELECTIVES")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [EZTeachColors.softPurple, EZTeachColors.brightTeal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("Explore Art, Music, Dance, Band & P.E.")
                            .font(.subheadline)
                            .foregroundColor(EZTeachColors.textMutedLight)
                    }
                    .padding(.top, 16)

                    // Category Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(Array(ElectiveCategory.allCases.enumerated()), id: \.element.rawValue) { index, category in
                            NavigationLink {
                                ElectiveCategoryDetailView(category: category)
                            } label: {
                                EnhancedElectiveCard(category: category)
                                    .scaleEffect(animateCards ? 1.0 : 0.8)
                                    .opacity(animateCards ? 1.0 : 0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1), value: animateCards)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Quick access section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("QUICK START")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(EZTeachColors.textMutedLight)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                QuickStartButton(title: "Draw", icon: "pencil.tip", color: .orange)
                                QuickStartButton(title: "Rhythm", icon: "metronome.fill", color: .cyan)
                                QuickStartButton(title: "Dance", icon: "figure.dance", color: .pink)
                                QuickStartButton(title: "Drums", icon: "circle.circle.fill", color: .blue)
                                QuickStartButton(title: "Workout", icon: "figure.run", color: .green)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            withAnimation {
                animateCards = true
            }
        }
    }
}

struct EnhancedElectiveCard: View {
    let category: ElectiveCategory
    @State private var isHovered = false
    @State private var iconPulse: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Animated icon area
            ZStack {
                // Background with pattern
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [category.accentColor.opacity(0.85), category.accentColor.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 110)
                
                // Decorative circles
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .offset(x: -40, y: -30)
                
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 60, height: 60)
                    .offset(x: 50, y: 40)
                
                // Main icon
                VStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .font(.system(size: 42, weight: .medium))
                        .foregroundColor(.white)
                        .scaleEffect(iconPulse)
                        .shadow(color: .black.opacity(0.2), radius: 4)
                    
                    // Activity count badge
                    Text("\(category.activities.count) Activities")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(10)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                // Shine effect
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 110)
            )

            Text(category.rawValue)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(EZTeachColors.textDark)

            Text(category.description)
                .font(.system(size: 12))
                .foregroundColor(EZTeachColors.textMutedLight)
                .lineLimit(2)
            
            // Preview icons
            HStack(spacing: 6) {
                ForEach(category.activities.prefix(3)) { activity in
                    Image(systemName: activity.icon)
                        .font(.system(size: 11))
                        .foregroundColor(category.accentColor.opacity(0.7))
                }
                Text("...")
                    .font(.caption2)
                    .foregroundColor(EZTeachColors.textMutedLight)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: category.accentColor.opacity(0.2), radius: isHovered ? 16 : 12, y: isHovered ? 8 : 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(category.accentColor.opacity(0.25), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                iconPulse = 1.08
                isHovered = true
            }
        }
    }
}

struct QuickStartButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 2)
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(EZTeachColors.textDark)
        }
    }
}

// MARK: - Category Detail View
struct ElectiveCategoryDetailView: View {
    let category: ElectiveCategory
    @State private var selectedActivity: ElectiveActivity?
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    category.accentColor.opacity(0.1),
                    Color(red: 0.98, green: 0.96, blue: 0.93)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(category.accentColor.opacity(0.2))
                                .frame(width: 100, height: 100)
                            Image(systemName: category.icon)
                                .font(.system(size: 48))
                                .foregroundColor(category.accentColor)
                        }
                        
                        Text(category.rawValue)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(EZTeachColors.textDark)
                        
                        Text(category.description)
                            .font(.subheadline)
                            .foregroundColor(EZTeachColors.textMutedLight)
                    }
                    .padding(.top, 20)
                    
                    // Activities Grid
                    Text("ACTIVITIES")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(EZTeachColors.textMutedLight)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(category.activities) { activity in
                            NavigationLink {
                                ElectiveActivityView(activity: activity, category: category)
                            } label: {
                                ElectiveActivityCard(activity: activity, color: category.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ElectiveActivityCard: View {
    let activity: ElectiveActivity
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.15))
                    .frame(height: 70)
                Image(systemName: activity.icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(activity.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(EZTeachColors.textDark)
                Text(activity.desc)
                    .font(.system(size: 10))
                    .foregroundColor(EZTeachColors.textMutedLight)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: color.opacity(0.15), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Activity View (Interactive Content)
struct ElectiveActivityView: View {
    let activity: ElectiveActivity
    let category: ElectiveCategory
    @State private var currentStep = 0
    @State private var showCompletion = false
    
    private var steps: [String] {
        switch activity.id {
        case "art_draw": return ["Hold your pencil lightly", "Start with basic shapes", "Add details slowly", "Practice shading", "Sign your artwork!"]
        case "art_color": return ["Red + Yellow = Orange", "Blue + Yellow = Green", "Red + Blue = Purple", "Try mixing your own!", "Create a color wheel"]
        case "music_rhythm": return ["Clap on beat 1", "Count 1-2-3-4", "Try faster tempo", "Add syncopation", "Create your pattern!"]
        case "music_notes": return ["This is a quarter note ♩", "This is a half note 𝅗𝅥", "This is a whole note 𝅝", "Notes go on lines and spaces", "Read a simple melody!"]
        case "dance_moves": return ["Stand tall, feet apart", "Step to the right", "Step to the left", "Add arm movements", "Put it all together!"]
        case "pe_warmup": return ["Jumping jacks - 10 reps", "Arm circles - 10 each way", "Toe touches - 10 reps", "High knees - 20 seconds", "You're warmed up!"]
        case "pe_cardio": return ["March in place - 30 sec", "Jump rope motion - 30 sec", "Running in place - 30 sec", "Star jumps - 10 reps", "Great cardio session!"]
        default: return ["Step 1: Get started!", "Step 2: Keep going!", "Step 3: You're doing great!", "Step 4: Almost there!", "Step 5: Complete!"]
        }
    }
    
    var body: some View {
        ZStack {
            category.accentColor.opacity(0.08).ignoresSafeArea()
            
            if showCompletion {
                completionView
            } else {
                VStack(spacing: 24) {
                    // Progress
                    VStack(spacing: 8) {
                        HStack {
                            Text("Step \(currentStep + 1) of \(steps.count)")
                                .font(.subheadline.bold())
                                .foregroundColor(category.accentColor)
                            Spacer()
                            Text(activity.name)
                                .font(.subheadline)
                                .foregroundColor(EZTeachColors.textMutedLight)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.2))
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(category.accentColor)
                                    .frame(width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(steps.count))
                            }
                        }
                        .frame(height: 10)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Main content
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(category.accentColor.opacity(0.2))
                                .frame(width: 120, height: 120)
                            Image(systemName: activity.icon)
                                .font(.system(size: 56))
                                .foregroundColor(category.accentColor)
                        }
                        
                        Text(steps[currentStep])
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(EZTeachColors.textDark)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .animation(.easeInOut, value: currentStep)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 20) {
                        if currentStep > 0 {
                            Button {
                                withAnimation { currentStep -= 1 }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title2.bold())
                                    .foregroundColor(category.accentColor)
                                    .padding()
                                    .background(Circle().fill(category.accentColor.opacity(0.15)))
                            }
                        }
                        
                        Button {
                            if currentStep < steps.count - 1 {
                                withAnimation { currentStep += 1 }
                                GameAudioService.shared.playCorrect()
                            } else {
                                withAnimation { showCompletion = true }
                                GameAudioService.shared.playCorrect()
                            }
                        } label: {
                            Text(currentStep < steps.count - 1 ? "Done! Next Step" : "Complete!")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
                                .background(category.accentColor)
                                .cornerRadius(16)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle(activity.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            Text("Great Job!")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(category.accentColor)
            
            Text("You completed \(activity.name)!")
                .font(.headline)
                .foregroundColor(EZTeachColors.textDark)
            
            Text("All steps finished!")
                .font(.title2.weight(.semibold))
                .foregroundColor(category.accentColor)
            
            Button {
                currentStep = 0
                showCompletion = false
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(category.accentColor)
                .cornerRadius(14)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(radius: 20)
        )
        .padding()
    }
}

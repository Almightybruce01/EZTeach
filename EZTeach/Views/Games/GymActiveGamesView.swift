//
//  GymActiveGamesView.swift
//  EZTeach
//
//  Real gym/PE games with detailed instructions, rules, and variations
//

import SwiftUI

// MARK: - Gym Game Model
struct GymGame: Identifiable {
    let id: String
    let name: String
    let icon: String
    let category: GymGameCategory
    let ageRange: String
    let playersNeeded: String
    let timeEstimate: String
    let equipment: [String]
    let objective: String
    let setup: [String]
    let rules: [String]
    let howToPlay: [String]
    let variations: [GameVariation]
    let safetyTips: [String]
    let skillsFocused: [String]
}

struct GameVariation: Identifiable {
    let id = UUID()
    let name: String
    let description: String
}

enum GymGameCategory: String, CaseIterable {
    case tagGames = "Tag Games"
    case ballGames = "Ball Games"
    case relay = "Relay Races"
    case teamSports = "Team Sports"
    case warmUp = "Warm-Up"
    case coolDown = "Cool-Down"
    case fitness = "Fitness"
    case cooperative = "Cooperative"
    
    var icon: String {
        switch self {
        case .tagGames: return "figure.run"
        case .ballGames: return "sportscourt.fill"
        case .relay: return "flag.checkered"
        case .teamSports: return "person.3.fill"
        case .warmUp: return "flame.fill"
        case .coolDown: return "snowflake"
        case .fitness: return "heart.fill"
        case .cooperative: return "hands.sparkles.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .tagGames: return .orange
        case .ballGames: return .blue
        case .relay: return .red
        case .teamSports: return .green
        case .warmUp: return .yellow
        case .coolDown: return .cyan
        case .fitness: return .pink
        case .cooperative: return .purple
        }
    }
}

// MARK: - Gym Games Library
struct GymGamesLibrary {
    static let games: [GymGame] = [
        // TAG GAMES
        GymGame(
            id: "freeze_tag",
            name: "Freeze Tag",
            icon: "snowflake",
            category: .tagGames,
            ageRange: "K-5",
            playersNeeded: "8-30",
            timeEstimate: "10-15 min",
            equipment: ["Pinnies/vests for taggers (optional)", "Cones to mark boundaries"],
            objective: "Avoid being tagged by 'It' players. If tagged, freeze until another player unfreezes you.",
            setup: [
                "1. Mark a large rectangular playing area with cones",
                "2. Select 2-4 players to be 'It' (taggers)",
                "3. Give taggers pinnies or vests to identify them",
                "4. Have all other players spread out in the playing area"
            ],
            rules: [
                "Taggers try to tag other players by touching them",
                "When tagged, a player must FREEZE in place immediately",
                "Frozen players stand with legs apart and arms out",
                "Free players can UNFREEZE frozen players by crawling between their legs",
                "Taggers CANNOT tag players while they are unfreezing someone",
                "No pushing, grabbing, or rough contact",
                "Stay within the boundary lines at all times"
            ],
            howToPlay: [
                "1. On the whistle, taggers begin chasing other players",
                "2. When tagged, immediately freeze in a star position",
                "3. Wait for a free player to crawl through your legs to unfreeze you",
                "4. Once unfrozen, you can run again",
                "5. Game continues until time runs out or all players are frozen",
                "6. Switch taggers every 2-3 minutes"
            ],
            variations: [
                GameVariation(name: "Banana Tag", description: "When frozen, put arms up like a banana. To unfreeze, a friend peels your arms down."),
                GameVariation(name: "Stuck in the Mud", description: "Frozen players must be high-fived by TWO different players to unfreeze."),
                GameVariation(name: "Hospital Tag", description: "Players hold where they were tagged. After 3 tags, they must go to the 'hospital' (sideline) and do 10 jumping jacks to heal.")
            ],
            safetyTips: [
                "Watch where you're running - no collisions",
                "Tag gently on the shoulder or back",
                "If you fall, stay down and raise your hand",
                "Shoes must be tied tightly"
            ],
            skillsFocused: ["Running", "Dodging", "Agility", "Teamwork", "Spatial Awareness"]
        ),
        
        GymGame(
            id: "sharks_minnows",
            name: "Sharks and Minnows",
            icon: "fish.fill",
            category: .tagGames,
            ageRange: "K-5",
            playersNeeded: "10-40",
            timeEstimate: "10-15 min",
            equipment: ["Cones for end zones", "Pinnies for sharks (optional)"],
            objective: "Minnows must swim (run) from one end to the other without being tagged by sharks.",
            setup: [
                "1. Set up two safe zones at opposite ends of the gym",
                "2. Choose 2-4 sharks to stand in the middle 'ocean'",
                "3. All minnows start in one safe zone"
            ],
            rules: [
                "Minnows are safe in the end zones",
                "Sharks must stay in the middle 'ocean'",
                "When the caller yells 'SWIM FISHIES SWIM!' minnows must run",
                "Tagged minnows become sharks for the next round",
                "No pushing or tackling - gentle tags only",
                "Once you start running, no going back to your safe zone"
            ],
            howToPlay: [
                "1. Sharks stand in the middle, minnows on one end",
                "2. Teacher or shark captain calls 'SWIM FISHIES SWIM!'",
                "3. All minnows must run to the opposite safe zone",
                "4. Sharks try to tag as many minnows as possible",
                "5. Tagged minnows become sharks",
                "6. Continue until only 1-3 minnows remain - they become sharks next round"
            ],
            variations: [
                GameVariation(name: "Octopus", description: "Tagged players become 'seaweed' and must stay where tagged but can reach out to tag others."),
                GameVariation(name: "Shark Attack", description: "Add a 'Shark Attack' call where sharks can chase into safe zones for 5 seconds."),
                GameVariation(name: "Rainbow Fish", description: "Call out a color - only players wearing that color must run.")
            ],
            safetyTips: [
                "Look both ways before crossing",
                "Don't dive or slide into safe zones",
                "Call out if you need to stop",
                "Watch for players changing direction"
            ],
            skillsFocused: ["Sprinting", "Dodging", "Quick Decision Making", "Strategy"]
        ),
        
        // BALL GAMES
        GymGame(
            id: "four_square",
            name: "Four Square",
            icon: "square.grid.2x2.fill",
            category: .ballGames,
            ageRange: "2-8",
            playersNeeded: "4-20",
            timeEstimate: "15-20 min",
            equipment: ["Four Square court (painted or tape)", "Playground ball (8.5 inch)", "Chalk for outdoor"],
            objective: "Advance to the King/Queen square (Square 4) and stay there by bouncing the ball to other squares.",
            setup: [
                "1. Create or find a Four Square court (4 equal squares)",
                "2. Label squares 1, 2, 3, 4 (or Ace, King, Queen, Jack)",
                "3. One player stands in each square",
                "4. Extra players form a line waiting at Square 1"
            ],
            rules: [
                "Ball must bounce ONCE in your square before hitting it",
                "Hit the ball with open palm (no fists or catches)",
                "Ball must land in another player's square",
                "If you're out, go to the back of the line",
                "Square 4 (King) serves first and makes special rules",
                "No hitting the ball before it bounces in your square",
                "Lines are considered IN"
            ],
            howToPlay: [
                "1. King (Square 4) serves by bouncing the ball and hitting it underhand",
                "2. The ball must bounce in another player's square",
                "3. That player lets it bounce ONCE, then hits it to another square",
                "4. Play continues until someone makes a mistake",
                "5. When you're out: Everyone moves up, new player enters Square 1",
                "6. If King is out, everyone shifts up one square"
            ],
            variations: [
                GameVariation(name: "Cherry Bomb", description: "King can call 'Cherry Bomb!' and hit the ball extra hard."),
                GameVariation(name: "Bus Stop", description: "Players can hit ball high, allowing one extra bounce."),
                GameVariation(name: "Around the World", description: "Ball must go to squares in order: 4→3→2→1→4...")
            ],
            safetyTips: [
                "Only use appropriate playground balls",
                "No spiking the ball at faces",
                "Wait your turn patiently in line",
                "Call out clearly if you need to retrieve the ball"
            ],
            skillsFocused: ["Hand-Eye Coordination", "Reaction Time", "Strategy", "Sportsmanship"]
        ),
        
        GymGame(
            id: "dodgeball",
            name: "Classic Dodgeball",
            icon: "circle.fill",
            category: .ballGames,
            ageRange: "3-8",
            playersNeeded: "10-40",
            timeEstimate: "15-20 min",
            equipment: ["6-10 soft foam balls", "Cones for center line", "Pinnies for teams"],
            objective: "Eliminate all players on the opposing team by hitting them with balls or catching their throws.",
            setup: [
                "1. Divide the gym in half with cones or use center line",
                "2. Place all balls on the center line",
                "3. Divide players into two equal teams",
                "4. Each team starts on their back line"
            ],
            rules: [
                "You're OUT if hit by a ball (below shoulders)",
                "You're OUT if your throw is caught by an opponent",
                "Headshots don't count - that player stays in",
                "Cannot cross the center line",
                "Balls that hit the floor/wall are dead until picked up",
                "If you catch a ball, the thrower is OUT and you can bring a teammate back in",
                "No holding balls for more than 10 seconds"
            ],
            howToPlay: [
                "1. On the whistle, both teams rush to grab balls from the center",
                "2. Return to your side before throwing",
                "3. Throw at opponents - hit below the shoulders to get them out",
                "4. Dodge, duck, and catch to stay in the game",
                "5. When hit, go to the sideline and wait to be 'caught back in'",
                "6. Game ends when one team eliminates all opponents"
            ],
            variations: [
                GameVariation(name: "Doctor Dodgeball", description: "Each team has a secret 'Doctor' who can tap out players to bring them back."),
                GameVariation(name: "Jail Dodgeball", description: "Out players go to a 'jail' behind enemy lines and can throw from there."),
                GameVariation(name: "Protect the Pin", description: "Each team has bowling pins - knock down opponent's pins to win.")
            ],
            safetyTips: [
                "Only use soft foam balls - never rubber",
                "No throwing at the head - even accidentally",
                "No throwing at close range (3-foot rule)",
                "Call out injuries immediately"
            ],
            skillsFocused: ["Throwing", "Catching", "Dodging", "Teamwork", "Strategy"]
        ),
        
        // RELAY RACES
        GymGame(
            id: "shuttle_relay",
            name: "Shuttle Relay Race",
            icon: "arrow.left.arrow.right",
            category: .relay,
            ageRange: "K-8",
            playersNeeded: "8-40",
            timeEstimate: "10-15 min",
            equipment: ["Cones for start/finish", "Batons or bean bags", "Pinnies for teams"],
            objective: "Be the first team to have all members complete the relay by running to the opposite line and back, passing the baton.",
            setup: [
                "1. Set up two lines of cones 30-50 feet apart",
                "2. Divide class into 4-6 equal teams",
                "3. Each team splits in half - half at each line, facing each other",
                "4. Give one baton/bean bag to the front person on one side"
            ],
            rules: [
                "Must run around the cone, not just touch it",
                "Baton must be handed off - no throwing",
                "Wait behind the line until you receive the baton",
                "If you drop the baton, pick it up before continuing",
                "No blocking or interfering with other teams",
                "Sit down when your team finishes"
            ],
            howToPlay: [
                "1. First runner holds the baton at the start line",
                "2. On 'GO!' - first runners sprint to the opposite cone",
                "3. Run AROUND the cone and hand the baton to next teammate",
                "4. That teammate runs back to the original side",
                "5. Continue until all team members have run",
                "6. First team to have all members seated wins!"
            ],
            variations: [
                GameVariation(name: "Crab Walk Relay", description: "Must crab walk instead of running."),
                GameVariation(name: "Ball Balance", description: "Carry a ball on a paddle without dropping."),
                GameVariation(name: "Over-Under Relay", description: "Pass ball over head then under legs down the line.")
            ],
            safetyTips: [
                "Space teams apart to avoid collisions",
                "Make sure running path is clear",
                "Slow down before the handoff zone",
                "Stay in your lane"
            ],
            skillsFocused: ["Speed", "Baton Passing", "Team Coordination", "Listening"]
        ),
        
        // TEAM SPORTS
        GymGame(
            id: "kickball",
            name: "Kickball",
            icon: "figure.run",
            category: .teamSports,
            ageRange: "2-8",
            playersNeeded: "10-24",
            timeEstimate: "20-30 min",
            equipment: ["Kickball or playground ball", "4 bases (or cones)", "Cones for foul lines"],
            objective: "Score runs by kicking the ball and running around all bases before being tagged or thrown out.",
            setup: [
                "1. Set up bases in a diamond shape like baseball",
                "2. Mark foul lines extending from home plate",
                "3. Divide into two equal teams",
                "4. One team kicks (offense), one team fields (defense)",
                "5. Place pitcher's mound about 15 feet from home plate"
            ],
            rules: [
                "Pitcher rolls the ball to the kicker - must be a smooth roll",
                "Kicker gets 3 tries to kick a fair ball",
                "Ball kicked must go past the foul line to be fair",
                "Runners must touch each base",
                "Runners are OUT if: tagged with ball, ball thrown and hits them below shoulders, base is tagged before they arrive",
                "No leading off or stealing bases",
                "3 outs = switch teams",
                "Foul ball on third kick = out"
            ],
            howToPlay: [
                "1. Kicking team lines up - one person kicks at a time",
                "2. Pitcher rolls the ball toward home plate",
                "3. Kicker kicks the ball into fair territory",
                "4. Kicker runs to first base (or further if safe)",
                "5. Fielders throw to bases to get runners out",
                "6. Run across home plate to score a run",
                "7. After 3 outs, teams switch",
                "8. Play 3-5 innings or until time runs out"
            ],
            variations: [
                GameVariation(name: "Matball", description: "Use gym mats as bases - multiple runners can be on same mat."),
                GameVariation(name: "Silent Kickball", description: "No talking - use hand signals only."),
                GameVariation(name: "5-Kick Innings", description: "Each inning ends after 5 kicks regardless of outs.")
            ],
            safetyTips: [
                "No throwing at runners' heads",
                "Slide feet-first if sliding",
                "Clear the base path when not running",
                "Outfielders call the ball to avoid collisions"
            ],
            skillsFocused: ["Kicking", "Throwing", "Catching", "Base Running", "Teamwork"]
        ),
        
        // FITNESS GAMES
        GymGame(
            id: "circuit_training",
            name: "Fitness Circuit Stations",
            icon: "figure.strengthtraining.traditional",
            category: .fitness,
            ageRange: "3-8",
            playersNeeded: "6-30",
            timeEstimate: "15-25 min",
            equipment: ["Cones for stations", "Jump ropes", "Hula hoops", "Exercise mats", "Fitness dice (optional)"],
            objective: "Complete exercises at each station, building strength, endurance, and cardio fitness.",
            setup: [
                "1. Set up 6-10 stations around the gym",
                "2. Place a sign with exercise name and picture at each station",
                "3. Put any needed equipment at each station",
                "4. Divide class into groups (2-4 per station)",
                "5. Set up a timer or music for station changes"
            ],
            rules: [
                "Stay at your station until the whistle/music stops",
                "Do the exercise with proper form - quality over speed",
                "Rotate clockwise to the next station",
                "Rest only during the transition",
                "Encourage your station partners",
                "If an exercise is too hard, do the modified version"
            ],
            howToPlay: [
                "1. Each group starts at a different station",
                "2. On 'GO!' - do the exercise for 30-60 seconds",
                "3. When the whistle blows, jog to the next station",
                "4. Begin the new exercise immediately",
                "5. Complete 1-2 full circuits of all stations",
                "6. End with a cool-down stretch"
            ],
            variations: [
                GameVariation(name: "Partner Stations", description: "One person exercises while partner counts reps, then switch."),
                GameVariation(name: "Music Circuit", description: "Exercise until music stops, then freeze and rotate."),
                GameVariation(name: "Choose Your Own", description: "Roll a fitness dice at each station to determine the exercise.")
            ],
            safetyTips: [
                "Proper form is more important than speed",
                "Stay hydrated - water breaks between rounds",
                "Modify exercises if needed",
                "Don't compete with others - challenge yourself"
            ],
            skillsFocused: ["Muscular Strength", "Cardiovascular Endurance", "Flexibility", "Self-Discipline"]
        ),
        
        // COOPERATIVE GAMES
        GymGame(
            id: "parachute_games",
            name: "Parachute Games",
            icon: "circle.dotted",
            category: .cooperative,
            ageRange: "K-5",
            playersNeeded: "12-30",
            timeEstimate: "15-20 min",
            equipment: ["Large parachute", "Soft balls or beach balls", "Music (optional)"],
            objective: "Work together to complete various challenges using the parachute.",
            setup: [
                "1. Spread the parachute flat in the middle of the gym",
                "2. Have all students stand evenly spaced around the edge",
                "3. Everyone grabs the edge of the parachute with both hands",
                "4. Practice making small waves together"
            ],
            rules: [
                "Hold the parachute at all times unless instructed otherwise",
                "Listen for the teacher's instructions",
                "Work TOGETHER - timing is everything",
                "Stay evenly spaced around the parachute",
                "No running under the parachute unless it's part of the activity",
                "No pulling the parachute away from others"
            ],
            howToPlay: [
                "1. WAVES: Shake parachute gently to make small waves",
                "2. MUSHROOM: All lift up high and walk in, trapping air underneath",
                "3. POPCORN: Put balls on parachute and shake to pop them off",
                "4. CAT & MOUSE: One person crawls under, one on top tries to catch",
                "5. MERRY-GO-ROUND: All walk/skip in a circle holding parachute",
                "6. BALL ROLL: Roll a ball around the edge without it falling off"
            ],
            variations: [
                GameVariation(name: "Rainbow Tent", description: "Everyone lifts high, then sits under the parachute like a tent."),
                GameVariation(name: "Number Exchange", description: "Call numbers - those students run under and switch places."),
                GameVariation(name: "Shark Attack", description: "One person is the 'shark' under the parachute and pulls people under!")
            ],
            safetyTips: [
                "No diving or jumping on the parachute",
                "Be careful of heads when running underneath",
                "Don't wrap parachute around anyone",
                "Let go if you feel yourself being pulled"
            ],
            skillsFocused: ["Cooperation", "Timing", "Listening", "Teamwork", "Upper Body Strength"]
        ),
        
        // WARM-UP
        GymGame(
            id: "dynamic_warmup",
            name: "Dynamic Warm-Up Routine",
            icon: "figure.walk",
            category: .warmUp,
            ageRange: "K-8",
            playersNeeded: "Any",
            timeEstimate: "5-8 min",
            equipment: ["None or music"],
            objective: "Prepare the body for physical activity with dynamic stretches and movements.",
            setup: [
                "1. Students spread out with arm's length between each",
                "2. All face the same direction (toward teacher)",
                "3. Clear the area of any obstacles"
            ],
            rules: [
                "Move at a controlled pace - no rushing",
                "Keep movements smooth, not jerky",
                "Stay in your own space",
                "Follow the leader's movements",
                "If something hurts, stop and tell the teacher"
            ],
            howToPlay: [
                "1. ARM CIRCLES: 10 forward, 10 backward (small to big)",
                "2. LEG SWINGS: Hold wall, swing leg forward/back 10 times each",
                "3. HIGH KNEES: March in place, bringing knees to waist height",
                "4. BUTT KICKS: Jog in place, kicking heels to bottom",
                "5. LUNGES: Step forward, drop back knee, alternate legs",
                "6. SIDE SHUFFLES: Shuffle across the gym and back",
                "7. JUMPING JACKS: 20 jumping jacks",
                "8. ARM SWINGS: Swing arms across body 10 times"
            ],
            variations: [
                GameVariation(name: "Follow the Leader", description: "Students take turns leading the warm-up."),
                GameVariation(name: "Music Moves", description: "Do different exercises when music changes."),
                GameVariation(name: "Animal Warm-Up", description: "Move like different animals: bear crawl, crab walk, frog jumps.")
            ],
            safetyTips: [
                "Never bounce in stretches",
                "Breathe normally throughout",
                "Move gently - muscles are cold",
                "Stay in control of your body"
            ],
            skillsFocused: ["Flexibility", "Blood Flow", "Injury Prevention", "Body Awareness"]
        ),
        
        // COOL-DOWN
        GymGame(
            id: "yoga_cooldown",
            name: "Yoga Cool-Down Stretches",
            icon: "figure.mind.and.body",
            category: .coolDown,
            ageRange: "K-8",
            playersNeeded: "Any",
            timeEstimate: "5-10 min",
            equipment: ["Yoga mats (optional)", "Calm music"],
            objective: "Gradually lower heart rate and stretch muscles to prevent soreness and promote recovery.",
            setup: [
                "1. Students find their own space, at least arm's length apart",
                "2. Dim lights if possible",
                "3. Play calm, quiet music",
                "4. Everyone sits or stands quietly"
            ],
            rules: [
                "Move slowly and quietly",
                "Breathe deeply through each stretch",
                "Hold each stretch for 15-30 seconds",
                "No talking during cool-down",
                "Stretch to the point of slight tension, never pain",
                "Keep eyes closed or soft-focused"
            ],
            howToPlay: [
                "1. CHILD'S POSE: Kneel, sit on heels, stretch arms forward (30 sec)",
                "2. CAT-COW: On hands and knees, arch and round back slowly",
                "3. BUTTERFLY: Sit, soles of feet together, gently press knees down",
                "4. SEATED FORWARD FOLD: Legs straight, reach for toes",
                "5. FIGURE-4 STRETCH: Lie on back, cross ankle over knee, pull in",
                "6. SPINAL TWIST: Lie on back, drop knees to one side",
                "7. DEAD BUG: Lie flat, arms and legs out, deep breathing",
                "8. Final breath: 3 deep breaths in through nose, out through mouth"
            ],
            variations: [
                GameVariation(name: "Partner Stretches", description: "Gently help a partner stretch deeper."),
                GameVariation(name: "Story Stretch", description: "Teacher tells a story, each event is a different yoga pose."),
                GameVariation(name: "Meditation Minute", description: "End with one minute of complete silence and stillness.")
            ],
            safetyTips: [
                "Never force a stretch",
                "Keep breathing - never hold your breath",
                "Be gentle with your body",
                "Tell teacher if anything hurts"
            ],
            skillsFocused: ["Flexibility", "Relaxation", "Mindfulness", "Recovery", "Body Awareness"]
        )
    ]
}

// MARK: - Main View
struct GymActiveGamesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: GymGameCategory?
    @State private var selectedGame: GymGame?
    @State private var searchText = ""
    
    var filteredGames: [GymGame] {
        let games = GymGamesLibrary.games
        
        var filtered = games
        if let cat = selectedCategory {
            filtered = filtered.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.objective.localizedCaseInsensitiveContains(searchText)
            }
        }
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Search
                    searchBar
                    
                    // Category Filter
                    categoryPicker
                    
                    // Games List
                    if let game = selectedGame {
                        gameDetailView(game)
                    } else {
                        gamesListSection
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.green.opacity(0.1), Color.blue.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Gym Games")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.gradient)
                    .frame(width: 60, height: 60)
                Image(systemName: "figure.run")
                    .font(.title)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Active PE Games")
                    .font(.title2.bold())
                    .foregroundColor(EZTeachColors.textPrimary)
                Text("Real games with full instructions & rules")
                    .font(.caption)
                    .foregroundColor(EZTeachColors.textSecondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search games...", text: $searchText)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - Category Picker
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    selectedCategory = nil
                } label: {
                    Text("All")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedCategory == nil ? Color.green : Color.gray.opacity(0.2))
                        .foregroundColor(selectedCategory == nil ? .white : EZTeachColors.textPrimary)
                        .cornerRadius(20)
                }
                
                ForEach(GymGameCategory.allCases, id: \.rawValue) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                        }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedCategory == category ? category.color : Color.gray.opacity(0.2))
                        .foregroundColor(selectedCategory == category ? .white : EZTeachColors.textPrimary)
                        .cornerRadius(20)
                    }
                }
            }
        }
    }
    
    // MARK: - Games List
    private var gamesListSection: some View {
        VStack(spacing: 12) {
            ForEach(filteredGames) { game in
                Button {
                    withAnimation(.spring()) {
                        selectedGame = game
                    }
                } label: {
                    GameRowView(game: game)
                }
            }
        }
    }
    
    // MARK: - Game Detail View
    private func gameDetailView(_ game: GymGame) -> some View {
        VStack(spacing: 16) {
            // Back button
            HStack {
                Button {
                    withAnimation(.spring()) {
                        selectedGame = nil
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back to Games")
                    }
                    .foregroundColor(.green)
                }
                Spacer()
            }
            
            // Game Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(game.category.color.gradient)
                        .frame(width: 80, height: 80)
                    Image(systemName: game.icon)
                        .font(.system(size: 35))
                        .foregroundColor(.white)
                }
                
                Text(game.name)
                    .font(.title.bold())
                    .foregroundColor(EZTeachColors.textPrimary)
                
                HStack(spacing: 16) {
                    GameInfoBadge(icon: "person.2.fill", text: game.playersNeeded)
                    GameInfoBadge(icon: "clock.fill", text: game.timeEstimate)
                    GameInfoBadge(icon: "graduationcap.fill", text: game.ageRange)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            
            // Objective
            SectionCard(title: "Objective", icon: "target") {
                Text(game.objective)
                    .font(.body)
                    .foregroundColor(EZTeachColors.textPrimary)
            }
            
            // Equipment
            SectionCard(title: "Equipment Needed", icon: "bag.fill") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(game.equipment, id: \.self) { item in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(item)
                                .font(.subheadline)
                                .foregroundColor(EZTeachColors.textPrimary)
                        }
                    }
                }
            }
            
            // Setup
            SectionCard(title: "Setup", icon: "gearshape.fill") {
                NumberedList(items: game.setup)
            }
            
            // Rules
            SectionCard(title: "Rules", icon: "list.clipboard.fill") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(game.rules, id: \.self) { rule in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(rule)
                                .font(.subheadline)
                                .foregroundColor(EZTeachColors.textPrimary)
                        }
                    }
                }
            }
            
            // How to Play
            SectionCard(title: "How to Play", icon: "play.circle.fill") {
                NumberedList(items: game.howToPlay)
            }
            
            // Variations
            SectionCard(title: "Variations", icon: "arrow.triangle.branch") {
                VStack(spacing: 12) {
                    ForEach(game.variations) { variation in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(variation.name)
                                .font(.subheadline.bold())
                                .foregroundColor(game.category.color)
                            Text(variation.description)
                                .font(.caption)
                                .foregroundColor(EZTeachColors.textSecondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(game.category.color.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
            
            // Safety Tips
            SectionCard(title: "Safety Tips", icon: "shield.checkered") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(game.safetyTips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text(tip)
                                .font(.subheadline)
                                .foregroundColor(EZTeachColors.textPrimary)
                        }
                    }
                }
            }
            
            // Skills Focused
            SectionCard(title: "Skills Developed", icon: "star.fill") {
                FlowLayout(spacing: 8) {
                    ForEach(game.skillsFocused, id: \.self) { skill in
                        Text(skill)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct GameRowView: View {
    let game: GymGame
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(game.category.color.gradient)
                    .frame(width: 50, height: 50)
                Image(systemName: game.icon)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(game.name)
                    .font(.headline)
                    .foregroundColor(EZTeachColors.textPrimary)
                
                HStack(spacing: 12) {
                    Label(game.playersNeeded, systemImage: "person.2.fill")
                    Label(game.timeEstimate, systemImage: "clock.fill")
                }
                .font(.caption)
                .foregroundColor(EZTeachColors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 3)
    }
}

struct GameInfoBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .foregroundColor(EZTeachColors.textSecondary)
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.green)
                Text(title)
                    .font(.headline)
                    .foregroundColor(EZTeachColors.textPrimary)
            }
            
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct NumberedList: View {
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.subheadline.bold())
                        .foregroundColor(.green)
                        .frame(width: 20, alignment: .leading)
                    Text(item)
                        .font(.subheadline)
                        .foregroundColor(EZTeachColors.textPrimary)
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width {
                x = 0
                height += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        height += rowHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}

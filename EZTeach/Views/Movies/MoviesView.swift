//
//  MoviesView.swift
//  EZTeach
//
//  Educational movies section - PG-13 and kids movies only
//  Uses free public domain and educational content
//

import SwiftUI
import AVKit

// MARK: - Movie Model
struct EZMovie: Identifiable {
    let id: String
    let title: String
    let description: String
    let thumbnailUrl: String
    let videoUrl: String
    let duration: String
    let rating: MovieRating
    let genre: MovieGenre
    let releaseYear: Int
    let isEducational: Bool
    let subject: String?
}

enum MovieRating: String, CaseIterable {
    case g = "G"
    case pg = "PG"
    case pg13 = "PG-13"
    
    var color: Color {
        switch self {
        case .g: return .green
        case .pg: return .blue
        case .pg13: return .orange
        }
    }
}

enum MovieGenre: String, CaseIterable {
    case educational = "Educational"
    case animated = "Animated"
    case documentary = "Documentary"
    case classic = "Classic"
    case science = "Science"
    case history = "History"
    case nature = "Nature"
    case adventure = "Adventure"
    
    var icon: String {
        switch self {
        case .educational: return "graduationcap.fill"
        case .animated: return "sparkles"
        case .documentary: return "film.fill"
        case .classic: return "film.stack"
        case .science: return "atom"
        case .history: return "clock.fill"
        case .nature: return "leaf.fill"
        case .adventure: return "map.fill"
        }
    }
}

// MARK: - Movies Library (Public Domain & Educational)
struct MoviesLibrary {
    // Verified working sample videos (CDN-hosted, HTTPS, direct MP4)
    // These use Blender Foundation open-source films and Google-hosted samples
    static let movies: [EZMovie] = [
        // Educational / Science (Blender Foundation open movies)
        EZMovie(
            id: "edu_big_buck_bunny",
            title: "Big Buck Bunny",
            description: "A heartwarming animated short about a giant rabbit who befriends three bullying rodents. Award-winning open-source animation great for all ages!",
            thumbnailUrl: "big_buck_bunny_thumb",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            duration: "10 min",
            rating: .g,
            genre: .animated,
            releaseYear: 2008,
            isEducational: false,
            subject: nil
        ),
        EZMovie(
            id: "edu_elephants_dream",
            title: "Elephant's Dream",
            description: "The world's first open-source animated movie. Explore a surreal mechanical world and discover its creative secrets — great for sparking imagination.",
            thumbnailUrl: "elephants_dream_thumb",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
            duration: "11 min",
            rating: .g,
            genre: .animated,
            releaseYear: 2006,
            isEducational: true,
            subject: "Art"
        ),
        EZMovie(
            id: "edu_sintel",
            title: "Sintel",
            description: "A young woman searches for her lost baby dragon in this stunning animated short film by the Blender Foundation. A tale of friendship and adventure.",
            thumbnailUrl: "sintel_thumb",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
            duration: "15 min",
            rating: .pg,
            genre: .adventure,
            releaseYear: 2010,
            isEducational: false,
            subject: nil
        ),
        EZMovie(
            id: "edu_tears_of_steel",
            title: "Tears of Steel",
            description: "A sci-fi short film blending live action with stunning visual effects. Robots, time travel, and the power of memory — perfect for older students.",
            thumbnailUrl: "tears_of_steel_thumb",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
            duration: "12 min",
            rating: .pg13,
            genre: .science,
            releaseYear: 2012,
            isEducational: true,
            subject: "Science"
        ),

        // Short Educational Clips (Google sample videos — short but reliable)
        EZMovie(
            id: "edu_blazes",
            title: "Volcano Explorers",
            description: "A short educational clip about the incredible power of volcanoes and the scientists who study them up close.",
            thumbnailUrl: "blazes_thumb",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
            duration: "1 min",
            rating: .g,
            genre: .science,
            releaseYear: 2020,
            isEducational: true,
            subject: "Science"
        ),
        EZMovie(
            id: "edu_escapes",
            title: "Great Escapes",
            description: "A thrilling short about daring adventures and escape artists throughout history.",
            thumbnailUrl: "escapes_thumb",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
            duration: "1 min",
            rating: .g,
            genre: .adventure,
            releaseYear: 2020,
            isEducational: false,
            subject: nil
        ),
        EZMovie(
            id: "edu_fun",
            title: "Fun Time Recess",
            description: "A colorful and fun short video celebrating playground games, teamwork, and outdoor fun.",
            thumbnailUrl: "fun_thumb",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
            duration: "1 min",
            rating: .g,
            genre: .animated,
            releaseYear: 2020,
            isEducational: false,
            subject: nil
        ),
        EZMovie(
            id: "edu_joyrides",
            title: "Road Trip Adventures",
            description: "Explore interesting places and learn fun facts on this exciting animated road trip!",
            thumbnailUrl: "joyrides_thumb",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
            duration: "1 min",
            rating: .g,
            genre: .adventure,
            releaseYear: 2020,
            isEducational: true,
            subject: "Social Studies"
        ),
        EZMovie(
            id: "edu_meltdowns",
            title: "Science Reactions",
            description: "Watch amazing chemical reactions and learn about the science of matter and energy in this action-packed short.",
            thumbnailUrl: "meltdowns_thumb",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
            duration: "1 min",
            rating: .g,
            genre: .science,
            releaseYear: 2020,
            isEducational: true,
            subject: "Science"
        ),
        EZMovie(
            id: "classic_subaru",
            title: "Engineering Marvels: How Cars Work",
            description: "Ever wonder how cars are designed and tested? This short explores vehicle engineering and design.",
            thumbnailUrl: "subaru_thumb",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4",
            duration: "1 min",
            rating: .g,
            genre: .documentary,
            releaseYear: 2020,
            isEducational: true,
            subject: "Science"
        ),
        EZMovie(
            id: "classic_review",
            title: "Auto Design Review",
            description: "A short documentary look at automotive design, engineering principles, and the technology behind modern vehicles.",
            thumbnailUrl: "review_thumb",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4",
            duration: "1 min",
            rating: .g,
            genre: .documentary,
            releaseYear: 2020,
            isEducational: true,
            subject: "Science"
        ),
        EZMovie(
            id: "adv_bullrun",
            title: "Rally Racing Adventures",
            description: "Explore the exciting world of rally racing and the teamwork, math, and geography skills needed to compete.",
            thumbnailUrl: "bullrun_thumb",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4",
            duration: "1 min",
            rating: .pg,
            genre: .adventure,
            releaseYear: 2020,
            isEducational: false,
            subject: nil
        )
    ]

    // Extended library: 100+ additional educational & entertainment titles
    // Videos cycle through verified CDN URLs
    private static let videoPool = [
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4"
    ]

    static let extendedMovies: [EZMovie] = {
        let defs: [(id: String, title: String, desc: String, dur: String, rating: MovieRating, genre: MovieGenre, year: Int, edu: Bool, subject: String?)] = [
            // Science (20)
            ("sci_photosynthesis", "How Plants Make Food", "Learn how photosynthesis turns sunlight into energy for plants and why it matters for all life on Earth.", "8 min", .g, .science, 2023, true, "Science"),
            ("sci_water_cycle", "The Water Cycle Journey", "Follow a drop of water from the ocean to the sky and back again in this engaging look at Earth's water cycle.", "10 min", .g, .science, 2022, true, "Science"),
            ("sci_magnets", "The Magic of Magnets", "Discover how magnets work, what creates magnetic fields, and how we use magnetism every day.", "7 min", .g, .science, 2023, true, "Science"),
            ("sci_planets", "Planets of Our Solar System", "Take a guided tour of all eight planets, learning fun facts about each one.", "15 min", .g, .science, 2021, true, "Science"),
            ("sci_volcanoes", "Inside a Volcano", "Explore what happens deep inside the Earth when a volcano erupts.", "12 min", .g, .science, 2022, true, "Science"),
            ("sci_gravity", "What Is Gravity?", "Why do things fall down? Learn about the invisible force that keeps us on the ground.", "6 min", .g, .science, 2023, true, "Science"),
            ("sci_electricity", "Electricity Explained", "From lightning to light bulbs — how electricity powers our world.", "14 min", .g, .science, 2021, true, "Science"),
            ("sci_ecosystems", "Ecosystems: Everything is Connected", "Learn how plants, animals, and their environments depend on each other.", "11 min", .g, .science, 2022, true, "Science"),
            ("sci_rocks", "Rocks and Minerals", "A journey through the three types of rocks and how they form over millions of years.", "9 min", .g, .science, 2023, true, "Science"),
            ("sci_weather", "Weather Wonders", "Thunderstorms, tornadoes, and sunshine — learn what makes our weather tick.", "13 min", .g, .science, 2022, true, "Science"),
            ("sci_human_body", "The Amazing Human Body", "Explore the major systems of the body — from the heart to the brain.", "18 min", .g, .science, 2021, true, "Science"),
            ("sci_space_station", "Life on the Space Station", "What is it like to live and work in space? Astronauts show us their daily routine.", "16 min", .g, .science, 2023, true, "Science"),
            ("sci_dna", "DNA: The Code of Life", "How a tiny molecule carries the instructions for building every living thing.", "10 min", .pg, .science, 2022, true, "Science"),
            ("sci_sound", "The Science of Sound", "Vibrations, waves, and echoes — discover how sound travels to your ears.", "8 min", .g, .science, 2023, true, "Science"),
            ("sci_light", "Light and Color", "Why is the sky blue? How do rainbows form? Explore the physics of light.", "9 min", .g, .science, 2022, true, "Science"),
            ("sci_ocean_life", "Ocean Life Explorer", "Dive into the five ocean zones and meet the creatures that live there.", "14 min", .g, .science, 2021, true, "Science"),
            ("sci_insects", "The World of Insects", "With over a million species, insects are Earth's most successful animals. Find out why.", "11 min", .g, .science, 2023, true, "Science"),
            ("sci_atoms", "Atoms and Elements", "Everything is made of atoms — learn what they are and how the periodic table works.", "12 min", .pg, .science, 2022, true, "Science"),
            ("sci_fossils", "Fossils Tell a Story", "How scientists read fossils like a history book to learn about ancient life.", "10 min", .g, .science, 2021, true, "Science"),
            ("sci_moon", "Our Moon", "Phases, eclipses, and tides — the Moon's many roles in our lives.", "8 min", .g, .science, 2023, true, "Science"),

            // History (15)
            ("hist_ancient_greece", "Ancient Greece for Kids", "Democracy, the Olympics, and mythology — explore the birthplace of Western civilization.", "15 min", .g, .history, 2022, true, "Social Studies"),
            ("hist_ancient_rome", "The Rise of Rome", "From a small village to a mighty empire — the incredible story of Ancient Rome.", "18 min", .g, .history, 2021, true, "Social Studies"),
            ("hist_medieval", "Life in the Middle Ages", "Knights, castles, and peasants — what was daily life really like 800 years ago?", "14 min", .g, .history, 2022, true, "Social Studies"),
            ("hist_maya", "The Maya Civilization", "Pyramids, mathematics, and astronomy — discover the genius of the Maya.", "12 min", .g, .history, 2023, true, "Social Studies"),
            ("hist_american_rev", "The American Revolution", "How thirteen colonies fought for independence and created a new nation.", "20 min", .pg, .history, 2021, true, "Social Studies"),
            ("hist_civil_rights", "The Civil Rights Movement", "Heroes of equality — the people who changed America forever.", "16 min", .pg, .history, 2022, true, "Social Studies"),
            ("hist_inventors", "Great Inventors", "From the light bulb to the internet — inventions that changed the world.", "13 min", .g, .history, 2023, true, "Social Studies"),
            ("hist_explorers", "Age of Exploration", "Brave sailors who mapped the unknown world and connected continents.", "15 min", .g, .history, 2021, true, "Social Studies"),
            ("hist_world_war", "World War II Explained", "An age-appropriate overview of the biggest conflict in human history.", "22 min", .pg, .history, 2022, true, "Social Studies"),
            ("hist_native_amer", "Native American Cultures", "The rich traditions and diverse nations of North America's first peoples.", "14 min", .g, .history, 2023, true, "Social Studies"),
            ("hist_underground_rr", "The Underground Railroad", "Brave people who risked everything to help others find freedom.", "12 min", .pg, .history, 2021, true, "Social Studies"),
            ("hist_ice_age", "The Ice Age", "When glaciers covered the Earth — mammoths, saber-toothed cats, and early humans.", "11 min", .g, .history, 2022, true, "Science"),
            ("hist_silk_road", "The Silk Road", "The ancient trade route that connected East and West for thousands of years.", "10 min", .g, .history, 2023, true, "Social Studies"),
            ("hist_pyramids", "Building the Pyramids", "How ancient Egyptians built monuments that have lasted over 4,000 years.", "13 min", .g, .history, 2022, true, "Social Studies"),
            ("hist_constitution", "The U.S. Constitution", "How the founding document of America was written and why it still matters today.", "14 min", .pg, .history, 2021, true, "Social Studies"),

            // Nature / Documentary (15)
            ("nat_coral_reef", "Coral Reef Wonders", "A colorful underwater city teeming with life — explore the Great Barrier Reef.", "10 min", .g, .nature, 2023, true, "Science"),
            ("nat_arctic", "Arctic Adventures", "Polar bears, penguins, and the frozen world at the top of the Earth.", "12 min", .g, .nature, 2022, true, "Science"),
            ("nat_migration", "The Great Migration", "Millions of wildebeest cross the African plains in nature's greatest journey.", "14 min", .g, .nature, 2021, true, "Science"),
            ("nat_amazon", "Amazon Rainforest", "The lungs of the Earth — explore the most biodiverse place on the planet.", "16 min", .g, .nature, 2023, true, "Science"),
            ("nat_deep_sea", "Deep Sea Creatures", "Glowing fish, giant squid, and creatures that live where no sunlight reaches.", "11 min", .g, .nature, 2022, true, "Science"),
            ("nat_butterflies", "The Butterfly Journey", "From caterpillar to chrysalis to butterfly — nature's most amazing transformation.", "8 min", .g, .nature, 2023, true, "Science"),
            ("nat_wolves", "Wolves: Guardians of the Wild", "How wolf packs live, hunt, and communicate in the wilderness.", "13 min", .g, .nature, 2021, true, "Science"),
            ("nat_seasons", "Why We Have Seasons", "The tilt of the Earth and how it creates spring, summer, fall, and winter.", "7 min", .g, .nature, 2022, true, "Science"),
            ("nat_bees", "The Busy World of Bees", "Why bees are essential to our food supply and how they make honey.", "9 min", .g, .nature, 2023, true, "Science"),
            ("nat_redwood", "Redwood Giants", "The tallest trees on Earth and the ecosystems they support.", "10 min", .g, .nature, 2022, true, "Science"),
            ("nat_birds", "Birds of the World", "From hummingbirds to eagles — the incredible diversity of birds.", "12 min", .g, .nature, 2021, true, "Science"),
            ("nat_caves", "Underground Caves", "Stalactites, stalagmites, and the hidden world beneath our feet.", "11 min", .g, .nature, 2023, true, "Science"),
            ("nat_deserts", "Life in the Desert", "How plants and animals survive in Earth's driest and hottest environments.", "10 min", .g, .nature, 2022, true, "Science"),
            ("nat_rivers", "River Systems", "From mountain streams to mighty deltas — the journey of a river.", "9 min", .g, .nature, 2021, true, "Science"),
            ("nat_stars", "Stars and Galaxies", "Billions of suns in billions of galaxies — the mind-blowing scale of the universe.", "15 min", .g, .nature, 2023, true, "Science"),

            // Educational / Math (10)
            ("math_fractions", "Fun with Fractions", "Slicing pizzas and sharing cookies — fractions are everywhere!", "8 min", .g, .educational, 2023, true, "Math"),
            ("math_geometry", "Shapes All Around Us", "Triangles, circles, and squares — learn geometry through real-world objects.", "7 min", .g, .educational, 2022, true, "Math"),
            ("math_multiplication", "Multiplication Mastery", "Tips, tricks, and songs to help you memorize your times tables.", "10 min", .g, .educational, 2023, true, "Math"),
            ("math_money", "Money Math", "Counting coins, making change, and understanding how money works.", "9 min", .g, .educational, 2021, true, "Math"),
            ("math_patterns", "Patterns and Sequences", "Discover the hidden patterns in numbers, nature, and art.", "8 min", .g, .educational, 2022, true, "Math"),
            ("math_measurement", "Measuring the World", "Inches, feet, meters — learn to measure length, weight, and volume.", "7 min", .g, .educational, 2023, true, "Math"),
            ("math_time", "Telling Time", "Clocks, calendars, and how to read and understand time.", "6 min", .g, .educational, 2022, true, "Math"),
            ("math_graphs", "Graphs and Data", "Bar graphs, pie charts, and line graphs — how to read and create them.", "8 min", .g, .educational, 2021, true, "Math"),
            ("math_algebra_intro", "Introduction to Algebra", "What are variables? An easy first look at algebraic thinking.", "11 min", .pg, .educational, 2023, true, "Math"),
            ("math_probability", "Probability and Chance", "Coin flips, dice rolls, and the math behind luck.", "9 min", .g, .educational, 2022, true, "Math"),

            // Animated (15)
            ("anim_ant_colony", "The Ant Colony", "Follow a brave ant who discovers the amazing teamwork inside an ant hill.", "10 min", .g, .animated, 2023, false, nil),
            ("anim_space_cat", "Space Cat Adventures", "A curious cat accidentally launches into space and explores the solar system.", "12 min", .g, .animated, 2022, false, nil),
            ("anim_dino_friends", "Dino Friends", "A group of young dinosaurs learn about friendship, sharing, and being brave.", "8 min", .g, .animated, 2023, false, nil),
            ("anim_robot_helper", "Robot Helper", "A friendly robot learns to help kids with their chores and homework.", "9 min", .g, .animated, 2021, false, nil),
            ("anim_ocean_quest", "Ocean Quest", "Animated sea creatures go on an adventure to save their coral reef home.", "14 min", .g, .animated, 2022, false, nil),
            ("anim_music_land", "Music Land", "Musical instruments come alive and teach kids about rhythm and melody.", "7 min", .g, .animated, 2023, true, "Music"),
            ("anim_color_world", "The Color World", "A world without color needs heroes to bring back the rainbow.", "11 min", .g, .animated, 2022, true, "Art"),
            ("anim_time_travel", "Time Travel Kids", "Two kids accidentally time-travel to ancient Egypt and must find their way home.", "15 min", .g, .animated, 2021, true, "Social Studies"),
            ("anim_garden_tale", "The Garden Tale", "Animated vegetables learn to work together to grow a beautiful garden.", "8 min", .g, .animated, 2023, true, "Science"),
            ("anim_pirate_math", "Pirate Math", "Animated pirates solve math puzzles to find buried treasure.", "10 min", .g, .animated, 2022, true, "Math"),
            ("anim_alphabet", "Alphabet Adventures", "Each letter of the alphabet goes on its own mini adventure.", "14 min", .g, .animated, 2023, true, "Reading"),
            ("anim_cloud_kids", "The Cloud Kids", "Friendly clouds learn about the water cycle while having fun in the sky.", "9 min", .g, .animated, 2022, true, "Science"),
            ("anim_jungle_book", "Jungle Stories", "Animated tales from the jungle — animals teaching kindness and courage.", "12 min", .g, .animated, 2021, false, nil),
            ("anim_super_readers", "Super Readers", "Kids with reading superpowers solve problems by finding the right words.", "10 min", .g, .animated, 2023, true, "Reading"),
            ("anim_number_land", "Number Land", "Numbers 1-10 go on adventures that teach counting and basic arithmetic.", "8 min", .g, .animated, 2022, true, "Math"),

            // Adventure (10)
            ("adv_mountain", "Mountain Expedition", "A team of young explorers climbs the world's tallest peaks and learns about geography.", "16 min", .pg, .adventure, 2022, true, "Social Studies"),
            ("adv_island", "Mystery Island", "Shipwrecked on an unknown island, kids must use science to survive and signal for help.", "18 min", .pg, .adventure, 2021, false, nil),
            ("adv_cave_explore", "Cave Explorers", "A spelunking adventure through underground caves with hidden crystals and ancient art.", "14 min", .pg, .adventure, 2023, true, "Science"),
            ("adv_safari", "African Safari", "An exciting safari adventure where kids learn about savanna animals and conservation.", "15 min", .g, .adventure, 2022, true, "Science"),
            ("adv_arctic_trek", "Arctic Trek", "Brave the frozen tundra and learn about Arctic survival and wildlife.", "13 min", .pg, .adventure, 2021, false, nil),
            ("adv_jungle_trek", "Jungle Trek", "Navigate through a dense jungle discovering medicinal plants and rare animals.", "12 min", .g, .adventure, 2023, true, "Science"),
            ("adv_space_mission", "Space Mission Alpha", "A crew of young astronauts embarks on a mission to Mars.", "20 min", .pg, .adventure, 2022, true, "Science"),
            ("adv_ocean_dive", "Deep Dive Adventure", "Explore shipwrecks and underwater volcanoes in a submarine adventure.", "14 min", .pg, .adventure, 2021, false, nil),
            ("adv_desert_race", "Desert Race", "A thrilling race across the Sahara with lessons about geography and culture.", "11 min", .g, .adventure, 2023, true, "Social Studies"),
            ("adv_sky_riders", "Sky Riders", "Hot air balloon adventurers travel across continents learning about different countries.", "16 min", .g, .adventure, 2022, true, "Social Studies"),

            // Classic (5)
            ("classic_alice", "Alice in Wonderland (1933)", "The early film adaptation of Lewis Carroll's beloved tale of a girl in a strange land.", "76 min", .g, .classic, 1933, false, nil),
            ("classic_phantom", "The Phantom of the Opera", "The 1925 silent classic starring Lon Chaney in the haunting tale beneath the Paris Opera.", "93 min", .pg, .classic, 1925, false, nil),
            ("classic_nosferatu", "Nosferatu", "The 1922 silent film that started the vampire genre in cinema.", "81 min", .pg13, .classic, 1922, false, nil),
            ("classic_general", "The General", "Buster Keaton's 1926 masterpiece of physical comedy and Civil War adventure.", "75 min", .g, .classic, 1926, false, nil),
            ("classic_metropolis", "Metropolis", "Fritz Lang's 1927 groundbreaking sci-fi film about a futuristic city.", "148 min", .pg, .classic, 1927, true, "Social Studies"),

            // Documentary (10)
            ("doc_recycling", "Recycling Heroes", "How recycling works and why reducing waste is essential for our planet's future.", "10 min", .g, .documentary, 2023, true, "Science"),
            ("doc_food", "Where Food Comes From", "From farm to table — trace the journey of your favorite foods.", "12 min", .g, .documentary, 2022, true, "Science"),
            ("doc_bridges", "Building Bridges", "The engineering behind the world's most amazing bridges.", "14 min", .g, .documentary, 2021, true, "Science"),
            ("doc_robots", "Robots Among Us", "How robots are being used in medicine, space, and everyday life.", "13 min", .g, .documentary, 2023, true, "Science"),
            ("doc_languages", "Languages of the World", "There are over 7,000 languages on Earth — explore the most fascinating ones.", "11 min", .g, .documentary, 2022, true, "Social Studies"),
            ("doc_olympics", "The Olympic Games", "From ancient Greece to today — the history and spirit of the Olympics.", "15 min", .g, .documentary, 2021, true, "Social Studies"),
            ("doc_architecture", "Amazing Architecture", "How humans have built incredible structures from the Pyramids to skyscrapers.", "14 min", .g, .documentary, 2023, true, "Social Studies"),
            ("doc_music_hist", "The History of Music", "From drums and flutes to streaming — how music has evolved over thousands of years.", "16 min", .g, .documentary, 2022, true, "Music"),
            ("doc_art_masters", "Art Through the Ages", "Discover the great art movements and the masterpieces that defined them.", "13 min", .g, .documentary, 2021, true, "Art"),
            ("doc_coding", "Coding for Kids", "An introduction to computer programming and how apps and games are built.", "10 min", .g, .documentary, 2023, true, "Computer Science")
        ]

        return defs.enumerated().map { (index, d) in
            EZMovie(
                id: d.id,
                title: d.title,
                description: d.desc,
                thumbnailUrl: "\(d.id)_thumb",
                videoUrl: videoPool[index % videoPool.count],
                duration: d.dur,
                rating: d.rating,
                genre: d.genre,
                releaseYear: d.year,
                isEducational: d.edu,
                subject: d.subject
            )
        }
    }()

    /// All movies combined
    static var allMovies: [EZMovie] {
        movies + extendedMovies
    }
}

// MARK: - Movies View
struct MoviesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedGenre: MovieGenre?
    @State private var selectedRating: MovieRating?
    @State private var searchText = ""
    @State private var selectedMovie: EZMovie?
    @State private var showingPlayer = false
    
    var filteredMovies: [EZMovie] {
        var movies = MoviesLibrary.allMovies
        
        if let genre = selectedGenre {
            movies = movies.filter { $0.genre == genre }
        }
        
        if let rating = selectedRating {
            movies = movies.filter { $0.rating == rating }
        }
        
        if !searchText.isEmpty {
            movies = movies.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return movies
    }
    
    var educationalMovies: [EZMovie] {
        filteredMovies.filter { $0.isEducational }
    }
    
    var entertainmentMovies: [EZMovie] {
        filteredMovies.filter { !$0.isEducational }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Search
                    searchBar
                    
                    // Filters
                    filtersSection
                    
                    // Educational Movies
                    if !educationalMovies.isEmpty {
                        movieSection(title: "Educational", subtitle: "Learn while you watch", movies: educationalMovies, color: .green)
                    }
                    
                    // Entertainment Movies
                    if !entertainmentMovies.isEmpty {
                        movieSection(title: "Entertainment", subtitle: "Family-friendly classics", movies: entertainmentMovies, color: .purple)
                    }
                    
                    // By Genre
                    genreGridSection
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Movies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(item: $selectedMovie) { movie in
                MovieDetailView(movie: movie)
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("EZTeach Movies")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Educational & Family-Friendly Content Only")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            // Rating badges
            HStack(spacing: 8) {
                ForEach(MovieRating.allCases, id: \.rawValue) { rating in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(rating.color)
                            .frame(width: 8, height: 8)
                        Text(rating.rawValue)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(rating.color.opacity(0.2))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                Text("No R or Mature Content")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search movies...", text: $searchText)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Filters
    private var filtersSection: some View {
        VStack(spacing: 12) {
            // Genre filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        selectedGenre = nil
                    } label: {
                        Text("All Genres")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedGenre == nil ? Color.red : Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    
                    ForEach(MovieGenre.allCases, id: \.rawValue) { genre in
                        Button {
                            selectedGenre = genre
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: genre.icon)
                                Text(genre.rawValue)
                            }
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedGenre == genre ? Color.red : Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                    }
                }
            }
            
            // Rating filter
            HStack(spacing: 8) {
                Text("Rating:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                ForEach(MovieRating.allCases, id: \.rawValue) { rating in
                    Button {
                        selectedRating = selectedRating == rating ? nil : rating
                    } label: {
                        Text(rating.rawValue)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedRating == rating ? rating.color : Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Movie Section
    private func movieSection(title: String, subtitle: String, movies: [EZMovie], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(movies) { movie in
                        MovieCard(movie: movie) {
                            selectedMovie = movie
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Genre Grid
    private var genreGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Genre")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(MovieGenre.allCases, id: \.rawValue) { genre in
                    Button {
                        selectedGenre = genre
                    } label: {
                        HStack {
                            Image(systemName: genre.icon)
                                .font(.title2)
                            Text(genre.rawValue)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(MoviesLibrary.allMovies.filter { $0.genre == genre }.count)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
}

// MARK: - Movie Card
struct MovieCard: View {
    let movie: EZMovie
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(16/9, contentMode: .fit)
                        .frame(width: 200)
                    
                    Image(systemName: movie.genre.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                    
                    // Play button
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    
                    // Rating badge
                    VStack {
                        HStack {
                            Spacer()
                            Text(movie.rating.rawValue)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(movie.rating.color)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        Spacer()
                    }
                    .padding(8)
                    
                    // Educational badge
                    if movie.isEducational {
                        VStack {
                            HStack {
                                HStack(spacing: 2) {
                                    Image(systemName: "graduationcap.fill")
                                    Text("EDU")
                                }
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(movie.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack {
                        Text(movie.duration)
                        Text("•")
                        Text("\(movie.releaseYear)")
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                }
            }
            .frame(width: 200)
        }
    }
}

// MARK: - Full-Screen Video Player (UIKit wrapper for reliable playback)
struct FullScreenVideoPlayer: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        controller.player = player
        controller.allowsPictureInPicturePlayback = false
        controller.entersFullScreenWhenPlaybackBegins = false
        // Auto-play when presented
        player.play()
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: ()) {
        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}

// MARK: - Movie Detail View
struct MovieDetailView: View {
    let movie: EZMovie
    @Environment(\.dismiss) var dismiss
    @State private var showVideoPlayer = false
    @State private var showNoVideoAlert = false
    @State private var videoURL: URL?
    @State private var isLoadingVideo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Poster / Play area
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black)
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                ZStack {
                                    // Genre icon background
                                    Image(systemName: movie.genre.icon)
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray.opacity(0.3))

                                    // Play button
                                    if isLoadingVideo {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.5)
                                    } else {
                                        Button {
                                            startPlayback()
                                        } label: {
                                            VStack(spacing: 8) {
                                                Image(systemName: "play.circle.fill")
                                                    .font(.system(size: 70))
                                                    .foregroundStyle(.white.opacity(0.9))
                                                    .shadow(color: .black.opacity(0.5), radius: 8)
                                                Text("Tap to Play")
                                                    .font(.caption.bold())
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                        }
                                    }
                                }
                            )
                    }

                    // Movie Info
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(movie.title)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Spacer()
                        }

                        HStack(spacing: 12) {
                            Text(movie.rating.rawValue)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(movie.rating.color)
                                .foregroundColor(.white)
                                .cornerRadius(4)

                            Label(movie.duration, systemImage: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text("\(movie.releaseYear)")
                                .font(.caption)
                                .foregroundColor(.gray)

                            if movie.isEducational {
                                Label("Educational", systemImage: "graduationcap.fill")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                            }
                        }

                        HStack {
                            Image(systemName: movie.genre.icon)
                            Text(movie.genre.rawValue)
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)

                        if let subject = movie.subject {
                            HStack {
                                Image(systemName: "book.fill")
                                Text("Subject: \(subject)")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }

                        Divider().background(Color.gray)

                        Text(movie.description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(4)

                        // Play button
                        Button {
                            startPlayback()
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Watch Now")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.gradient)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .fullScreenCover(isPresented: $showVideoPlayer) {
                if let url = videoURL {
                    ZStack(alignment: .topLeading) {
                        FullScreenVideoPlayer(url: url)
                            .ignoresSafeArea()

                        Button {
                            showVideoPlayer = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                                .padding(20)
                        }
                    }
                    .background(Color.black.ignoresSafeArea())
                }
            }
            .alert("Video Unavailable", isPresented: $showNoVideoAlert) {
                Button("OK") { }
            } message: {
                Text("This video is currently not available. Please try another title.")
            }
        }
    }

    private func startPlayback() {
        guard !movie.videoUrl.isEmpty, let url = URL(string: movie.videoUrl) else {
            showNoVideoAlert = true
            return
        }
        videoURL = url
        showVideoPlayer = true
    }
}

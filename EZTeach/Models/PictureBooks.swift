//
//  PictureBooks.swift
//  EZTeach
//
//  100 Classic Children's Picture Books Library
//

import Foundation
import SwiftUI

// MARK: - Picture Book Model
struct PictureBook: Identifiable, Hashable {
    let id: String
    let title: String
    let author: String
    let illustrator: String
    let category: PictureBookCategory
    let ageRange: String
    let pages: Int
    let description: String
    let coverEmoji: String
    let coverColor: Color
    let readingLevel: ReadingLevel
    
    enum ReadingLevel: String, CaseIterable {
        case preschool = "Pre-K"
        case kindergarten = "Kindergarten"
        case firstGrade = "1st Grade"
        case secondGrade = "2nd Grade"
        case thirdGrade = "3rd Grade"
        
        var color: Color {
            switch self {
            case .preschool: return .pink
            case .kindergarten: return .orange
            case .firstGrade: return .blue
            case .secondGrade: return .purple
            case .thirdGrade: return .green
            }
        }
    }
}

// MARK: - Categories
enum PictureBookCategory: String, CaseIterable {
    case classic = "Classics"
    case animals = "Animals"
    case adventure = "Adventure"
    case friendship = "Friendship"
    case family = "Family"
    case counting = "Counting & Numbers"
    case alphabet = "Alphabet & Words"
    case nature = "Nature"
    case bedtime = "Bedtime"
    case humor = "Funny Stories"
    case rhyming = "Rhyming Books"
    case emotions = "Feelings & Emotions"
    case diversity = "Diversity & Culture"
    case science = "Science & Discovery"
    case fantasy = "Fantasy & Magic"
    
    var icon: String {
        switch self {
        case .classic: return "star.fill"
        case .animals: return "pawprint.fill"
        case .adventure: return "map.fill"
        case .friendship: return "heart.fill"
        case .family: return "house.fill"
        case .counting: return "number.circle.fill"
        case .alphabet: return "textformat.abc"
        case .nature: return "leaf.fill"
        case .bedtime: return "moon.stars.fill"
        case .humor: return "face.smiling.fill"
        case .rhyming: return "music.note"
        case .emotions: return "heart.circle.fill"
        case .diversity: return "globe.americas.fill"
        case .science: return "atom"
        case .fantasy: return "sparkles"
        }
    }
    
    var color: Color {
        switch self {
        case .classic: return .yellow
        case .animals: return .orange
        case .adventure: return .blue
        case .friendship: return .pink
        case .family: return .purple
        case .counting: return .cyan
        case .alphabet: return .indigo
        case .nature: return .green
        case .bedtime: return .indigo.opacity(0.8)
        case .humor: return .orange
        case .rhyming: return .purple
        case .emotions: return .red
        case .diversity: return .teal
        case .science: return .mint
        case .fantasy: return .purple
        }
    }
}

// MARK: - Picture Books Library
struct PictureBooksLibrary {
    static let allBooks: [PictureBook] = [
        // Dr. Seuss Collection (10 books)
        PictureBook(id: "seuss1", title: "The Cat in the Hat", author: "Dr. Seuss", illustrator: "Dr. Seuss", category: .classic, ageRange: "4-8", pages: 10, description: "A tall cat in a red and white hat visits two children on a rainy day, bringing chaos and fun.", coverEmoji: "🎩", coverColor: .red, readingLevel: .firstGrade),
        PictureBook(id: "seuss2", title: "Green Eggs and Ham", author: "Dr. Seuss", illustrator: "Dr. Seuss", category: .rhyming, ageRange: "3-7", pages: 10, description: "Sam-I-Am tries to convince a grumpy character to try green eggs and ham.", coverEmoji: "🍳", coverColor: .green, readingLevel: .kindergarten),
        PictureBook(id: "seuss3", title: "One Fish Two Fish Red Fish Blue Fish", author: "Dr. Seuss", illustrator: "Dr. Seuss", category: .rhyming, ageRange: "3-6", pages: 10, description: "A whimsical exploration of rhyming, counting, and colorful fish.", coverEmoji: "🐠", coverColor: .blue, readingLevel: .preschool),
        PictureBook(id: "seuss4", title: "The Lorax", author: "Dr. Seuss", illustrator: "Dr. Seuss", category: .nature, ageRange: "5-9", pages: 12, description: "The Lorax speaks for the trees in this environmental tale.", coverEmoji: "🌳", coverColor: .orange, readingLevel: .secondGrade),
        PictureBook(id: "seuss5", title: "Horton Hears a Who!", author: "Dr. Seuss", illustrator: "Dr. Seuss", category: .classic, ageRange: "4-8", pages: 10, description: "An elephant discovers a tiny world on a speck of dust.", coverEmoji: "🐘", coverColor: .purple, readingLevel: .firstGrade),
        PictureBook(id: "seuss6", title: "Oh, the Places You'll Go!", author: "Dr. Seuss", illustrator: "Dr. Seuss", category: .adventure, ageRange: "4-99", pages: 12, description: "An inspiring journey about life's adventures and challenges.", coverEmoji: "🎈", coverColor: .yellow, readingLevel: .secondGrade),
        PictureBook(id: "seuss7", title: "How the Grinch Stole Christmas", author: "Dr. Seuss", illustrator: "Dr. Seuss", category: .classic, ageRange: "4-8", pages: 12, description: "A grumpy green creature learns the true meaning of Christmas.", coverEmoji: "🎄", coverColor: .green, readingLevel: .firstGrade),
        PictureBook(id: "seuss8", title: "Hop on Pop", author: "Dr. Seuss", illustrator: "Dr. Seuss", category: .rhyming, ageRange: "2-5", pages: 8, description: "Simple rhyming words make this perfect for beginning readers.", coverEmoji: "🦘", coverColor: .blue, readingLevel: .preschool),
        PictureBook(id: "seuss9", title: "Fox in Socks", author: "Dr. Seuss", illustrator: "Dr. Seuss", category: .rhyming, ageRange: "4-8", pages: 10, description: "A tongue-twisting adventure with Fox and Knox.", coverEmoji: "🦊", coverColor: .red, readingLevel: .kindergarten),
        PictureBook(id: "seuss10", title: "There's a Wocket in My Pocket", author: "Dr. Seuss", illustrator: "Dr. Seuss", category: .humor, ageRange: "3-7", pages: 10, description: "Silly creatures hide all around the house!", coverEmoji: "🏠", coverColor: .pink, readingLevel: .kindergarten),
        
        // Pete the Cat Series (10 books)
        PictureBook(id: "pete1", title: "Pete the Cat: I Love My White Shoes", author: "James Dean", illustrator: "James Dean", category: .classic, ageRange: "3-7", pages: 10, description: "Pete steps in different colored berries but stays groovy.", coverEmoji: "👟", coverColor: .blue, readingLevel: .preschool),
        PictureBook(id: "pete2", title: "Pete the Cat: Rocking in My School Shoes", author: "James Dean", illustrator: "James Dean", category: .classic, ageRange: "3-7", pages: 10, description: "Pete's first day of school is totally groovy.", coverEmoji: "🎸", coverColor: .blue, readingLevel: .preschool),
        PictureBook(id: "pete3", title: "Pete the Cat and His Four Groovy Buttons", author: "James Dean", illustrator: "James Dean", category: .counting, ageRange: "3-6", pages: 10, description: "Pete counts down as his buttons pop off one by one.", coverEmoji: "🔘", coverColor: .yellow, readingLevel: .preschool),
        PictureBook(id: "pete4", title: "Pete the Cat Saves Christmas", author: "James Dean", illustrator: "James Dean", category: .classic, ageRange: "3-7", pages: 12, description: "Pete helps Santa deliver presents on Christmas Eve.", coverEmoji: "🎅", coverColor: .red, readingLevel: .kindergarten),
        PictureBook(id: "pete5", title: "Pete the Cat: The Wheels on the Bus", author: "James Dean", illustrator: "James Dean", category: .rhyming, ageRange: "2-5", pages: 10, description: "Pete sings along to this classic song.", coverEmoji: "🚌", coverColor: .yellow, readingLevel: .preschool),
        PictureBook(id: "pete6", title: "Pete the Cat: Five Little Pumpkins", author: "James Dean", illustrator: "James Dean", category: .counting, ageRange: "3-6", pages: 10, description: "Pete counts pumpkins on Halloween night.", coverEmoji: "🎃", coverColor: .orange, readingLevel: .preschool),
        PictureBook(id: "pete7", title: "Pete the Cat: Construction Destruction", author: "James Dean", illustrator: "James Dean", category: .adventure, ageRange: "3-7", pages: 10, description: "Pete drives construction vehicles to help build.", coverEmoji: "🚜", coverColor: .yellow, readingLevel: .kindergarten),
        PictureBook(id: "pete8", title: "Pete the Cat: A Pet for Pete", author: "James Dean", illustrator: "James Dean", category: .animals, ageRange: "3-7", pages: 10, description: "Pete adopts a pet goldfish and learns responsibility.", coverEmoji: "🐟", coverColor: .blue, readingLevel: .preschool),
        PictureBook(id: "pete9", title: "Pete the Cat: Firefighter Pete", author: "James Dean", illustrator: "James Dean", category: .adventure, ageRange: "3-7", pages: 10, description: "Pete becomes a firefighter for the day.", coverEmoji: "🚒", coverColor: .red, readingLevel: .kindergarten),
        PictureBook(id: "pete10", title: "Pete the Cat: Robo-Pete", author: "James Dean", illustrator: "James Dean", category: .science, ageRange: "4-8", pages: 10, description: "Pete builds a robot version of himself.", coverEmoji: "🤖", coverColor: Color(red: 0.4, green: 0.6, blue: 0.85), readingLevel: .firstGrade),
        
        // Eric Carle Collection (10 books)
        PictureBook(id: "carle1", title: "The Very Hungry Caterpillar", author: "Eric Carle", illustrator: "Eric Carle", category: .classic, ageRange: "2-5", pages: 10, description: "A caterpillar eats through different foods before becoming a butterfly.", coverEmoji: "🐛", coverColor: .green, readingLevel: .preschool),
        PictureBook(id: "carle2", title: "Brown Bear, Brown Bear, What Do You See?", author: "Bill Martin Jr.", illustrator: "Eric Carle", category: .animals, ageRange: "1-4", pages: 10, description: "Animals ask each other what they see in vivid colors.", coverEmoji: "🐻", coverColor: Color(red: 0.75, green: 0.5, blue: 0.25), readingLevel: .preschool),
        PictureBook(id: "carle3", title: "The Very Busy Spider", author: "Eric Carle", illustrator: "Eric Carle", category: .animals, ageRange: "2-5", pages: 10, description: "A spider spins her web despite distractions.", coverEmoji: "🕷️", coverColor: .purple, readingLevel: .preschool),
        PictureBook(id: "carle4", title: "The Very Quiet Cricket", author: "Eric Carle", illustrator: "Eric Carle", category: .animals, ageRange: "2-5", pages: 10, description: "A cricket learns to make beautiful sounds.", coverEmoji: "🦗", coverColor: .green, readingLevel: .preschool),
        PictureBook(id: "carle5", title: "The Grouchy Ladybug", author: "Eric Carle", illustrator: "Eric Carle", category: .emotions, ageRange: "3-7", pages: 12, description: "A grouchy ladybug learns about manners and sharing.", coverEmoji: "🐞", coverColor: .red, readingLevel: .kindergarten),
        PictureBook(id: "carle6", title: "Polar Bear, Polar Bear, What Do You Hear?", author: "Bill Martin Jr.", illustrator: "Eric Carle", category: .animals, ageRange: "1-4", pages: 10, description: "Zoo animals hear different sounds all around.", coverEmoji: "🐻‍❄️", coverColor: Color(red: 0.45, green: 0.7, blue: 0.9), readingLevel: .preschool),
        PictureBook(id: "carle7", title: "The Very Lonely Firefly", author: "Eric Carle", illustrator: "Eric Carle", category: .animals, ageRange: "2-5", pages: 10, description: "A firefly searches for friends who light up like him.", coverEmoji: "✨", coverColor: .yellow, readingLevel: .preschool),
        PictureBook(id: "carle8", title: "Papa, Please Get the Moon for Me", author: "Eric Carle", illustrator: "Eric Carle", category: .family, ageRange: "3-6", pages: 10, description: "Monica wants the moon, and Papa finds a way.", coverEmoji: "🌙", coverColor: Color(red: 0.4, green: 0.35, blue: 0.85), readingLevel: .preschool),
        PictureBook(id: "carle9", title: "10 Little Rubber Ducks", author: "Eric Carle", illustrator: "Eric Carle", category: .counting, ageRange: "2-5", pages: 10, description: "Ten rubber ducks float to different adventures.", coverEmoji: "🦆", coverColor: .yellow, readingLevel: .preschool),
        PictureBook(id: "carle10", title: "The Mixed-Up Chameleon", author: "Eric Carle", illustrator: "Eric Carle", category: .animals, ageRange: "3-7", pages: 10, description: "A chameleon wishes to be like other animals.", coverEmoji: "🦎", coverColor: .green, readingLevel: .kindergarten),
        
        // Mo Willems Collection (10 books)
        PictureBook(id: "mo1", title: "Don't Let the Pigeon Drive the Bus!", author: "Mo Willems", illustrator: "Mo Willems", category: .humor, ageRange: "3-7", pages: 10, description: "The pigeon really, really wants to drive the bus.", coverEmoji: "🐦", coverColor: .blue, readingLevel: .preschool),
        PictureBook(id: "mo2", title: "Knuffle Bunny", author: "Mo Willems", illustrator: "Mo Willems", category: .family, ageRange: "2-5", pages: 10, description: "Trixie loses her beloved bunny at the laundromat.", coverEmoji: "🐰", coverColor: .pink, readingLevel: .preschool),
        PictureBook(id: "mo3", title: "Elephant and Piggie: Today I Will Fly!", author: "Mo Willems", illustrator: "Mo Willems", category: .friendship, ageRange: "4-8", pages: 10, description: "Piggie wants to fly, and Gerald is worried.", coverEmoji: "🐷", coverColor: .pink, readingLevel: .kindergarten),
        PictureBook(id: "mo4", title: "The Pigeon Finds a Hot Dog!", author: "Mo Willems", illustrator: "Mo Willems", category: .humor, ageRange: "3-7", pages: 10, description: "Pigeon must decide whether to share his hot dog.", coverEmoji: "🌭", coverColor: .yellow, readingLevel: .preschool),
        PictureBook(id: "mo5", title: "Leonardo the Terrible Monster", author: "Mo Willems", illustrator: "Mo Willems", category: .emotions, ageRange: "4-8", pages: 10, description: "Leonardo tries to be scary but learns about friendship.", coverEmoji: "👹", coverColor: .purple, readingLevel: .kindergarten),
        PictureBook(id: "mo6", title: "The Duckling Gets a Cookie!?", author: "Mo Willems", illustrator: "Mo Willems", category: .humor, ageRange: "3-7", pages: 10, description: "Pigeon is jealous when duckling gets a cookie.", coverEmoji: "🍪", coverColor: .orange, readingLevel: .preschool),
        PictureBook(id: "mo7", title: "Elephant and Piggie: I Broke My Trunk!", author: "Mo Willems", illustrator: "Mo Willems", category: .friendship, ageRange: "4-8", pages: 10, description: "Gerald tells the story of his broken trunk.", coverEmoji: "🐘", coverColor: Color(red: 0.5, green: 0.65, blue: 0.85), readingLevel: .kindergarten),
        PictureBook(id: "mo8", title: "Naked Mole Rat Gets Dressed", author: "Mo Willems", illustrator: "Mo Willems", category: .humor, ageRange: "4-8", pages: 10, description: "Wilbur loves wearing clothes even though mole rats don't.", coverEmoji: "👔", coverColor: Color(red: 0.85, green: 0.55, blue: 0.3), readingLevel: .kindergarten),
        PictureBook(id: "mo9", title: "Elephant and Piggie: We Are in a Book!", author: "Mo Willems", illustrator: "Mo Willems", category: .humor, ageRange: "4-8", pages: 10, description: "Gerald and Piggie realize they're characters in a book.", coverEmoji: "📚", coverColor: .blue, readingLevel: .firstGrade),
        PictureBook(id: "mo10", title: "Don't Let the Pigeon Stay Up Late!", author: "Mo Willems", illustrator: "Mo Willems", category: .bedtime, ageRange: "3-7", pages: 10, description: "Pigeon uses every excuse to avoid bedtime.", coverEmoji: "😴", coverColor: Color(red: 0.4, green: 0.4, blue: 0.85), readingLevel: .preschool),
        
        // Caldecott Winners & Classics (20 books)
        PictureBook(id: "classic1", title: "Goodnight Moon", author: "Margaret Wise Brown", illustrator: "Clement Hurd", category: .bedtime, ageRange: "1-4", pages: 10, description: "A bunny says goodnight to everything in the great green room.", coverEmoji: "🌙", coverColor: .green, readingLevel: .preschool),
        PictureBook(id: "classic2", title: "Where the Wild Things Are", author: "Maurice Sendak", illustrator: "Maurice Sendak", category: .fantasy, ageRange: "4-8", pages: 10, description: "Max sails to where the wild things are.", coverEmoji: "👑", coverColor: .blue, readingLevel: .kindergarten),
        PictureBook(id: "classic3", title: "The Giving Tree", author: "Shel Silverstein", illustrator: "Shel Silverstein", category: .friendship, ageRange: "4-99", pages: 10, description: "A tree gives everything to a boy throughout his life.", coverEmoji: "🌳", coverColor: .green, readingLevel: .firstGrade),
        PictureBook(id: "classic4", title: "Corduroy", author: "Don Freeman", illustrator: "Don Freeman", category: .friendship, ageRange: "3-7", pages: 10, description: "A teddy bear searches for his missing button.", coverEmoji: "🧸", coverColor: Color(red: 0.8, green: 0.55, blue: 0.3), readingLevel: .preschool),
        PictureBook(id: "classic5", title: "Chicka Chicka Boom Boom", author: "Bill Martin Jr.", illustrator: "Lois Ehlert", category: .alphabet, ageRange: "2-5", pages: 10, description: "Letters race up the coconut tree.", coverEmoji: "🌴", coverColor: .yellow, readingLevel: .preschool),
        PictureBook(id: "classic6", title: "The Rainbow Fish", author: "Marcus Pfister", illustrator: "Marcus Pfister", category: .friendship, ageRange: "3-7", pages: 10, description: "A beautiful fish learns to share his special scales.", coverEmoji: "🐟", coverColor: .cyan, readingLevel: .preschool),
        PictureBook(id: "classic7", title: "Guess How Much I Love You", author: "Sam McBratney", illustrator: "Anita Jeram", category: .family, ageRange: "2-5", pages: 10, description: "Big and Little Nutbrown Hare express their love.", coverEmoji: "🐰", coverColor: Color(red: 0.8, green: 0.55, blue: 0.3), readingLevel: .preschool),
        PictureBook(id: "classic8", title: "If You Give a Mouse a Cookie", author: "Laura Numeroff", illustrator: "Felicia Bond", category: .humor, ageRange: "3-7", pages: 10, description: "A mouse leads a boy on a wild adventure.", coverEmoji: "🐭", coverColor: Color(red: 0.85, green: 0.55, blue: 0.3), readingLevel: .preschool),
        PictureBook(id: "classic9", title: "The Snowy Day", author: "Ezra Jack Keats", illustrator: "Ezra Jack Keats", category: .classic, ageRange: "3-7", pages: 10, description: "Peter explores his neighborhood after a snowfall.", coverEmoji: "❄️", coverColor: .blue, readingLevel: .preschool),
        PictureBook(id: "classic10", title: "Harold and the Purple Crayon", author: "Crockett Johnson", illustrator: "Crockett Johnson", category: .fantasy, ageRange: "4-8", pages: 10, description: "Harold draws his way through an adventure.", coverEmoji: "🖍️", coverColor: .purple, readingLevel: .kindergarten),
        PictureBook(id: "classic11", title: "Madeline", author: "Ludwig Bemelmans", illustrator: "Ludwig Bemelmans", category: .adventure, ageRange: "4-8", pages: 12, description: "The smallest girl in a Paris boarding school has an adventure.", coverEmoji: "🗼", coverColor: .yellow, readingLevel: .firstGrade),
        PictureBook(id: "classic12", title: "Curious George", author: "H.A. Rey", illustrator: "H.A. Rey", category: .adventure, ageRange: "3-7", pages: 10, description: "A curious monkey gets into all kinds of trouble.", coverEmoji: "🐵", coverColor: .yellow, readingLevel: .preschool),
        PictureBook(id: "classic13", title: "The Polar Express", author: "Chris Van Allsburg", illustrator: "Chris Van Allsburg", category: .fantasy, ageRange: "4-8", pages: 12, description: "A magical train ride to the North Pole on Christmas Eve.", coverEmoji: "🚂", coverColor: .blue, readingLevel: .firstGrade),
        PictureBook(id: "classic14", title: "Alexander and the Terrible, Horrible, No Good, Very Bad Day", author: "Judith Viorst", illustrator: "Ray Cruz", category: .emotions, ageRange: "4-8", pages: 12, description: "Alexander has the worst day ever.", coverEmoji: "😤", coverColor: .red, readingLevel: .firstGrade),
        PictureBook(id: "classic15", title: "The Little Engine That Could", author: "Watty Piper", illustrator: "George Hauman", category: .classic, ageRange: "3-7", pages: 10, description: "A little engine proves that attitude matters.", coverEmoji: "🚂", coverColor: .blue, readingLevel: .preschool),
        PictureBook(id: "classic16", title: "Mike Mulligan and His Steam Shovel", author: "Virginia Lee Burton", illustrator: "Virginia Lee Burton", category: .classic, ageRange: "4-8", pages: 12, description: "Mike and Mary Anne dig their way to a new home.", coverEmoji: "🏗️", coverColor: .red, readingLevel: .firstGrade),
        PictureBook(id: "classic17", title: "Make Way for Ducklings", author: "Robert McCloskey", illustrator: "Robert McCloskey", category: .animals, ageRange: "3-7", pages: 12, description: "Mrs. Mallard leads her ducklings through Boston.", coverEmoji: "🦆", coverColor: Color(red: 0.85, green: 0.6, blue: 0.3), readingLevel: .kindergarten),
        PictureBook(id: "classic18", title: "Strega Nona", author: "Tomie dePaola", illustrator: "Tomie dePaola", category: .fantasy, ageRange: "4-8", pages: 10, description: "Big Anthony causes trouble with Strega Nona's magic pot.", coverEmoji: "🍝", coverColor: .red, readingLevel: .firstGrade),
        PictureBook(id: "classic19", title: "Sylvester and the Magic Pebble", author: "William Steig", illustrator: "William Steig", category: .fantasy, ageRange: "4-8", pages: 12, description: "A donkey makes a wish that has unexpected consequences.", coverEmoji: "💎", coverColor: .red, readingLevel: .firstGrade),
        PictureBook(id: "classic20", title: "The True Story of the 3 Little Pigs", author: "Jon Scieszka", illustrator: "Lane Smith", category: .humor, ageRange: "5-9", pages: 10, description: "The wolf tells his side of the famous story.", coverEmoji: "🐺", coverColor: Color(red: 0.5, green: 0.65, blue: 0.8), readingLevel: .secondGrade),
        
        // Diverse & Cultural Books (15 books)
        PictureBook(id: "div1", title: "Last Stop on Market Street", author: "Matt de la Peña", illustrator: "Christian Robinson", category: .diversity, ageRange: "4-8", pages: 12, description: "CJ and his grandma find beauty in their community.", coverEmoji: "🚌", coverColor: .purple, readingLevel: .firstGrade),
        PictureBook(id: "div2", title: "The Name Jar", author: "Yangsook Choi", illustrator: "Yangsook Choi", category: .diversity, ageRange: "5-9", pages: 12, description: "Unhei moves from Korea and considers changing her name.", coverEmoji: "🏺", coverColor: .blue, readingLevel: .secondGrade),
        PictureBook(id: "div3", title: "Alma and How She Got Her Name", author: "Juana Martinez-Neal", illustrator: "Juana Martinez-Neal", category: .diversity, ageRange: "4-8", pages: 10, description: "Alma learns the stories behind her many names.", coverEmoji: "🌸", coverColor: .pink, readingLevel: .firstGrade),
        PictureBook(id: "div4", title: "Hair Love", author: "Matthew A. Cherry", illustrator: "Vashti Harrison", category: .family, ageRange: "4-8", pages: 10, description: "A father learns to do his daughter's hair.", coverEmoji: "💇", coverColor: .purple, readingLevel: .kindergarten),
        PictureBook(id: "div5", title: "The Proudest Blue", author: "Ibtihaj Muhammad", illustrator: "Hatem Aly", category: .diversity, ageRange: "4-8", pages: 10, description: "Faizah's sister wears her first hijab on the first day of school.", coverEmoji: "🧕", coverColor: .blue, readingLevel: .firstGrade),
        PictureBook(id: "div6", title: "Sulwe", author: "Lupita Nyong'o", illustrator: "Vashti Harrison", category: .emotions, ageRange: "4-8", pages: 10, description: "Sulwe learns to love the skin she's in.", coverEmoji: "✨", coverColor: Color(red: 0.45, green: 0.4, blue: 0.85), readingLevel: .firstGrade),
        PictureBook(id: "div7", title: "Thank You, Omu!", author: "Oge Mora", illustrator: "Oge Mora", category: .diversity, ageRange: "4-8", pages: 10, description: "Omu shares her delicious stew with her community.", coverEmoji: "🍲", coverColor: .orange, readingLevel: .kindergarten),
        PictureBook(id: "div8", title: "Dreamers", author: "Yuyi Morales", illustrator: "Yuyi Morales", category: .diversity, ageRange: "4-8", pages: 10, description: "A mother and child's immigration journey to America.", coverEmoji: "🦋", coverColor: .teal, readingLevel: .firstGrade),
        PictureBook(id: "div9", title: "The Year of the Dog", author: "Grace Lin", illustrator: "Grace Lin", category: .diversity, ageRange: "6-10", pages: 12, description: "Pacy celebrates the Chinese Year of the Dog.", coverEmoji: "🐕", coverColor: .red, readingLevel: .thirdGrade),
        PictureBook(id: "div10", title: "Grandfather's Journey", author: "Allen Say", illustrator: "Allen Say", category: .diversity, ageRange: "5-9", pages: 12, description: "A Japanese American reflects on his grandfather's life.", coverEmoji: "🗾", coverColor: .blue, readingLevel: .secondGrade),
        PictureBook(id: "div11", title: "Each Kindness", author: "Jacqueline Woodson", illustrator: "E.B. Lewis", category: .emotions, ageRange: "5-9", pages: 10, description: "Chloe learns a lesson about kindness and regret.", coverEmoji: "💧", coverColor: .blue, readingLevel: .secondGrade),
        PictureBook(id: "div12", title: "Eyes That Kiss in the Corners", author: "Joanna Ho", illustrator: "Dung Ho", category: .diversity, ageRange: "4-8", pages: 10, description: "A girl celebrates her Asian heritage and her eyes.", coverEmoji: "👀", coverColor: .gold, readingLevel: .kindergarten),
        PictureBook(id: "div13", title: "The Colors of Us", author: "Karen Katz", illustrator: "Karen Katz", category: .diversity, ageRange: "3-7", pages: 10, description: "Lena discovers the beautiful range of skin colors.", coverEmoji: "🎨", coverColor: Color(red: 0.9, green: 0.6, blue: 0.35), readingLevel: .preschool),
        PictureBook(id: "div14", title: "Islandborn", author: "Junot Díaz", illustrator: "Leo Espinosa", category: .diversity, ageRange: "5-9", pages: 12, description: "Lola explores her family's history on their island home.", coverEmoji: "🏝️", coverColor: .teal, readingLevel: .secondGrade),
        PictureBook(id: "div15", title: "My Two Grannies", author: "Floella Benjamin", illustrator: "Margaret Chamberlain", category: .family, ageRange: "4-8", pages: 10, description: "A girl loves her two very different grandmothers.", coverEmoji: "👵", coverColor: .pink, readingLevel: .kindergarten),
        
        // STEM & Nature Books (15 books)
        PictureBook(id: "stem1", title: "Rosie Revere, Engineer", author: "Andrea Beaty", illustrator: "David Roberts", category: .science, ageRange: "5-9", pages: 10, description: "Rosie learns that failure is a step toward success.", coverEmoji: "👷‍♀️", coverColor: .red, readingLevel: .firstGrade),
        PictureBook(id: "stem2", title: "Ada Twist, Scientist", author: "Andrea Beaty", illustrator: "David Roberts", category: .science, ageRange: "5-9", pages: 10, description: "Ada asks questions and experiments to find answers.", coverEmoji: "🔬", coverColor: .purple, readingLevel: .firstGrade),
        PictureBook(id: "stem3", title: "Iggy Peck, Architect", author: "Andrea Beaty", illustrator: "David Roberts", category: .science, ageRange: "5-9", pages: 10, description: "Iggy builds amazing structures from anything.", coverEmoji: "🏛️", coverColor: .blue, readingLevel: .firstGrade),
        PictureBook(id: "stem4", title: "The Magic School Bus Inside the Human Body", author: "Joanna Cole", illustrator: "Bruce Degen", category: .science, ageRange: "5-9", pages: 12, description: "Ms. Frizzle takes her class inside a human body.", coverEmoji: "🚌", coverColor: .yellow, readingLevel: .secondGrade),
        PictureBook(id: "stem5", title: "A Seed Is Sleepy", author: "Dianna Aston", illustrator: "Sylvia Long", category: .nature, ageRange: "4-8", pages: 10, description: "Explore the life cycle and diversity of seeds.", coverEmoji: "🌱", coverColor: .green, readingLevel: .kindergarten),
        PictureBook(id: "stem6", title: "What Do You Do With an Idea?", author: "Kobi Yamada", illustrator: "Mae Besom", category: .emotions, ageRange: "4-8", pages: 10, description: "A child learns to nurture and share their idea.", coverEmoji: "💡", coverColor: .gold, readingLevel: .kindergarten),
        PictureBook(id: "stem7", title: "Over and Under the Pond", author: "Kate Messner", illustrator: "Christopher Silas Neal", category: .nature, ageRange: "4-8", pages: 10, description: "Explore life above and below the pond.", coverEmoji: "🐸", coverColor: .green, readingLevel: .kindergarten),
        PictureBook(id: "stem8", title: "Me...Jane", author: "Patrick McDonnell", illustrator: "Patrick McDonnell", category: .science, ageRange: "4-8", pages: 10, description: "Young Jane Goodall dreams of studying animals.", coverEmoji: "🦍", coverColor: .green, readingLevel: .firstGrade),
        PictureBook(id: "stem9", title: "The Boy Who Harnessed the Wind", author: "William Kamkwamba", illustrator: "Elizabeth Zunon", category: .science, ageRange: "5-9", pages: 12, description: "A boy builds a windmill to help his village.", coverEmoji: "🌬️", coverColor: .blue, readingLevel: .secondGrade),
        PictureBook(id: "stem10", title: "If You Plant a Seed", author: "Kadir Nelson", illustrator: "Kadir Nelson", category: .nature, ageRange: "3-7", pages: 10, description: "Learn about cause and effect through planting.", coverEmoji: "🌻", coverColor: .yellow, readingLevel: .preschool),
        PictureBook(id: "stem11", title: "On a Beam of Light", author: "Jennifer Berne", illustrator: "Vladimir Radunsky", category: .science, ageRange: "5-9", pages: 12, description: "The story of Albert Einstein as a curious child.", coverEmoji: "⚡", coverColor: .yellow, readingLevel: .secondGrade),
        PictureBook(id: "stem12", title: "The Watermelon Seed", author: "Greg Pizzoli", illustrator: "Greg Pizzoli", category: .humor, ageRange: "3-7", pages: 10, description: "A crocodile worries about swallowing a seed.", coverEmoji: "🍉", coverColor: .green, readingLevel: .preschool),
        PictureBook(id: "stem13", title: "Starfish", author: "Lisa Fipps", illustrator: "Lisa Fipps", category: .nature, ageRange: "4-8", pages: 10, description: "Learn about the amazing starfish.", coverEmoji: "⭐", coverColor: .orange, readingLevel: .kindergarten),
        PictureBook(id: "stem14", title: "A Rock Is Lively", author: "Dianna Aston", illustrator: "Sylvia Long", category: .nature, ageRange: "4-8", pages: 10, description: "Discover the wonders of rocks and geology.", coverEmoji: "🪨", coverColor: Color(red: 0.55, green: 0.7, blue: 0.85), readingLevel: .firstGrade),
        PictureBook(id: "stem15", title: "Sofia Valdez, Future Prez", author: "Andrea Beaty", illustrator: "David Roberts", category: .adventure, ageRange: "5-9", pages: 10, description: "Sofia fights to turn a landfill into a park.", coverEmoji: "🗳️", coverColor: .purple, readingLevel: .firstGrade),
        
        // Feelings & Social-Emotional (10 books)
        PictureBook(id: "feel1", title: "The Color Monster", author: "Anna Llenas", illustrator: "Anna Llenas", category: .emotions, ageRange: "3-7", pages: 10, description: "A monster learns to sort and understand his emotions.", coverEmoji: "👾", coverColor: .colorful, readingLevel: .preschool),
        PictureBook(id: "feel2", title: "In My Heart: A Book of Feelings", author: "Jo Witek", illustrator: "Christine Roussey", category: .emotions, ageRange: "3-6", pages: 10, description: "Explore different emotions in your heart.", coverEmoji: "❤️", coverColor: .red, readingLevel: .preschool),
        PictureBook(id: "feel3", title: "The Invisible String", author: "Patrice Karst", illustrator: "Geoff Stevenson", category: .family, ageRange: "4-8", pages: 10, description: "An invisible string connects us to those we love.", coverEmoji: "🧵", coverColor: .red, readingLevel: .kindergarten),
        PictureBook(id: "feel4", title: "Llama Llama Red Pajama", author: "Anna Dewdney", illustrator: "Anna Dewdney", category: .bedtime, ageRange: "2-5", pages: 10, description: "Little Llama misses Mama at bedtime.", coverEmoji: "🦙", coverColor: .red, readingLevel: .preschool),
        PictureBook(id: "feel5", title: "When Sophie Gets Angry", author: "Molly Bang", illustrator: "Molly Bang", category: .emotions, ageRange: "4-8", pages: 10, description: "Sophie learns to calm down when she's angry.", coverEmoji: "😠", coverColor: .red, readingLevel: .kindergarten),
        PictureBook(id: "feel6", title: "The Feelings Book", author: "Todd Parr", illustrator: "Todd Parr", category: .emotions, ageRange: "2-5", pages: 10, description: "All kinds of feelings are okay.", coverEmoji: "😊", coverColor: .yellow, readingLevel: .preschool),
        PictureBook(id: "feel7", title: "Have You Filled a Bucket Today?", author: "Carol McCloud", illustrator: "David Messing", category: .emotions, ageRange: "4-8", pages: 10, description: "Everyone has an invisible bucket of happiness.", coverEmoji: "🪣", coverColor: .yellow, readingLevel: .kindergarten),
        PictureBook(id: "feel8", title: "Wemberly Worried", author: "Kevin Henkes", illustrator: "Kevin Henkes", category: .emotions, ageRange: "4-8", pages: 10, description: "Wemberly worries about everything until she makes a friend.", coverEmoji: "🐭", coverColor: .pink, readingLevel: .kindergarten),
        PictureBook(id: "feel9", title: "Enemy Pie", author: "Derek Munson", illustrator: "Tara Calahan King", category: .friendship, ageRange: "5-9", pages: 10, description: "Dad has a recipe to get rid of enemies.", coverEmoji: "🥧", coverColor: .orange, readingLevel: .firstGrade),
        PictureBook(id: "feel10", title: "Ruby's Worry", author: "Tom Percival", illustrator: "Tom Percival", category: .emotions, ageRange: "4-8", pages: 10, description: "Ruby's worry grows until she shares it.", coverEmoji: "☁️", coverColor: .yellow, readingLevel: .kindergarten)
    ]
    
    // MARK: - Get Books by Category
    static func books(for category: PictureBookCategory) -> [PictureBook] {
        allBooks.filter { $0.category == category }
    }
    
    // MARK: - Get Books by Reading Level
    static func books(for level: PictureBook.ReadingLevel) -> [PictureBook] {
        allBooks.filter { $0.readingLevel == level }
    }
    
    // MARK: - Search Books
    static func search(_ query: String) -> [PictureBook] {
        guard !query.isEmpty else { return allBooks }
        let lowercased = query.lowercased()
        return allBooks.filter {
            $0.title.lowercased().contains(lowercased) ||
            $0.author.lowercased().contains(lowercased) ||
            $0.description.lowercased().contains(lowercased)
        }
    }
    
    // MARK: - Get Featured Books
    static var featured: [PictureBook] {
        Array(allBooks.shuffled().prefix(8))
    }
    
    // MARK: - Get Books by Author
    static func books(by author: String) -> [PictureBook] {
        allBooks.filter { $0.author.lowercased().contains(author.lowercased()) }
    }
}

// MARK: - Color Extension for Book Covers
extension Color {
    static var colorful: Color {
        Color(red: 0.9, green: 0.3, blue: 0.5)
    }
    
    static var gold: Color {
        Color(red: 1.0, green: 0.84, blue: 0.0)
    }
}

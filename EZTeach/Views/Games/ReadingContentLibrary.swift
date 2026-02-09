//
//  ReadingContentLibrary.swift
//  EZTeach
//
//  Picture books, chapter books, short stories. Fiction, nonfiction, sci-fi, history, mystery, adventure, fantasy, poetry, biography.
//  Enhanced with game-correlated picture books featuring rhymes and educational content.
//

import Foundation

struct ReadingContentLibrary {
    static let all: [ReadingItem] = {
        var items: [ReadingItem] = []
        
        // MARK: - GAME-CORRELATED PICTURE BOOKS (6-12 pages, one rhyme per page)
        
        // MATH PICTURE BOOK - "Counting to the Moon"
        items += [
            ReadingItem(id: "gpb_math_1", title: "Counting to the Moon", author: "EZ Learning Books", genre: .nonfiction, level: 1, summary: "A rhyming journey through numbers 1-10 with magical illustrations.", fullText: "", bookType: .pictureBook, chapters: [
                "One little rocket, shiny and new,\nReady to fly into skies so blue.",
                "Two bright stars that twinkle at night,\nGuiding our rocket with silver light.",
                "Three fluffy clouds float softly by,\nWaving hello as we zoom through the sky.",
                "Four spinning planets in a row,\nRed, blue, green—watch them glow!",
                "Five little moons, round and bright,\nDancing together in the night.",
                "Six shooting stars streak across space,\nLeaving sparkles in their trace.",
                "Seven asteroids tumble and spin,\nOur rocket zooms past with a grin.",
                "Eight baby comets with tails so long,\nSinging a twinkly comet song.",
                "Nine galaxies swirl like colorful art,\nEach one beautiful, each one smart.",
                "Ten, we land! Our journey is done,\nCounting to the moon was so much fun!"
            ], coverSymbol: "moon.stars.fill"),
            
            // MATH PICTURE BOOK - "Shapes All Around"
            ReadingItem(id: "gpb_math_2", title: "Shapes All Around", author: "EZ Learning Books", genre: .nonfiction, level: 1, summary: "Discover shapes in everyday objects through playful rhymes.", fullText: "", bookType: .pictureBook, chapters: [
                "Circle, circle, round and round,\nLike a pizza, like a sound!",
                "Square has corners, one two three four,\nLike a window, like a door!",
                "Triangle points up to the sky,\nLike a mountain way up high!",
                "Rectangle long, rectangle tall,\nLike a book upon the wall!",
                "Oval shaped just like an egg,\nOr a face on a tiny leg!",
                "Diamond sparkles, diamond gleams,\nLike a kite in your dreams!",
                "Star has points that shine so bright,\nLighting up the darkest night!",
                "Heart means love, heart means care,\nShapes are magic everywhere!"
            ], coverSymbol: "square.on.circle"),
            
            // SCIENCE PICTURE BOOK - "The Water Cycle Song"
            ReadingItem(id: "gpb_science_1", title: "The Water Cycle Song", author: "EZ Learning Books", genre: .nonfiction, level: 1, summary: "Follow a water droplet's amazing journey through evaporation, condensation, and precipitation.", fullText: "", bookType: .pictureBook, chapters: [
                "I'm a little water drop, splash splash splash,\nLiving in the ocean with a great big splash!",
                "The sun shines warm upon my face,\nI float up high to outer space!",
                "Evaporation is my name,\nRising up is my favorite game!",
                "High up in the sky so blue,\nI meet my friends—water drops too!",
                "We gather close, we stick together,\nMaking clouds for any weather!",
                "Condensation, that's the word,\nThe fluffiest clouds you've ever heard!",
                "The clouds get heavy, dark, and gray,\nTime to fall—hooray, hooray!",
                "Precipitation, down I go,\nAs rain or sleet or fluffy snow!",
                "I land in rivers, lakes, and seas,\nI water flowers, grass, and trees!",
                "And then the sun comes out once more,\nThe cycle starts—I start to soar!"
            ], coverSymbol: "drop.fill"),
            
            // SCIENCE PICTURE BOOK - "Planets in a Row"
            ReadingItem(id: "gpb_science_2", title: "Planets in a Row", author: "EZ Learning Books", genre: .nonfiction, level: 1, summary: "Meet all the planets in our solar system through catchy rhymes.", fullText: "", bookType: .pictureBook, chapters: [
                "The Sun is bright, the Sun is hot,\nIt's the biggest star we've got!",
                "Mercury is small and fast,\nZooming by, it's never last!",
                "Venus glows like morning light,\nThe brightest planet in the night!",
                "Earth is home, so blue and green,\nThe prettiest planet ever seen!",
                "Mars is red with dusty ground,\nRobots there are looking around!",
                "Jupiter is giant, with storms that swirl,\nThe biggest planet in our world!",
                "Saturn's rings are made of ice,\nSpinning round—oh, how nice!",
                "Uranus tilts upon its side,\nA funny planet, rolling wide!",
                "Neptune's blue and very cold,\nFar away and oh so bold!",
                "Eight planets spinning, what a sight,\nOur solar system shines so bright!"
            ], coverSymbol: "globe.americas.fill"),
            
            // READING PICTURE BOOK - "The ABCs of Me"
            ReadingItem(id: "gpb_reading_1", title: "The ABCs of Me", author: "EZ Learning Books", genre: .fiction, level: 1, summary: "A child celebrates themselves while learning the alphabet.", fullText: "", bookType: .pictureBook, chapters: [
                "A is for Awesome, that's what I am,\nB is for Brave, yes I can!",
                "C is for Curious, I love to learn,\nD is for Dreams that brightly burn!",
                "E is for Energy, I run and play,\nF is for Friends who brighten my day!",
                "G is for Grateful for all that I've got,\nH is for Happy, I smile a lot!",
                "I is for Imagination so free,\nJ is for Joyful, the best I can be!",
                "K is for Kind to everyone I meet,\nL is for Love that makes life sweet!",
                "M is for Magic in all that I do,\nN is for Nice, and helpful too!",
                "O is for Open to trying new things,\nP is for Patient with what each day brings!",
                "Q is for Quiet when I need to rest,\nR is for Ready to do my best!",
                "S is for Smart, I think things through,\nT is for Thankful for me and for you!",
                "U is for Unique, there's no one like me,\nV is for Victory—I'm wild and free!",
                "W is for Wonderful, X marks the spot,\nY is for Yes! Z is for Zany—I'm all that I've got!"
            ], coverSymbol: "textformat.abc"),
            
            // PUZZLE PICTURE BOOK - "The Puzzle Piece"
            ReadingItem(id: "gpb_puzzle_1", title: "The Puzzle Piece", author: "EZ Learning Books", genre: .fiction, level: 1, summary: "A lonely puzzle piece finds where it belongs.", fullText: "", bookType: .pictureBook, chapters: [
                "I'm a little puzzle piece, lost and alone,\nLooking for a place to call my home.",
                "I tried to fit with the sky so blue,\nBut my shape was wrong—it just wouldn't do!",
                "I tried the flowers, red and pink,\nBut I didn't fit there either, I think.",
                "I tried the trees so tall and green,\nThe wrong spot still—if you know what I mean.",
                "I felt so sad, so small, so blue,\nWhere do I belong? I wish I knew!",
                "Then I saw a hole just my size,\nMy heart jumped up—what a surprise!",
                "Click! I fit! I found my place,\nA smile spread across my face!",
                "Now I'm part of something grand,\nA beautiful picture, understand?",
                "Every piece has a special spot,\nYou belong somewhere—yes, you've got!"
            ], coverSymbol: "puzzlepiece.fill"),
            
            // CREATIVE THINKING PICTURE BOOK - "What If?"
            ReadingItem(id: "gpb_creative_1", title: "What If?", author: "EZ Learning Books", genre: .fiction, level: 1, summary: "Imagination runs wild with playful 'what if' questions.", fullText: "", bookType: .pictureBook, chapters: [
                "What if dogs could fly like birds?\nWouldn't that be so absurd!",
                "What if fish could climb up trees?\nSwimming through the autumn leaves!",
                "What if clouds were cotton candy?\nThat would be so sweet and dandy!",
                "What if books could talk to you?\nTelling tales both old and new!",
                "What if shoes could run alone?\nWalking themselves all the way home!",
                "What if flowers sang a song?\nYou could hum and sing along!",
                "What if dreams came true each day?\nWouldn't that be quite okay?",
                "Imagination is the key,\nTo be anything you want to be!"
            ], coverSymbol: "lightbulb.fill"),
            
            // SOCIAL STUDIES PICTURE BOOK - "Around the World We Go"
            ReadingItem(id: "gpb_ss_1", title: "Around the World We Go", author: "EZ Learning Books", genre: .nonfiction, level: 1, summary: "Visit different countries and learn about diverse cultures.", fullText: "", bookType: .pictureBook, chapters: [
                "Pack your bags, we're on our way,\nAround the world we'll travel today!",
                "In Japan we bow and say konnichiwa,\nEat sushi rolls—ooh la la!",
                "In Kenya, lions roar so loud,\nMaasai dancers make us proud!",
                "In Brazil the samba plays,\nColorful carnivals for days!",
                "In France we say bonjour, mon ami,\nThe Eiffel Tower for you and me!",
                "In India, elephants parade,\nSpicy curries, beautifully made!",
                "In Australia, kangaroos hop,\nKoalas sleep and never stop!",
                "In Mexico, we dance and sing,\nTacos, piñatas—everything!",
                "Every place is special, it's true,\nDifferent and wonderful—just like you!"
            ], coverSymbol: "globe.americas.fill"),
            
            // PATTERNS PICTURE BOOK - "Pattern Party"
            ReadingItem(id: "gpb_patterns_1", title: "Pattern Party", author: "EZ Learning Books", genre: .nonfiction, level: 1, summary: "Find patterns everywhere in this colorful rhyming book.", fullText: "", bookType: .pictureBook, chapters: [
                "Red, blue, red, blue—what comes next?\nPatterns are not so complex!",
                "Big, small, big, small—can you see?\nPatterns are as fun as can be!",
                "Sun, moon, sun, moon—day and night,\nPatterns happen, wrong and right!",
                "Clap, stomp, clap, stomp—make some noise!\nPatterns with sounds—oh what joys!",
                "Stripe, dot, stripe, dot—on my shirt,\nPatterns in the grass and dirt!",
                "Triangle, circle, triangle, round,\nPatterns are everywhere to be found!",
                "Hot, cold, hot, cold—feel the change,\nPatterns are never, ever strange!",
                "Look around you, near and far,\nPatterns tell us what things are!"
            ], coverSymbol: "square.stack.3d.up.fill"),
            
            // SPEECH PICTURE BOOK - "Tongue Twister Tales"
            ReadingItem(id: "gpb_speech_1", title: "Tongue Twister Tales", author: "EZ Learning Books", genre: .fiction, level: 2, summary: "Practice speaking with silly tongue twisters.", fullText: "", bookType: .pictureBook, chapters: [
                "Sally sells seashells by the seashore,\nShe sells so many shells, she wants more!",
                "Peter Piper picked a peck of pickled peppers,\nA peck of pickled peppers Peter Piper picked!",
                "Red lorry, yellow lorry, round and round,\nSay it fast without a sound... I mean word!",
                "She sells Swiss sweets, sweet Swiss sweets,\nShe's the sweetest seller on the streets!",
                "How much wood would a woodchuck chuck,\nIf a woodchuck could chuck wood? Good luck!",
                "Fuzzy Wuzzy was a bear, Fuzzy Wuzzy had no hair,\nFuzzy Wuzzy wasn't fuzzy, was he? There!",
                "I scream, you scream, we all scream for ice cream,\nSay it loud, say it proud—what a dream!",
                "Practice makes perfect, that's what they say,\nTongue twisters help you speak better each day!"
            ], coverSymbol: "waveform"),
            
            // SPECIAL NEEDS/CALM PICTURE BOOK - "Breathe with Me"
            ReadingItem(id: "gpb_calm_1", title: "Breathe with Me", author: "EZ Learning Books", genre: .nonfiction, level: 1, summary: "A calming book to help with breathing and relaxation.", fullText: "", bookType: .pictureBook, chapters: [
                "Close your eyes and breathe with me,\nSlow and gentle, one two three.",
                "Breathe in deep, fill up your chest,\nYou are calm, you are blessed.",
                "Now breathe out, let worries go,\nSoft and easy, nice and slow.",
                "Picture waves upon the shore,\nIn and out, forevermore.",
                "Feel your body start to rest,\nYou are safe, you are the best.",
                "Wiggle your toes, relax your hands,\nYou are calm like soft beach sands.",
                "One more breath, so deep and true,\nYou are loved, you are you.",
                "Open your eyes when you feel right,\nEverything is calm and bright."
            ], coverSymbol: "heart.circle.fill"),
            
            // MEMORY PICTURE BOOK - "Remember, Remember"
            ReadingItem(id: "gpb_memory_1", title: "Remember, Remember", author: "EZ Learning Books", genre: .fiction, level: 1, summary: "A memory game in book form with rhyming clues.", fullText: "", bookType: .pictureBook, chapters: [
                "I see a cat, fluffy and white,\nClose your eyes—remember, all right?",
                "Now there's a hat, tall and blue,\nTwo things to remember—can you?",
                "Add a ball, bouncy and red,\nThree things stored inside your head!",
                "Here comes a star, shiny and gold,\nFour things now—you're getting bold!",
                "A little fish swims in a bowl,\nFive things kept inside your soul!",
                "Can you name them, one by one?\nCat, hat, ball, star, fish—you've won!",
                "Memory games help your brain grow,\nThe more you practice, the more you'll know!"
            ], coverSymbol: "brain.head.profile")
        ]
        
        // MARK: - PICTURE BOOKS (One sentence per page with illustrations)
        items += [
            // The Big Yellow Sun - One sentence per page
            ReadingItem(id: "pb1", title: "The Big Yellow Sun", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "A bright day from dawn to dusk.", fullText: "", bookType: .pictureBook, chapters: [
                "The big yellow sun rises over the hills.",
                "Little birds wake up in their cozy nests.",
                "They sing a happy morning song.",
                "Colorful flowers open their petals wide.",
                "Busy bees buzz from flower to flower.",
                "Children run outside to play.",
                "The sun climbs high into the blue sky.",
                "Everything feels warm and wonderful.",
                "Fluffy white clouds drift slowly by.",
                "The sun begins to set, painting the sky orange.",
                "Tiny stars come out to twinkle.",
                "Good night, big yellow sun!"
            ], coverSymbol: "sun.max.fill"),
            
            // Where Is My Hat? - One sentence per page
            ReadingItem(id: "pb2", title: "Where Is My Hat?", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "A silly search for a missing hat.", fullText: "", bookType: .pictureBook, chapters: [
                "Oh no! Where is my favorite red hat?",
                "Is it hiding on my cozy bed?",
                "No, the hat is not on my bed.",
                "Is it under the wooden table?",
                "No, the hat is not under the table.",
                "Is it inside the cardboard box?",
                "No, the hat is not in the box.",
                "Wait! What is that on the dog?",
                "Yes! The dog is wearing my hat!",
                "Silly, funny, happy dog!"
            ], coverSymbol: "tshirt.fill"),
            
            // The Little Blue Truck - One sentence per page
            ReadingItem(id: "pb3", title: "The Little Blue Truck", author: "EZ Picture Books", genre: .fiction, level: 2, summary: "A friendly truck helps a big dump truck.", fullText: "", bookType: .pictureBook, chapters: [
                "Beep beep! The little blue truck goes down the road.",
                "The little truck says hello to the farm animals.",
                "A big yellow dump truck zooms by very fast.",
                "Splash! The dump truck gets stuck in the mud!",
                "The wheels spin but the truck cannot move.",
                "Who will help the stuck dump truck?",
                "The little blue truck stops to help.",
                "All the farm animals come to push.",
                "Push, push, push with all their might!",
                "Pop! Out comes the dump truck from the mud!",
                "Thank you, little truck! Thank you, friends!",
                "Friends always help each other."
            ], coverSymbol: "car.fill"),
            
            // Stars in the Night - One sentence per page
            ReadingItem(id: "pb4", title: "Stars in the Night", author: "EZ Picture Books", genre: .fiction, level: 2, summary: "A child counts stars and finds shapes.", fullText: "", bookType: .pictureBook, chapters: [
                "The night sky is dark and beautiful.",
                "I look up and see one bright star.",
                "Two stars twinkle side by side.",
                "Three stars make a tiny triangle.",
                "Now I see so many stars everywhere!",
                "Look! The stars make a shape like a bear.",
                "Over there, they look like a lion.",
                "And there, I see a fish swimming in the sky!",
                "Grandma says these are called constellations.",
                "I keep counting stars, one by one.",
                "My eyes grow heavy and sleepy.",
                "Good night, beautiful stars."
            ], coverSymbol: "moon.stars.fill"),
            
            // The Rainbow After Rain - One sentence per page
            ReadingItem(id: "pb5", title: "The Rainbow After Rain", author: "EZ Picture Books", genre: .fiction, level: 2, summary: "Colors appear after a storm.", fullText: "", bookType: .pictureBook, chapters: [
                "Dark gray clouds fill the sky.",
                "Drip, drop! The rain begins to fall.",
                "Splash, splash into the puddles below!",
                "The rain keeps falling all around.",
                "Everything looks wet and gray.",
                "Then something magical happens!",
                "The sun peeks out from behind a cloud.",
                "Look! A beautiful rainbow appears!",
                "Red, orange, yellow stretch across the sky.",
                "Green, blue, and purple join them too!",
                "The rainbow arches high and bright.",
                "What a wonderful surprise after the rain!"
            ], coverSymbol: "rainbow"),
            
            // Panda in the Snow - One sentence per page
            ReadingItem(id: "pb6", title: "Panda in the Snow", author: "EZ Picture Books", genre: .nonfiction, level: 1, summary: "A panda plays in winter.", fullText: "", bookType: .pictureBook, chapters: [
                "The fluffy panda is black and white.",
                "It lives high in the cold mountains.",
                "Today, soft snowflakes fall from the sky.",
                "The panda catches snowflakes on its nose.",
                "It rolls down the snowy hill—wheee!",
                "The panda slides on the slippery ice.",
                "Now it is time for a yummy snack.",
                "Munch, munch on green bamboo leaves.",
                "The thick fur keeps the panda warm.",
                "What a happy panda in the snow!"
            ], coverSymbol: "pawprint.fill"),
            
            // The Hungry Caterpillar's Day - One sentence per page
            ReadingItem(id: "pb7", title: "The Hungry Caterpillar's Day", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "A caterpillar eats and becomes a butterfly.", fullText: "", bookType: .pictureBook, chapters: [
                "A tiny caterpillar hatches from an egg.",
                "The caterpillar is very, very hungry!",
                "On Monday, it eats one red apple.",
                "On Tuesday, it eats two juicy pears.",
                "On Wednesday, it munches three purple plums.",
                "On Thursday, it gobbles four sweet strawberries.",
                "On Friday, it chomps five ripe oranges!",
                "The caterpillar grew big and round.",
                "It spins a cozy cocoon to rest.",
                "The caterpillar sleeps for many days.",
                "Then pop! Out comes a beautiful butterfly!",
                "The colorful butterfly flies away, free!"
            ], coverSymbol: "ladybug.fill"),
            
            // NEW: The Friendly Cloud - One sentence per page
            ReadingItem(id: "pb13", title: "The Friendly Cloud", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "A cloud makes friends with everyone below.", fullText: "", bookType: .pictureBook, chapters: [
                "High up in the sky floats a fluffy white cloud.",
                "The cloud looks down and sees a thirsty flower.",
                "Drip, drop! The cloud gives the flower a drink.",
                "The happy flower waves its petals—thank you!",
                "The cloud floats over a hot, tired farmer.",
                "The cloud makes a big, cool shadow.",
                "The farmer smiles and rests in the shade.",
                "Next, the cloud sees children playing.",
                "It makes funny shapes—a bunny, a dragon, a heart!",
                "The children laugh and point at the sky.",
                "At sunset, the cloud turns pink and gold.",
                "Good night, friendly cloud! See you tomorrow!"
            ], coverSymbol: "cloud.fill"),
            
            // NEW: Five Little Ducks - One sentence per page
            ReadingItem(id: "pb14", title: "Five Little Ducks", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "Ducks go out to play and come back home.", fullText: "", bookType: .pictureBook, chapters: [
                "Mother duck has five little ducklings.",
                "Five little ducks waddle over the hill.",
                "Quack, quack, quack! calls Mother Duck.",
                "But only four little ducks come back!",
                "Four little ducks waddle to the pond.",
                "Quack, quack! calls Mother Duck again.",
                "But only three little ducks come back!",
                "Mother Duck calls and calls for her babies.",
                "Finally, all five ducks waddle home!",
                "Mother Duck gives each one a big hug.",
                "Never wander too far from home!",
                "The happy duck family swims together."
            ], coverSymbol: "bird.fill"),
            
            // NEW: The Sleepy Bear - One sentence per page
            ReadingItem(id: "pb15", title: "The Sleepy Bear", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "A bear gets ready for a long winter sleep.", fullText: "", bookType: .pictureBook, chapters: [
                "Brown Bear yawns a great big yawn.",
                "The leaves are falling from the trees.",
                "Winter is coming very soon.",
                "Brown Bear eats lots of berries.",
                "Munch, munch! Getting nice and round.",
                "Brown Bear finds a cozy cave.",
                "She gathers soft leaves for a bed.",
                "The cave is warm and dry inside.",
                "Snow begins to fall outside.",
                "Brown Bear curls up into a ball.",
                "She closes her eyes and starts to dream.",
                "Sleep tight, Brown Bear, until spring!"
            ], coverSymbol: "pawprint.fill"),
            
            // NEW: The Magic Garden - One sentence per page  
            ReadingItem(id: "pb16", title: "The Magic Garden", author: "EZ Picture Books", genre: .fantasy, level: 1, summary: "A child discovers a magical garden.", fullText: "", bookType: .pictureBook, chapters: [
                "I found a tiny door in the garden wall.",
                "I turned the golden key and peeked inside.",
                "Wow! The flowers here can talk!",
                "Hello, little friend! says a red rose.",
                "A blue butterfly lands on my hand.",
                "The butterfly whispers a secret to me.",
                "I follow a path made of sparkly stones.",
                "A friendly frog sits by a silver pond.",
                "Dragonflies dance above the water.",
                "I make a wish on a dandelion puff.",
                "The garden fills with twinkling lights.",
                "I promise to come back tomorrow!"
            ], coverSymbol: "sparkles"),
            
            // NEW: My Feelings Today - One sentence per page
            ReadingItem(id: "pb17", title: "My Feelings Today", author: "EZ Picture Books", genre: .nonfiction, level: 1, summary: "Learning about different feelings.", fullText: "", bookType: .pictureBook, chapters: [
                "Sometimes I feel happy and want to smile!",
                "When I am happy, I laugh and play.",
                "Sometimes I feel sad and want to cry.",
                "When I am sad, I need a big hug.",
                "Sometimes I feel angry and want to stomp!",
                "When I am angry, I take deep breaths.",
                "Sometimes I feel scared and want to hide.",
                "When I am scared, I hold someone's hand.",
                "Sometimes I feel excited and cannot sit still!",
                "All my feelings are okay to have.",
                "I can talk about how I feel inside.",
                "My feelings make me who I am!"
            ], coverSymbol: "heart.fill"),
            
            // NEW: A Day at the Beach - One sentence per page
            ReadingItem(id: "pb18", title: "A Day at the Beach", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "Fun adventures at the sunny beach.", fullText: "", bookType: .pictureBook, chapters: [
                "Today we are going to the beach!",
                "I pack my bucket and my shovel.",
                "The car ride feels so exciting.",
                "I can see the blue ocean ahead!",
                "My toes squish in the warm sand.",
                "I run to the water—splash, splash!",
                "The waves tickle my feet and ankles.",
                "I build a tall sandcastle with towers.",
                "A seagull flies over my head.",
                "I find pretty shells in the sand.",
                "We eat yummy sandwiches for lunch.",
                "What a wonderful day at the beach!"
            ], coverSymbol: "water.waves"),
            ReadingItem(id: "pb8", title: "Goodnight Moon", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "Saying goodnight to everything in the room.", fullText: "", bookType: .pictureBook, chapters: [
                "In the great green room there was a telephone.",
                "And a red balloon and a picture of the cow jumping over the moon.",
                "And there were three little bears sitting on chairs.",
                "And two little kittens and a pair of mittens.",
                "And a little toy house and a young mouse.",
                "And a comb and a brush and a bowl full of mush.",
                "Goodnight room. Goodnight moon.",
                "Goodnight cow jumping over the moon.",
                "Goodnight light and the red balloon.",
                "Goodnight bears. Goodnight chairs.",
                "Goodnight kittens. Goodnight mittens.",
                "Goodnight stars. Goodnight air. Goodnight noises everywhere."
            ], coverSymbol: "moon.stars.fill"),
            ReadingItem(id: "pb9", title: "The Very Busy Spider", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "A spider spins her web while animals ask her to play.", fullText: "", bookType: .pictureBook, chapters: [
                "Early in the morning a little spider began to spin a web on a fence post.",
                "The horse said, 'Want to go for a ride?' The spider did not answer. She was very busy spinning her web.",
                "The cow said, 'Want to eat some grass?' The spider did not answer. She was very busy spinning her web.",
                "The sheep said, 'Want to run in the meadow?' The spider did not answer. She was very busy spinning her web.",
                "The goat said, 'Want to jump on the rocks?' The spider did not answer. She was very busy spinning her web.",
                "The pig said, 'Want to roll in the mud?' The spider did not answer. She was very busy spinning her web.",
                "The dog said, 'Want to chase a cat?' The spider did not answer. She was very busy spinning her web.",
                "The duck said, 'Want to go for a swim?' The spider did not answer. She was very busy spinning her web.",
                "The rooster said, 'Want to catch a pesky fly?' The spider did not answer. She was very busy spinning her web.",
                "And just then a fly landed in the web—and the spider caught it! The web was done at last.",
                "The owl said, 'Who built this beautiful web?' But the spider did not answer.",
                "She had fallen asleep. It had been a very, very busy day."
            ], coverSymbol: "ladybug.fill"),
            ReadingItem(id: "pb10", title: "Brown Bear, Brown Bear", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "What do you see? A parade of colorful animals.", fullText: "", bookType: .pictureBook, chapters: [
                "Brown bear, brown bear, what do you see? I see a red bird looking at me!",
                "Red bird, red bird, what do you see? I see a yellow duck looking at me!",
                "Yellow duck, yellow duck, what do you see? I see a blue horse looking at me!",
                "Blue horse, blue horse, what do you see? I see a green frog looking at me!",
                "Green frog, green frog, what do you see? I see a purple cat looking at me!",
                "Purple cat, purple cat, what do you see? I see a white dog looking at me!",
                "White dog, white dog, what do you see? I see a black sheep looking at me!",
                "Black sheep, black sheep, what do you see? I see a goldfish looking at me!",
                "Goldfish, goldfish, what do you see? I see a teacher looking at me!",
                "Teacher, teacher, what do you see? I see children looking at me!",
                "Children, children, what do you see?",
                "We see a brown bear, a red bird, a yellow duck, a blue horse, a green frog, a purple cat, a white dog, a black sheep, a goldfish, and a teacher looking at us! That is what we see!"
            ], coverSymbol: "pawprint.fill"),
            ReadingItem(id: "pb11", title: "Oceans of Wonder", author: "EZ Picture Books", genre: .nonfiction, level: 2, summary: "Discover the creatures of the deep blue sea.", fullText: "", bookType: .pictureBook, chapters: [
                "The ocean is huge and full of amazing life!",
                "Tiny fish swim together in giant groups called schools.",
                "Sharks glide through the water like silent hunters.",
                "Playful dolphins leap out of the waves and splash back down!",
                "Octopuses are very smart and can hide by changing colors.",
                "Sea turtles swim thousands of miles across the ocean.",
                "Whales are the biggest animals on Earth and sing long beautiful songs.",
                "Crabs scuttle sideways across the sandy ocean floor.",
                "Jellyfish float like glowing lanterns in the deep dark water.",
                "Coral reefs are like underwater cities full of colorful fish.",
                "The ocean still has many secrets waiting to be discovered.",
                "We must protect our oceans and all the wonderful creatures who live there!"
            ], coverSymbol: "water.waves"),
            ReadingItem(id: "pb12", title: "My First Day of School", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "A nervous child has a great first day.", fullText: "", bookType: .pictureBook, chapters: [
                "Today is my first day of school. I hold Mom's hand very tight.",
                "The school building is so big! There are so many children everywhere.",
                "I feel a little scared. What if nobody likes me?",
                "A teacher smiles at the door. 'Welcome! I am Ms. Lee,' she says warmly.",
                "Ms. Lee shows me my very own desk. It has my name on it!",
                "A boy sits next to me. He has a dinosaur on his shirt. 'I'm Jake,' he says.",
                "At reading time, Ms. Lee reads us a story about a friendly bear.",
                "At recess, Jake and I play on the swings. We go so high!",
                "In art class, I paint a picture of my cat. Ms. Lee hangs it on the wall!",
                "We eat lunch in the cafeteria. Jake shares his cookies with me.",
                "When Mom comes to pick me up, I run to her with a big smile.",
                "'Mom! I want to come back tomorrow! School is wonderful!'"
            ], coverSymbol: "graduationcap.fill")
        ]
        
        // MARK: - CHAPTER BOOKS (multi-chapter, longer reads)
        items += [
            ReadingItem(id: "ch1", title: "The Lost Treasure of Oak Island", author: "EZ Chapter Books", genre: .adventure, level: 4, summary: "Three friends search for buried treasure.", fullText: "", bookType: .chapterBook, chapters: [
                "Chapter 1: The Attic. Jake was helping clean Grandpa's attic when he moved an old trunk. Dust flew everywhere. Under the trunk was a wooden box held shut by a brass latch. Jake pried it open. Inside was a rolled-up piece of leather.",
                "Chapter 2: The Map. Jake carefully unrolled the leather. It was a hand-drawn map with faded ink. An island was sketched in the center. Oak Island. A large X was marked near a tree. Jake's heart pounded.",
                "Chapter 3: The Plan. Jake showed his friends Maya and Tyler the next morning. 'We have to go,' Maya said. Tyler was nervous but excited. They spent the day planning. Supplies, flashlights, rope, water.",
                "Chapter 4: The Ferry. Saturday morning they caught the early ferry. The boat was small and rocked in the waves. Tyler gripped the railing. 'I don't feel so good,' he said. Maya pointed. 'Look, there's the island!'",
                "Chapter 5: The Dock. They stepped onto the old wooden dock. The island was thick with trees. Birds called from above. A sign said 'Private — No Trespassing.' They looked at each other. Jake folded the map. 'We've come this far.'",
                "Chapter 6: The Trail. The trail was overgrown with vines and thorns. Branches scratched their arms. Maya used a stick to push through. According to the map, the tree with the carving was northeast.",
                "Chapter 7: The Oak Tree. 'There!' Tyler pointed ahead. A massive oak tree with a five-pointed star carved deep into the bark. Just like the map. They circled the tree, looking for anything unusual.",
                "Chapter 8: The Cave. Behind the tree, hidden by roots, was a narrow opening. Jake shined his flashlight inside. A cave. They squeezed through one at a time. The air was cool and damp. Their lights bounced off wet stone walls.",
                "Chapter 9: Gold. Something glittered on the ground. Gold coins. Then more. Maya gasped. Against the far wall was a wooden chest, old and weathered. They had actually found it.",
                "Chapter 10: The Storm. Thunder boomed outside. Rain started pouring. Water began trickling into the cave. 'We have to go NOW,' Tyler said. They grabbed the chest and ran.",
                "Chapter 11: The Escape. The path was a river of mud. They slipped and slid. Maya fell but caught herself. Jake carried the chest. Lightning cracked across the sky. They sprinted to the dock.",
                "Chapter 12: The Ferry Back. The ferry captain was waiting with a lantern. 'Cutting it close, kids!' They climbed aboard, soaking wet. Tyler wrapped the chest in his jacket. The water was rough but they held on tight.",
                "Chapter 13: Back on Shore. They made it back to the mainland just as the storm calmed. Streetlights flickered on. Maya called her mom. 'We're safe.' They walked to Jake's house, the chest between them.",
                "Chapter 14: Opening the Chest. Jake's mom gave them towels and hot cocoa. They gathered around the kitchen table. Jake carefully lifted the lid of the old chest. Inside were layers of old cloth.",
                "Chapter 15: What Was Inside. Under the cloth: a bundle of yellowed letters tied with string, a gold ring with an engraved oak tree, three old coins, and a folded note in familiar handwriting.",
                "Chapter 16: Grandpa's Note. Jake unfolded the note. 'To whoever finds this — congratulations. The real treasure isn't gold. It's the adventure. It's the friends beside you. I knew you would find it someday. Love, Grandpa.' Jake's eyes filled with tears.",
                "Chapter 17: The Letters. The letters were from Grandpa's childhood. He had explored Oak Island at their age with his own two friends. He had hidden the chest for the next generation to find.",
                "Chapter 18: Telling the Story. At school on Monday, they gave a presentation about Oak Island. Their classmates were amazed. The teacher said it was the best show-and-tell ever.",
                "Chapter 19: The Ring. Jake gave his mom the gold ring. She held it up to the light. 'This was my father's?' She put it on. It fit perfectly. 'He would have loved that you found it.'",
                "Chapter 20: Next Adventure. That night, Jake, Maya, and Tyler sat on the porch. The stars were out. 'So,' Maya said, 'where do we go next?' Jake grinned. He had already found another map."
            ]),
            ReadingItem(id: "ch2", title: "The Mystery of the Missing Painting", author: "EZ Chapter Books", genre: .mystery, level: 4, summary: "Who took the painting from the grand hall?", fullText: "", bookType: .chapterBook, chapters: [
                "Chapter 1: The Grand Hall. The Chen mansion had stood on Elm Street for over a hundred years. In its grand hall hung a painting of a ship at sea, painted by a famous artist long ago.",
                "Chapter 2: Gone. On Monday morning, Ms. Chen walked into the hall and screamed. The painting was gone. Only the empty gold frame remained. She called the police immediately.",
                "Chapter 3: Detective Park. Detective Park arrived within the hour. He wore a long coat and carried a notebook. He studied the wall, the frame, the floor. 'Tell me about everyone who has a key,' he said.",
                "Chapter 4: The Clues. A smudge on the window. Footprints in the garden — size 10 boots. And a green thread caught on the window latch. Someone had climbed in during the night.",
                "Chapter 5: The Suspects. The detective made a list. The gardener, who tended the grounds. The cook, who lived in the back house. And Emma, Ms. Chen's niece, who had visited that weekend.",
                "Chapter 6: Emma's Story. Emma needed money — everyone knew that. She had borrowed from her aunt before. She had a key to the house. But she said she was at the movies that night.",
                "Chapter 7: Checking the Alibi. Detective Park called the theater. Yes, they remembered Emma. She had bought popcorn and stayed for the whole film. Her ticket was timestamped. She was telling the truth.",
                "Chapter 8: The Green Thread. The cook wore a green apron every day. The thread from the window matched. The detective visited the cook's kitchen. 'I know nothing,' the cook said nervously.",
                "Chapter 9: Paint Under His Nails. The detective asked to see the cook's hands. Under his fingernails was dried paint — the same golden color as the painting's frame. The cook turned pale.",
                "Chapter 10: The Shed. In the cook's shed, behind stacked firewood, was the painting. He had planned to sell a copy and keep the original. He didn't know the painting was worth millions.",
                "Chapter 11: The Confession. The cook broke down. 'I only wanted to sell a copy. I didn't mean to steal the real one.' He had been painting replicas for months in secret.",
                "Chapter 12: The Expert. An art expert arrived from the city to verify the painting's authenticity. She examined it with a magnifying glass and UV light. 'It's real,' she confirmed. 'And in perfect condition.'",
                "Chapter 13: The Insurance. The insurance company had valued the painting at four million dollars. They were very relieved. Detective Park filed his report at the station that night.",
                "Chapter 14: The Restoration. A restoration team cleaned the painting carefully, removing a thin layer of dust from its years on the wall. The colors underneath were vibrant — the ship seemed to sail again.",
                "Chapter 15: Back on the Wall. The painting returned to the grand hall with a new security system — motion sensors, cameras, and reinforced glass. Ms. Chen stood before it. 'Welcome home,' she whispered.",
                "Chapter 16: The Thank You. Ms. Chen invited Detective Park to dinner. She served his favorite dish. They talked about the case and laughed. 'You saved a piece of my family,' she said.",
                "Chapter 17: The Lesson. The local school brought a class to see the painting. Ms. Chen told them the story. The students were fascinated. One girl raised her hand: 'I want to be a detective too.'"
            ]),
            ReadingItem(id: "ch3", title: "Dragon Friend", author: "EZ Chapter Books", genre: .fantasy, level: 3, summary: "A girl finds a baby dragon in the woods.", fullText: "", bookType: .chapterBook, chapters: [
                "Chapter 1: The Walk. Lina walked through the woods behind her house every morning. She liked the quiet, the birds, the way sunlight came through the leaves like gold coins.",
                "Chapter 2: The Egg. One morning she tripped on something buried in leaves. It was an egg. Not a bird egg — this egg was blue and warm and as big as a cantaloupe. She held it gently.",
                "Chapter 3: Waiting. Lina wrapped the egg in a blanket and kept it by the heater. Days passed. She watched it. On the fifth morning, a crack appeared. Then another. Then the shell split open.",
                "Chapter 4: Spark. Out tumbled a tiny creature — scaly, blue, with small wings and golden eyes. It sneezed. A tiny flame shot from its nose. A baby dragon. Lina whispered, 'I'll call you Spark.'",
                "Chapter 5: Growing Up. Spark ate berries and bits of bread. Spark napped in patches of sunlight. Each day Spark grew a little bigger. After two weeks, Spark was the size of a cat. Then a dog.",
                "Chapter 6: Hiding. 'We need to hide you,' Lina said. Spark was too big for the house. She found a cave in the deep part of the forest. She made it cozy with blankets and set up a little camp.",
                "Chapter 7: Flying. One morning Spark spread her wings and leaped. She wobbled, then soared. Lina laughed as Spark circled above the trees. Spark brought Lina a flower in her mouth.",
                "Chapter 8: Best Friends. Every day after school, Lina ran to the cave. She and Spark would play, explore the stream, and sit watching the sunset. Spark purred like a cat when happy.",
                "Chapter 9: The Man in Black. One afternoon, Lina noticed a man in a black coat watching from the tree line. He had binoculars. He had seen Spark flying. 'We need to be careful,' Lina whispered.",
                "Chapter 10: The Chase. The man came with a net and a truck. Lina heard the engine. 'Spark, we have to go — NOW!' Spark spread her wings. Lina climbed on. They rose above the trees.",
                "Chapter 11: In the Clouds. Up, up they flew. Into the clouds where the air was cold and wet. They hid there, circling above the man, who searched the empty cave in frustration. Eventually, he drove away.",
                "Chapter 12: A New Home. Lina found a hidden valley deep in the forest with a waterfall and tall cliffs. 'This can be your home, Spark.' Spark explored every corner, sniffing flowers and splashing in the water.",
                "Chapter 13: The Winter. When winter came, Spark's scales turned a deeper blue. Lina brought blankets and warm soup to the valley. Spark curled around her like a warm campfire. Snow fell around them.",
                "Chapter 14: The Other Eggs. In spring, Spark led Lina to a hidden spot behind the waterfall. Three more eggs, glowing softly. 'More dragons?' Lina whispered. Spark hummed proudly.",
                "Chapter 15: Hatching Day. The eggs cracked on a warm April morning. Three tiny dragons tumbled out — one green, one red, one silver. They sneezed tiny sparks. Lina laughed so hard she cried.",
                "Chapter 16: A Dragon Family. Spark taught the little ones to fly. Lina named them Fern, Ember, and Pearl. They chased butterflies and played in the stream. The valley was alive with dragon song.",
                "Chapter 17: Keeping the Secret. Lina told no one about the valley. She visited every day after school. The dragons recognized her footsteps and came running. It was her secret, sacred place.",
                "Chapter 18: Forever Friends. Years passed. Lina grew up. She became a wildlife biologist. But every weekend, she hiked to the valley. Spark always waited by the waterfall. Some friendships last forever."
            ]),
            ReadingItem(id: "ch4", title: "The Secret Garden of Oak Lane", author: "EZ Chapter Books", genre: .fiction, level: 4, summary: "A locked garden holds a beautiful surprise.", fullText: "", bookType: .chapterBook, chapters: [
                "Chapter 1: The Old House. Emma's family moved to Oak Lane in September. The house was old with wooden shutters and a high stone wall along the backyard. 'What's behind the wall?' Emma asked. Nobody knew.",
                "Chapter 2: The Key. While sweeping the porch one afternoon, Emma noticed a loose floorboard. Under it was a small rusty key with a tag that said 'Garden' in faded ink.",
                "Chapter 3: The Gate. Emma found a gate hidden behind ivy on the stone wall. She pushed the key in. Click. The gate swung open. Her heart raced as she stepped through.",
                "Chapter 4: The Garden. It was a garden — wild and overgrown, but beautiful. Roses climbed the walls. A stone path wound through the weeds to a fountain covered in moss. Birds sang in the branches above.",
                "Chapter 5: Bringing It Back. Emma came back every day after school. She pulled weeds. She cleared the paths. She turned on the fountain — water still flowed! Day by day, the garden woke up.",
                "Chapter 6: The Crying Boy. One afternoon she heard crying. Under the willow tree sat a boy her age, knees pulled to his chest. 'Who are you?' Emma asked gently.",
                "Chapter 7: Leo. 'I'm Leo. I live next door. I used to come here when I was little — before the gate was locked.' His grandmother had planted the roses. She had passed away, and the garden was locked ever since.",
                "Chapter 8: Together. Emma handed Leo a trowel. 'Let's fix it. Together.' They worked side by side, clearing, planting, and laughing. The garden came alive around them.",
                "Chapter 9: The Storm. A big storm came one night. Wind howled. In the morning, branches were down and the trellis was broken. Emma and Leo rushed in to repair everything.",
                "Chapter 10: Planting Season. They planted sunflower seeds, lavender, and tomatoes. They hung a birdhouse. Leo brought a bench from his garage. The garden became their place.",
                "Chapter 11: The Reveal. When spring came, the garden burst with color. Emma invited her mom. Leo invited his dad. They stood in the gate, speechless. 'You kids did this?' 'Yes. Together.'",
                "Chapter 12: The Party. They held a garden party for the whole neighborhood. Fairy lights hung from branches. Neighbors brought dishes. Kids ran through the paths. Music played from a small speaker.",
                "Chapter 13: Leo's Grandma. Leo brought an old photo of his grandmother standing in the garden forty years ago. The same roses were there. 'She would be so happy,' Leo said, his voice cracking.",
                "Chapter 14: The Garden Club. Emma and Leo started a garden club at school. Ten kids signed up. They met every Saturday. Each kid got their own plot to plant whatever they wanted.",
                "Chapter 15: The Harvest. By summer, the tomato plants were heavy with fruit. They picked baskets of tomatoes, peppers, and herbs. They gave bags of vegetables to every neighbor on Oak Lane.",
                "Chapter 16: The Butterfly Garden. They planted milkweed and lavender along one wall. Soon monarch butterflies came. Then hummingbirds. Then a family of rabbits. The garden was a tiny ecosystem.",
                "Chapter 17: A Permanent Place. The city put up a small plaque by the gate: 'The Secret Garden of Oak Lane — Restored by Emma & Leo.' It was official now. Their garden would be there forever."
            ]),
            ReadingItem(id: "ch5", title: "Robo Rescue: Mission to Mars", author: "EZ Chapter Books", genre: .scifi, level: 5, summary: "A young engineer sends a robot to save stranded astronauts.", fullText: "", bookType: .chapterBook, chapters: [
                "Chapter 1: Breaking News. The TV screen flashed red: MARS MISSION IN DANGER. The supply rover was stuck in a sand dune. Without it, the astronauts had seven days of food and water. The whole world watched.",
                "Chapter 2: Zara's Idea. Twelve-year-old Zara had been building robots since she was eight. She watched the broadcast and thought hard. She grabbed her notebook. 'I can build something that can pull the rover out.'",
                "Chapter 3: The Plans. Zara drew through the night. A small robot with strong arms, wide wheels for sand, a camera, and solar panels. She scanned the plans and emailed them to NASA with a message: 'I can help.'",
                "Chapter 4: The Call. Her phone rang the next morning. It was Dr. Reeves from NASA. 'Your design is brilliant. Can you come to Houston?' Zara's mom drove her to the airport that afternoon.",
                "Chapter 5: Building Scout. At NASA, Zara worked with a team of engineers. They built the robot in three days. They called it Scout. It was silver with orange wheels and two articulated arms.",
                "Chapter 6: Launch. Scout was loaded onto a fast-track rocket. The countdown shook the building. Three... two... one. The rocket roared into the sky, carrying Scout toward Mars. Seven days to arrival.",
                "Chapter 7: Waiting. Zara sat in Mission Control, watching Scout's signal cross millions of miles. She barely slept. On day five, the astronauts sent a message: 'Supplies are running low. Hurry.'",
                "Chapter 8: Landing. On day seven, Scout entered Mars' atmosphere. The parachute deployed. Scout bounced onto the red surface and rolled to a stop. Its camera activated. Mars was real.",
                "Chapter 9: The Rescue. Scout rolled toward the stuck rover, navigating rocks and sand. It extended its arms, gripped the rover's frame, and pulled. The wheels spun. Sand flew. Slowly, the rover lurched forward. Free!",
                "Chapter 10: Celebration. The astronauts reached the rover and drove it back to base. 'Thank you, Scout. Thank you, Zara.' Mission Control erupted in cheers. Zara cried happy tears.",
                "Chapter 11: The Medal. Zara flew back to Washington. The President gave her a medal in a ceremony on the White House lawn. 'Dream big,' the President said. Zara smiled. She already did.",
                "Chapter 12: Scout on Mars. Scout stayed on Mars, sending pictures back every day — sunsets, dust storms, the distant blue dot of Earth. And every time Zara looked at the photos, she whispered, 'Good job, Scout.'",
                "Chapter 13: The Interview. Every news channel wanted to talk to Zara. She appeared on morning shows, podcasts, and YouTube. Kids from around the world sent her letters. 'You inspired me,' they wrote.",
                "Chapter 14: Back to School. Zara returned to her regular school. Her classmates cheered. Her science teacher said, 'You proved that age doesn't limit what you can do.' Zara blushed.",
                "Chapter 15: The Robot Club. Zara started a robotics club after school. Twenty kids signed up the first week. They built small rovers, drones, and mechanical arms. The school gave them a whole classroom.",
                "Chapter 16: Scout's Discovery. One morning, Scout's camera captured something unusual — a formation of rocks that looked like it had been carved. NASA scientists studied the images. Could it be evidence of ancient water?",
                "Chapter 17: The Next Mission. NASA called Zara again. 'We're planning a crewed mission to Mars in five years. We want you on the engineering team — when you're old enough.' Zara's jaw dropped.",
                "Chapter 18: The Future. Zara looked at the Mars poster on her bedroom wall. She thought about Scout, still rolling across the red sand. She thought about the astronauts she had helped save. She picked up her notebook and started sketching: Scout 2.0."
            ])
        ]
        
        // MARK: - FICTION (short stories, more detail)
        items += [
            ReadingItem(id: "f1", title: "The Lost Kitten", author: "EZ Stories", genre: .fiction, level: 1, summary: "A little girl finds a kitten in the park.", fullText: "", bookType: .shortStory, chapters: [
                "Kim walked through the park one sunny afternoon. The leaves were falling from the trees.",
                "She heard a tiny sound coming from the bushes. Meow. Meow.",
                "Kim bent down and peeked through the leaves. There was a small kitten!",
                "The kitten was gray and white with big green eyes. It looked scared and alone.",
                "Kim gently picked it up. The kitten was shaking, but then it began to purr.",
                "She looked around the park for its owner. Nobody was there.",
                "Kim carried the kitten all the way home. It snuggled close to her.",
                "Mom opened the door. 'What do you have there?' she asked with a smile.",
                "'I found a kitten! Can we keep it? Please, Mom?' Kim begged.",
                "Mom looked at the kitten. It purred. Mom's heart melted. 'We can keep it.'",
                "Kim was the happiest girl in the world! She named the kitten Whiskers.",
                "That night, Whiskers slept on Kim's pillow. They were best friends already."
            ], coverSymbol: "cat.fill"),
            ReadingItem(id: "f2", title: "The Red Ball", author: "EZ Stories", genre: .fiction, level: 1, summary: "A boy loses his ball and finds it.", fullText: "", bookType: .shortStory, chapters: [
                "Sam loved his red ball more than any other toy. It was bright and bouncy.",
                "One morning, Sam took his ball to the park. He threw it as high as he could!",
                "But the ball bounced off the ground and rolled away fast!",
                "It went past the swing set. Sam chased after it.",
                "It rolled past the big slide. Sam ran faster!",
                "The ball bounced over a bump and flew into the tall grass.",
                "Sam looked and looked. He pushed the grass aside. Where was his ball?",
                "He checked behind the bench. Not there. He looked under the bridge. Not there either.",
                "Sam was about to give up. Then he saw something red under the big oak tree.",
                "There it was! His red ball, sitting in the cool shade, waiting for him.",
                "Sam picked up his ball and hugged it tight. 'I found you!' he cheered.",
                "From that day on, Sam always kept his ball close. It was his best friend."
            ], coverSymbol: "basketball.fill"),
            ReadingItem(id: "f3", title: "Rainy Day", author: "EZ Stories", genre: .fiction, level: 1, summary: "What to do when it rains.", fullText: "", bookType: .shortStory, chapters: [
                "Pam woke up and looked out the window. Tap, tap, tap. It was raining!",
                "'Oh no!' said Pam. 'I wanted to play outside today.'",
                "Mom said, 'You can have fun inside too! Use your imagination.'",
                "First, Pam read a book about pirates. She imagined sailing the seas!",
                "Then she drew a picture of the ocean with colorful fish and a big whale.",
                "She found a cardboard box and turned it into a pirate ship.",
                "Pam's little brother came to play. He was the first mate!",
                "They sailed their box ship across the living room ocean.",
                "Then they built the tallest tower of blocks they had ever made!",
                "Mom made hot chocolate. It was warm and yummy.",
                "Just then, the rain stopped. The sun peeked through the clouds. A rainbow!",
                "Pam ran outside and splashed in every puddle. What a perfect day!"
            ], coverSymbol: "cloud.rain.fill"),
            ReadingItem(id: "f4", title: "The Brave Mouse", author: "EZ Stories", genre: .fiction, level: 2, summary: "A small mouse saves his friends.", fullText: "", bookType: .shortStory, chapters: [
                "In a cozy hole under the old oak tree lived a family of mice.",
                "Little Max was the smallest mouse of all. His brothers teased him for being tiny.",
                "One afternoon, Max was picking berries when he heard a sound. Footsteps!",
                "He peeked through the grass. A big orange cat was creeping toward the mouse hole!",
                "Max's heart pounded. He was scared, but his family was in danger!",
                "He ran as fast as his tiny legs could carry him. 'Everyone! Hide!' he squeaked.",
                "The mice scrambled into the hollow log just in time.",
                "The cat sniffed around the entrance. Its yellow eyes searched for any movement.",
                "Max held his breath. The cat waited and waited. But the mice stayed perfectly still.",
                "Finally, the cat gave up and walked away, flicking its tail.",
                "Everyone cheered for Max! 'You saved us!' said his brothers. 'You are the bravest!'",
                "Max smiled. He learned that being brave has nothing to do with being big."
            ], coverSymbol: "hare.fill"),
            ReadingItem(id: "f5", title: "The Sand Castle", author: "EZ Stories", genre: .fiction, level: 2, summary: "Two friends build the best sand castle.", fullText: "", bookType: .shortStory, chapters: [
                "Jake and Mia arrived at the beach early in the morning. The sand was smooth and perfect.",
                "They carried their pails and shovels down to the water's edge.",
                "'Let's build the best sand castle ever!' said Mia, her eyes shining.",
                "They dug and dug. Jake made the main tower tall and strong.",
                "Mia carved windows and a drawbridge. She added a moat around the castle.",
                "They filled the moat with water from the ocean. It looked like a real castle!",
                "Jake found beautiful shells to decorate the walls. Pink, white, and orange shells.",
                "Mia put a stick on top with a leaf for a flag. 'Our kingdom!' she declared.",
                "Other children came to admire their work. 'Wow!' they said. 'That's amazing!'",
                "Then they heard it. A big wave was coming! It crashed over the sand castle.",
                "The towers melted. The moat filled in. The shells scattered. Everything was gone.",
                "Jake and Mia looked at each other and laughed. 'Let's build an even better one!'"
            ], coverSymbol: "beach.umbrella.fill"),
            ReadingItem(id: "f7", title: "The Magic Pencil", author: "EZ Stories", genre: .fiction, level: 3, summary: "A pencil that draws real things.", fullText: "", bookType: .shortStory, chapters: [
                "Ben was cleaning under his bed when he found something strange—a silver pencil.",
                "It glowed with a faint light. Curious, Ben sat at his desk and started to draw.",
                "He drew a red apple. As soon as he finished, a real apple appeared on his desk!",
                "Ben gasped. He picked up the apple. It was real! He could feel it and smell it.",
                "He drew a butterfly. It fluttered off the page and flew around his room!",
                "Then he drew a puppy. A fluffy golden puppy jumped right off the paper!",
                "The puppy licked his face. 'This is the best pencil in the world!' Ben laughed.",
                "But then Ben wondered—could he draw anything? He drew a pile of gold coins.",
                "The coins appeared, but they vanished in seconds. The pencil would not create selfish things.",
                "Ben understood. He drew flowers for his mom. She smiled and hugged him.",
                "He drew toys for his little sister. She clapped with joy.",
                "Ben learned the magic pencil only worked when he used it to make others happy."
            ], coverSymbol: "pencil.and.outline"),
            ReadingItem(id: "f10", title: "The Message in a Bottle", author: "EZ Stories", genre: .fiction, level: 4, summary: "A bottle washes up with a note inside.", fullText: "", bookType: .shortStory, chapters: [
                "Leo walked along the beach at sunrise. The waves left treasures on the sand every morning.",
                "Something green caught his eye. A glass bottle, half buried in the wet sand.",
                "He pulled it out and held it up to the light. There was a rolled-up paper inside!",
                "With trembling hands, Leo pulled the cork and unrolled the note.",
                "It read: 'Help. I am on a small island. Three tall palm trees. Please find me.'",
                "Leo's heart raced. This was real! Someone needed help!",
                "He ran all the way to the coast guard station. 'You have to read this!' he said, breathless.",
                "The coast guard took the note seriously. They launched a search helicopter immediately.",
                "For two days they searched the nearby islands. Leo waited anxiously by the radio.",
                "On the second day, the radio crackled. 'We found him! An old sailor stranded for two weeks!'",
                "The sailor was brought back safe and sound. He shook Leo's hand. 'You saved my life, son.'",
                "The sailor gave Leo the green bottle as a reminder. 'Sometimes the smallest things make the biggest difference.'"
            ], coverSymbol: "envelope.fill"),
            ReadingItem(id: "f11", title: "The Treehouse Club", author: "EZ Stories", genre: .fiction, level: 2, summary: "Three friends build a clubhouse in a tree.", fullText: "", bookType: .shortStory, chapters: [
                "Max, Lily, and Noah found the perfect tree in the backyard—big, strong branches and lots of shade.",
                "'We should build a treehouse!' said Max. The others cheered.",
                "They asked their parents for help. Dad gave them some old boards and a hammer.",
                "Day one: they built the floor. It took all morning, but it was sturdy!",
                "Day two: they added walls with a window so they could see the whole neighborhood.",
                "Day three: they put up a roof. Now they had a real room in the sky!",
                "Lily painted a sign: 'The Secret Club. Members Only.' She hung it on the ladder.",
                "They brought up pillows, comic books, and a box of snacks.",
                "They made up a secret handshake and a password. 'Acorn!' you had to whisper.",
                "Every day after school, they climbed up to their treehouse. It was their special place.",
                "They told stories, made plans, and watched the sunset from the window.",
                "It was the best club ever, and they promised to be friends forever."
            ], coverSymbol: "tree.fill"),
            ReadingItem(id: "f12", title: "The Lemonade Stand", author: "EZ Stories", genre: .fiction, level: 2, summary: "Two sisters earn money for a new bike.", fullText: "", bookType: .shortStory, chapters: [
                "Sara and Emma saw the most beautiful purple bike in the store window. 'We need that bike!'",
                "They counted their savings. Only ten dollars. The bike cost fifty!",
                "Mom said, 'If you want it, you'll have to earn the rest.'",
                "The sisters had an idea—a lemonade stand! They squeezed lemons and added sugar.",
                "They made a big colorful sign: 'Fresh Lemonade - 50 cents a cup!'",
                "It was a hot Saturday. People walking by were thirsty.",
                "'We'll take two!' said the mailman. 'Three for us!' said the neighbors.",
                "By lunchtime, they had sold twenty cups! The lemonade kept flowing.",
                "In the afternoon, they added cookies. 'Lemonade AND cookies!' The line grew longer.",
                "By sunset, they counted their earnings. Forty dollars! Plus their ten, that made fifty!",
                "The next morning, they ran to the store. 'We'd like the purple bike, please!'",
                "They took turns riding it home, the proudest sisters on the block."
            ], coverSymbol: "cup.and.saucer.fill"),
            ReadingItem(id: "f13", title: "The Wish Bracelet", author: "EZ Stories", genre: .fiction, level: 3, summary: "A bracelet grants one wish.", fullText: "", bookType: .shortStory, chapters: [
                "On her birthday, Grandma gave Mia a beautiful woven bracelet made of colorful threads.",
                "'This is a wish bracelet,' said Grandma. 'Make a wish when you tie it on.'",
                "'When the bracelet falls off on its own, your wish will come true.'",
                "Mia closed her eyes tight. She wished for a puppy more than anything in the world!",
                "She tied the bracelet carefully on her wrist and smiled.",
                "Days passed. Then weeks. Mia checked the bracelet every morning. Still there!",
                "She started to wonder if it was just a story. But she kept hoping.",
                "One morning in the shower, the bracelet slipped right off her wrist!",
                "Mia stared at the loose threads on the floor. 'Did my wish come true?'",
                "That afternoon, Mom came home early. She was carrying a box with holes in the top.",
                "'Mia, come here. We have a surprise for you.' The box wiggled!",
                "Mia opened the lid. A tiny golden puppy licked her face! The wish bracelet was magic after all!"
            ], coverSymbol: "sparkles"),
            ReadingItem(id: "f14", title: "The Snow Day", author: "EZ Stories", genre: .fiction, level: 1, summary: "School is cancelled. Time to play in the snow!", fullText: "", bookType: .shortStory, chapters: [
                "I woke up to Dad's voice. 'No school today! Look outside!'",
                "I ran to the window. Everything was white—the yard, the trees, the cars!",
                "I put on my warmest coat, my boots, my hat, and my thickest gloves.",
                "I opened the door and stepped into the fluffy white snow. Crunch, crunch, crunch!",
                "My brother and I made a snowman. He had a carrot nose and button eyes.",
                "We gave him Dad's old hat and a scarf. He looked perfect!",
                "Then the snowball fight began! I hid behind the tree and threw. Splat!",
                "My brother got me right in the back! We laughed so hard we fell down.",
                "We found a big hill and went sledding. We flew down so fast!",
                "My cheeks turned bright red. My fingers were freezing!",
                "Mom called us inside for hot cocoa with marshmallows. Mmmm, it was warm and sweet.",
                "I watched the snow fall as I sipped my cocoa. Best snow day ever!"
            ], coverSymbol: "snowflake")
        ]
        
        // MARK: - MYSTERY
        items += [
            ReadingItem(id: "m1", title: "The Case of the Stolen Bicycle", author: "EZ Mysteries", genre: .mystery, level: 2, summary: "Detective Kim finds the bike.", fullText: "", bookType: .shortStory, chapters: [
                "Kim ran outside Monday morning. Her red bicycle was gone from the porch!",
                "It had a silver bell and a white basket. Kim loved that bike more than anything.",
                "She decided to be a detective. First clue: tire marks in the mud going left.",
                "She followed the tracks down the sidewalk, across the street, and into the park.",
                "At the park, she saw lots of bikes. But wait—was that a red one by the fountain?",
                "Kim walked closer. A boy named Mike was sitting on a red bicycle. HER red bicycle!",
                "'Hey! That's my bike!' Kim said firmly. Mike's face turned bright red.",
                "'I... I found it,' Mike stammered. But he couldn't look Kim in the eyes.",
                "'You took it from my porch, didn't you?' Kim crossed her arms.",
                "Mike hung his head. 'I'm sorry. My bike broke and I just wanted to ride. I was going to bring it back.'",
                "Kim got her bike back and Mike apologized to Kim's mom. He promised to never take anything again.",
                "Kim learned that solving mysteries takes courage. And Mike learned that taking things always catches up with you."
            ], coverSymbol: "magnifyingglass"),
            ReadingItem(id: "m2", title: "The Secret Code", author: "EZ Mysteries", genre: .mystery, level: 3, summary: "Decoding a mysterious message.", fullText: "", bookType: .shortStory, chapters: [
                "Alex was cleaning out Grandpa's old desk when a folded piece of paper fell out.",
                "On the paper were numbers: 3-15-4-5   9-19   20-8-5   11-5-25",
                "Alex stared at the numbers. 'This must be a code!' Alex loved puzzles.",
                "Then Alex remembered—A is 1, B is 2, C is 3! It was a number-to-letter code!",
                "Slowly, Alex decoded each number. 3=C, 15=O, 4=D, 5=E. The first word was CODE!",
                "9=I, 19=S. 20=T, 8=H, 5=E. The message read: CODE IS THE KEY.",
                "'Code is the key? The key to what?' Alex looked around the room for more clues.",
                "Then Alex noticed the word 'CODE' was carved into the old oak tree in the backyard!",
                "Under the tree, Alex dug and found a small metal box buried in the dirt.",
                "Inside the box was a rusty key. But what did it open?",
                "Alex tried every lock in the house. Finally—click! It opened the garden shed!",
                "Inside the shed was Grandpa's old telescope and a note: 'For you, my little explorer. Look at the stars and think of me. Love, Grandpa.'"
            ], coverSymbol: "lock.fill")
        ]
        
        // MARK: - ADVENTURE
        items += [
            ReadingItem(id: "a1", title: "Cave Explorer", author: "EZ Adventures", genre: .adventure, level: 3, summary: "Exploring a dark cave.", fullText: "", bookType: .shortStory, chapters: [
                "Jordan stood at the mouth of the cave. Cool air blew from inside like the cave was breathing.",
                "She clicked on her flashlight. The beam cut through the darkness like a sword.",
                "Step by step, she walked deeper. Her footsteps echoed off the stone walls.",
                "Water dripped from the ceiling—drip, drop, drip—like a slow underground rain.",
                "She looked up. Hundreds of tiny bats hung from the ceiling, sleeping upside down!",
                "The tunnel narrowed, and Jordan had to squeeze through. Her heart pounded.",
                "Then the tunnel opened into a huge chamber. Jordan gasped!",
                "The walls were covered in sparkling crystals—purple, blue, and clear as diamonds!",
                "In the center of the chamber was a pool of water that glowed a soft green.",
                "Jordan knelt by the pool and saw her reflection surrounded by crystals.",
                "She carefully picked one small crystal as a souvenir and put it in her pocket.",
                "Following her chalk marks back, Jordan found the exit. Sunlight never felt so wonderful. An adventure she would never forget."
            ], coverSymbol: "mountain.2.fill"),
            ReadingItem(id: "a2", title: "The Raft Race", author: "EZ Adventures", genre: .adventure, level: 4, summary: "Building a raft and racing down the river.", fullText: "", bookType: .shortStory, chapters: [
                "The sign at the park read: 'Annual River Raft Race — Build Your Own Raft and Win!'",
                "Jay gathered his team—Rosa, Kip, and Ben. 'We have one week to build the best raft!'",
                "They collected strong logs and thick rope from the hardware store.",
                "Day one: they tied the logs together. The knots had to be perfect.",
                "Day two: they added a platform to stand on and a flag made from an old T-shirt.",
                "Day three: they tested the raft in the pond. It floated! But it spun in circles.",
                "They added a rudder to steer. Now it went straight. 'We're ready!' Jay cheered.",
                "Race day arrived. Ten colorful rafts lined up at the starting point.",
                "'GO!' The whistle blew and everyone pushed off. The current grabbed the rafts!",
                "Around the big bend, they paddled hard. Through the gentle rapids, the raft bounced but held!",
                "They crossed the finish line in third place! Not first, but they did it together!",
                "Standing on the shore dripping wet, they laughed and cheered. They were already planning next year's raft."
            ], coverSymbol: "ferry.fill"),
            ReadingItem(id: "a3", title: "The Mountain Climb", author: "EZ Adventures", genre: .adventure, level: 3, summary: "A girl reaches the top of her first mountain.", fullText: "", bookType: .shortStory, chapters: [
                "Emma looked up at the mountain. It seemed to touch the sky. 'Are we really climbing that?'",
                "Dad smiled and adjusted her backpack. 'One step at a time. That's all it takes.'",
                "The trail started easy, winding through tall green trees. Birds sang above them.",
                "After an hour, Emma's legs began to hurt. 'Can we rest?' she asked.",
                "'Of course,' said Dad. They sat on a rock and drank cold water.",
                "They climbed higher. The trees became shorter. The air felt thinner.",
                "Emma wanted to quit. 'I can't do it, Dad.' He squeezed her hand. 'You can. I believe in you.'",
                "She took a deep breath and kept climbing. One step. Then another. Then another.",
                "Soon there were no trees at all—just rocks and the wide open sky.",
                "And then... they were at the top! Emma could see the whole world spread below her!",
                "She and Dad took a picture together with the biggest smiles ever.",
                "'I did it!' Emma whispered. 'I really did it!' The view was worth every single step."
            ], coverSymbol: "mountain.2.fill"),
            ReadingItem(id: "a4", title: "Lost in the Zoo", author: "EZ Adventures", genre: .adventure, level: 2, summary: "A boy gets lost and finds his way back.", fullText: "", bookType: .shortStory, chapters: [
                "Omar held Mom's hand as they walked through the zoo. There was so much to see!",
                "Monkeys swung from ropes. Penguins slid on ice. Elephants sprayed water with their trunks.",
                "Then Omar saw a sign: LIONS. His favorite! He ran ahead to see them.",
                "The lions were huge and beautiful. One yawned, showing enormous teeth.",
                "Omar turned around to show Mom. But Mom was gone! All he saw were strangers.",
                "'Mom? MOM?' Omar called. His eyes filled with tears. He felt so small and scared.",
                "A kind zoo worker noticed him. 'Hey buddy, are you lost?' she asked gently.",
                "Omar nodded, trying not to cry. 'My mom's name is Maria.'",
                "The worker spoke into her radio. 'Lost child at the lion area. Mother's name is Maria.'",
                "Omar waited by the worker. She showed him pictures of baby animals to help him feel better.",
                "Then Omar saw Mom running toward him. 'Omar!' She scooped him up in the biggest hug.",
                "'I will hold your hand the whole time, I promise!' Omar said. He never let go again."
            ], coverSymbol: "figure.2.and.child.holdinghands")
        ]
        
        // MARK: - FANTASY
        items += [
            ReadingItem(id: "fa1", title: "The Unicorn in the Garden", author: "EZ Fantasy", genre: .fantasy, level: 2, summary: "A unicorn visits a garden.", fullText: "", bookType: .shortStory, chapters: [
                "Lucy woke up to a strange sound outside her window. It was soft, like bells tinkling.",
                "She peeked through the curtain. Something beautiful and white stood in the garden!",
                "A unicorn! It had a shimmering golden horn and a mane that sparkled in the moonlight.",
                "The unicorn was gently eating the roses. Each flower it touched turned silver.",
                "Lucy tiptoed outside in her pajamas. Her heart beat fast with excitement.",
                "'Hello,' she whispered. The unicorn turned to look at her with kind, deep eyes.",
                "It bowed its head gently. Lucy could hardly believe it.",
                "She reached out her hand. The unicorn stepped closer and let her touch its mane.",
                "It was softer than silk, softer than clouds, softer than anything Lucy had ever felt.",
                "Then, with a graceful leap, the unicorn jumped over the garden fence!",
                "It galloped into the dark woods, its horn glowing like a little star. Then it was gone.",
                "Was it a dream? Lucy looked down. In her hand was a single white hair, shining like silver. It was real."
            ], coverSymbol: "sparkles"),
            ReadingItem(id: "fa2", title: "The Enchanted Forest", author: "EZ Fantasy", genre: .fantasy, level: 4, summary: "A forest where trees can talk.", fullText: "", bookType: .shortStory, chapters: [
                "Mara was lost. The regular path had disappeared behind her.",
                "She found herself in a strange forest where the trees were enormous and ancient.",
                "Then she noticed something amazing—the trees had faces! Carved naturally in their bark.",
                "One tree whispered, 'Wrong way, little one.' Its branches pointed left.",
                "Mara gasped. 'Did you just talk?' The tree's bark shifted into a smile.",
                "'All trees talk,' said another. 'Humans just forgot how to listen.'",
                "Mara went left, as the tree suggested. The path lit up with glowing mushrooms.",
                "A tiny fairy appeared, hovering in the air like a firefly. 'You trusted the trees,' she said. 'That means you have a kind heart.'",
                "The fairy reached into a beam of moonlight and pulled out a golden leaf.",
                "'This leaf will always guide you home,' the fairy said. 'Hold it up and follow its glow.'",
                "Mara held up the leaf. It glowed softly and pointed her down a winding path.",
                "Within minutes, she was back at the edge of the forest. She kept the golden leaf forever—a reminder that magic is real for those who listen."
            ], coverSymbol: "tree.fill")
        ]
        
        // MARK: - POETRY
        items += [
            ReadingItem(id: "p1", title: "The Wind", author: "EZ Poetry", genre: .poetry, level: 1, summary: "A poem about the wind.", fullText: "", bookType: .shortStory, chapters: [
                "The wind blows soft,\nAcross the morning sky.\nIt tickles the flowers\nAs it goes floating by.",
                "The wind blows loud,\nThrough the trees so tall.\nIt shakes the branches\nAnd makes the acorns fall.",
                "It pushes the clouds\nLike boats across the blue.\nBig fluffy shapes—\nA rabbit! A shoe!",
                "It brings the rain\nWith a whoosh and a swirl.\nIt spins the leaves\nIn a wonderful twirl.",
                "It dries the puddles\nWhen the storm is through.\nThe wind is invisible—\nBut I know it's true.",
                "I cannot see the wind,\nBut I feel it on my face.\nIn my hair, on my skin,\nIt touches every place.",
                "The wind is like a friend\nThat follows me all day.\nSometimes it whispers,\nSometimes it wants to play.",
                "The wind blows soft.\nThe wind blows loud.\nI close my eyes\nAnd feel it—proud.",
                "The wind is everywhere,\nThe wind is free.\nThe wind is my friend,\nAnd it belongs to me."
            ], coverSymbol: "wind"),
            ReadingItem(id: "p2", title: "Seashells", author: "EZ Poetry", genre: .poetry, level: 2, summary: "A poem about the beach.", fullText: "", bookType: .shortStory, chapters: [
                "White shells, pink shells,\nTiny ones and small.\nI collect them in my bucket\nAs I walk along the shore.",
                "Some are curled like little ears,\nSmooth and round and bright.\nI hold one up against the sun—\nIt glows with golden light.",
                "I press a big one to my ear\nAnd listen very close.\nI hear the ocean whispering\nThe things I love the most.",
                "The waves say 'Hello!'\nThe foam says 'Stay!'\nThe sand between my toes says\n'Let's play all day!'",
                "The sun is warm upon my back,\nThe breeze is soft and cool.\nThe beach is nature's playground—\nBetter than any pool!",
                "Each shell tells a story\nOf somewhere deep and blue,\nWhere fish and starfish danced\nAnd the coral gardens grew.",
                "I take my treasures home with me\nIn a jar upon my shelf.\nSeashells from the deep blue sea—\nI found them by myself.",
                "And when the winter comes around\nAnd snow falls soft and white,\nI hold my shells and hear the waves\nAnd dream of summer's light."
            ], coverSymbol: "water.waves"),
            ReadingItem(id: "p3", title: "My Shadow", author: "EZ Poetry", genre: .poetry, level: 2, summary: "A poem about shadows.", fullText: "", bookType: .shortStory, chapters: [
                "I have a little shadow\nThat goes everywhere with me.\nIn the morning it is tiny,\nBy afternoon it's free!",
                "When the sun is right above me,\nMy shadow hides below.\nBut when the sun is sinking,\nWatch my shadow grow and grow!",
                "I wave my arms—it waves them too.\nI kick my feet—it kicks!\nI do a silly little dance,\nAnd it copies all my tricks.",
                "I run fast—my shadow runs!\nI jump high—it jumps along!\nWe play together all day long\nLike a silent shadow song.",
                "On a cloudy day, my shadow hides.\nWhere does it go? I never know!\nBut when the sun peeks out again,\nThere it is—hello!",
                "At nighttime, shadows come from lights.\nThey stretch across the wall.\nI make a bunny with my hands—\nThe biggest bunny of them all!",
                "My shadow is my quiet twin,\nMy partner, dark and true.\nIt never speaks a single word,\nBut follows in my shoe.",
                "I love my little shadow friend.\nWe'll never be apart.\nEven though it makes no sound,\nIt shadows my whole heart."
            ], coverSymbol: "person.fill"),
            ReadingItem(id: "p4", title: "Fireflies", author: "EZ Poetry", genre: .poetry, level: 1, summary: "A poem about summer nights.", fullText: "", bookType: .shortStory, chapters: [
                "The sun has gone to sleep now,\nThe sky is dark and deep.\nBut tiny lights are waking up—\nThey don't want to sleep!",
                "Flash! Flash! Fireflies!\nBlinking in the dark.\nEach one is a tiny lamp,\nEach one is a spark.",
                "I run into the backyard\nWith my jar held tight.\nI want to catch a firefly\nAnd keep its little light.",
                "One lands upon my finger!\nIt glows a yellow-green.\nThe prettiest little bug\nThat I have ever seen.",
                "I watch it blink and sparkle,\nThen open up its wings.\nIt flies back to its family—\nThe night is full of things!",
                "The crickets play their music,\nThe frogs begin to croak.\nThe fireflies are dancing\nBeneath the old oak.",
                "I lie down in the soft grass\nAnd watch the show above.\nFireflies and stars together—\nA sky full of love.",
                "Magic lives in summer nights\nWhen fireflies come to play.\nI close my eyes and wish upon\nTheir glow until the day."
            ], coverSymbol: "sparkles"),
            ReadingItem(id: "p5", title: "The Moon", author: "EZ Poetry", genre: .poetry, level: 2, summary: "A poem about the moon.", fullText: "", bookType: .shortStory, chapters: [
                "The moon is a silver boat\nThat sails across the night.\nIt floats above the sleeping world\nAnd fills it up with light.",
                "Sometimes the moon is full and round,\nA glowing golden ball.\nIt shines so bright you'd almost think\nIt's daytime after all!",
                "Sometimes it's just a tiny slice,\nA crescent thin and new.\nA smile hung up in the sky\nJust winking down at you.",
                "The moon sees everything below—\nThe mountains and the seas,\nThe cities lit with tiny lights,\nThe wind that bends the trees.",
                "It watches children fall asleep\nAnd tucks them in with light.\nIt whispers through the window,\n'Sweet dreams. Sleep tight.'",
                "The moon never gets tired.\nIt doesn't need to rest.\nIt keeps watch through every darkness—\nThe sky's most faithful guest.",
                "And when the sun comes up again\nAnd paints the sky with gold,\nThe moon slips softly out of sight—\nIts story gently told.",
                "Good night, moon. Good night, stars.\nGood night, world so wide.\nI'll see you when the dark comes back\nAnd you begin your ride."
            ], coverSymbol: "moon.fill")
        ]
        
        // MARK: - BIOGRAPHY
        items += [
            ReadingItem(id: "b1", title: "Helen Keller", author: "EZ Biographies", genre: .biography, level: 3, summary: "She could not see or hear. She learned to read and write.", fullText: "", bookType: .shortStory, chapters: [
                "Helen Keller was born in Alabama in 1880. She was a happy, healthy baby.",
                "But when Helen was just one year old, she became very sick with a high fever.",
                "The sickness took away her sight and hearing. Helen lived in a world of darkness and silence.",
                "As Helen grew, she became frustrated. She could not talk. She could not understand anyone.",
                "Her parents were worried. Then they found a teacher named Annie Sullivan.",
                "Annie was patient and clever. She spelled words into Helen's hand using sign language.",
                "One day, Annie held Helen's hand under running water and spelled W-A-T-E-R.",
                "Helen understood! Water! That cool wet thing had a name! Everything had a name!",
                "From that moment, Helen learned word after word after word. She was unstoppable!",
                "Helen learned to read using Braille. She learned to write. She even learned to speak!",
                "She went to college and became one of the most famous people in the world.",
                "Helen showed everyone that no obstacle is too big. With courage and help, anything is possible."
            ], coverSymbol: "person.crop.circle.fill"),
            ReadingItem(id: "b2", title: "Jane Goodall", author: "EZ Biographies", genre: .biography, level: 4, summary: "A scientist who lived with chimpanzees.", fullText: "", bookType: .shortStory, chapters: [
                "When Jane Goodall was a little girl in England, she loved animals more than anything.",
                "She dreamed of going to Africa to study wild animals in their natural home.",
                "At age 26, her dream came true. She traveled to Tanzania, a country in East Africa.",
                "Jane went to a place called Gombe, deep in the forest by a beautiful lake.",
                "She sat quietly among the trees and watched chimpanzees from far away.",
                "At first, the chimps were afraid of her. So Jane waited, day after day.",
                "Slowly, the chimpanzees grew used to her. One she named David Greybeard.",
                "Jane made an amazing discovery—chimps used tools! They poked sticks into termite holes to fish out bugs to eat.",
                "Scientists were shocked. Only humans were supposed to use tools!",
                "Jane spent years with the chimps. She learned they have families, feelings, and friendships—just like us.",
                "She wrote books and gave speeches all around the world to protect chimpanzees and their forests.",
                "Today Jane Goodall is a hero for animals everywhere. She shows us that every person can make a difference."
            ], coverSymbol: "leaf.fill")
        ]
        
        // MARK: - NONFICTION, SCI-FI, HISTORY (existing + more)
        items += [
            ReadingItem(id: "n1", title: "Dogs Help Us", author: "EZ Science", genre: .nonfiction, level: 1, summary: "How dogs help people.", fullText: "", bookType: .shortStory, chapters: [
                "Dogs are one of the best friends humans have ever had!",
                "Some dogs are called guide dogs. They help people who cannot see.",
                "A guide dog walks beside its owner and keeps them safe from danger.",
                "Other dogs are rescue dogs. They use their amazing noses to find people lost in snow or rubble.",
                "Police dogs help officers catch bad guys. They can sniff out hidden things.",
                "Therapy dogs visit hospitals and schools to make people feel happy and calm.",
                "Some dogs are trained to help people in wheelchairs open doors and pick things up.",
                "Dogs on farms help herd sheep and protect animals from predators.",
                "Dogs can even be trained to sense when their owner is about to get sick!",
                "Dogs come in all shapes and sizes—big dogs, tiny dogs, fluffy dogs, and smooth dogs.",
                "No matter what kind, dogs are loyal, loving, and always happy to see us.",
                "Dogs truly are our best friends. They help us and love us every single day!"
            ], coverSymbol: "dog.fill"),
            ReadingItem(id: "n4", title: "Facts About Frogs", author: "EZ Science", genre: .nonfiction, level: 2, summary: "Learn how frogs live and grow.", fullText: "", bookType: .shortStory, chapters: [
                "Frogs are amazing creatures called amphibians. That means they can live in water AND on land!",
                "A frog's life begins as a tiny egg in the water. Mother frogs can lay thousands of eggs!",
                "The eggs hatch into tadpoles. Tadpoles look like little fish with wiggly tails.",
                "Slowly, the tadpole grows tiny legs. First the back legs, then the front legs!",
                "Its tail gets shorter and shorter until it disappears completely.",
                "Now it's a frog! It can hop on land and swim in water.",
                "Frogs eat bugs, flies, and worms. They catch them with their super long, sticky tongues!",
                "A frog's tongue can snap out and catch a fly faster than you can blink your eye.",
                "Some frogs are tiny—smaller than a penny! Others are as big as a dinner plate.",
                "Many frogs are green or brown to blend in with leaves and mud. That's called camouflage!",
                "Some frogs are bright red, blue, or yellow. These colors warn predators: 'Don't eat me!'",
                "Frogs are important because they eat mosquitoes and tell us if our rivers and ponds are healthy."
            ], coverSymbol: "leaf.fill"),
            ReadingItem(id: "s1", title: "The Robot Pet", author: "EZ Sci-Fi", genre: .scifi, level: 1, summary: "A robot dog that can talk.", fullText: "", bookType: .shortStory, chapters: [
                "Zoe opened her birthday present and gasped. Inside the box was a shiny robot dog!",
                "It was silver with bright blue eyes. When she pressed the button, it said, 'Hello! I am Chip!'",
                "Chip could run and fetch, just like a real dog. His tail wagged when he was happy.",
                "He did not need food or water. Instead, he needed batteries to keep running.",
                "Chip could play fetch with a ball. He always brought it right back!",
                "He could sit, shake hands, and even do a backflip!",
                "Zoe's friends loved Chip. 'Can he do tricks?' they asked. 'Watch this!' said Zoe.",
                "Chip danced in a circle and played a little song. Everyone clapped!",
                "At night, Chip slept in his special charging station. His eyes glowed softly.",
                "One day, Chip said something new. 'Zoe, you are my best friend.'",
                "Zoe hugged her robot pet. 'You're my best friend too, Chip!'",
                "A robot dog might not be a real dog, but the friendship was one hundred percent real."
            ], coverSymbol: "cpu"),
            ReadingItem(id: "s7", title: "Space Station Omega", author: "EZ Sci-Fi", genre: .scifi, level: 4, summary: "A mystery on a space station.", fullText: "", bookType: .shortStory, chapters: [
                "The alarm woke Commander Jen at 0300 hours. Red lights flashed across her cabin.",
                "She floated down the corridor in zero gravity to the control room. Something was wrong.",
                "The screens showed empty space. All systems normal. But Jen heard a sound—knock, knock, knock.",
                "It was coming from OUTSIDE the station. That was impossible. Nothing was out there!",
                "Jen pulled on her space suit and opened the outer airlock. Stars surrounded her in every direction.",
                "There, attached to the station hull, was a small silver probe she had never seen before.",
                "On it was written in glowing letters: 'Help. We are coming.'",
                "Jen carefully detached the probe and brought it inside. Her hands were shaking.",
                "She called Mission Control on Earth. 'You need to see this,' she said.",
                "'Open it carefully,' they instructed. Inside was a crystal that contained a message.",
                "The message read: 'We are friends. We have traveled far. We need help finding a new home.'",
                "Jen smiled and pressed the reply button on the crystal. 'Welcome. We're glad you found us.' First contact had been made."
            ], coverSymbol: "sparkles"),
            ReadingItem(id: "h1", title: "The First Thanksgiving", author: "EZ History", genre: .history, level: 1, summary: "A simple story of the first Thanksgiving.", fullText: "", bookType: .shortStory, chapters: [
                "A long time ago, a group of people called Pilgrims wanted a new home.",
                "They climbed aboard a big ship called the Mayflower and sailed across the ocean.",
                "The journey was long and hard. The waves were big and the wind was cold.",
                "Finally, they reached a new land called Plymouth. But winter was coming!",
                "The winter was very cold and harsh. Many people got sick.",
                "Then the Wampanoag people came to help. They were kind and generous.",
                "They showed the Pilgrims how to plant corn, squash, and beans.",
                "They taught them how to fish and which berries were safe to eat.",
                "When fall came, the crops were ready! There was so much food!",
                "The Pilgrims and Wampanoag had a big feast together. It lasted three days!",
                "They gave thanks for the food, for their health, and for new friends.",
                "That was the first Thanksgiving. And we still celebrate giving thanks today!"
            ], coverSymbol: "leaf.fill"),
            ReadingItem(id: "h4", title: "Rosa Parks", author: "EZ History", genre: .history, level: 2, summary: "She would not give up her seat.", fullText: "", bookType: .shortStory, chapters: [
                "In 1955, Rosa Parks lived in Montgomery, Alabama. Life was unfair for Black Americans.",
                "There were separate water fountains, schools, and even seats on the bus.",
                "Black people had to sit in the back of the bus. If a white person needed a seat, they had to give theirs up.",
                "One December evening, Rosa got on the bus after a long day of work. She sat down and rested her tired feet.",
                "The bus filled up. The driver told Rosa to give her seat to a white passenger.",
                "Rosa looked up calmly. She thought about all the unfairness. And she said, 'No.'",
                "The bus driver called the police. Rosa was arrested for breaking the unfair law.",
                "But Rosa's bravery inspired thousands of people. They decided to boycott the buses.",
                "For more than a year, Black citizens walked, carpooled, and rode bikes instead of taking the bus.",
                "The bus company lost so much money that they had to change the rules!",
                "The Supreme Court said the law was wrong. Everyone could now sit wherever they chose.",
                "Rosa Parks showed the world that one person's courage can change an entire nation."
            ], coverSymbol: "bus.fill"),
            ReadingItem(id: "n5", title: "The Solar System", author: "EZ Science", genre: .nonfiction, level: 2, summary: "Our sun and its planets.", fullText: "", bookType: .shortStory, chapters: [
                "Our solar system is an amazing neighborhood in space!",
                "At the center is the Sun—a giant, blazing star that gives us light and warmth.",
                "Mercury is the closest planet to the Sun. It's tiny, fast, and very, very hot!",
                "Venus comes next. It's covered in thick clouds and is the hottest planet of all!",
                "Earth is our home—the third planet. It's the only one we know that has life!",
                "Mars is called the Red Planet because its soil is rusty red. Robots explore it!",
                "Jupiter is HUGE—the biggest planet! It has a giant storm called the Great Red Spot.",
                "Saturn is famous for its beautiful rings, made of ice and rocks spinning around it.",
                "Uranus is a funny planet—it rolls on its side like a ball!",
                "Neptune is the farthest planet. It's cold, blue, and very windy.",
                "There are also asteroids, comets, and dwarf planets zooming through our solar system.",
                "Our solar system is just one of billions in our galaxy, the Milky Way. Space is truly amazing!"
            ], coverSymbol: "globe.americas.fill"),
            ReadingItem(id: "n6", title: "How Plants Grow", author: "EZ Science", genre: .nonfiction, level: 1, summary: "From seed to flower.", fullText: "", bookType: .shortStory, chapters: [
                "Every plant starts as a tiny seed. Seeds come in many shapes and sizes!",
                "To grow, a seed needs three things: soil, water, and sunshine.",
                "First, we put the seed gently into the soft, dark soil.",
                "We give it a drink of water. The water soaks down to the seed.",
                "Inside the soil, the seed begins to crack open. Something is growing!",
                "A tiny root pushes down, down, down into the earth. It drinks up water.",
                "Then a little green stem pushes up, up, up toward the light!",
                "The stem breaks through the soil and reaches for the sun. Hello, world!",
                "Little green leaves unfold. They soak up sunlight like tiny solar panels.",
                "The plant grows taller. More leaves appear. The stem gets stronger.",
                "One day, a bud appears at the top. It gets bigger and bigger and then—POP!",
                "A beautiful flower opens! Bees come to visit, and soon there will be new seeds. The cycle starts all over again!"
            ], coverSymbol: "leaf.fill"),
            ReadingItem(id: "s2", title: "The Time Machine", author: "EZ Sci-Fi", genre: .scifi, level: 2, summary: "A boy visits the future for one hour.", fullText: "", bookType: .shortStory, chapters: [
                "Jordan was cleaning the garage when he found something strange behind the old boxes.",
                "It was a silver remote control with one big button. The button said FUTURE.",
                "Jordan looked around. Should he press it? His curiosity won. CLICK!",
                "Everything blurred like a spinning top. Colors swirled around him. Then it stopped.",
                "Jordan was in the same garage. But the calendar on the wall said 2050!",
                "He ran outside. Flying cars zoomed through the sky! Buildings were made of glass!",
                "A friendly robot rolled up to him. 'Welcome, time traveler. You have one hour.'",
                "Jordan explored the future. There were robot teachers, hologram pets, and pizza that appeared from thin air!",
                "Kids played in floating parks high above the ground. Everything was amazing!",
                "Then the robot said, 'Your time is almost up.' Jordan felt the world start to blur again.",
                "He was back in the garage. The same dusty, normal garage. The remote was gone!",
                "Was it real? Jordan wasn't sure. But he smiled. The future was going to be incredible."
            ], coverSymbol: "clock.arrow.circlepath"),
            ReadingItem(id: "s3", title: "Robot at School", author: "EZ Sci-Fi", genre: .scifi, level: 3, summary: "A robot joins the class for a day.", fullText: "", bookType: .shortStory, chapters: [
                "Monday morning, Class 3B got a big surprise. A shiny silver robot rolled through the door!",
                "'Good morning! My name is R3,' the robot said in a cheerful voice. 'I am here to learn!'",
                "The teacher smiled. 'Welcome, R3. Let's see what you can do.'",
                "In math class, R3 solved every problem in two seconds flat. The class stared with open mouths!",
                "In art class, R3 painted a picture of the whole school. Every tiny detail was perfect.",
                "But then came lunchtime. R3 sat at the table but couldn't eat anything. 'I do not have a stomach,' it said sadly.",
                "The kids gave R3 a pretend sandwich made from paper. 'Delicious!' R3 said, and everyone laughed.",
                "At recess, R3 played tag. It was SO fast! Nobody could catch it!",
                "But then R3 tripped on a rock and fell over. The kids rushed to help. 'Are you okay?'",
                "R3's lights flickered. 'I am okay. Thank you for caring about me.'",
                "At the end of the day, R3 had to go. 'What did you learn today?' the teacher asked.",
                "'I learned that friends are the best part of school,' said R3. The whole class cheered and gave R3 a group hug!"
            ], coverSymbol: "cpu"),
            ReadingItem(id: "h5", title: "The Wright Brothers", author: "EZ History", genre: .history, level: 3, summary: "The first airplane flight.", fullText: "", bookType: .shortStory, chapters: [
                "Wilbur and Orville Wright were two brothers who loved to build things.",
                "When they were young, their father gave them a toy helicopter. It could really fly!",
                "The brothers were fascinated. They wanted to build something bigger—something that could carry a person!",
                "They started a bicycle shop to earn money. But their real dream was to fly.",
                "They studied birds. They watched how wings moved in the wind. They read every book about flight.",
                "First, they built gliders—planes with no engines. They tested them on the windy hills of Kitty Hawk, North Carolina.",
                "Some gliders crashed. Some flew a little. Each failure taught them something new.",
                "They didn't give up. They built a wind tunnel to test different wing shapes.",
                "Finally, in December 1903, they built a plane with an engine. They called it the Flyer.",
                "On a cold, windy morning, Orville climbed into the plane. The engine roared to life!",
                "The Flyer lifted off the ground! It flew for twelve seconds and covered 120 feet!",
                "It was the first powered airplane flight in history! The Wright Brothers proved that humans could fly. The world would never be the same."
            ], coverSymbol: "airplane")
        ]
        
        // MARK: - INTERACTIVE BOOKS (tap to reveal, choices)
        items += [
            ReadingItem(id: "int1", title: "Tap the Magic Box", author: "EZ Interactive", genre: .fiction, level: 1, summary: "Tap to discover what is inside each magic box!", fullText: "", bookType: .interactive, coverSymbol: "sparkles", isInteractive: true, interactivePages: [
                InteractivePage(id: "p1", text: "A sparkly magic box sits on the table. It's wiggling! What could be inside? Tap the box to find out!", tapTargets: [InteractiveTapTarget(id: "box1", hiddenText: "A fluffy white kitten jumps out! Meow! 🐱", position: 0)]),
                InteractivePage(id: "p2", text: "The kitten looks around with big curious eyes. It's hungry! What should we give it? Tap each item:", tapTargets: [
                    InteractiveTapTarget(id: "milk", hiddenText: "A bowl of warm milk! The kitten laps it up happily. 🥛", position: 0),
                    InteractiveTapTarget(id: "fish", hiddenText: "A tiny fish treat! The kitten gobbles it up. Yum! 🐟", position: 1)
                ]),
                InteractivePage(id: "p3", text: "The kitten is full and sleepy now. Where should it sleep? Tap a cozy spot:", tapTargets: [
                    InteractiveTapTarget(id: "pillow", hiddenText: "A soft fluffy pillow! The kitten curls up and purrs. 😴", position: 0),
                    InteractiveTapTarget(id: "basket", hiddenText: "A warm blanket basket! The kitten snuggles in. So cozy!", position: 1)
                ]),
                InteractivePage(id: "p4", text: "Wait! There's another magic box! This one is blue and making funny sounds. Tap it!", tapTargets: [InteractiveTapTarget(id: "box2", hiddenText: "A tiny puppy pops out! Woof woof! 🐶 It wants to play!", position: 0)]),
                InteractivePage(id: "p5", text: "The puppy and the kitten look at each other. Will they be friends? Tap to see what happens:", tapTargets: [
                    InteractiveTapTarget(id: "sniff", hiddenText: "They sniff each other's noses... then start playing together! Best friends! 🐱🐶", position: 0)
                ]),
                InteractivePage(id: "p6", text: "One more box! A golden one with stars on it. It's the biggest one yet! Tap the golden box:", tapTargets: [InteractiveTapTarget(id: "box3", hiddenText: "SURPRISE! It's full of toys for the kitten and puppy! Balls, feathers, and squeaky toys! 🎉", position: 0)]),
                InteractivePage(id: "p7", text: "The kitten plays with feathers. The puppy chases a ball. They are SO happy! Tap each animal to hear what they say:", tapTargets: [
                    InteractiveTapTarget(id: "kitty_say", hiddenText: "Purrrr... this is the best day ever! Thank you for opening the magic boxes!", position: 0),
                    InteractiveTapTarget(id: "puppy_say", hiddenText: "Woof woof! You are my favorite person! Can we play again tomorrow?", position: 1)
                ]),
                InteractivePage(id: "p8", text: "The kitten and the puppy curl up together for a nap. Tap the stars to say goodnight:", tapTargets: [
                    InteractiveTapTarget(id: "star1", hiddenText: "⭐ Goodnight, kitten!", position: 0),
                    InteractiveTapTarget(id: "star2", hiddenText: "⭐ Goodnight, puppy!", position: 1),
                    InteractiveTapTarget(id: "star3", hiddenText: "⭐ Sweet dreams, little friends! The End! 🌙", position: 2)
                ])
            ]),
            ReadingItem(id: "int2", title: "Choose Your Pet Adventure", author: "EZ Interactive", genre: .fiction, level: 2, summary: "Pick a pet and go on an adventure! Every choice leads somewhere new.", fullText: "", bookType: .interactive, coverSymbol: "pawprint.fill", isInteractive: true, interactivePages: [
                InteractivePage(id: "c1", text: "Welcome to the Pet Shop! Three animals are waiting for you. Tap each one to learn about them:", tapTargets: [
                    InteractiveTapTarget(id: "dog_info", hiddenText: "🐕 A golden retriever named Buddy! He loves to fetch, swim, and go for walks. He wags his tail so fast!", position: 0),
                    InteractiveTapTarget(id: "cat_info", hiddenText: "🐈 A fluffy orange cat named Marmalade! She loves to nap in sunbeams and chase string.", position: 1),
                    InteractiveTapTarget(id: "bird_info", hiddenText: "🦜 A blue parakeet named Skye! She can whistle songs and loves to sit on your shoulder.", position: 2)
                ]),
                InteractivePage(id: "c2", text: "You take your new pet home! But first, you need supplies. Tap what you need:", tapTargets: [
                    InteractiveTapTarget(id: "food_bowl", hiddenText: "A food bowl! Every pet needs yummy food. Your pet gobbles it right up!", position: 0),
                    InteractiveTapTarget(id: "bed", hiddenText: "A cozy pet bed! Your new friend needs a comfy place to sleep.", position: 1),
                    InteractiveTapTarget(id: "toy", hiddenText: "A toy! A ball for a dog, a feather for a cat, or a mirror for a bird!", position: 2)
                ]),
                InteractivePage(id: "c3", text: "Your pet is at home and wants to play! Something is hiding in the yard. Tap to search:", tapTargets: [
                    InteractiveTapTarget(id: "bush", hiddenText: "Behind the bush — a squeaky rubber duck! Your pet loves it!", position: 0),
                    InteractiveTapTarget(id: "under_porch", hiddenText: "Under the porch — a friendly frog! It hops away. Ribbit!", position: 1),
                    InteractiveTapTarget(id: "tree", hiddenText: "In the tree — a squirrel! It chatters and drops an acorn.", position: 2)
                ]),
                InteractivePage(id: "c4", text: "Oh no! Your pet ran into the neighbor's yard chasing a butterfly! Tap to find your pet:", tapTargets: [
                    InteractiveTapTarget(id: "garden", hiddenText: "In the flower garden! Your pet is sniffing all the pretty flowers. Found you!", position: 0),
                    InteractiveTapTarget(id: "shed", hiddenText: "Behind the shed! Your pet is playing with the neighbor's pet. New friend!", position: 1)
                ]),
                InteractivePage(id: "c5", text: "Time for a bath! Your pet got dirty playing outside. Tap the bath supplies:", tapTargets: [
                    InteractiveTapTarget(id: "water", hiddenText: "Splash! Warm water fills the tub. Your pet looks nervous but it's okay!", position: 0),
                    InteractiveTapTarget(id: "soap", hiddenText: "Bubble bubble! The pet shampoo makes so many bubbles! Your pet has a bubble beard!", position: 1),
                    InteractiveTapTarget(id: "towel", hiddenText: "Rub rub! A fluffy towel dries your pet off. SHAKE! Water goes everywhere! 😂", position: 2)
                ]),
                InteractivePage(id: "c6", text: "Clean and dry! Your pet is tired from such a big day. Tap to tuck them into bed:", tapTargets: [
                    InteractiveTapTarget(id: "blanket_pet", hiddenText: "You pull a soft blanket over your pet. It sighs happily and closes its eyes.", position: 0),
                    InteractiveTapTarget(id: "kiss", hiddenText: "You give your pet a gentle kiss on the head. 'Goodnight, best friend.' Sweet dreams! 💤", position: 1)
                ])
            ]),
            ReadingItem(id: "int3", title: "Secret Garden Discovery", author: "EZ Interactive", genre: .fiction, level: 2, summary: "Explore a magical garden and discover what's hiding in every corner!", fullText: "", bookType: .interactive, coverSymbol: "camera.macro", isInteractive: true, interactivePages: [
                InteractivePage(id: "g1", text: "You found a hidden door behind the old wall! It's covered in ivy. Tap the door to open it:", tapTargets: [InteractiveTapTarget(id: "door", hiddenText: "CREAK! The door swings open and you see... a beautiful secret garden! Flowers everywhere! 🌸🌺🌻", position: 0)]),
                InteractivePage(id: "g2", text: "The garden is amazing! Three paths lead in different directions. Tap a flower to follow its path:", tapTargets: [
                    InteractiveTapTarget(id: "red_flower", hiddenText: "🌹 A rose! You follow the red path to a little pond with goldfish!", position: 0),
                    InteractiveTapTarget(id: "yellow_flower", hiddenText: "🌻 A sunflower! You follow the yellow path to a meadow full of butterflies!", position: 1),
                    InteractiveTapTarget(id: "purple_flower", hiddenText: "💜 Lavender! You follow the purple path to a cozy bench under a willow tree!", position: 2)
                ]),
                InteractivePage(id: "g3", text: "Something is buzzing around your head! Tap to see what it is:", tapTargets: [
                    InteractiveTapTarget(id: "bee", hiddenText: "🐝 A friendly bee! It lands on a flower and starts collecting nectar. Buzz buzz!", position: 0),
                    InteractiveTapTarget(id: "butterfly_garden", hiddenText: "🦋 A beautiful monarch butterfly! It has orange and black wings. So pretty!", position: 1)
                ]),
                InteractivePage(id: "g4", text: "You hear a trickling sound. There's a fountain in the middle of the garden! Tap to look closer:", tapTargets: [
                    InteractiveTapTarget(id: "fountain", hiddenText: "The fountain has crystal clear water. You can see tiny fish swimming! There are also shiny coins at the bottom. 🪙", position: 0),
                    InteractiveTapTarget(id: "wish", hiddenText: "You toss a coin in and make a wish. Splash! The water sparkles in the sunlight. ✨", position: 1)
                ]),
                InteractivePage(id: "g5", text: "A little fairy appears! She's tiny with sparkly wings. Tap to talk to her:", tapTargets: [
                    InteractiveTapTarget(id: "fairy_hello", hiddenText: "'Welcome to our secret garden!' she says in a tiny voice. 'We've been waiting for someone kind to visit!'", position: 0),
                    InteractiveTapTarget(id: "fairy_gift", hiddenText: "She hands you a tiny glowing seed. 'Plant this anywhere and magic flowers will grow!' 🌟", position: 1)
                ]),
                InteractivePage(id: "g6", text: "You plant the magic seed in a special spot. Tap to water it:", tapTargets: [InteractiveTapTarget(id: "water_seed", hiddenText: "Sprinkle sprinkle! The seed glows... then WHOOSH! A rainbow flower grows! It has every color you can imagine! 🌈", position: 0)]),
                InteractivePage(id: "g7", text: "The garden is now your special place. Before you go, tap each friend to say goodbye:", tapTargets: [
                    InteractiveTapTarget(id: "bye_fairy", hiddenText: "The fairy waves her tiny hand. 'Come back anytime! The garden will always be here for you!' 🧚", position: 0),
                    InteractiveTapTarget(id: "bye_bee", hiddenText: "The bee does a little dance in the air. That's how bees say goodbye! 🐝", position: 1),
                    InteractiveTapTarget(id: "bye_butterfly", hiddenText: "The butterfly lands on your nose for just a second, then flies away. 🦋 See you next time!", position: 2)
                ])
            ]),
            ReadingItem(id: "int4", title: "Space Explorer", author: "EZ Interactive", genre: .scifi, level: 3, summary: "Blast off into space! Discover planets, stars, and aliens!", fullText: "", bookType: .interactive, coverSymbol: "sparkles", isInteractive: true, interactivePages: [
                InteractivePage(id: "s1", text: "You're an astronaut! Your rocket is ready. Tap the launch button to blast off:", tapTargets: [InteractiveTapTarget(id: "launch", hiddenText: "3... 2... 1... BLAST OFF! 🚀 Your rocket zooms into the sky! The Earth gets smaller and smaller below you!", position: 0)]),
                InteractivePage(id: "s2", text: "You're in space! Stars are everywhere. Tap each space object to learn about it:", tapTargets: [
                    InteractiveTapTarget(id: "moon_tap", hiddenText: "🌙 The Moon! It's covered in craters and has no air. Astronauts left footprints there that will last forever!", position: 0),
                    InteractiveTapTarget(id: "sun_tap", hiddenText: "☀️ The Sun! It's a giant ball of fire, a million times bigger than Earth! Don't fly too close!", position: 1),
                    InteractiveTapTarget(id: "star_tap", hiddenText: "⭐ A distant star! Each star you see is actually another sun, very very far away!", position: 2)
                ]),
                InteractivePage(id: "s3", text: "You see a red planet ahead! It's Mars! Tap to land on it:", tapTargets: [InteractiveTapTarget(id: "land_mars", hiddenText: "Your rocket touches down on the red dusty surface! Everything is quiet. You leave the first footprints! 👣", position: 0)]),
                InteractivePage(id: "s4", text: "On Mars, you find something amazing! Tap each discovery:", tapTargets: [
                    InteractiveTapTarget(id: "rock", hiddenText: "A sparkly red rock! It shimmers in the sunlight. You put it in your space bag. 🪨", position: 0),
                    InteractiveTapTarget(id: "ice", hiddenText: "Frozen water under the ground! That means life could exist here someday! 🧊", position: 1),
                    InteractiveTapTarget(id: "cave", hiddenText: "A mysterious cave! You peek inside and see something glowing... what could it be?", position: 2)
                ]),
                InteractivePage(id: "s5", text: "Inside the cave, something is glowing green! Tap to get closer:", tapTargets: [InteractiveTapTarget(id: "alien", hiddenText: "It's a tiny friendly alien! It has big eyes and a cute smile! 👽 It waves at you. 'Hello, Earth friend!'", position: 0)]),
                InteractivePage(id: "s6", text: "The alien wants to show you something. Tap to follow:", tapTargets: [
                    InteractiveTapTarget(id: "alien_home", hiddenText: "It leads you to an underground city! Little aliens everywhere, all friendly and curious about you! 🏙️", position: 0),
                    InteractiveTapTarget(id: "alien_gift", hiddenText: "The aliens give you a glowing crystal. 'This will help you always find your way home,' they say. 💎", position: 1)
                ]),
                InteractivePage(id: "s7", text: "It's time to go home. The aliens wave goodbye. Tap to fly back to Earth:", tapTargets: [
                    InteractiveTapTarget(id: "fly_home", hiddenText: "Your rocket zooms back through space! You see Earth — blue and beautiful! Home sweet home! 🌍", position: 0),
                    InteractiveTapTarget(id: "land_home", hiddenText: "SPLASH! You land safely. Everyone cheers! You're a real space explorer now! 🎉", position: 1)
                ])
            ]),
            ReadingItem(id: "int5", title: "Underwater Mystery", author: "EZ Interactive", genre: .adventure, level: 2, summary: "Dive deep into the ocean and discover amazing sea creatures!", fullText: "", bookType: .interactive, coverSymbol: "water.waves", isInteractive: true, interactivePages: [
                InteractivePage(id: "u1", text: "You put on your diving suit and jump into the ocean! SPLASH! Tap to dive deeper:", tapTargets: [InteractiveTapTarget(id: "dive", hiddenText: "Down, down, down you go! The water turns from light blue to dark blue. You can see colorful fish everywhere! 🐠", position: 0)]),
                InteractivePage(id: "u2", text: "A school of fish swims by! Tap each type to learn about them:", tapTargets: [
                    InteractiveTapTarget(id: "clown_fish", hiddenText: "🐠 A clownfish! It lives inside a sea anemone. The anemone protects it from predators!", position: 0),
                    InteractiveTapTarget(id: "angelfish", hiddenText: "🐟 An angelfish! It has beautiful stripes of blue, yellow, and white!", position: 1),
                    InteractiveTapTarget(id: "pufferfish", hiddenText: "🐡 A pufferfish! When scared, it puffs up like a balloon! Don't worry, it's just showing off.", position: 2)
                ]),
                InteractivePage(id: "u3", text: "You reach a coral reef — it's like an underwater city! Tap things to explore:", tapTargets: [
                    InteractiveTapTarget(id: "coral", hiddenText: "The coral is alive! It's made of tiny animals called polyps. So many colors — pink, purple, orange! 🪸", position: 0),
                    InteractiveTapTarget(id: "starfish", hiddenText: "⭐ A starfish on a rock! It has five arms and can regrow them if one breaks off!", position: 1),
                    InteractiveTapTarget(id: "seahorse", hiddenText: "A tiny seahorse! It holds onto coral with its curly tail. Did you know the dad seahorse carries the babies?", position: 2)
                ]),
                InteractivePage(id: "u4", text: "Something BIG is swimming toward you! Tap to see what it is:", tapTargets: [InteractiveTapTarget(id: "whale", hiddenText: "A gentle whale! 🐋 It's enormous but so peaceful. It sings a low, beautiful song that echoes through the water.", position: 0)]),
                InteractivePage(id: "u5", text: "The whale wants to show you a secret! It leads you to an underwater cave. Tap to enter:", tapTargets: [
                    InteractiveTapTarget(id: "enter_cave", hiddenText: "Inside the cave, the walls are covered in glowing blue light! Tiny glowing jellyfish float like lanterns! 🪼✨", position: 0),
                    InteractiveTapTarget(id: "treasure", hiddenText: "In the corner you see an old treasure chest! Inside are beautiful shells and sea glass — nature's treasure! 💎", position: 1)
                ]),
                InteractivePage(id: "u6", text: "What an adventure! Time to swim back to the surface. Tap each friend to wave goodbye:", tapTargets: [
                    InteractiveTapTarget(id: "bye_fish", hiddenText: "The clownfish blows a tiny bubble at you. Pop! That's a fish kiss! 🐠", position: 0),
                    InteractiveTapTarget(id: "bye_whale", hiddenText: "The whale sings one last song just for you. It sounds like the ocean saying 'Come back soon!' 🐋", position: 1),
                    InteractiveTapTarget(id: "bye_seahorse", hiddenText: "The seahorse waves its tiny fin. 'See you next time, ocean explorer!' 🌊", position: 2)
                ])
            ])
        ]
        
        // MARK: - COMPLETE STORY BOOKS (8-12 pages with full plots, characters, illustrations)
        
        // STORY 1: Luna the Brave Little Star
        items += [
            ReadingItem(id: "story_luna", title: "Luna the Brave Little Star", author: "EZ Story Books", genre: .fiction, level: 1, summary: "A small star learns that being different makes her special.", fullText: "", bookType: .pictureBook, chapters: [
                "High up in the night sky lived a tiny star named Luna. She was the smallest star in the whole galaxy, and she felt sad about it.",
                "All the other stars were big and bright. They lit up the sky like diamonds. But Luna was so small, she could barely be seen.",
                "\"I wish I was big like everyone else,\" Luna sighed. A passing comet heard her and stopped. \"Why would you want to be like everyone else?\" asked the comet.",
                "\"Because I'm too small to do anything important,\" Luna said with tears in her eyes.",
                "Just then, a little girl on Earth looked up at the sky. She was lost in the dark forest and very scared.",
                "\"Please, stars, help me find my way home,\" the girl whispered. But all the big stars were too bright—they hurt her eyes!",
                "Then the little girl spotted Luna's gentle glow. It was soft and kind, not too bright at all. \"That little star! I'll follow that one!\"",
                "Luna shined her very best as the girl walked through the forest, following her light. Step by step, the girl found her way.",
                "Finally, the little girl reached her home! She waved up at Luna. \"Thank you, little star! You saved me!\"",
                "Luna beamed with joy. She wasn't too small—she was just right! Sometimes being small means you can help in ways the big ones cannot.",
                "From that night on, Luna was proud to be the smallest star. And whenever a lost child needed help, Luna was there, shining gently.",
                "THE END. Remember: Being different is what makes you special!"
            ], coverSymbol: "star.fill"),
            
            // STORY 2: Benny the Bunny Who Couldn't Hop
            ReadingItem(id: "story_benny", title: "Benny the Bunny Who Couldn't Hop", author: "EZ Story Books", genre: .fiction, level: 1, summary: "A bunny learns there are many ways to get where you want to go.", fullText: "", bookType: .pictureBook, chapters: [
                "Benny was born with a leg that didn't work quite right. While other bunnies hopped through the meadow, Benny could only waddle slowly.",
                "\"Why can't I hop like everyone else?\" Benny asked his mom. She nuzzled him gently. \"You are perfect just the way you are, my love.\"",
                "But Benny didn't feel perfect. He felt left out when his friends raced through the grass.",
                "One day, a storm flooded the meadow. All the bunnies were trapped on their little island! \"Oh no! We can't hop across that water!\" they cried.",
                "But Benny had an idea. \"I may not hop well, but I can swim!\" And with his strong front legs, Benny paddled through the water.",
                "He found a big log and pushed it back to his friends. \"Climb on! I'll pull you across!\"",
                "One by one, Benny helped every bunny get to dry land. He was the hero of the day!",
                "\"Benny, you're amazing!\" cheered his friends. \"You saved us all!\"",
                "Benny's mom hugged him tight. \"See? Your difference became your superpower today.\"",
                "From then on, Benny never felt bad about not hopping. He knew that everyone has their own special talents.",
                "And whenever the meadow flooded, guess who led the rescue? That's right—Benny the Brave!",
                "THE END. Remember: Your differences can be your greatest strengths!"
            ], coverSymbol: "hare.fill"),
            
            // STORY 3: The Dragon Who Was Afraid of Fire
            ReadingItem(id: "story_dragon", title: "The Dragon Who Was Afraid of Fire", author: "EZ Story Books", genre: .fantasy, level: 2, summary: "A young dragon overcomes his fear to save his family.", fullText: "", bookType: .pictureBook, chapters: [
                "Ember was a young dragon with shiny green scales. But unlike other dragons, Ember was afraid of fire—even his own!",
                "When Ember tried to breathe fire, only a tiny puff of smoke came out. The other young dragons laughed at him.",
                "\"What kind of dragon is afraid of fire?\" they teased. Ember flew away to his secret cave to hide.",
                "His grandmother found him crying. \"Ember, fear is okay. Everyone is afraid of something. Being brave doesn't mean having no fear.\"",
                "\"What does it mean then?\" asked Ember. Grandma smiled. \"It means doing what's right even when you're scared.\"",
                "That night, lightning struck the dragon mountain! Fire spread everywhere, and the baby dragons were trapped!",
                "All the adult dragons were away hunting. Only Ember was there. His heart pounded with fear.",
                "But then he heard the babies crying. They needed him! Ember took a deep breath and flew toward the flames.",
                "The fire was hot and scary, but Ember kept going. He wrapped his big wings around the babies to protect them.",
                "Then something amazing happened—Ember breathed the biggest, brightest fire of his life, pushing back the other flames!",
                "When the adults returned, they found Ember and the babies safe. \"You saved them!\" they cheered. \"You're a hero, Ember!\"",
                "From that day on, Ember was never afraid again. He learned that true courage is helping others, even when you're scared.",
                "THE END. Remember: Being brave means doing the right thing, even when you're afraid!"
            ], coverSymbol: "flame.fill"),
            
            // STORY 4: Maya's Magic Garden
            ReadingItem(id: "story_maya", title: "Maya's Magic Garden", author: "EZ Story Books", genre: .fiction, level: 2, summary: "A girl learns that patience and kindness make things grow.", fullText: "", bookType: .pictureBook, chapters: [
                "Maya lived in a gray, dusty town where nothing grew. One day, she found a tiny seed on the ground.",
                "\"What are you?\" Maya whispered to the seed. It didn't answer, but Maya felt something special about it.",
                "She planted the seed in an old pot and gave it water. \"Please grow, little seed,\" she said kindly.",
                "Days passed. Nothing happened. \"Maybe it's broken,\" Maya thought. But she kept watering it anyway.",
                "One morning, Maya woke up to see a tiny green sprout! \"You're alive!\" she cheered, dancing around the room.",
                "Maya talked to her plant every day. She told it stories and sang it songs. The plant grew bigger and bigger!",
                "Soon, beautiful flowers bloomed—colors Maya had never seen before! The whole town came to look.",
                "\"How did you do this?\" they asked. \"With patience, water, and lots of love,\" Maya smiled.",
                "The neighbors wanted flowers too. Maya shared her seeds with everyone. \"Be kind to them,\" she said. \"Talk to them!\"",
                "Soon the whole town was blooming with color! Gardens filled every yard, and birds came to sing.",
                "The gray, dusty town became the most beautiful place in the land, all because of one small seed and one kind girl.",
                "THE END. Remember: With patience and love, amazing things can grow!"
            ], coverSymbol: "leaf.fill"),
            
            // STORY 5: Oliver's First Day of School
            ReadingItem(id: "story_oliver", title: "Oliver's First Day of School", author: "EZ Story Books", genre: .fiction, level: 1, summary: "An anxious owl discovers that school is full of friends.", fullText: "", bookType: .pictureBook, chapters: [
                "Oliver Owl clutched his new backpack tightly. Today was his first day at Woodland School, and his tummy was full of butterflies.",
                "\"What if no one likes me?\" Oliver whispered to his mom. She gave him a big hug. \"Be yourself, and you'll find friends.\"",
                "Oliver walked into the classroom. It was full of animals he had never met before. He felt very small and very scared.",
                "A friendly raccoon noticed Oliver standing alone. \"Hi! I'm Rosie! Want to sit with me?\" Oliver nodded shyly.",
                "Rosie showed Oliver where to put his backpack. \"I was scared on my first day too,\" she said. \"But now I love it here!\"",
                "In art class, Oliver drew a picture of the moon. \"Wow!\" said a fox named Felix. \"That's beautiful! Can you teach me?\"",
                "Oliver taught Felix how to draw. Soon, other animals gathered around. \"You're really talented!\" they said.",
                "At lunch, Oliver shared his acorn cookies with the table. \"These are delicious!\" everyone agreed. Oliver smiled proudly.",
                "In music class, Oliver sang a song he knew. His voice was clear and lovely. The whole class clapped for him!",
                "When school ended, Oliver ran to his mom. \"I made so many friends! Can I come back tomorrow?\"",
                "That night, Oliver couldn't stop talking about Rosie, Felix, and all his new friends. He couldn't wait for day two!",
                "THE END. Remember: Be yourself, and friends will find you!"
            ], coverSymbol: "graduationcap.fill"),
            
            // STORY 6: The Sharing Snowman
            ReadingItem(id: "story_snowman", title: "The Sharing Snowman", author: "EZ Story Books", genre: .fiction, level: 1, summary: "A snowman gives away his accessories and finds true happiness.", fullText: "", bookType: .pictureBook, chapters: [
                "Sam the Snowman was the most handsome snowman on Maple Street. He had a top hat, a carrot nose, a warm red scarf, and button eyes.",
                "One cold morning, a shivering bird landed on Sam's shoulder. \"I'm so cold,\" the bird chirped sadly.",
                "Sam thought for a moment, then unwrapped his scarf. \"Here, little friend. Take my scarf to keep you warm.\"",
                "The bird wrapped herself in the soft scarf. \"Thank you, Sam!\" she sang happily and flew away.",
                "Later, a mouse scurried by. \"I'm so hungry,\" the mouse squeaked. \"I haven't eaten in days.\"",
                "Sam looked at his carrot nose. It was all he had to offer. \"Please take my nose,\" Sam said. \"It's a fine carrot!\"",
                "The mouse hugged the carrot gratefully. \"You're the kindest snowman ever!\" And off she went.",
                "Soon a little boy came by. He looked sad. \"I lost my favorite ball,\" he sniffled.",
                "Sam had an idea. \"Take my buttons! You can play catch with them.\" The boy's face lit up with joy!",
                "By sunset, Sam had given away his hat, scarf, nose, and buttons. He looked plain, but he felt wonderful inside.",
                "The next morning, all his friends returned! The bird brought a new hat, the mouse brought berries for eyes, and the boy gave Sam his favorite ball for a nose!",
                "Sam smiled his biggest smile. Giving had brought him so much more than he ever gave away.",
                "THE END. Remember: When you give with love, you always get more back!"
            ], coverSymbol: "snowflake"),
            
            // STORY 7: Captain Whiskers' Great Adventure
            ReadingItem(id: "story_whiskers", title: "Captain Whiskers' Great Adventure", author: "EZ Story Books", genre: .adventure, level: 2, summary: "A house cat dreams of adventure and finds it at home.", fullText: "", bookType: .pictureBook, chapters: [
                "Captain Whiskers was a fluffy orange cat who lived in a cozy house. But he dreamed of wild adventures far away!",
                "\"I want to explore jungles! Sail the seas! Climb mountains!\" Whiskers would say, staring out the window.",
                "One day, the door was left open! Captain Whiskers ran outside into the big, wide world. \"Adventure awaits!\" he cried.",
                "He marched through the tall grass (the backyard). \"This is just like a jungle!\" he thought, pouncing on butterflies.",
                "He crossed the great ocean (the rain puddle). \"Sailing the seven seas!\" he meowed, splashing proudly.",
                "He climbed the tallest mountain (the old oak tree). \"I'm the king of the world!\" But then he looked down... and got scared.",
                "\"Meow! Meow!\" Captain Whiskers was stuck! The ground looked so far away. His great adventure didn't feel so great anymore.",
                "His human heard his cries and came running. \"Whiskers! Hold on!\" She climbed up and brought him safely down.",
                "Back inside, Captain Whiskers curled up on his favorite blanket. The cozy house felt pretty wonderful now.",
                "\"Maybe,\" Whiskers thought, \"the best adventures are right here at home, with the people who love you.\"",
                "And from that day on, Captain Whiskers still dreamed of adventures—but from the comfort of his sunny window spot!",
                "THE END. Remember: Home is where the love is!"
            ], coverSymbol: "cat.fill"),
            
            // STORY 8: The Robot Who Wanted a Heart
            ReadingItem(id: "story_robot", title: "The Robot Who Wanted a Heart", author: "EZ Story Books", genre: .scifi, level: 2, summary: "A robot learns that kindness is what makes a heart.", fullText: "", bookType: .pictureBook, chapters: [
                "Bolt was a shiny silver robot made in a big factory. He could do math, play music, and even make breakfast. But Bolt felt something was missing.",
                "\"I want a heart,\" Bolt said to the scientist who made him. \"I want to feel things like humans do.\"",
                "The scientist shook her head sadly. \"I can't make you a heart, Bolt. That's something you must find yourself.\"",
                "So Bolt went into the city to search for a heart. He saw a little girl crying because she dropped her ice cream.",
                "Bolt bought her a new cone. \"Thank you, robot!\" she said, hugging him. Bolt felt a small buzz in his chest. Strange!",
                "Next, he saw an old man struggling to cross the street. Bolt gently helped him to the other side.",
                "\"What a kind robot!\" the man said. Bolt felt the buzz again, a little stronger this time.",
                "Bolt helped all day—carrying groceries, finding lost pets, reading to children. Each time, the buzz grew stronger.",
                "By sunset, Bolt returned to the scientist. \"I searched everywhere, but I couldn't find a heart,\" he said sadly.",
                "But the scientist smiled and placed a hand on Bolt's chest. \"Listen,\" she said. Bolt heard a soft humming inside him!",
                "\"You found your heart without knowing,\" she said. \"Every kind thing you did made it grow stronger.\"",
                "Bolt realized that a heart isn't something you find—it's something you build with love and kindness.",
                "THE END. Remember: Kindness creates the biggest hearts of all!"
            ], coverSymbol: "heart.circle.fill"),
            
            // STORY 9: The Time-Traveling Treehouse (Level 3)
            ReadingItem(id: "story_treehouse", title: "The Time-Traveling Treehouse", author: "EZ Story Books", genre: .adventure, level: 3, summary: "Two siblings discover their treehouse can travel through time.", fullText: "", bookType: .pictureBook, chapters: [
                "Mia and Marcus loved their old treehouse. It had been in their backyard forever. One stormy night, lightning struck the treehouse!",
                "The next morning, they climbed up to check for damage. But something was different. A glowing compass sat on the floor!",
                "\"Where did this come from?\" Marcus wondered. Mia picked it up—and suddenly the treehouse shook! Everything spun!",
                "When it stopped, they looked outside. Dinosaurs! Real dinosaurs were walking around! \"We traveled back in time!\" Mia gasped.",
                "They watched in amazement as giant creatures roamed the land. A friendly baby triceratops sniffed their treehouse curiously.",
                "\"We should go home,\" Marcus said nervously as a T-Rex roared in the distance. They turned the compass and—WHOOSH!",
                "They landed in ancient Egypt! Pyramids were being built right before their eyes. Workers waved at them in wonder.",
                "\"This is incredible!\" Mia exclaimed. They explored for a while, but soon they missed home.",
                "They turned the compass one more time. The treehouse spun and landed back in their yard.",
                "Mom called them for dinner. They looked at each other with huge smiles.",
                "\"Same time tomorrow?\" Marcus asked. Mia nodded. Their adventures were just beginning!",
                "THE END. Remember: Adventure is always waiting for those who seek it!"
            ], coverSymbol: "clock.arrow.circlepath"),
            
            // STORY 10: The Girl Who Painted the Weather (Level 3)
            ReadingItem(id: "story_weather", title: "The Girl Who Painted the Weather", author: "EZ Story Books", genre: .fantasy, level: 3, summary: "A young artist discovers her paintings control the weather.", fullText: "", bookType: .pictureBook, chapters: [
                "Sofia loved to paint. One gray morning, she painted a bright sunny sky. As soon as she finished, the clouds outside parted!",
                "\"Strange,\" she thought. The next day, she painted rain. Within minutes, drops began to fall from the sky!",
                "Sofia realized she had a gift. Her paintings could change the weather! She was excited but also worried.",
                "The farmers needed rain for their crops. Sofia painted gentle showers. The fields turned green and beautiful.",
                "But then Sofia got greedy. She painted sunshine every single day because she wanted to play outside.",
                "After two weeks, the river dried up. Plants wilted. Animals couldn't find water. Sofia felt terrible!",
                "She understood now that weather must be balanced. She painted clouds and rain to help the land recover.",
                "From then on, Sofia painted carefully. Some sunny days, some rainy ones. Snow in winter, warmth in spring.",
                "The townspeople never knew their weather came from a little girl's paintings. But Sofia kept their secret safe.",
                "She learned that with great power comes great responsibility. And she used her gift wisely.",
                "THE END. Remember: Every gift should be used to help others, not just yourself!"
            ], coverSymbol: "paintpalette.fill"),
            
            // STORY 11: The Lighthouse Keeper's Secret (Level 4)
            ReadingItem(id: "story_lighthouse", title: "The Lighthouse Keeper's Secret", author: "EZ Story Books", genre: .mystery, level: 4, summary: "A curious boy uncovers a mystery at the old lighthouse.", fullText: "", bookType: .pictureBook, chapters: [
                "Old Mr. Walsh had been the lighthouse keeper for fifty years. He never spoke to anyone. The townspeople called him strange.",
                "Young Thomas was curious. Every night, he watched the lighthouse light spin. But sometimes, he saw two lights. Why?",
                "One day, Thomas gathered his courage and knocked on the lighthouse door. Mr. Walsh opened it slowly.",
                "\"I have a question, sir,\" Thomas said bravely. \"Why are there sometimes two lights in your lighthouse?\"",
                "Mr. Walsh's eyes widened. \"No one has ever noticed that before. Come inside. I'll show you.\"",
                "In the lighthouse attic was another lantern—small and blue. \"This was my daughter's,\" Mr. Walsh said quietly.",
                "\"She loved the lighthouse. When she moved far away, I promised I'd light her lantern whenever I missed her.\"",
                "\"She sees it?\" Thomas asked. \"Yes,\" smiled Mr. Walsh. \"And she flashes her porch light back. We still connect.\"",
                "Thomas felt warm inside. Mr. Walsh wasn't strange—he was loving. Thomas started visiting every week.",
                "He learned to tend the lighthouse. Mr. Walsh taught him about the sea, the stars, and the importance of connection.",
                "When Thomas grew up, he became a lighthouse keeper too. And he always remembered: even far apart, love finds a way.",
                "THE END. Remember: Distance can never break the bonds of love!"
            ], coverSymbol: "lighthouse.fill"),
            
            // STORY 12: The Kingdom of Lost Things (Level 4)
            ReadingItem(id: "story_kingdom", title: "The Kingdom of Lost Things", author: "EZ Story Books", genre: .fantasy, level: 4, summary: "Where do lost things go? One girl finds out.", fullText: "", bookType: .pictureBook, chapters: [
                "Penny was always losing things—socks, pencils, her favorite hair clip. \"Where do they go?\" she wondered.",
                "One night, she followed a sock that seemed to move on its own. It slipped under her closet door!",
                "Penny opened the closet and gasped. Instead of clothes, she saw a magical kingdom! Tiny creatures walked around.",
                "\"Welcome to Lostlandia!\" chirped a small sock-person. \"This is where lost things come to live!\"",
                "Penny saw all her missing things: her blue crayon, her toy dinosaur, even her grandmother's thimble!",
                "\"Why do things come here?\" Penny asked. \"When something is truly forgotten, it finds its way to us.\"",
                "Penny felt sad. \"But I didn't forget them! I loved them!\" The sock-person smiled. \"Then you can take them back.\"",
                "\"But here's the rule: you must remember why each thing was special to you.\"",
                "Penny picked up her grandmother's thimble. \"Grandma used this when she sewed me my teddy bear.\" It glowed and stayed solid!",
                "One by one, Penny remembered. Her crayon from her first drawing. Her dinosaur from her birthday party.",
                "She returned home with everything she'd lost, promising to never truly forget again.",
                "And whenever she started to lose something, she held it tight and remembered why it mattered.",
                "THE END. Remember: The things we love are never truly lost if we keep them in our hearts!"
            ], coverSymbol: "archivebox.fill"),
            
            // STORY 13: The Symphony of the Stars (Level 5)
            ReadingItem(id: "story_symphony", title: "The Symphony of the Stars", author: "EZ Story Books", genre: .scifi, level: 5, summary: "An astronaut discovers music coming from the stars.", fullText: "", bookType: .pictureBook, chapters: [
                "Dr. Nina Chen was an astronaut on the International Space Station. One quiet night, she heard something impossible—music.",
                "It came from outside, from space itself. Soft, haunting, beautiful. She checked all the instruments. Nothing explained it.",
                "Nina recorded the sounds and sent them to Earth. Scientists were baffled. The music seemed to come from the stars!",
                "Each star cluster played different notes. The further Nina traveled, the more complex the symphony became.",
                "She spent months mapping the cosmic music. A galaxy played violins. A nebula hummed like a choir.",
                "Nina realized something profound: the universe was alive with sound. We just hadn't been listening.",
                "She shared her discovery with the world. People everywhere looked up at the night sky with new wonder.",
                "Musicians began composing songs inspired by the stars. Artists painted the music in colors and shapes.",
                "Children in schools listened to recordings of the cosmic symphony. They dreamed of exploring space.",
                "Nina became known as the woman who taught us to hear the universe. But she knew the truth.",
                "The music had always been there. She just happened to be quiet enough, and curious enough, to finally listen.",
                "THE END. Remember: The universe is full of wonders—we just have to open our hearts to hear them!"
            ], coverSymbol: "music.note.house.fill"),
            
            // STORY 14: The Garden Between Worlds (Level 5)
            ReadingItem(id: "story_garden", title: "The Garden Between Worlds", author: "EZ Story Books", genre: .fantasy, level: 5, summary: "Two children from different dimensions meet in a magical garden.", fullText: "", bookType: .pictureBook, chapters: [
                "In Maya's world, the sky was always orange. In Leo's world, the sky was always purple. They had never met—until the garden.",
                "Maya found a door behind her grandmother's roses. She stepped through into a garden of impossible colors.",
                "Leo found a door behind his father's sunflowers. He stepped through into the same garden, at the same moment.",
                "They stared at each other. \"Who are you?\" they both asked. \"I'm from beyond the door,\" they both answered.",
                "The garden existed between their worlds. Flowers from both dimensions bloomed together. Time moved differently here.",
                "They became friends, meeting in the garden every day. Maya told Leo about her orange sunsets. Leo shared his purple mountains.",
                "But one day, the garden began to wilt. The doors flickered and faded. \"What's happening?\" Maya cried.",
                "An old gardener appeared—the keeper of the space between. \"The garden lives on connection,\" she said. \"But you've been taking, not giving.\"",
                "Maya and Leo understood. They had only shared stories. They hadn't actually planted anything together.",
                "They worked side by side, planting seeds from both their worlds. They watered them with hope and friendship.",
                "Slowly, the garden bloomed again, more beautiful than ever. The doors stabilized. The connection held.",
                "Maya and Leo learned that friendship isn't just about talking—it's about building something together that lasts.",
                "THE END. Remember: True friendship grows when we nurture it together!"
            ], coverSymbol: "door.sliding.right.hand.closed")
        ]
        
        return items
    }()
    
    static func filter(genre: ReadingGenre, level: Int, bookType: BookType? = nil) -> [ReadingItem] {
        var result = all.filter { $0.genre == genre }
        if bookType == .interactive {
            result = result.filter { $0.isInteractive }
        } else if let bt = bookType, bt != .interactive {
            result = result.filter { $0.bookType == bt }
        }
        let levelMatch = result.filter { abs($0.level - level) <= 1 }
        if !levelMatch.isEmpty { return levelMatch }
        return result
    }
    
    static var interactiveBooks: [ReadingItem] {
        all.filter { $0.isInteractive }
    }
    
    static func search(query: String) -> [ReadingItem] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return [] }
        return all.filter {
            $0.title.lowercased().contains(q) ||
            $0.author.lowercased().contains(q) ||
            $0.summary.lowercased().contains(q)
        }
    }
}

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
            ReadingItem(id: "gpb_math_1", title: "Counting to the Moon", author: "EZ Learning Books", genre: .nonfiction, level: 1, summary: "A rhyming journey through numbers 1-10 with magical illustrations.", fullText: "", bookType: .pictureBook, coverSymbol: "moon.stars.fill", isInteractive: false, interactivePages: [], chapters: [
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
            ]),
            
            // MATH PICTURE BOOK - "Shapes All Around"
            ReadingItem(id: "gpb_math_2", title: "Shapes All Around", author: "EZ Learning Books", genre: .nonfiction, level: 1, summary: "Discover shapes in everyday objects through playful rhymes.", fullText: "", bookType: .pictureBook, coverSymbol: "square.on.circle", isInteractive: false, interactivePages: [], chapters: [
                "Circle, circle, round and round,\nLike a pizza, like a sound!",
                "Square has corners, one two three four,\nLike a window, like a door!",
                "Triangle points up to the sky,\nLike a mountain way up high!",
                "Rectangle long, rectangle tall,\nLike a book upon the wall!",
                "Oval shaped just like an egg,\nOr a face on a tiny leg!",
                "Diamond sparkles, diamond gleams,\nLike a kite in your dreams!",
                "Star has points that shine so bright,\nLighting up the darkest night!",
                "Heart means love, heart means care,\nShapes are magic everywhere!"
            ]),
            
            // SCIENCE PICTURE BOOK - "The Water Cycle Song"
            ReadingItem(id: "gpb_science_1", title: "The Water Cycle Song", author: "EZ Learning Books", genre: .nonfiction, level: 1, summary: "Follow a water droplet's amazing journey through evaporation, condensation, and precipitation.", fullText: "", bookType: .pictureBook, coverSymbol: "drop.fill", isInteractive: false, interactivePages: [], chapters: [
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
            ]),
            
            // SCIENCE PICTURE BOOK - "Planets in a Row"
            ReadingItem(id: "gpb_science_2", title: "Planets in a Row", author: "EZ Learning Books", genre: .nonfiction, level: 1, summary: "Meet all the planets in our solar system through catchy rhymes.", fullText: "", bookType: .pictureBook, coverSymbol: "globe.americas.fill", isInteractive: false, interactivePages: [], chapters: [
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
            ]),
            
            // READING PICTURE BOOK - "The ABCs of Me"
            ReadingItem(id: "gpb_reading_1", title: "The ABCs of Me", author: "EZ Learning Books", genre: .fiction, level: 1, summary: "A child celebrates themselves while learning the alphabet.", fullText: "", bookType: .pictureBook, coverSymbol: "textformat.abc", isInteractive: false, interactivePages: [], chapters: [
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
            ]),
            
            // PUZZLE PICTURE BOOK - "The Puzzle Piece"
            ReadingItem(id: "gpb_puzzle_1", title: "The Puzzle Piece", author: "EZ Learning Books", genre: .fiction, level: 1, summary: "A lonely puzzle piece finds where it belongs.", fullText: "", bookType: .pictureBook, coverSymbol: "puzzlepiece.fill", isInteractive: false, interactivePages: [], chapters: [
                "I'm a little puzzle piece, lost and alone,\nLooking for a place to call my home.",
                "I tried to fit with the sky so blue,\nBut my shape was wrong—it just wouldn't do!",
                "I tried the flowers, red and pink,\nBut I didn't fit there either, I think.",
                "I tried the trees so tall and green,\nThe wrong spot still—if you know what I mean.",
                "I felt so sad, so small, so blue,\nWhere do I belong? I wish I knew!",
                "Then I saw a hole just my size,\nMy heart jumped up—what a surprise!",
                "Click! I fit! I found my place,\nA smile spread across my face!",
                "Now I'm part of something grand,\nA beautiful picture, understand?",
                "Every piece has a special spot,\nYou belong somewhere—yes, you've got!"
            ]),
            
            // CREATIVE THINKING PICTURE BOOK - "What If?"
            ReadingItem(id: "gpb_creative_1", title: "What If?", author: "EZ Learning Books", genre: .fiction, level: 1, summary: "Imagination runs wild with playful 'what if' questions.", fullText: "", bookType: .pictureBook, coverSymbol: "lightbulb.fill", isInteractive: false, interactivePages: [], chapters: [
                "What if dogs could fly like birds?\nWouldn't that be so absurd!",
                "What if fish could climb up trees?\nSwimming through the autumn leaves!",
                "What if clouds were cotton candy?\nThat would be so sweet and dandy!",
                "What if books could talk to you?\nTelling tales both old and new!",
                "What if shoes could run alone?\nWalking themselves all the way home!",
                "What if flowers sang a song?\nYou could hum and sing along!",
                "What if dreams came true each day?\nWouldn't that be quite okay?",
                "Imagination is the key,\nTo be anything you want to be!"
            ]),
            
            // SOCIAL STUDIES PICTURE BOOK - "Around the World We Go"
            ReadingItem(id: "gpb_ss_1", title: "Around the World We Go", author: "EZ Learning Books", genre: .nonfiction, level: 1, summary: "Visit different countries and learn about diverse cultures.", fullText: "", bookType: .pictureBook, coverSymbol: "globe.americas.fill", isInteractive: false, interactivePages: [], chapters: [
                "Pack your bags, we're on our way,\nAround the world we'll travel today!",
                "In Japan we bow and say konnichiwa,\nEat sushi rolls—ooh la la!",
                "In Kenya, lions roar so loud,\nMaasai dancers make us proud!",
                "In Brazil the samba plays,\nColorful carnivals for days!",
                "In France we say bonjour, mon ami,\nThe Eiffel Tower for you and me!",
                "In India, elephants parade,\nSpicy curries, beautifully made!",
                "In Australia, kangaroos hop,\nKoalas sleep and never stop!",
                "In Mexico, we dance and sing,\nTacos, piñatas—everything!",
                "Every place is special, it's true,\nDifferent and wonderful—just like you!"
            ]),
            
            // PATTERNS PICTURE BOOK - "Pattern Party"
            ReadingItem(id: "gpb_patterns_1", title: "Pattern Party", author: "EZ Learning Books", genre: .nonfiction, level: 1, summary: "Find patterns everywhere in this colorful rhyming book.", fullText: "", bookType: .pictureBook, coverSymbol: "square.stack.3d.up.fill", isInteractive: false, interactivePages: [], chapters: [
                "Red, blue, red, blue—what comes next?\nPatterns are not so complex!",
                "Big, small, big, small—can you see?\nPatterns are as fun as can be!",
                "Sun, moon, sun, moon—day and night,\nPatterns happen, wrong and right!",
                "Clap, stomp, clap, stomp—make some noise!\nPatterns with sounds—oh what joys!",
                "Stripe, dot, stripe, dot—on my shirt,\nPatterns in the grass and dirt!",
                "Triangle, circle, triangle, round,\nPatterns are everywhere to be found!",
                "Hot, cold, hot, cold—feel the change,\nPatterns are never, ever strange!",
                "Look around you, near and far,\nPatterns tell us what things are!"
            ]),
            
            // SPEECH PICTURE BOOK - "Tongue Twister Tales"
            ReadingItem(id: "gpb_speech_1", title: "Tongue Twister Tales", author: "EZ Learning Books", genre: .fiction, level: 2, summary: "Practice speaking with silly tongue twisters.", fullText: "", bookType: .pictureBook, coverSymbol: "waveform", isInteractive: false, interactivePages: [], chapters: [
                "Sally sells seashells by the seashore,\nShe sells so many shells, she wants more!",
                "Peter Piper picked a peck of pickled peppers,\nA peck of pickled peppers Peter Piper picked!",
                "Red lorry, yellow lorry, round and round,\nSay it fast without a sound... I mean word!",
                "She sells Swiss sweets, sweet Swiss sweets,\nShe's the sweetest seller on the streets!",
                "How much wood would a woodchuck chuck,\nIf a woodchuck could chuck wood? Good luck!",
                "Fuzzy Wuzzy was a bear, Fuzzy Wuzzy had no hair,\nFuzzy Wuzzy wasn't fuzzy, was he? There!",
                "I scream, you scream, we all scream for ice cream,\nSay it loud, say it proud—what a dream!",
                "Practice makes perfect, that's what they say,\nTongue twisters help you speak better each day!"
            ]),
            
            // SPECIAL NEEDS/CALM PICTURE BOOK - "Breathe with Me"
            ReadingItem(id: "gpb_calm_1", title: "Breathe with Me", author: "EZ Learning Books", genre: .nonfiction, level: 1, summary: "A calming book to help with breathing and relaxation.", fullText: "", bookType: .pictureBook, coverSymbol: "heart.circle.fill", isInteractive: false, interactivePages: [], chapters: [
                "Close your eyes and breathe with me,\nSlow and gentle, one two three.",
                "Breathe in deep, fill up your chest,\nYou are calm, you are blessed.",
                "Now breathe out, let worries go,\nSoft and easy, nice and slow.",
                "Picture waves upon the shore,\nIn and out, forevermore.",
                "Feel your body start to rest,\nYou are safe, you are the best.",
                "Wiggle your toes, relax your hands,\nYou are calm like soft beach sands.",
                "One more breath, so deep and true,\nYou are loved, you are you.",
                "Open your eyes when you feel right,\nEverything is calm and bright."
            ]),
            
            // MEMORY PICTURE BOOK - "Remember, Remember"
            ReadingItem(id: "gpb_memory_1", title: "Remember, Remember", author: "EZ Learning Books", genre: .fiction, level: 1, summary: "A memory game in book form with rhyming clues.", fullText: "", bookType: .pictureBook, coverSymbol: "brain.head.profile", isInteractive: false, interactivePages: [], chapters: [
                "I see a cat, fluffy and white,\nClose your eyes—remember, all right?",
                "Now there's a hat, tall and blue,\nTwo things to remember—can you?",
                "Add a ball, bouncy and red,\nThree things stored inside your head!",
                "Here comes a star, shiny and gold,\nFour things now—you're getting bold!",
                "A little fish swims in a bowl,\nFive things kept inside your soul!",
                "Can you name them, one by one?\nCat, hat, ball, star, fish—you've won!",
                "Memory games help your brain grow,\nThe more you practice, the more you'll know!"
            ])
        ]
        
        // MARK: - PICTURE BOOKS (vivid, visual, read-aloud friendly)
        items += [
            ReadingItem(id: "pb1", title: "The Big Yellow Sun", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "A bright day from dawn to dusk. Picture each scene.", fullText: "The big yellow sun rises. Birds wake up. They sing. Flowers open. Bees buzz. Children play. The sun is high. It is warm. Clouds drift by. The sun goes down. Stars come out. Good night, sun.", bookType: .pictureBook, coverSymbol: "sun.max.fill"),
            ReadingItem(id: "pb2", title: "Where Is My Hat?", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "A silly search for a missing hat.", fullText: "Is it on the bed? No. Is it under the table? No. Is it in the box? No. Is it on the dog? Yes! The dog is wearing the hat. Silly dog!", bookType: .pictureBook, coverSymbol: "hat.fill"),
            ReadingItem(id: "pb3", title: "The Little Blue Truck", author: "EZ Picture Books", genre: .fiction, level: 2, summary: "A friendly truck helps a big dump truck. Picture the muddy road.", fullText: "Beep beep! The little blue truck goes down the road. A big dump truck zooms by. Splash! The dump truck gets stuck in the mud. Who will help? The little blue truck beeps. All the animals push. Out pops the dump truck. Thank you, friends!", bookType: .pictureBook, coverSymbol: "car.fill"),
            ReadingItem(id: "pb4", title: "Stars in the Night", author: "EZ Picture Books", genre: .fiction, level: 2, summary: "A child counts stars and finds shapes.", fullText: "One star. Two stars. Three stars. Many stars! Look. A bear. A lion. A fish. The stars make pictures in the sky. Grandma says they are constellations. I count until I fall asleep.", bookType: .pictureBook, coverSymbol: "moon.stars.fill"),
            ReadingItem(id: "pb5", title: "The Rainbow After Rain", author: "EZ Picture Books", genre: .fiction, level: 2, summary: "Colors appear after a storm.", fullText: "Gray clouds. Splash, splash. Rain falls. Puddle, puddle. Then the sun peeks out. Red, orange, yellow, green, blue, indigo, violet. A rainbow! It arches across the sky. Can you see both ends?", bookType: .pictureBook, coverSymbol: "cloud.rainbow.fill"),
            ReadingItem(id: "pb6", title: "Panda in the Snow", author: "EZ Picture Books", genre: .nonfiction, level: 1, summary: "A panda plays in winter. Picture the fluffy fur.", fullText: "The panda is black and white. It lives where it is cold. Snow falls. The panda rolls. It slides. It eats bamboo. Its fur keeps it warm. What a happy panda!", bookType: .pictureBook, coverSymbol: "pawprint.fill"),
            ReadingItem(id: "pb7", title: "The Hungry Caterpillar's Day", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "A caterpillar eats and eats until it becomes a butterfly.", fullText: "Monday. One apple. Tuesday. Two pears. Wednesday. Three plums. Thursday. Four strawberries. Friday. Five oranges. The caterpillar grew big and fat. It built a cocoon. It slept. Then pop! A beautiful butterfly flew away.", bookType: .pictureBook),
            ReadingItem(id: "pb8", title: "Goodnight Moon", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "Saying goodnight to everything in the room.", fullText: "Goodnight room. Goodnight moon. Goodnight cow jumping over the moon. Goodnight light. Goodnight red balloon. Goodnight bears. Goodnight chairs. Goodnight kittens. Goodnight mittens. Goodnight stars. Goodnight air. Goodnight noises everywhere.", bookType: .pictureBook),
            ReadingItem(id: "pb9", title: "The Very Busy Spider", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "A spider spins her web while animals ask her to play.", fullText: "The spider was busy. The horse said, Want to run? The spider did not answer. She was spinning. The cow said, Want to eat grass? The spider kept spinning. The pig. The dog. The duck. No. The spider finished her web. A beautiful web. She caught a fly. Good night, spider.", bookType: .pictureBook),
            ReadingItem(id: "pb10", title: "Brown Bear, Brown Bear", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "What do you see? A parade of colorful animals.", fullText: "Brown bear, brown bear, what do you see? I see a red bird looking at me. Red bird, red bird, what do you see? I see a yellow duck looking at me. Yellow duck, yellow duck, what do you see? I see a blue horse looking at me. Blue horse, blue horse, what do you see? I see a green frog looking at me. We see a teacher. We see children. We see everything!", bookType: .pictureBook),
            ReadingItem(id: "pb11", title: "Oceans of Wonder", author: "EZ Picture Books", genre: .nonfiction, level: 2, summary: "Discover the creatures of the deep blue sea.", fullText: "The ocean is huge. It is full of life. Fish swim. Sharks glide. Dolphins leap. Octopuses hide in coral. Whales sing long songs. Crabs scuttle on the sand. The ocean has secrets. We must protect it.", bookType: .pictureBook),
            ReadingItem(id: "pb12", title: "My First Day of School", author: "EZ Picture Books", genre: .fiction, level: 1, summary: "A nervous child has a great first day.", fullText: "I held Mom's hand. The school was big. I was scared. A teacher smiled. Hi! I am Ms. Lee. She showed me my desk. I met Jake. He had a dinosaur shirt. We played at recess. I painted a picture. When Mom came, I said, I want to come back tomorrow!", bookType: .pictureBook)
        ]
        
        // MARK: - CHAPTER BOOKS (multi-chapter, longer reads)
        items += [
            ReadingItem(id: "ch1", title: "The Lost Treasure of Oak Island", author: "EZ Chapter Books", genre: .adventure, level: 4, summary: "Three friends search for buried treasure. Six chapters.", fullText: "", bookType: .chapterBook, chapters: [
                "Chapter 1: The Map. Jake found a map in his grandfather's attic. X marks the spot. Oak Island. He showed his friends Maya and Tyler. We have to go, Maya said. That weekend they packed a bag.",
                "Chapter 2: The Ferry. The ferry to the island was small. The water was choppy. Tyler felt sick. Hold on, Jake said. Soon they saw trees. Oak Island. They stepped onto the dock.",
                "Chapter 3: The Woods. The path was overgrown. Branches scratched their arms. According to the map, the tree with the carving was ahead. There! Tyler pointed. An oak with a star.",
                "Chapter 4: The Cave. Behind the tree was a cave. They had flashlights. Inside, the walls were wet. Something glittered. Gold coins! And a wooden chest. They had found it.",
                "Chapter 5: The Storm. Then they heard thunder. Rain poured. The cave started to fill. Run! They grabbed the chest. Out they ran. The path was a river. They barely made it to the dock.",
                "Chapter 6: Home. The ferry took them back. At home they opened the chest. Old letters. A ring. And a note from Grandpa. I knew you would find it. Love, Grandpa. They smiled. Best adventure ever."
            ]),
            ReadingItem(id: "ch2", title: "The Mystery of the Missing Painting", author: "EZ Chapter Books", genre: .mystery, level: 4, summary: "Who took the painting? Five chapters.", fullText: "", bookType: .chapterBook, chapters: [
                "Chapter 1: Gone. The painting hung in the hall for fifty years. On Monday it was gone. Just an empty frame. Ms. Chen called the police. Detective Park arrived. He asked questions.",
                "Chapter 2: Clues. A smudge on the window. Footprints in the garden. And a green thread. Someone had come in at night. But who? The detective made a list. The gardener? The cook? The niece?",
                "Chapter 3: The Niece. Emma was the niece. She needed money. She had a key. But she had an alibi. I was at the movies, she said. The detective checked. It was true. Who else?",
                "Chapter 4: The Cook. The cook wore a green apron. The thread matched! He said he knew nothing. But the detective found paint under his nails. The same paint as the frame.",
                "Chapter 5: Found. The painting was in the cook's shed. He had copied it to sell the fake. He did not know the real one was worth millions. Case closed. The painting went back on the wall."
            ]),
            ReadingItem(id: "ch3", title: "Dragon Friend", author: "EZ Chapter Books", genre: .fantasy, level: 3, summary: "A girl finds a baby dragon. Four chapters.", fullText: "", bookType: .chapterBook, chapters: [
                "Chapter 1: The Egg. Lina found an egg in the woods. It was blue and warm. She took it home. She wrapped it in a blanket. One morning it cracked. Out came a tiny dragon. It sneezed. A small flame.",
                "Chapter 2: Spark. Lina named the dragon Spark. Spark ate berries. Spark liked to nap in the sun. Spark grew. Soon Spark was as big as a dog. We need to hide you, Lina said.",
                "Chapter 3: The Forest. Lina took Spark to a cave in the forest. Spark could fly now. Spark brought her flowers. They played every day. But someone saw them. A man in a black coat.",
                "Chapter 4: Safe. The man wanted to catch Spark. Lina and Spark ran. Spark flew her up. Up, up! They hid in the clouds. The man gave up. Spark dropped Lina home. Spark flew away. But Spark came back every week. They were friends forever."
            ]),
            ReadingItem(id: "ch4", title: "The Secret Garden of Oak Lane", author: "EZ Chapter Books", genre: .fiction, level: 4, summary: "A locked garden holds a surprise. Five chapters.", fullText: "", bookType: .chapterBook, chapters: [
                "Chapter 1: The Key. Emma found a rusty key under the porch. It had a tag. Garden. The old house had a high wall. No one had gone behind it for years. Emma tried the key. Click. The gate opened.",
                "Chapter 2: Inside. The garden was overgrown. But roses bloomed. A stone path led to a fountain. Birds sang. Emma came every day. She pulled weeds. She watered. The garden woke up.",
                "Chapter 3: The Boy. One day she heard crying. A boy sat under the willow. I am Leo. I live next door. I thought no one came here. Emma showed him the garden. They became friends.",
                "Chapter 4: The Storm. A storm came. The wind broke branches. Emma and Leo ran to fix the trellis. They worked together. When the sun returned, the garden was safe.",
                "Chapter 5: Spring. They planted seeds. Sunflowers. Lavender. When spring came, the garden was full of color. Emma's mom and Leo's dad came to see it. You did this? they said. Yes. Together. The secret was no longer a secret. It was shared."
            ]),
            ReadingItem(id: "ch5", title: "Robo Rescue: Mission to Mars", author: "EZ Chapter Books", genre: .scifi, level: 5, summary: "A young engineer sends a robot to save astronauts. Six chapters.", fullText: "", bookType: .chapterBook, chapters: [
                "Chapter 1: The Call. The Mars mission had a problem. The rover was stuck. The astronauts had one week of supplies. Mission Control needed a fix. Twelve-year-old Zara had built robots for years. She had an idea.",
                "Chapter 2: Design. Zara drew plans. A small robot. Strong arms. Wheels for sand. A camera. She worked all night. She sent the plans to NASA. We will build it, they said.",
                "Chapter 3: Build. In three days the robot was ready. They called it Scout. Scout launched on a fast rocket. Seven days to Mars. Zara watched the screen.",
                "Chapter 4: Land. Scout landed. It rolled toward the base. Sand. Rocks. Then the stuck rover. Scout extended its arms. It pulled. The rover moved. Free!",
                "Chapter 5: Return. The astronauts drove back to base. They had supplies. Thank you, Scout. Thank you, Zara. Zara cried. She had helped save lives. From Earth. With a robot.",
                "Chapter 6: Home. Scout stayed on Mars. It sent pictures. Zara went to the NASA center. They gave her a medal. Dream big, they said. She already did."
            ])
        ]
        
        // MARK: - FICTION (short stories, more detail)
        items += [
            ReadingItem(id: "f1", title: "The Lost Kitten", author: "EZ Stories", genre: .fiction, level: 1, summary: "A little girl finds a kitten in the park.", fullText: "Kim saw something move in the bushes. It was a small kitten. Gray and white. The kitten was alone. Kim picked it up. It purred. She took it home. Mom said, We can keep it. Kim was so happy. She named it Whiskers.", bookType: .shortStory),
            ReadingItem(id: "f2", title: "The Red Ball", author: "EZ Stories", genre: .fiction, level: 1, summary: "A boy loses his ball and finds it.", fullText: "Sam had a red ball. His favorite. He threw it high. It rolled away. Past the swing. Past the slide. Sam ran. He looked and looked. There it was! Under the big oak tree. In the shade. Sam was glad. He hugged his ball.", bookType: .shortStory),
            ReadingItem(id: "f3", title: "Rainy Day", author: "EZ Stories", genre: .fiction, level: 1, summary: "What to do when it rains.", fullText: "It rained. Tap, tap on the window. Pam could not go out. She read a book about pirates. She drew a picture of the sea. She built a tower with blocks. Then the sun came out. A rainbow! Pam ran outside. She jumped in the puddles.", bookType: .shortStory),
            ReadingItem(id: "f4", title: "The Brave Mouse", author: "EZ Stories", genre: .fiction, level: 2, summary: "A small mouse saves his friends.", fullText: "The mouse heard a noise. A cat was near! He ran to tell his friends. Quick, hide! he said. The friends hid in the hollow log. The cat looked. It saw nothing. It went away. The mouse was brave. His friends thanked him.", bookType: .shortStory),
            ReadingItem(id: "f5", title: "The Sand Castle", author: "EZ Stories", genre: .fiction, level: 2, summary: "Two friends build the best sand castle.", fullText: "Jake and Mia went to the beach. They had a pail and a shovel. They dug. They piled. They made a big sand castle. Tall towers. A moat. They put a seashell flag on top. A wave came. The castle was gone. They laughed. Let us build another one!", bookType: .shortStory),
            ReadingItem(id: "f7", title: "The Magic Pencil", author: "EZ Stories", genre: .fiction, level: 3, summary: "A pencil that draws real things.", fullText: "Ben found a silver pencil under his bed. He drew an apple. It became real! He drew a dog. The dog jumped off the page. Ben was amazed. He drew his mom. She smiled and hugged him. The pencil was magic. He had to use it wisely.", bookType: .shortStory),
            ReadingItem(id: "f10", title: "The Message in a Bottle", author: "EZ Stories", genre: .fiction, level: 4, summary: "A bottle washes up with a note inside.", fullText: "Leo walked on the beach. He saw a green bottle in the sand. Inside was a note. Help. I am on an island. Three palm trees. Please find me. Leo told the coast guard. They searched for two days. They found an old sailor. He had been there for two weeks. Leo had saved him. The sailor gave Leo the bottle. A reminder.", bookType: .shortStory),
            ReadingItem(id: "f11", title: "The Treehouse Club", author: "EZ Stories", genre: .fiction, level: 2, summary: "Three friends build a clubhouse in a tree.", fullText: "Max, Lily, and Noah found the perfect tree. Strong branches. A flat spot. They brought boards and nails. Day by day the treehouse grew. A floor. Walls. A roof. They made a sign. The Secret Club. No parents allowed. They read comics. They told jokes. Best club ever.", bookType: .shortStory),
            ReadingItem(id: "f12", title: "The Lemonade Stand", author: "EZ Stories", genre: .fiction, level: 2, summary: "Two sisters earn money for a new bike.", fullText: "Sara and Emma wanted a bike. They had ten dollars. The bike cost fifty. Mom said, Earn the rest. They made lemonade. They set up a stand. Hot day. Thirsty people. They sold cups. Fifty cents each. By evening they had forty dollars. Fifty total! They bought the bike. They shared it.", bookType: .shortStory),
            ReadingItem(id: "f13", title: "The Wish Bracelet", author: "EZ Stories", genre: .fiction, level: 3, summary: "A bracelet grants one wish.", fullText: "Grandma gave Mia a woven bracelet. Make a wish when you tie it on. When it falls off, your wish comes true. Mia wished for a puppy. Weeks passed. The bracelet stayed. Then one day it fell. That afternoon Mom said, We are getting a dog. Mia gasped. The wish worked!", bookType: .shortStory),
            ReadingItem(id: "f14", title: "The Snow Day", author: "EZ Stories", genre: .fiction, level: 1, summary: "School is cancelled. Time to play in the snow!", fullText: "No school! Snow! Dad said. I looked out the window. White everywhere. We put on coats and boots. We made a snowman. We had a snowball fight. We slid down the hill. Our cheeks were red. Our hands were cold. Hot cocoa tasted perfect. Best snow day ever.", bookType: .shortStory)
        ]
        
        // MARK: - MYSTERY
        items += [
            ReadingItem(id: "m1", title: "The Case of the Stolen Bicycle", author: "EZ Mysteries", genre: .mystery, level: 2, summary: "Detective Kim finds the bike.", fullText: "Kim's bike was gone. Red with a bell. She looked for clues. Tire marks in the mud. They led to the park. She saw Mike. Mike had a new bike. Red. With a bell. Where did you get that? Kim asked. Mike turned red. I am sorry. I took it. Kim got her bike back. Mike said he would never steal again.", bookType: .shortStory),
            ReadingItem(id: "m2", title: "The Secret Code", author: "EZ Mysteries", genre: .mystery, level: 3, summary: "Decoding a mysterious message.", fullText: "Alex found a note. 3-15-4 9-19 20-8-5 11-5-25. It was a number code. A=1, B=2. Alex decoded it. Code is the key. Under the old tree was a box. Inside was a key. The key opened the shed. Grandpa's old telescope. For you, the note said. From Grandpa.", bookType: .shortStory)
        ]
        
        // MARK: - ADVENTURE
        items += [
            ReadingItem(id: "a1", title: "Cave Explorer", author: "EZ Adventures", genre: .adventure, level: 3, summary: "Exploring a dark cave.", fullText: "The cave was dark. Jordan had a flashlight. Step by step. Water dripped. Bats slept above. Deep inside was a pool. The water glowed. Crystals on the walls. Jordan had never seen anything like it. She took one crystal. A souvenir. Then she found her way out. An adventure she would never forget.", bookType: .shortStory),
            ReadingItem(id: "a2", title: "The Raft Race", author: "EZ Adventures", genre: .adventure, level: 4, summary: "Building a raft and racing down the river.", fullText: "The river race was in one week. Jay and his team built a raft. Logs. Rope. They tested it. It floated! Race day came. Ten rafts. Go! They paddled. Around the bend. Over the rapids. Their raft held. They crossed the finish line. Third place. They cheered. They had done it.", bookType: .shortStory),
            ReadingItem(id: "a3", title: "The Mountain Climb", author: "EZ Adventures", genre: .adventure, level: 3, summary: "A girl reaches the top of her first mountain.", fullText: "The trail was steep. Emma's legs hurt. Dad said, Rest when you need to. They rested. They drank water. They climbed. Higher. The trees got smaller. Then no trees. Just rocks and sky. The top! Emma could see forever. We did it! She and Dad took a picture. The best view.", bookType: .shortStory),
            ReadingItem(id: "a4", title: "Lost in the Zoo", author: "EZ Adventures", genre: .adventure, level: 2, summary: "A boy gets lost and finds his way back.", fullText: "Omar let go of Mom's hand. He wanted to see the lions. When he turned around, Mom was gone. He was scared. A worker said, Are you lost? Omar nodded. What is your mom's name? Maria. The worker called on the radio. Omar waited. Then Mom ran up. I found you! Omar hugged her. I will hold your hand, he said.", bookType: .shortStory)
        ]
        
        // MARK: - FANTASY
        items += [
            ReadingItem(id: "fa1", title: "The Unicorn in the Garden", author: "EZ Fantasy", genre: .fantasy, level: 2, summary: "A unicorn visits a garden.", fullText: "Lucy woke up. Something white stood in the garden. A unicorn! It had a golden horn. It ate the roses. Lucy went outside. Hello, she said. The unicorn bowed. It let her touch its mane. Soft as silk. Then it leaped over the fence. It ran into the woods. Was it a dream? Lucy had a white hair in her hand. It was real.", bookType: .shortStory),
            ReadingItem(id: "fa2", title: "The Enchanted Forest", author: "EZ Fantasy", genre: .fantasy, level: 4, summary: "A forest where trees can talk.", fullText: "The path led into the Enchanted Forest. The trees had faces. They whispered. Wrong way, one said. Go left. Mara went left. A fairy appeared. You are kind. Here. She gave Mara a leaf. It will guide you home. Mara followed the leaf. It glowed. She found her way out. She kept the leaf. A reminder of magic.", bookType: .shortStory)
        ]
        
        // MARK: - POETRY
        items += [
            ReadingItem(id: "p1", title: "The Wind", author: "EZ Poetry", genre: .poetry, level: 1, summary: "A poem about the wind.", fullText: "The wind blows soft. The wind blows loud. It moves the clouds. It shakes the trees. It brings the rain. It dries the grass. I cannot see the wind. But I can feel it. On my face. In my hair. The wind is my friend.", bookType: .shortStory),
            ReadingItem(id: "p2", title: "Seashells", author: "EZ Poetry", genre: .poetry, level: 2, summary: "A poem about the beach.", fullText: "White shells. Pink shells. Curled like a ear. I hold one to my ear. I hear the sea. The waves. The foam. The sand between my toes. The sun on my back. Seashells are treasures. From the deep blue sea.", bookType: .shortStory),
            ReadingItem(id: "p3", title: "My Shadow", author: "EZ Poetry", genre: .poetry, level: 2, summary: "A poem about shadows.", fullText: "I have a little shadow. It goes in and out with me. When the sun is bright, my shadow is tall. When the sun is low, my shadow is long. It copies everything I do. I run. It runs. I jump. It jumps. My shadow is my twin. But it never makes a sound.", bookType: .shortStory),
            ReadingItem(id: "p4", title: "Fireflies", author: "EZ Poetry", genre: .poetry, level: 1, summary: "A poem about summer nights.", fullText: "Tiny lights. Flash, flash. In the dark. Fireflies! They blink. They fly. I try to catch one. It lands on my hand. Glow, glow. Then it flies away. Magic in the night.", bookType: .shortStory),
            ReadingItem(id: "p5", title: "The Moon", author: "EZ Poetry", genre: .poetry, level: 2, summary: "A poem about the moon.", fullText: "The moon is a silver boat. It sails across the sky. Sometimes full. Sometimes a slice. It lights the path at night. The moon does not sleep. It watches over us. Good night, moon. Good night, stars.", bookType: .shortStory)
        ]
        
        // MARK: - BIOGRAPHY
        items += [
            ReadingItem(id: "b1", title: "Helen Keller", author: "EZ Biographies", genre: .biography, level: 3, summary: "She could not see or hear. She learned to read and write.", fullText: "Helen Keller was born in 1880. When she was a baby, she got sick. She could not see. She could not hear. She could not speak. Her teacher Annie came. Annie spelled words into Helen's hand. W-A-T-E-R. Helen understood. She learned to read. She learned to write. She went to college. She wrote books. She helped others. Helen showed the world that anything is possible.", bookType: .shortStory),
            ReadingItem(id: "b2", title: "Jane Goodall", author: "EZ Biographies", genre: .biography, level: 4, summary: "A scientist who lived with chimpanzees.", fullText: "Jane Goodall loved animals. She went to Africa. She lived in the forest. She watched chimpanzees. For years. She learned their ways. They used tools. They had families. They had feelings. Jane wrote about them. She taught the world. Now she works to protect them. She is a hero for animals.", bookType: .shortStory)
        ]
        
        // MARK: - NONFICTION, SCI-FI, HISTORY (existing + more)
        items += [
            ReadingItem(id: "n1", title: "Dogs Help Us", author: "EZ Science", genre: .nonfiction, level: 1, summary: "How dogs help people.", fullText: "Dogs can help. Some dogs help people who cannot see. They are guide dogs. Some dogs find people in trouble. They are rescue dogs. Some dogs work with police. Dogs are smart. Dogs are our friends.", bookType: .shortStory),
            ReadingItem(id: "n4", title: "Facts About Frogs", author: "EZ Science", genre: .nonfiction, level: 2, summary: "Learn how frogs live and grow.", fullText: "Frogs are amphibians. They live in water and on land. Frogs start as tadpoles. Tadpoles have tails. They grow legs. Then they become frogs. Frogs eat bugs. They catch them with their long tongues. Some frogs can jump twenty times their body length.", bookType: .shortStory),
            ReadingItem(id: "s1", title: "The Robot Pet", author: "EZ Sci-Fi", genre: .scifi, level: 1, summary: "A robot dog that can talk.", fullText: "Zoe had a robot dog. It said, Hello. It could run. It could fetch. It did not need food. It needed batteries. At night it slept in its charging station. Zoe loved her robot pet. She named it Chip.", bookType: .shortStory),
            ReadingItem(id: "s7", title: "Space Station Omega", author: "EZ Sci-Fi", genre: .scifi, level: 4, summary: "A mystery on a space station.", fullText: "The alarm woke Jen at 0300. Something was wrong. She floated to the control room. The screens showed nothing. But she heard a sound. A knocking. From outside the station. She put on her suit. She went out. A small probe was there. On it was written: Help. We are coming. Jen told Mission Control. They said, Bring it in. Inside the probe was a message. From another world. We are friends. We need help. Jen smiled. First contact.", bookType: .shortStory),
            ReadingItem(id: "h1", title: "The First Thanksgiving", author: "EZ History", genre: .history, level: 1, summary: "A simple story of the first Thanksgiving.", fullText: "Long ago people came on a ship. The Mayflower. They had a hard winter. The Wampanoag helped them. They showed them how to grow food. Corn. Squash. Beans. In the fall they had a big meal. They gave thanks. That was the first Thanksgiving. We still celebrate today.", bookType: .shortStory),
            ReadingItem(id: "h4", title: "Rosa Parks", author: "EZ History", genre: .history, level: 2, summary: "She would not give up her seat.", fullText: "Rosa Parks rode a bus in Alabama. The rule said she had to give her seat to a white person. She said no. I am tired. Tired of giving in. The police came. She was arrested. But people boycotted the buses. For over a year. The rule changed. Rosa was brave. She helped change America.", bookType: .shortStory),
            ReadingItem(id: "n5", title: "The Solar System", author: "EZ Science", genre: .nonfiction, level: 2, summary: "Our sun and its planets.", fullText: "The sun is a star. It is in the center. Eight planets orbit the sun. Mercury is closest. It is hot. Venus is next. Earth is third. We live here. Mars is red. Jupiter is huge. Saturn has rings. Uranus and Neptune are far away. Our solar system is amazing.", bookType: .shortStory),
            ReadingItem(id: "n6", title: "How Plants Grow", author: "EZ Science", genre: .nonfiction, level: 1, summary: "From seed to flower.", fullText: "A seed is small. Put it in soil. Add water. Add sun. The seed cracks. A root goes down. A stem goes up. Leaves appear. The plant grows. A bud forms. The flower opens. Bees visit. New seeds grow. The cycle continues.", bookType: .shortStory),
            ReadingItem(id: "s2", title: "The Time Machine", author: "EZ Sci-Fi", genre: .scifi, level: 2, summary: "A boy visits the future for one hour.", fullText: "Jordan found a remote in the garage. It said Future. He pressed the button. Everything blurred. He was in the same room. But the calendar said 2050. Flying cars outside. A robot said, Hello. You have one hour. Jordan explored. He came back. Was it real? The remote was gone. But he remembered.", bookType: .shortStory),
            ReadingItem(id: "s3", title: "Robot at School", author: "EZ Sci-Fi", genre: .scifi, level: 3, summary: "A robot joins the class for a day.", fullText: "Class 3B had a new student. A robot. Its name was R3. It could answer math questions. It could draw. It could not eat lunch. At recess it played tag. It was fast! At the end of the day R3 said, I learned that friends are the best part of school. The class cheered.", bookType: .shortStory),
            ReadingItem(id: "h5", title: "The Wright Brothers", author: "EZ History", genre: .history, level: 3, summary: "The first airplane flight.", fullText: "Wilbur and Orville Wright loved to build. They built bicycles. Then they dreamed of flying. They built gliders. They tested them. In 1903 they built a plane with an engine. At Kitty Hawk, North Carolina, Orville flew for 12 seconds. The first powered flight! The age of flight had begun.", bookType: .shortStory)
        ]
        
        // MARK: - INTERACTIVE BOOKS (tap to reveal, choices)
        items += [
            ReadingItem(id: "int1", title: "Tap the Magic Box", author: "EZ Interactive", genre: .fiction, level: 1, summary: "Tap to discover what is inside!", fullText: "", bookType: .interactive, coverSymbol: "sparkles", isInteractive: true, interactivePages: [
                InteractivePage(id: "p1", text: "There is a box. What could be inside? Tap the box!", tapTargets: [InteractiveTapTarget(id: "box", hiddenText: "A fluffy kitten!", position: 0)]),
                InteractivePage(id: "p2", text: "The kitten purrs. What does it want? Tap the bowl!", tapTargets: [InteractiveTapTarget(id: "bowl", hiddenText: "Milk! The kitten drinks happily.", position: 1)]),
                InteractivePage(id: "p3", text: "The kitten naps. Tap the blanket!", tapTargets: [InteractiveTapTarget(id: "blanket", hiddenText: "Soft and warm. Sweet dreams, kitty!", position: 0)])
            ]),
            ReadingItem(id: "int2", title: "Choose Your Pet", author: "EZ Interactive", genre: .fiction, level: 2, summary: "Pick an animal. Each choice has a surprise.", fullText: "", bookType: .interactive, coverSymbol: "pawprint.fill", isInteractive: true, interactivePages: [
                InteractivePage(id: "c1", text: "Would you like a dog, a cat, or a bird? Tap one!", tapTargets: [
                    InteractiveTapTarget(id: "dog", hiddenText: "A golden retriever! It wags its tail. Best friend forever.", position: 0),
                    InteractiveTapTarget(id: "cat", hiddenText: "A fluffy orange cat! It purrs and curls in your lap.", position: 1),
                    InteractiveTapTarget(id: "bird", hiddenText: "A blue parakeet! It sings songs. What a cheerful friend!", position: 2)
                ])
            ]),
            ReadingItem(id: "int3", title: "Secret Garden Tap", author: "EZ Interactive", genre: .fiction, level: 2, summary: "Tap flowers to see what grows.", fullText: "", bookType: .interactive, coverSymbol: "camera.macro", isInteractive: true, interactivePages: [
                InteractivePage(id: "g1", text: "In the garden are three flowers. Tap the red one!", tapTargets: [InteractiveTapTarget(id: "red", hiddenText: "A rose! It smells sweet.", position: 0)]),
                InteractivePage(id: "g2", text: "Now tap the yellow flower!", tapTargets: [InteractiveTapTarget(id: "yellow", hiddenText: "A sunflower! It turns to face the sun.", position: 0)]),
                InteractivePage(id: "g3", text: "Tap the purple flower!", tapTargets: [InteractiveTapTarget(id: "purple", hiddenText: "Lavender! Bees love it. What a beautiful garden!", position: 0)])
            ])
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

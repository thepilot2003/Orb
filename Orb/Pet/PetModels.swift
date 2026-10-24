import SwiftUI

// MARK: - Notch Pet Types

enum NotchPetType: String, CaseIterable, Identifiable, Codable {
    case cat = "cat"
    case dog = "dog"
    case duck = "duck"
    case spider = "spider"
    case orb = "orb"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cat: return "Cat (Mochi)"
        case .dog: return "Dog (Bento)"
        case .duck: return "Duck (Waddles)"
        case .spider: return "Spider (Webby)"
        case .orb: return "Orb (Lumi)"
        }
    }

    var shortName: String {
        switch self {
        case .cat: return "Mochi"
        case .dog: return "Bento"
        case .duck: return "Waddles"
        case .spider: return "Webby"
        case .orb: return "Lumi"
        }
    }

    var emoji: String {
        switch self {
        case .cat: return "🐱"
        case .dog: return "🐶"
        case .duck: return "🦆"
        case .spider: return "🕷️"
        case .orb: return "🔮"
        }
    }

    var subtitle: String {
        switch self {
        case .cat: return "Playful feline that loves fish & milk"
        case .dog: return "Bouncy golden pup that wags & pants"
        case .duck: return "Cute duckling that flaps & waddles"
        case .spider: return "Notch acrobat hanging by silver silk"
        case .orb: return "Holographic orb pulsing with audio"
        }
    }

    var soundText: String {
        switch self {
        case .cat: return "Purrrrr... 🐱"
        case .dog: return "Woof! ❤️"
        case .duck: return "Quack! ✨"
        case .spider: return "Tickle! 🕷️"
        case .orb: return "Zzzzt! 🔮"
        }
    }

    /// Companion-specific food menu
    var availableTreats: [PetTreat] {
        switch self {
        case .cat:
            return [.fish, .milk, .catnip]
        case .dog:
            return [.bone, .sausage, .biscuit]
        case .duck:
            return [.bread, .seed, .berry]
        case .spider:
            return [.fly, .firefly, .dew]
        case .orb:
            return [.starCandy, .energy, .stardust]
        }
    }
}

// MARK: - Notch Pet Placement

enum NotchPetPlacement: String, CaseIterable, Identifiable, Codable {
    case right = "Right of Notch"
    case left = "Left of Notch"
    case both = "Both Sides (Roaming)"

    var id: String { rawValue }

    var title: String { rawValue }

    var icon: String {
        switch self {
        case .right: return "arrow.right.to.line"
        case .left: return "arrow.left.to.line"
        case .both: return "arrow.left.and.right"
        }
    }
}

// MARK: - Notch Pet Actions

enum NotchPetAction: String, CaseIterable {
    case idle
    case walking
    case dancing
    case singing
    case sleeping
    case eating
    case typing
    case stretching
    case happy
}

// MARK: - Activity Level

enum NotchPetActivity: String, CaseIterable, Identifiable {
    case chill = "Chill"
    case playful = "Playful"
    case energetic = "Energetic"

    var id: String { rawValue }

    var title: String { rawValue }

    var interval: TimeInterval {
        switch self {
        case .chill: return 7.5
        case .playful: return 4.0
        case .energetic: return 2.2
        }
    }
}

// MARK: - Wardrobe: Hats

enum PetHat: String, CaseIterable, Identifiable {
    case none = "None"
    case djHeadphones = "DJ Headphones"
    case sunglasses = "Sunglasses"
    case rainHat = "Rain Hat"
    case winterBeanie = "Winter Beanie"
    case partyHat = "Party Hat"
    case royalCrown = "Royal Crown"
    case chefHat = "Chef Hat"
    case detectiveFedora = "Fedora"
    case wizardHat = "Wizard Hat"
    case strawSunhat = "Sunhat"
    case gamerHeadset = "Gamer Headset"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .none: return "slash.circle"
        case .djHeadphones: return "headphones"
        case .sunglasses: return "eyeglasses"
        case .rainHat: return "cloud.rain.fill"
        case .winterBeanie: return "snowflake"
        case .partyHat: return "party.popper.fill"
        case .royalCrown: return "crown.fill"
        case .chefHat: return "fork.knife"
        case .detectiveFedora: return "magnifyingglass"
        case .wizardHat: return "wand.and.stars"
        case .strawSunhat: return "sun.max.fill"
        case .gamerHeadset: return "gamecontroller.fill"
        }
    }
}

// MARK: - Wardrobe: Outfits

enum PetOutfit: String, CaseIterable, Identifiable {
    case none = "None"
    case raincoat = "Raincoat & Boots"
    case winterSweater = "Winter Sweater"
    case tuxedo = "Tuxedo & Bowtie"
    case superheroCape = "Hero Cape"
    case hawaiianShirt = "Hawaiian Shirt"
    case onesie = "Dino Onesie"
    case astronaut = "Astronaut Suit"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .none: return "slash.circle"
        case .raincoat: return "umbrella.fill"
        case .winterSweater: return "thermometer.snowflake"
        case .tuxedo: return "person.badge.shield.checkmark.fill"
        case .superheroCape: return "shield.lefthalf.filled"
        case .hawaiianShirt: return "leaf.fill"
        case .onesie: return "sparkles"
        case .astronaut: return "moon.stars.fill"
        }
    }
}

// MARK: - Animal-Specific Treats & Nutrition

enum PetTreat: String, CaseIterable, Identifiable {
    // Cat Treats
    case fish = "Fresh Salmon"
    case milk = "Milk Saucer"
    case catnip = "Catnip Cookie"

    // Dog Treats
    case bone = "Golden Bone"
    case sausage = "Meat Sausage"
    case biscuit = "Puppy Biscuit"

    // Duck Treats
    case bread = "Golden Bread"
    case seed = "Lily Seed"
    case berry = "Sweet Berry"

    // Spider Treats
    case fly = "Fruit Fly"
    case firefly = "Firefly Snack"
    case dew = "Morning Dew"

    // Orb Treats
    case starCandy = "Cosmic Star"
    case energy = "Energy Spark"
    case stardust = "Stardust"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .fish: return "🐟"
        case .milk: return "🥛"
        case .catnip: return "🌿"
        case .bone: return "🦴"
        case .sausage: return "🥩"
        case .biscuit: return "🍪"
        case .bread: return "🍞"
        case .seed: return "🌾"
        case .berry: return "🫐"
        case .fly: return "🪰"
        case .firefly: return "✨"
        case .dew: return "💧"
        case .starCandy: return "⭐"
        case .energy: return "⚡"
        case .stardust: return "💫"
        }
    }

    var label: String { rawValue }
}

// MARK: - Weather Condition Reaction Mode

enum PetWeatherMode: String, CaseIterable, Identifiable {
    case auto = "Auto (Weather)"
    case sunny = "Sunny ☀️"
    case rainy = "Rainy 🌧️"
    case snowy = "Snowy / Cold ❄️"

    var id: String { rawValue }
}

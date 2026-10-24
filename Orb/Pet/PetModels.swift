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
        case .cat: return "Cat"
        case .dog: return "Dog"
        case .duck: return "Duck"
        case .spider: return "Spider"
        case .orb: return "Orb"
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
        case .cat: return "Playful feline with swishing tail"
        case .dog: return "Loyal puppy that wags and pants"
        case .duck: return "Feathered friend that waddles & flaps"
        case .spider: return "Notch acrobat hanging by silver silk"
        case .orb: return "Dynamic glowing energy companion"
        }
    }

    var favoriteTreat: PetTreat {
        switch self {
        case .cat: return .fish
        case .dog: return .bone
        case .duck: return .bread
        case .spider: return .fly
        case .orb: return .starCandy
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
        case .wizardHat: return .init("wand.and.stars")
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

// MARK: - Feeding Treats

enum PetTreat: String, CaseIterable, Identifiable {
    case fish = "Fish"
    case bone = "Bone"
    case bread = "Bread"
    case fly = "Fly"
    case starCandy = "Star Candy"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .fish: return "🐟"
        case .bone: return "🦴"
        case .bread: return "🍞"
        case .fly: return "🪰"
        case .starCandy: return "⭐"
        }
    }

    var label: String {
        switch self {
        case .fish: return "Fresh Salmon"
        case .bone: return "Juicy Bone"
        case .bread: return "Golden Bread"
        case .fly: return "Notch Fly"
        case .starCandy: return "Cosmic Star"
        }
    }

    var bestFor: NotchPetType {
        switch self {
        case .fish: return .cat
        case .bone: return .dog
        case .bread: return .duck
        case .fly: return .spider
        case .starCandy: return .orb
        }
    }
}

// MARK: - Weather Condition Reaction Mode

enum PetWeatherMode: String, CaseIterable, Identifiable {
    case auto = "Auto (Weather)"
    case sunny = "Sunny ☀️"
    case rainy = "Rainy 🌧️"
    case snowy = "Snowy / Cold ❄️"

    var id: String { rawValue }
}

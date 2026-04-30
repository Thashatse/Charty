import SwiftUI

enum Award: String, CaseIterable, Equatable {
    case doubleDiamond = "2xD"
    case diamond = "D"
    case platinum = "P"
    case gold = "G"
    case silver = "S"

    var tier: Int {
        switch self {
        case .doubleDiamond: return 5
        case .diamond: return 4
        case .platinum: return 3
        case .gold: return 2
        case .silver: return 1
        }
    }

    var displayName: String {
        switch self {
        case .doubleDiamond: return "2x Diamond"
        case .diamond: return "Diamond"
        case .platinum: return "Platinum"
        case .gold: return "Gold"
        case .silver: return "Silver"
        }
    }

    var color: Color {
        switch self {
        case .doubleDiamond: return .cyan
        case .diamond: return .cyan
        case .platinum: return .gray
        case .gold: return .yellow
        case .silver: return Color(white: 0.7)
        }
    }
}

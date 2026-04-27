import SwiftUI

enum Award: String {
    case silver = "S"
    case gold = "G"
    case platinum = "P"
    case diamond = "D"
    case doubleDiamond = "2xD"
    
    var displayName: String {
        switch self {
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .platinum: return "Platinum"
        case .diamond: return "Diamond"
        case .doubleDiamond: return "2x Diamond"
        }
    }
    
    var color: Color {
        switch self {
        case .gold: return .yellow
        case .platinum: return .gray
        case .diamond: return .cyan
        case .doubleDiamond: return .cyan
        case .silver: return Color(white: 0.7)
        }
    }
}

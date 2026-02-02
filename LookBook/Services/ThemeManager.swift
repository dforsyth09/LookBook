import SwiftUI

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    var accentColor: Color {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 12, 1, 2: return Color(red: 0.29, green: 0.56, blue: 0.85)  // #4A90D9
        case 3, 4, 5:  return Color(red: 0.36, green: 0.72, blue: 0.36)  // #5CB85C
        case 6, 7, 8:  return Color(red: 1.0, green: 0.42, blue: 0.42)   // #FF6B6B
        default:        return Color(red: 0.91, green: 0.58, blue: 0.23)  // #E8943A
        }
    }

    var seasonName: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 12, 1, 2: return "Winter"
        case 3, 4, 5:  return "Spring"
        case 6, 7, 8:  return "Summer"
        default:        return "Autumn"
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning!"
        case 12..<17: return "Good afternoon!"
        default:       return "Good evening!"
        }
    }

    var greetingSubtitle: String {
        "Look at these beautiful new arrivals for you."
    }
}

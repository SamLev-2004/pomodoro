import SwiftUI

enum SessionPhase: String, Equatable {
    case work
    case shortBreak
    case longBreak

    var label: String {
        switch self {
        case .work: return "Work"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    var arcColor: Color {
        switch self {
        case .work: return .red
        case .shortBreak: return Color(red: 0.2, green: 0.8, blue: 0.6)
        case .longBreak: return .blue
        }
    }
}

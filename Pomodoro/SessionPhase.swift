import SwiftUI
import CoreGraphics

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

    var fillCGColor: CGColor {
        switch self {
        case .work: return CGColor(red: 0.91, green: 0.30, blue: 0.24, alpha: 1.0)
        case .shortBreak: return CGColor(red: 0.20, green: 0.80, blue: 0.60, alpha: 1.0)
        case .longBreak: return CGColor(red: 0.25, green: 0.47, blue: 0.85, alpha: 1.0)
        }
    }
}

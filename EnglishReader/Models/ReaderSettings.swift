import SwiftUI
import UIKit

enum ReaderTheme: String, CaseIterable, Codable, Identifiable {
    case paper
    case warm
    case green
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .paper: return "白纸"
        case .warm: return "暖黄"
        case .green: return "护眼"
        case .dark: return "夜间"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .paper: return Color(red: 0.97, green: 0.97, blue: 0.95)
        case .warm: return Color(red: 0.96, green: 0.91, blue: 0.79)
        case .green: return Color(red: 0.86, green: 0.92, blue: 0.84)
        case .dark: return Color(red: 0.10, green: 0.11, blue: 0.12)
        }
    }

    var textColor: Color {
        switch self {
        case .dark: return Color(red: 0.84, green: 0.84, blue: 0.80)
        default: return Color(red: 0.12, green: 0.12, blue: 0.12)
        }
    }
}

struct ReaderSettings: Codable, Equatable {
    var fontSize: Double = 20
    var lineSpacing: Double = 8
    var theme: ReaderTheme = .paper
    var brightness: Double = Double(UIScreen.main.brightness)
    var volumePagingEnabled: Bool = false
}

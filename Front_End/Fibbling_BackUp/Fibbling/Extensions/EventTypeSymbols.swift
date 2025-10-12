//
//  EventTypeSymbols.swift
//  Fibbling
//
//  Created by AI Assistant on 2025-01-XX.
//

import SwiftUI

extension EventType {
    /// Returns the appropriate SF Symbol name for each event type
    var sfSymbolName: String {
        switch self {
        case .study:
            return "book.fill"
        case .party:
            return "party.popper.fill"
        case .business:
            return "briefcase.fill"
        case .cultural:
            return "theatermasks.fill"
        case .academic:
            return "graduationcap.fill"
        case .networking:
            return "person.2.fill"
        case .social:
            return "person.3.fill"
        case .language_exchange:
            return "globe"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
    
    /// Returns the appropriate color for each event type
    var color: Color {
        switch self {
        case .study:
            return .blue
        case .party:
            return .purple
        case .business:
            return .indigo
        case .cultural:
            return .orange
        case .academic:
            return .green
        case .networking:
            return .pink
        case .social:
            return .red
        case .language_exchange:
            return .teal
        case .other:
            return .gray
        }
    }
    
    /// Returns a SwiftUI Image with the appropriate SF Symbol
    var image: Image {
        Image(systemName: sfSymbolName)
    }
    
    /// Returns a SwiftUI Image with the appropriate SF Symbol and color
    var coloredImage: some View {
        Image(systemName: sfSymbolName)
            .foregroundColor(color)
    }
}

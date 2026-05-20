//
//  DatabaseKind.swift
//  mactable
//

import Foundation
import SwiftUI

enum DatabaseKind: String, CaseIterable, Codable, Identifiable {
    case postgres
    case mysql
    case mongodb

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .postgres: return "PostgreSQL"
        case .mysql:    return "MySQL"
        case .mongodb:  return "MongoDB"
        }
    }

    var defaultPort: Int {
        switch self {
        case .postgres: return 5432
        case .mysql:    return 3306
        case .mongodb:  return 27017
        }
    }

    var symbolName: String {
        switch self {
        case .postgres: return "cylinder.split.1x2"
        case .mysql:    return "cylinder.fill"
        case .mongodb:  return "leaf.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .postgres: return Color(red: 0.20, green: 0.45, blue: 0.85)
        case .mysql:    return Color(red: 0.95, green: 0.55, blue: 0.10)
        case .mongodb:  return Color(red: 0.30, green: 0.70, blue: 0.40)
        }
    }
}

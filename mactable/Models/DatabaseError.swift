//
//  DatabaseError.swift
//  mactable
//

import Foundation

enum DatabaseError: LocalizedError, Equatable {
    case notConnected
    case connectionFailed(String)
    case authenticationFailed(String)
    case queryFailed(String)
    case protocolError(String)
    case unsupported(String)
    case timeout
    case io(String)

    var errorDescription: String? {
        switch self {
        case .notConnected:                return "Not connected to a database."
        case .connectionFailed(let m):     return "Connection failed: \(m)"
        case .authenticationFailed(let m): return "Authentication failed: \(m)"
        case .queryFailed(let m):          return "Query failed: \(m)"
        case .protocolError(let m):        return "Protocol error: \(m)"
        case .unsupported(let m):          return "Unsupported: \(m)"
        case .timeout:                     return "Operation timed out."
        case .io(let m):                   return "I/O error: \(m)"
        }
    }
}

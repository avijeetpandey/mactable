//
//  QueryEditorViewModel.swift
//  mactable
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class QueryEditorViewModel: ObservableObject {
    @Published var sql: String = ""
    @Published private(set) var result: QueryResult = .empty
    @Published private(set) var isExecuting = false
    @Published var errorMessage: String?
    @Published var safeMode: Bool = true
    @Published var pendingDestructiveSQL: String?

    private let session: ConnectionSession
    weak var toastCenter: ToastCenter?

    init(session: ConnectionSession) {
        self.session = session
        self.sql = QueryEditorViewModel.defaultSQL(for: session.config.kind)
    }

    static func defaultSQL(for kind: DatabaseKind) -> String {
        switch kind {
        case .postgres: return "SELECT version();"
        case .mysql:    return "SELECT VERSION();"
        case .mongodb:  return "db.system.version.find({})"
        }
    }

    func run() {
        guard !isExecuting else { return }
        let trimmed = sql.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if safeMode && isDestructive(trimmed) && pendingDestructiveSQL == nil {
            pendingDestructiveSQL = trimmed
            return
        }

        let toExecute = pendingDestructiveSQL ?? trimmed
        pendingDestructiveSQL = nil
        execute(toExecute)
    }

    func confirmDestructive() {
        guard let sqlToRun = pendingDestructiveSQL else { return }
        pendingDestructiveSQL = nil
        execute(sqlToRun)
    }

    func cancelDestructive() {
        pendingDestructiveSQL = nil
    }

    private func execute(_ sqlToRun: String) {
        isExecuting = true
        errorMessage = nil
        let driver = session.driver
        Task { [weak self] in
            do {
                let r = try await driver.executeQuery(sqlToRun)
                await MainActor.run {
                    guard let self = self else { return }
                    self.result = r
                    self.isExecuting = false
                    let ms = Int(r.executionTime * 1000)
                    self.toastCenter?.push("Executed in \(ms) ms · \(r.rows.count) rows", kind: .success)
                }
            } catch {
                await MainActor.run {
                    guard let self = self else { return }
                    self.errorMessage = error.localizedDescription
                    self.isExecuting = false
                    self.toastCenter?.error(error)
                }
            }
        }
    }

    private func isDestructive(_ sql: String) -> Bool {
        let upper = sql.uppercased()
        let prefixes = ["UPDATE ", "DELETE ", "DROP ", "TRUNCATE ", "ALTER ", "INSERT "]
        return prefixes.contains { upper.hasPrefix($0) }
    }
}

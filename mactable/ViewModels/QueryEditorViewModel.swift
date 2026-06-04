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

    /// Phase 3: shared queue for cell-edit mutations buffered under Safe Mode.
    let mutationsQueue = MutationsQueue()

    /// Phase 4: in-memory time-travel ring storing the last N executed
    /// queries together with their result snapshot.
    @Published private(set) var history: [QueryHistoryEntry] = []
    @Published var historyIndex: Int? = nil

    /// Phase 3: most recently queried table name and inferred primary key.
    /// Used by the grid for safe inline edits. Updated whenever the user
    /// runs a `SELECT` whose FROM clause is parseable.
    @Published private(set) var currentTable: String? = nil
    @Published var primaryKeyColumn: String? = nil

    private let session: ConnectionSession
    weak var toastCenter: ToastCenter?
    private let historyCapacity = 10

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

    func toggleSafeMode() {
        safeMode.toggle()
        toastCenter?.push("Safe Mode \(safeMode ? "ON" : "OFF")", kind: safeMode ? .success : .warning)
    }

    func formatSQL() {
        sql = SQLFormatter.format(sql)
        toastCenter?.push("Formatted", kind: .info)
    }

    func loadHistory(at index: Int) {
        guard index >= 0, index < history.count else { return }
        let entry = history[index]
        sql = entry.sql
        result = entry.result
        errorMessage = nil
        historyIndex = index
    }

    // MARK: - Mutations commit

    func commitMutations() {
        let statements = mutationsQueue.compileSQL(quoting: session.config.kind == .mysql ? .backtick : .doubleQuote)
        guard !statements.isEmpty else { return }
        let driver = session.driver
        Task { [weak self] in
            for stmt in statements {
                do {
                    _ = try await driver.executeQuery(stmt)
                } catch {
                    await MainActor.run {
                        self?.toastCenter?.error(error)
                    }
                    return
                }
            }
            await MainActor.run {
                self?.mutationsQueue.clear()
                self?.toastCenter?.push("\(statements.count) edit\(statements.count == 1 ? "" : "s") committed", kind: .success)
            }
        }
    }

    func discardMutations() {
        mutationsQueue.clear()
        toastCenter?.push("Discarded uncommitted edits", kind: .warning)
    }

    // MARK: - Execution

    private func execute(_ sqlToRun: String) {
        isExecuting = true
        errorMessage = nil
        currentTable = SQLAnalyzer.tableName(in: sqlToRun)
        primaryKeyColumn = primaryKeyColumn ?? "id"
        let driver = session.driver
        Task { [weak self] in
            do {
                let r = try await driver.executeQuery(sqlToRun)
                await MainActor.run {
                    guard let self = self else { return }
                    self.result = r
                    self.isExecuting = false
                    self.recordHistory(sql: sqlToRun, result: r)
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

    private func recordHistory(sql: String, result: QueryResult) {
        let entry = QueryHistoryEntry(sql: sql, result: result, executedAt: Date())
        history.append(entry)
        if history.count > historyCapacity {
            history.removeFirst(history.count - historyCapacity)
        }
        historyIndex = history.count - 1
    }

    private func isDestructive(_ sql: String) -> Bool {
        let upper = sql.uppercased()
        let prefixes = ["UPDATE ", "DELETE ", "DROP ", "TRUNCATE ", "ALTER ", "INSERT "]
        return prefixes.contains { upper.hasPrefix($0) }
    }
}

struct QueryHistoryEntry: Hashable, Identifiable {
    let id = UUID()
    let sql: String
    let result: QueryResult
    let executedAt: Date
}

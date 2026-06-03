//
//  DatabaseDriver.swift
//  mactable
//

import Foundation

protocol DatabaseDriver: AnyObject {
    var kind: DatabaseKind { get }
    var isConnected: Bool { get }
    var serverVersion: String? { get }

    func connect(config: ConnectionConfig, password: String) async throws
    func disconnect() async
    func executeQuery(_ sql: String) async throws -> QueryResult
    func fetchTables() async throws -> [TableInfo]
    func fetchColumns(forTable table: TableInfo) async throws -> [ColumnDescriptor]
    func fetchMetrics() async throws -> DatabaseMetrics
}

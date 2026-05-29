//
//  DriverFactoryTests.swift
//  mactableTests
//

import Testing
@testable import mactable

struct DriverFactoryTests {
    @Test func makesPostgresDriver() {
        let d = DriverFactory.make(for: .postgres)
        #expect(d.kind == .postgres)
        #expect(d.isConnected == false)
    }

    @Test func makesMySQLDriver() {
        let d = DriverFactory.make(for: .mysql)
        #expect(d.kind == .mysql)
    }

    @Test func makesMongoDriver() {
        let d = DriverFactory.make(for: .mongodb)
        #expect(d.kind == .mongodb)
    }

    @Test func defaultPorts() {
        #expect(DatabaseKind.postgres.defaultPort == 5432)
        #expect(DatabaseKind.mysql.defaultPort == 3306)
        #expect(DatabaseKind.mongodb.defaultPort == 27017)
    }
}

//
//  MongoQueryParserTests.swift
//  mactableTests
//

import Testing
import Foundation
@testable import mactable

struct MongoQueryParserTests {
    @Test func parsesFindWithFilter() throws {
        let q = try MongoQueryParser.parse("db.users.find({\"age\": 30})", defaultDB: "test")
        #expect(q.database == "test")
        #expect(q.command["find"] == .string("users"))
        if case .document(let f)? = q.command["filter"] {
            #expect(f["age"] == .int32(30))
        } else {
            Issue.record("filter missing")
        }
    }

    @Test func parsesAggregate() throws {
        let q = try MongoQueryParser.parse("db.events.aggregate([{\"$match\": {\"x\": 1}}])", defaultDB: "test")
        #expect(q.command["aggregate"] == .string("events"))
        if case .array(let a)? = q.command["pipeline"] {
            #expect(a.count == 1)
        } else {
            Issue.record("pipeline missing")
        }
    }

    @Test func parsesCountDocuments() throws {
        let q = try MongoQueryParser.parse("db.things.countDocuments({\"a\": 1})", defaultDB: "x")
        #expect(q.command["count"] == .string("things"))
    }

    @Test func rawJSONCommandPassthrough() throws {
        let q = try MongoQueryParser.parse("{\"ping\": 1}", defaultDB: "admin")
        #expect(q.command["ping"] == .int32(1))
    }
}

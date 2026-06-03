//
//  BSONTests.swift
//  mactableTests
//

import Testing
import Foundation
@testable import mactable

struct BSONTests {
    @Test func encodeDecodeRoundTripScalars() throws {
        var doc = BSONDocument()
        doc["name"] = .string("Avijeet")
        doc["age"] = .int32(28)
        doc["score"] = .double(99.5)
        doc["active"] = .bool(true)
        doc["nothing"] = .null
        doc["big"] = .int64(1_000_000_000_000)

        let data = BSONEncoder.encode(doc)
        let decoded = try BSONDecoder.decode(data)

        #expect(decoded["name"] == .string("Avijeet"))
        #expect(decoded["age"] == .int32(28))
        #expect(decoded["score"] == .double(99.5))
        #expect(decoded["active"] == .bool(true))
        #expect(decoded["nothing"] == .null)
        #expect(decoded["big"] == .int64(1_000_000_000_000))
    }

    @Test func encodeDecodeNestedDoc() throws {
        var inner = BSONDocument()
        inner["x"] = .int32(1)
        var outer = BSONDocument()
        outer["nested"] = .document(inner)
        let data = BSONEncoder.encode(outer)
        let decoded = try BSONDecoder.decode(data)
        if case .document(let d) = decoded["nested"]! {
            #expect(d["x"] == .int32(1))
        } else {
            Issue.record("expected nested doc")
        }
    }

    @Test func encodeDecodeArray() throws {
        var doc = BSONDocument()
        doc["arr"] = .array([.int32(1), .int32(2), .string("three")])
        let data = BSONEncoder.encode(doc)
        let decoded = try BSONDecoder.decode(data)
        if case .array(let a) = decoded["arr"]! {
            #expect(a.count == 3)
            #expect(a[0] == .int32(1))
            #expect(a[2] == .string("three"))
        } else {
            Issue.record("expected array")
        }
    }
}

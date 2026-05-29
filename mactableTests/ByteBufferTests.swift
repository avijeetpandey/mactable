//
//  ByteBufferTests.swift
//  mactableTests
//

import Testing
import Foundation
@testable import mactable

struct ByteBufferTests {
    @Test func roundTripInt32BE() throws {
        var w = ByteWriter()
        w.writeInt32BE(123456789)
        var r = ByteReader(w.data)
        #expect(try r.readInt32BE() == 123456789)
    }

    @Test func roundTripInt32LE() throws {
        var w = ByteWriter()
        w.writeInt32LE(-42)
        var r = ByteReader(w.data)
        #expect(try r.readInt32LE() == -42)
    }

    @Test func cStringRoundTrip() throws {
        var w = ByteWriter()
        w.writeCString("hello")
        var r = ByteReader(w.data)
        #expect(try r.readCString() == "hello")
    }

    @Test func lengthEncodedString() throws {
        var w = ByteWriter()
        w.writeLengthEncodedString("MacTable")
        var r = ByteReader(w.data)
        #expect(try r.readLengthEncodedString() == "MacTable")
    }

    @Test func doubleRoundTrip() throws {
        var w = ByteWriter()
        w.writeDoubleLE(3.14159)
        var r = ByteReader(w.data)
        let d = try r.readDoubleLE()
        #expect(abs(d - 3.14159) < 1e-9)
    }
}

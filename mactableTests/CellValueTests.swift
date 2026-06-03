//
//  CellValueTests.swift
//  mactableTests
//

import Testing
import Foundation
@testable import mactable

struct CellValueTests {
    @Test func nullDisplaysAsNULL() {
        #expect(CellValue.null.displayString == "NULL")
    }

    @Test func integerInferredFromString() {
        let v = CellValue.from(string: "42", typeHint: "integer")
        if case .integer(let i) = v { #expect(i == 42) } else { Issue.record("expected integer") }
    }

    @Test func boolInferredFromTLetter() {
        let v = CellValue.from(string: "t", typeHint: "boolean")
        if case .bool(let b) = v { #expect(b == true) } else { Issue.record("expected bool") }
    }

    @Test func jsonRepresentationEscapesQuotes() {
        let v = CellValue.string("she said \"hi\"")
        #expect(v.jsonRepresentation.contains("\\\""))
    }

    @Test func nullCheck() {
        #expect(CellValue.null.isNull)
        #expect(!CellValue.integer(0).isNull)
    }
}

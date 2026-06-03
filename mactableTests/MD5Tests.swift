//
//  MD5Tests.swift
//  mactableTests
//

import Testing
import Foundation
@testable import mactable

struct MD5Tests {
    @Test func emptyHash() {
        #expect(MD5.hexHash(Data()) == "d41d8cd98f00b204e9800998ecf8427e")
    }

    @Test func abcHash() {
        #expect(MD5.hexHash("abc".data(using: .utf8)!) == "900150983cd24fb0d6963f7d28e17f72")
    }

    @Test func longerHash() {
        let s = "The quick brown fox jumps over the lazy dog"
        #expect(MD5.hexHash(s.data(using: .utf8)!) == "9e107d9d372bb6826bd81d3542a419d6")
    }
}

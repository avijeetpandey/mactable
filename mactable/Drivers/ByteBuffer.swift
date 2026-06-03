//
//  ByteBuffer.swift
//  mactable
//
//  Simple read/write byte buffer for protocol parsing.
//

import Foundation

struct ByteWriter {
    private(set) var data = Data()

    mutating func writeUInt8(_ v: UInt8) { data.append(v) }

    mutating func writeUInt16BE(_ v: UInt16) {
        data.append(UInt8(v >> 8))
        data.append(UInt8(v & 0xFF))
    }

    mutating func writeInt32BE(_ v: Int32) {
        let u = UInt32(bitPattern: v)
        data.append(UInt8((u >> 24) & 0xFF))
        data.append(UInt8((u >> 16) & 0xFF))
        data.append(UInt8((u >> 8) & 0xFF))
        data.append(UInt8(u & 0xFF))
    }

    mutating func writeUInt32LE(_ v: UInt32) {
        data.append(UInt8(v & 0xFF))
        data.append(UInt8((v >> 8) & 0xFF))
        data.append(UInt8((v >> 16) & 0xFF))
        data.append(UInt8((v >> 24) & 0xFF))
    }

    mutating func writeInt32LE(_ v: Int32) {
        writeUInt32LE(UInt32(bitPattern: v))
    }

    mutating func writeInt64LE(_ v: Int64) {
        let u = UInt64(bitPattern: v)
        for i in 0..<8 { data.append(UInt8((u >> (8 * i)) & 0xFF)) }
    }

    mutating func writeDoubleLE(_ v: Double) {
        writeInt64LE(Int64(bitPattern: v.bitPattern))
    }

    mutating func writeBytes(_ bytes: Data) { data.append(bytes) }

    mutating func writeCString(_ s: String) {
        if let bytes = s.data(using: .utf8) { data.append(bytes) }
        data.append(0)
    }

    mutating func writeLengthEncodedString(_ s: String) {
        let bytes = s.data(using: .utf8) ?? Data()
        writeLengthEncodedInt(UInt64(bytes.count))
        data.append(bytes)
    }

    mutating func writeLengthEncodedInt(_ v: UInt64) {
        if v < 251 {
            data.append(UInt8(v))
        } else if v < 1 << 16 {
            data.append(0xFC)
            data.append(UInt8(v & 0xFF))
            data.append(UInt8((v >> 8) & 0xFF))
        } else if v < 1 << 24 {
            data.append(0xFD)
            data.append(UInt8(v & 0xFF))
            data.append(UInt8((v >> 8) & 0xFF))
            data.append(UInt8((v >> 16) & 0xFF))
        } else {
            data.append(0xFE)
            for i in 0..<8 { data.append(UInt8((v >> (8 * i)) & 0xFF)) }
        }
    }
}

struct ByteReader {
    let data: Data
    private(set) var index: Int

    init(_ data: Data, index: Int = 0) {
        self.data = data
        self.index = index
    }

    var remaining: Int { data.count - index }
    var isAtEnd: Bool { index >= data.count }

    mutating func readUInt8() throws -> UInt8 {
        guard index < data.count else { throw DatabaseError.protocolError("read past end") }
        let v = data[data.startIndex + index]
        index += 1
        return v
    }

    mutating func readInt32BE() throws -> Int32 {
        guard index + 4 <= data.count else { throw DatabaseError.protocolError("short read i32be") }
        var u: UInt32 = 0
        for i in 0..<4 { u = (u << 8) | UInt32(data[data.startIndex + index + i]) }
        index += 4
        return Int32(bitPattern: u)
    }

    mutating func readUInt16BE() throws -> UInt16 {
        guard index + 2 <= data.count else { throw DatabaseError.protocolError("short read u16be") }
        let hi = UInt16(data[data.startIndex + index])
        let lo = UInt16(data[data.startIndex + index + 1])
        index += 2
        return (hi << 8) | lo
    }

    mutating func readUInt32LE() throws -> UInt32 {
        guard index + 4 <= data.count else { throw DatabaseError.protocolError("short read u32le") }
        var u: UInt32 = 0
        for i in 0..<4 { u |= UInt32(data[data.startIndex + index + i]) << (8 * i) }
        index += 4
        return u
    }

    mutating func readInt32LE() throws -> Int32 {
        Int32(bitPattern: try readUInt32LE())
    }

    mutating func readInt64LE() throws -> Int64 {
        guard index + 8 <= data.count else { throw DatabaseError.protocolError("short read i64le") }
        var u: UInt64 = 0
        for i in 0..<8 { u |= UInt64(data[data.startIndex + index + i]) << (8 * i) }
        index += 8
        return Int64(bitPattern: u)
    }

    mutating func readDoubleLE() throws -> Double {
        Double(bitPattern: UInt64(bitPattern: try readInt64LE()))
    }

    mutating func readBytes(_ n: Int) throws -> Data {
        guard index + n <= data.count else { throw DatabaseError.protocolError("short read bytes \(n)") }
        let slice = data.subdata(in: (data.startIndex + index)..<(data.startIndex + index + n))
        index += n
        return slice
    }

    mutating func readCString() throws -> String {
        var bytes: [UInt8] = []
        while index < data.count {
            let b = data[data.startIndex + index]
            index += 1
            if b == 0 { return String(bytes: bytes, encoding: .utf8) ?? "" }
            bytes.append(b)
        }
        throw DatabaseError.protocolError("unterminated cstring")
    }

    mutating func readLengthEncodedInt() throws -> UInt64 {
        let first = try readUInt8()
        switch first {
        case 0xFB: return 0 // NULL marker, treat as 0; caller checks 0xFB separately
        case 0xFC:
            let lo = UInt64(try readUInt8()); let hi = UInt64(try readUInt8())
            return lo | (hi << 8)
        case 0xFD:
            let b0 = UInt64(try readUInt8()); let b1 = UInt64(try readUInt8()); let b2 = UInt64(try readUInt8())
            return b0 | (b1 << 8) | (b2 << 16)
        case 0xFE:
            var u: UInt64 = 0
            for i in 0..<8 { u |= UInt64(try readUInt8()) << (8 * i) }
            return u
        default:
            return UInt64(first)
        }
    }

    mutating func readLengthEncodedString() throws -> String? {
        let first = try peekUInt8()
        if first == 0xFB { _ = try readUInt8(); return nil }
        let len = try readLengthEncodedInt()
        let bytes = try readBytes(Int(len))
        return String(data: bytes, encoding: .utf8) ?? ""
    }

    func peekUInt8() throws -> UInt8 {
        guard index < data.count else { throw DatabaseError.protocolError("peek past end") }
        return data[data.startIndex + index]
    }
}

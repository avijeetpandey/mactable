//
//  PostgresMessage.swift
//  mactable
//
//  PostgreSQL wire protocol v3 message helpers.
//  Reference: https://www.postgresql.org/docs/current/protocol-message-formats.html
//

import Foundation

enum PostgresBackend {
    case authenticationOk
    case authenticationCleartextPassword
    case authenticationMD5(salt: Data)
    case authenticationSASL(mechanisms: [String])
    case authenticationSASLContinue(Data)
    case authenticationSASLFinal(Data)
    case parameterStatus(name: String, value: String)
    case backendKeyData(processID: Int32, secretKey: Int32)
    case readyForQuery(status: UInt8)
    case rowDescription(fields: [PostgresFieldDescription])
    case dataRow(values: [Data?])
    case commandComplete(tag: String)
    case errorResponse(fields: [UInt8: String])
    case noticeResponse(fields: [UInt8: String])
    case emptyQueryResponse
    case parseComplete
    case bindComplete
    case noData
    case portalSuspended
    case other(type: UInt8, payload: Data)
}

struct PostgresFieldDescription: Hashable {
    let name: String
    let tableOID: Int32
    let columnAttr: Int16
    let typeOID: Int32
    let typeSize: Int16
    let typeModifier: Int32
    let format: Int16
}

enum PostgresProtocol {
    static func startupMessage(user: String, database: String) -> Data {
        var w = ByteWriter()
        w.writeInt32BE(196608) // protocol 3.0
        w.writeCString("user");     w.writeCString(user)
        if !database.isEmpty {
            w.writeCString("database"); w.writeCString(database)
        }
        w.writeCString("client_encoding"); w.writeCString("UTF8")
        w.writeCString("application_name"); w.writeCString("MacTable")
        w.writeUInt8(0)
        var prefix = ByteWriter()
        prefix.writeInt32BE(Int32(w.data.count + 4))
        return prefix.data + w.data
    }

    static func passwordMessage(_ password: String) -> Data {
        frame(type: UInt8(ascii: "p")) { w in
            w.writeCString(password)
        }
    }

    static func md5PasswordMessage(user: String, password: String, salt: Data) -> Data {
        let inner = MD5.hexHash((password + user).data(using: .utf8) ?? Data())
        let outer = "md5" + MD5.hexHash((inner.data(using: .utf8) ?? Data()) + salt)
        return passwordMessage(outer)
    }

    static func queryMessage(_ sql: String) -> Data {
        frame(type: UInt8(ascii: "Q")) { w in
            w.writeCString(sql)
        }
    }

    static func terminateMessage() -> Data {
        frame(type: UInt8(ascii: "X")) { _ in }
    }

    static func saslInitialResponse(mechanism: String, clientFirst: String) -> Data {
        frame(type: UInt8(ascii: "p")) { w in
            w.writeCString(mechanism)
            let bytes = clientFirst.data(using: .utf8) ?? Data()
            w.writeInt32BE(Int32(bytes.count))
            w.writeBytes(bytes)
        }
    }

    static func saslResponse(_ payload: String) -> Data {
        frame(type: UInt8(ascii: "p")) { w in
            w.writeBytes(payload.data(using: .utf8) ?? Data())
        }
    }

    private static func frame(type: UInt8, build: (inout ByteWriter) -> Void) -> Data {
        var inner = ByteWriter()
        build(&inner)
        var out = ByteWriter()
        out.writeUInt8(type)
        out.writeInt32BE(Int32(inner.data.count + 4))
        out.writeBytes(inner.data)
        return out.data
    }
}

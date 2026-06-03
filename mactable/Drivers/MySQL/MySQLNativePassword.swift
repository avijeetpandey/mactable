//
//  MySQLNativePassword.swift
//  mactable
//
//  mysql_native_password = SHA1(password) XOR SHA1(salt + SHA1(SHA1(password)))
//

import Foundation
import CryptoKit

enum MySQLNativePassword {
    static func scramble(password: String, nonce: Data) -> Data {
        guard !password.isEmpty else { return Data() }
        let pwd = password.data(using: .utf8) ?? Data()
        let stage1 = Data(Insecure.SHA1.hash(data: pwd))
        let stage2 = Data(Insecure.SHA1.hash(data: stage1))
        var concat = Data(); concat.append(nonce); concat.append(stage2)
        let stage3 = Data(Insecure.SHA1.hash(data: concat))
        var out = Data(count: stage1.count)
        for i in 0..<stage1.count { out[i] = stage1[i] ^ stage3[i] }
        return out
    }
}

enum MySQLCachingSHA2Password {
    /// Used for caching_sha2_password fast-path:
    /// XOR(SHA256(password), SHA256(SHA256(SHA256(password)) + scramble))
    static func scramble(password: String, nonce: Data) -> Data {
        guard !password.isEmpty else { return Data() }
        let pwd = password.data(using: .utf8) ?? Data()
        let s1 = Data(SHA256.hash(data: pwd))
        let s2 = Data(SHA256.hash(data: s1))
        var concat = Data(); concat.append(s2); concat.append(nonce)
        let s3 = Data(SHA256.hash(data: concat))
        var out = Data(count: s1.count)
        for i in 0..<s1.count { out[i] = s1[i] ^ s3[i] }
        return out
    }
}

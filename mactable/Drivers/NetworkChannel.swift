//
//  NetworkChannel.swift
//  mactable
//
//  Async TCP wrapper around Network.framework for raw DB wire protocols.
//

import Foundation
import Network

actor NetworkChannel {
    private let connection: NWConnection
    private var receiveBuffer = Data()
    private var isReady = false

    init(host: String, port: Int, useTLS: Bool) {
        // `localhost` on macOS prefers IPv6 (::1) but Docker's default port forward
        // only listens on IPv4. Force the IPv4 loopback to avoid a long .waiting hang.
        let effectiveHost = (host.lowercased() == "localhost") ? "127.0.0.1" : host
        let nwHost = NWEndpoint.Host(effectiveHost)
        let nwPort = NWEndpoint.Port(integerLiteral: UInt16(port))
        let params: NWParameters = useTLS ? .tls : .tcp
        params.includePeerToPeer = false
        if let tcp = params.defaultProtocolStack.transportProtocol as? NWProtocolTCP.Options {
            tcp.connectionTimeout = 5
            tcp.enableKeepalive = true
            tcp.noDelay = true
        }
        self.connection = NWConnection(host: nwHost, port: nwPort, using: params)
    }

    func start() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            var resumed = false
            let resumeOnce: (Result<Void, Error>) -> Void = { result in
                guard !resumed else { return }
                resumed = true
                switch result {
                case .success: cont.resume()
                case .failure(let e): cont.resume(throwing: e)
                }
            }
            connection.stateUpdateHandler = { [weak connection] state in
                switch state {
                case .ready:
                    resumeOnce(.success(()))
                case .failed(let err):
                    resumeOnce(.failure(DatabaseError.connectionFailed(Self.describe(err))))
                case .waiting(let err):
                    // Network.framework parks on .waiting for refused/unreachable peers and retries forever.
                    // Surface the error immediately and cancel so the connect attempt fails fast.
                    connection?.cancel()
                    resumeOnce(.failure(DatabaseError.connectionFailed(Self.describe(err))))
                case .cancelled:
                    resumeOnce(.failure(DatabaseError.connectionFailed("connection cancelled before ready")))
                default: break
                }
            }
            connection.start(queue: .global(qos: .userInitiated))
        }
        isReady = true
    }

    func send(_ data: Data) async throws {
        guard isReady else { throw DatabaseError.notConnected }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            connection.send(content: data, completion: .contentProcessed { err in
                if let err = err {
                    cont.resume(throwing: DatabaseError.io(err.localizedDescription))
                } else {
                    cont.resume()
                }
            })
        }
    }

    func receive(exactly n: Int) async throws -> Data {
        while receiveBuffer.count < n {
            try await receiveMore()
        }
        let chunk = receiveBuffer.prefix(n)
        receiveBuffer.removeFirst(n)
        return Data(chunk)
    }

    func receiveAvailable(maxBytes: Int = 65536) async throws -> Data {
        if !receiveBuffer.isEmpty {
            let out = receiveBuffer
            receiveBuffer.removeAll(keepingCapacity: false)
            return out
        }
        try await receiveMore()
        let out = receiveBuffer
        receiveBuffer.removeAll(keepingCapacity: false)
        return out
    }

    private func receiveMore() async throws {
        let data: Data = try await withCheckedThrowingContinuation { cont in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, err in
                if let err = err {
                    cont.resume(throwing: DatabaseError.io(err.localizedDescription))
                } else if let data = data, !data.isEmpty {
                    cont.resume(returning: data)
                } else if isComplete {
                    cont.resume(throwing: DatabaseError.io("connection closed"))
                } else {
                    cont.resume(returning: Data())
                }
            }
        }
        receiveBuffer.append(data)
    }

    func close() {
        isReady = false
        connection.cancel()
    }

    private static func describe(_ err: NWError) -> String {
        switch err {
        case .posix(let code):
            return "\(code) (\(err.localizedDescription))"
        case .dns(let code):
            return "DNS error \(code): \(err.localizedDescription)"
        case .tls(let code):
            return "TLS error \(code): \(err.localizedDescription)"
        @unknown default:
            return err.localizedDescription
        }
    }
}

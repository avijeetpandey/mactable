//
//  ConnectionFormView.swift
//  mactable
//

import SwiftUI
import SwiftData

struct ConnectionFormView: View {
    let existing: SavedConnection?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var connectionStore: ConnectionStore
    @EnvironmentObject private var toastCenter: ToastCenter

    @State private var name: String = "Local Postgres"
    @State private var kind: DatabaseKind = .postgres
    @State private var host: String = "localhost"
    @State private var port: String = "5432"
    @State private var username: String = ""
    @State private var database: String = ""
    @State private var password: String = ""
    @State private var useTLS: Bool = false
    @State private var isTesting: Bool = false
    @State private var testResult: TestResult?

    enum TestResult: Equatable { case success(String); case failure(String) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().opacity(0.3)
            form
            Divider().opacity(0.3)
            footer
        }
        .background(.ultraThinMaterial)
        .onAppear(perform: load)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: kind.symbolName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(kind.accentColor)
            Text(existing == nil ? "New Connection" : "Edit Connection")
                .font(.system(.title2, design: .rounded, weight: .bold))
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Database", selection: $kind) {
                    ForEach(DatabaseKind.allCases) { k in
                        Label(k.displayName, systemImage: k.symbolName).tag(k)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: kind) { _, new in
                    port = String(new.defaultPort)
                }

                LabeledContent("Name") {
                    TextField("My Database", text: $name).textFieldStyle(.roundedBorder)
                }
                HStack(spacing: 12) {
                    LabeledContent("Host") {
                        TextField("localhost", text: $host).textFieldStyle(.roundedBorder)
                    }
                    LabeledContent("Port") {
                        TextField("5432", text: $port).textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                    }
                }
                LabeledContent("Username") {
                    TextField("postgres", text: $username).textFieldStyle(.roundedBorder)
                }
                LabeledContent("Password") {
                    SecureField("•••••••", text: $password).textFieldStyle(.roundedBorder)
                }
                LabeledContent("Database") {
                    TextField("postgres", text: $database).textFieldStyle(.roundedBorder)
                }
                Toggle("Use TLS / SSL", isOn: $useTLS)

                if let testResult = testResult {
                    HStack(spacing: 8) {
                        Image(systemName: isSuccess(testResult) ? "checkmark.circle.fill" : "xmark.octagon.fill")
                            .foregroundStyle(isSuccess(testResult) ? .green : .red)
                        Text(message(testResult))
                            .font(.caption)
                            .foregroundStyle(isSuccess(testResult) ? .green : .red)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(20)
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button("Test Connection", action: test)
                .buttonStyle(HoverableButtonStyle(tint: .secondary))
                .disabled(isTesting)
            if isTesting { ProgressView().controlSize(.small) }
            Spacer()
            Button("Cancel") { dismiss() }
            Button(existing == nil ? "Save & Connect" : "Save", action: save)
                .keyboardShortcut(.defaultAction)
        }
        .padding(20)
    }

    private func isSuccess(_ r: TestResult) -> Bool { if case .success = r { return true } else { return false } }
    private func message(_ r: TestResult) -> String {
        switch r { case .success(let s): return s; case .failure(let s): return s }
    }

    private func load() {
        guard let existing = existing else { return }
        name = existing.name
        kind = existing.kind
        host = existing.host
        port = String(existing.port)
        username = existing.username
        database = existing.database
        useTLS = existing.useTLS
        password = KeychainService.loadPassword(for: existing.id) ?? ""
    }

    private func makeConfig() -> ConnectionConfig {
        ConnectionConfig(
            id: existing?.id ?? UUID(),
            name: name.isEmpty ? "Connection" : name,
            kind: kind,
            host: host,
            port: Int(port) ?? kind.defaultPort,
            username: username,
            database: database,
            useTLS: useTLS
        )
    }

    private func test() {
        isTesting = true
        testResult = nil
        let cfg = makeConfig()
        let pwd = password
        Task {
            let driver = DriverFactory.make(for: cfg.kind)
            do {
                try await driver.connect(config: cfg, password: pwd)
                let version = driver.serverVersion ?? "connected"
                await driver.disconnect()
                await MainActor.run {
                    testResult = .success("OK · \(version)")
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = .failure(error.localizedDescription)
                    isTesting = false
                }
            }
        }
    }

    private func save() {
        let cfg = makeConfig()
        do { try KeychainService.savePassword(password, for: cfg.id) }
        catch { toastCenter.error(error) }

        if let existing = existing {
            existing.update(from: cfg)
        } else {
            let saved = SavedConnection(id: cfg.id, name: cfg.name, kind: cfg.kind,
                                        host: cfg.host, port: cfg.port,
                                        username: cfg.username, database: cfg.database,
                                        useTLS: cfg.useTLS)
            modelContext.insert(saved)
        }
        try? modelContext.save()
        if existing == nil { connectionStore.startConnecting(config: cfg) }
        toastCenter.push("Saved connection “\(cfg.name)”", kind: .success)
        dismiss()
    }
}

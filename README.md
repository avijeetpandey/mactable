# MacTable

A native macOS database management application built in 100% Swift / SwiftUI.
A professional, open-source macOS database client — built entirely in Swift and SwiftUI.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![SwiftUI](https://img.shields.io/badge/SwiftUI-5-orange) ![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

| Phase | Capability | Status |
|-------|-----------|--------|
| 1 | App architecture, hidden title bar, NavigationSplitView, MVVM + POP | ✅ |
| 2 | PostgreSQL, MySQL, MongoDB drivers · Keychain · Skeleton loading | ✅ |
| 3 | Virtualized data grid · Inline value preview · CSV/JSON export · Safe Mode | ✅ |
| 4 | NSTextView SQL editor · syntax highlighting · autocomplete · split panes · ⌘↩ / ⌘T | ✅ |
| 5 | Metrics dashboard with Swift Charts · stat cards · sparklines · slow queries | ✅ |
| 6 | Floating toast system · spring animations · hover effects · empty states | ✅ |
| 7 | Unit tests (Swift Testing) · UI test scaffold · App icon · code structure | ✅ |

## Architecture

```
mactable/
├── App/             Entry point, window, root view, notifications
├── Models/          Domain types (Connection, QueryResult, CellValue, …)
├── Persistence/     SwiftData @Model for SavedConnection
├── Drivers/         DatabaseDriver protocol + concrete drivers
│   ├── Postgres/    Wire-protocol v3 client (MD5 + cleartext auth)
│   ├── MySQL/       Wire-protocol client (mysql_native_password, caching_sha2_password fast-path)
│   ├── Mongo/       OP_MSG wire client + JSON-style query parser
│   └── BSON/        Pure-Swift BSON encoder/decoder
├── Services/        ConnectionStore · KeychainService · ToastCenter · ExportService
├── ViewModels/      QueryEditorViewModel · DashboardViewModel
├── Views/           SwiftUI screens (Sidebar, ConnectionForm, SQLEditor, DataGrid, Dashboard, Toast, Common)
└── Utils/           AsyncSemaphore · TimeSeriesGenerator
```

Strict rules followed throughout:

* **Protocol-Oriented + MVVM** — every screen uses an `ObservableObject` view model; UI never talks to a driver directly outside its VM.
* **One type per file** — every `class`, `struct`, and `enum` lives in its own Swift file.
* **No placeholders** — there are no `TODO`/`fatalError("not implemented")`/mock stubs in the production code.
* **Mac-assed** — `.windowStyle(.hiddenTitleBar)`, `.background(.ultraThinMaterial)`, SF Symbols, SF Mono, spring animations, hover shimmer.

## Drivers

The drivers are written from scratch on top of `Network.framework` so the app
ships with **zero third-party dependencies**. This keeps the project portable
and removes SPM/Xcode-build friction.

| Driver | Auth Methods | Query Surface |
|--------|--------------|---------------|
| PostgreSQL | trust, cleartext, MD5 | Simple Query (`Q`) protocol, full row description, `pg_stat_statements` if enabled |
| MySQL      | `mysql_native_password`, `caching_sha2_password` (fast-path) | Text protocol `COM_QUERY` |
| MongoDB    | unauthenticated (SCRAM not yet wired — see Limitations) | OP_MSG · `find` / `aggregate` / `count` / arbitrary command JSON |

> **Limitations:** PostgreSQL SCRAM-SHA-256 and MongoDB SCRAM authentication are
> not yet implemented. Connect via MD5 / no-auth or through an SSH tunnel.
> SSL/TLS is supported transparently via `NWParameters.tls` if the toggle is
> enabled in the connection form.

## Building

```bash
xcodebuild -project mactable.xcodeproj -scheme mactable -destination 'platform=macOS' build
```

Run unit tests:

```bash
xcodebuild test -project mactable.xcodeproj -scheme mactable -destination 'platform=macOS' -only-testing:mactableTests
```

The app uses **App Sandbox + Hardened Runtime** with the
`com.apple.security.network.client` entitlement so it can dial out to remote
databases.

## Connection Form

* Choose database kind (segmented control auto-fills default port).
* Credentials are stored in macOS Keychain — never on disk in plaintext.
* "Test Connection" performs a real handshake with the target server.

## Safe Mode

Destructive statements (`UPDATE`, `DELETE`, `DROP`, `TRUNCATE`, `ALTER`,
`INSERT`) trigger a confirmation alert before execution. Toggle off only when
you know what you're doing.

## SwiftData

`SavedConnection` is a `@Model` so the connection list persists automatically
in the user's container. Passwords are stored in Keychain keyed by the
`SavedConnection.id` UUID.

## Tests

Unit tests cover:

* `CellValue` parsing
* `ByteWriter`/`ByteReader` round trips
* MD5 (RFC 1321 reference vectors)
* BSON encode/decode round-trips
* Mongo query parser
* Export service (CSV/JSON/SQL dump)
* Driver factory

UI tests live in `mactableUITests` and verify launch + connection form opening.

## License

MIT (or your preferred license — placeholder).

# Project Overview
Native iOS app built with SwiftUI. Deployment target **iOS 17.6**, Swift 6 language
mode (strict concurrency). Single Xcode project (`PideYa.xcodeproj`), no SPM
dependencies yet. Targets: `PideYa`, `PideYaTests`, `PideYaUITests` — all under the
single scheme `PideYa`.

## Essential CLI Commands
Prerequisite (one time, needs your password): `sudo xcode-select -s /Applications/Xcode.app`.
Until that's run, `xcodebuild` resolves to CommandLineTools and fails — prefix commands
with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` as a fallback.

- Build: `xcodebuild build -scheme PideYa -destination 'platform=iOS Simulator,name=iPhone 17'`
- Unit tests: `xcodebuild test -scheme PideYa -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PideYaTests`
- UI tests: same, with `-only-testing:PideYaUITests`

Pipe through `| xcbeautify` for readable output — **not installed yet**
(`brew install xcbeautify`).

## Tooling Not Yet Installed
Don't invoke these until they're set up; they are aspirational, not part of the build.
- `swiftformat` / `swiftlint` — `brew install swiftformat swiftlint`, then add configs.
- SnapshotTesting — not an SPM dependency yet; add before writing snapshot tests.
- There is no `project.yml`; the `.pbxproj` is checked in directly. Do not run `xcodegen`.

## Architecture & Patterns
- **Architecture**: MVVM with `@Observable` (Observation framework). Do not use `ObservableObject` or `@Published`.
- **Concurrency**: Swift 6 strict concurrency.
  - The project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so types are MainActor-isolated
    by default. Annotate ViewModels `@MainActor` explicitly anyway for intent; mark types that must
    leave the main actor as `nonisolated`.
  - All inter-boundary models must conform to `Sendable`.
  - Prefer `TaskGroup` or `async let` for parallel execution; avoid detached tasks unless explicitly isolated.
- **Dependency Injection**: Protocol-driven constructor injection via initializers. Avoid global singletons; pass dependencies through the environment or container.
- **Navigation**: Use NavigationStack with typed enum destinations (`.navigationDestination(for:)`).
- **Persistence**: None. The SwiftData template code was removed; re-add it deliberately if needed.

## Code Style & Guardrails
- **SwiftUI Views**: Keep view `body` under 40 lines. Decompose into modular, private subviews or computed properties.
- **View entry point**: `PideYaApp` → `HomeView(viewModel:)`. ViewModels are injected via `init` and held with `@State`.
- **Strictly Prohibited**:
  - `AnyView` (breaks view diffing and lifecycle optimization).
  - Unhandled `try?` in networking/business logic — always map or handle errors explicitly.
  - Direct access to `UserDefaults.standard` outside designated storage actors/services.
- **Testing**: Use the Swift Testing framework (`import Testing`, `@Test`, `#expect(...)`) instead of legacy `XCTest` where possible. Implement snapshot tests via SnapshotTesting once it's added.

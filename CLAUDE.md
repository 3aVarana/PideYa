# Project Overview
Native iOS app built with iOS 18+ minimum deployment target, Swift 6 strict concurrency, and SwiftUI.

## Essential CLI Commands
- Build (Device/Sim): `xcodebuild build -scheme App -destination 'platform=iOS Simulator,name=iPhone 16' | xcbeautify`
- Run Unit Tests: `xcodebuild test -scheme App -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AppTests | xcbeautify`
- Lint / Format: `swiftformat . --lint` / `swiftlint lint --strict`
- Generate Assets: `xcodegen generate` (if project.yml changes)

## Architecture & Patterns
- **Architecture**: MVVM with `@Observable` (Observation framework). Do not use `ObservableObject` or `@Published`.
- **Concurrency**: Swift 6 Strict Concurrency enabled. 
  - Annotate UI-bound ViewModels with `@MainActor`.
  - All inter-boundary models must conform to `Sendable`.
  - Prefer `TaskGroup` or `async let` for parallel execution; avoid detached tasks unless explicitly isolated.
- **Dependency Injection**: Protocol-driven constructor injection via initializers. Avoid global singletons; pass dependencies through the environment or container.
- **Navigation**: Use NavigationStack with typed enum destinations (`.navigationDestination(for:)`).

## Code Style & Guardrails
- **SwiftUI Views**: Keep view `body` under 40 lines. Decompose into modular, private subviews or computed properties.
- **Strictly Prohibited**:
  - `AnyView` (breaks view diffing and lifecycle optimization).
  - Unhandled `try?` in networking/business logic — always map or handle errors explicitly.
  - Direct access to `UserDefaults.standard` outside designated storage actors/services.
- **Testing**: Use the Swift Testing framework (`import Testing`, `@Test`, `#expect(...)`) instead of legacy `XCTest` where possible.

//
//  AccountModels.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import Foundation

// `Víctor Arana` below is the repository owner's own name, used as mock display data for the
// Cuenta tab. It is not a credential and is not stored anywhere (no `UserDefaults`, no
// persistence), so it does not require redaction — the same class of sample content as
// `Taquería Norte` in `MockOrdersContentProvider`.

// `nonisolated` on a type declaration does NOT propagate into a separate extension block under
// this project's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Every extension in this file is
// therefore marked explicitly with that keyword, and `esES` below is also marked with it, so
// those extensions can reference it from a nonisolated context. For *this* file, dropping either
// annotation stops the nonisolated test suites below (e.g. `AccountTileRowTests`,
// `MockAccountContentProviderTests`) from compiling — a compile-time error, a stronger guard than
// a runtime trap. The general reason this rule exists (why DESIGN.md §8.8 calls it out): on other
// call shapes it instead compiles and traps at runtime (`EXC_BREAKPOINT` in
// `swift_task_checkIsolatedSwift`) the moment a closure-bearing member is called from a
// nonisolated context.
private nonisolated let esES = Locale(identifier: "es_ES")

nonisolated enum VerificationState: String, Hashable, Sendable {
    case verified
    case pending
}

nonisolated enum AccountBadgeKind: String, CaseIterable, Identifiable, Hashable, Sendable {
    case email
    case phone

    var id: String { rawValue }
}

nonisolated struct AccountBadge: Identifiable, Hashable, Sendable {
    let kind: AccountBadgeKind
    let state: VerificationState

    var id: String { kind.rawValue }
}

nonisolated struct AccountProfile: Hashable, Sendable {
    let givenName: String
    let familyName: String
    let emailState: VerificationState
    let phoneState: VerificationState
}

nonisolated enum AccountTileKind: String, CaseIterable, Identifiable, Hashable, Sendable {
    case perfil
    case identidad
    case seguridad
    case notificaciones
    case comunicacion
    case pagos

    var id: String { rawValue }

    var title: String {
        switch self {
        case .perfil: "Perfil"
        case .identidad: "Identidad"
        case .seguridad: "Seguridad"
        case .notificaciones: "Notificaciones"
        case .comunicacion: "Comunicación"
        case .pagos: "Pagos"
        }
    }

    var systemImage: String {
        switch self {
        case .perfil: "person"
        case .identidad: "person.text.rectangle"
        case .seguridad: "checkmark.shield"
        case .notificaciones: "bell"
        case .comunicacion: "bubble.left"
        case .pagos: "creditcard"
        }
    }
}

nonisolated struct AccountTile: Identifiable, Hashable, Sendable {
    let kind: AccountTileKind
    let subtitle: String
    /// The single flag driving both the icon and the subtitle colour (DESIGN.md §4.3): the red
    /// is a state, not a per-tile decoration.
    let needsAttention: Bool

    var id: String { kind.rawValue }
}

nonisolated struct AccountTileRow: Identifiable, Hashable, Sendable {
    let id: Int
    let tiles: [AccountTile]

    /// Chunks `tiles` into rows of `columns` tiles each, in order. `columns` is clamped to
    /// `max(1, columns)` so a caller passing `0` or a negative value cannot crash. A ragged final
    /// row is returned short — the view is responsible for padding it to column width.
    static func rows(from tiles: [AccountTile], columns: Int) -> [AccountTileRow] {
        let clampedColumns = max(1, columns)
        return stride(from: 0, to: tiles.count, by: clampedColumns).enumerated()
            .map { rowIndex, start in
                let end = min(start + clampedColumns, tiles.count)
                return AccountTileRow(id: rowIndex, tiles: Array(tiles[start..<end]))
            }
    }
}

nonisolated struct AccountWallet: Hashable, Sendable {
    let balance: Decimal
}

nonisolated struct PaymentMethod: Hashable, Sendable {
    let brand: String
    let last4: String
}

nonisolated extension AccountBadge {
    /// Literal uppercase text, from `kind` × `state`. All four combinations are implemented and
    /// tested even though the mock only uses two of them.
    var text: String {
        switch (kind, state) {
        case (.email, .verified): "EMAIL VERIFICADO"
        case (.email, .pending): "EMAIL PENDIENTE"
        case (.phone, .verified): "TEL. VERIFICADO"
        case (.phone, .pending): "TEL. PENDIENTE"
        }
    }

    var isVerified: Bool {
        state == .verified
    }
}

nonisolated extension AccountProfile {
    /// Always exactly two badges, email then phone, derived from `emailState`/`phoneState` so a
    /// badge can never contradict the profile it came from.
    var badges: [AccountBadge] {
        [
            AccountBadge(kind: .email, state: emailState),
            AccountBadge(kind: .phone, state: phoneState),
        ]
    }
}

nonisolated extension AccountWallet {
    /// `"12,50\u{00A0}€"` — a NON-BREAKING SPACE (U+00A0) before `€`, not a plain space.
    var balanceText: String {
        balance.formatted(.currency(code: "EUR").locale(esES))
    }
}

nonisolated extension PaymentMethod {
    /// `"Visa ···· 4412"` — the masking glyphs are four U+00B7 middle dots.
    var maskedText: String {
        "\(brand) \u{00B7}\u{00B7}\u{00B7}\u{00B7} \(last4)"
    }

    /// `"Visa ···· 4412 · 12,50\u{00A0}€"`. Takes `wallet` rather than a number, so the Pagos
    /// tile subtitle is structurally incapable of showing a different balance from `MONEDERO`.
    func summaryText(wallet: AccountWallet) -> String {
        "\(maskedText) \u{00B7} \(wallet.balanceText)"
    }
}

nonisolated protocol AccountContentProviding: Sendable {
    func profile() -> AccountProfile
    /// Must return tiles with unique `kind`s: `AccountTile.id` is `kind.rawValue`, and a
    /// duplicate produces two equal `ForEach` ids in `AccountTileGridView`.
    func tiles() -> [AccountTile]
    func wallet() -> AccountWallet
}

nonisolated struct MockAccountContentProvider: AccountContentProviding {
    private static let seedWallet = AccountWallet(balance: 12.50)
    private static let seedPayment = PaymentMethod(brand: "Visa", last4: "4412")
    private static let seedProfile = AccountProfile(
        givenName: "Víctor",
        familyName: "Arana",
        emailState: .verified,
        phoneState: .pending
    )

    // All six rows are pinned by DESIGN.md §4.3 — nothing invented.
    private static let seedTiles: [AccountTile] = [
        AccountTile(kind: .perfil, subtitle: "Nombre, foto, direcciones", needsAttention: false),
        AccountTile(kind: .identidad, subtitle: "Teléfono sin verificar", needsAttention: true),
        AccountTile(kind: .seguridad, subtitle: "2FA desactivada", needsAttention: true),
        AccountTile(kind: .notificaciones, subtitle: "Push y email activos", needsAttention: false),
        AccountTile(kind: .comunicacion, subtitle: "Español · sin marketing", needsAttention: false),
        AccountTile(
            kind: .pagos,
            subtitle: seedPayment.summaryText(wallet: seedWallet),
            needsAttention: false
        ),
    ]

    func profile() -> AccountProfile {
        Self.seedProfile
    }

    func tiles() -> [AccountTile] {
        Self.seedTiles
    }

    func wallet() -> AccountWallet {
        Self.seedWallet
    }

    /// Not part of `AccountContentProviding` — exposed so tests can re-derive the Pagos tile's
    /// subtitle from its two real ingredients instead of asserting against a literal.
    func paymentMethod() -> PaymentMethod {
        Self.seedPayment
    }
}

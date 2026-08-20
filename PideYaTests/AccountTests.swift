//
//  AccountTests.swift
//  PideYaTests
//
//  Created by Victor Arana on 16/8/26.
//

import Foundation
import Testing

@testable import PideYa

private struct StubAccountContentProvider: AccountContentProviding {
    func profile() -> AccountProfile {
        AccountProfile(givenName: "Estela", familyName: "Ríos", emailState: .pending, phoneState: .verified)
    }

    func tiles() -> [AccountTile] {
        [
            AccountTile(kind: .perfil, subtitle: "Stub subtitle 1", needsAttention: false),
            AccountTile(kind: .pagos, subtitle: "Stub subtitle 2", needsAttention: true),
        ]
    }

    func wallet() -> AccountWallet {
        AccountWallet(balance: 3.05)
    }
}

private struct EmptyAccountContentProvider: AccountContentProviding {
    func profile() -> AccountProfile {
        AccountProfile(givenName: "", familyName: "", emailState: .pending, phoneState: .pending)
    }

    func tiles() -> [AccountTile] {
        []
    }

    func wallet() -> AccountWallet {
        AccountWallet(balance: 0)
    }
}

struct AccountTileKindTests {
    @Test func tileKindsAreTheSixDesignedTilesInOrder() {
        #expect(
            AccountTileKind.allCases.map(\.rawValue) == [
                "perfil", "identidad", "seguridad", "notificaciones", "comunicacion", "pagos",
            ]
        )
        #expect(
            AccountTileKind.allCases.map(\.title) == [
                "Perfil", "Identidad", "Seguridad", "Notificaciones", "Comunicación", "Pagos",
            ]
        )
        #expect(
            AccountTileKind.allCases.map(\.systemImage) == [
                "person", "person.text.rectangle", "checkmark.shield", "bell", "bubble.left", "creditcard",
            ]
        )
    }
}

struct AccountFormattingTests {
    @Test func badgeTextCoversEveryKindAndStateCombination() {
        #expect(AccountBadge(kind: .email, state: .verified).text == "EMAIL VERIFICADO")
        #expect(AccountBadge(kind: .email, state: .pending).text == "EMAIL PENDIENTE")
        #expect(AccountBadge(kind: .phone, state: .verified).text == "TEL. VERIFICADO")
        #expect(AccountBadge(kind: .phone, state: .pending).text == "TEL. PENDIENTE")
    }

    @Test func profileBadgesAreEmailThenPhoneAndDerivedFromState() {
        let profile = AccountProfile(givenName: "A", familyName: "B", emailState: .verified, phoneState: .pending)
        #expect(profile.badges.count == 2)
        #expect(profile.badges[0].kind == .email)
        #expect(profile.badges[0].text == "EMAIL VERIFICADO")
        #expect(profile.badges[1].kind == .phone)
        #expect(profile.badges[1].text == "TEL. PENDIENTE")

        let verifiedPhone = AccountProfile(
            givenName: "A", familyName: "B", emailState: .verified, phoneState: .verified
        )
        #expect(verifiedPhone.badges[1].text == "TEL. VERIFICADO")
    }

    @Test func walletBalanceTextUsesNonBreakingSpaceBeforeEuro() {
        #expect(AccountWallet(balance: 12.50).balanceText == "12,50\u{00A0}€")
        #expect(AccountWallet(balance: 0).balanceText == "0,00\u{00A0}€")
    }

    @Test func paymentMaskedTextUsesFourMiddleDots() {
        let payment = PaymentMethod(brand: "Visa", last4: "4412")
        #expect(payment.maskedText == "Visa \u{00B7}\u{00B7}\u{00B7}\u{00B7} 4412")
    }

    @Test func paymentSummaryTextReadsTheWalletItIsGiven() {
        let payment = PaymentMethod(brand: "Visa", last4: "4412")
        #expect(
            payment.summaryText(wallet: AccountWallet(balance: 12.50))
                == "Visa \u{00B7}\u{00B7}\u{00B7}\u{00B7} 4412 \u{00B7} 12,50\u{00A0}€")
        #expect(payment.summaryText(wallet: AccountWallet(balance: 99)).hasSuffix("99,00\u{00A0}€"))
    }
}

struct AccountTileRowTests {
    private func makeTiles(_ count: Int) -> [AccountTile] {
        (0..<count)
            .map { index in
                AccountTile(
                    kind: AccountTileKind.allCases[index % AccountTileKind.allCases.count], subtitle: "\(index)",
                    needsAttention: false)
            }
    }

    @Test func tileRowsChunkSixTilesIntoThreePairs() {
        let tiles = makeTiles(6)
        let rows = AccountTileRow.rows(from: tiles, columns: 2)
        #expect(rows.map(\.id) == [0, 1, 2])
        #expect(rows.map { $0.tiles.count } == [2, 2, 2])
        #expect(rows.flatMap(\.tiles) == tiles)
    }

    @Test func tileRowsCollapseToOnePerRowForOneColumn() {
        let tiles = makeTiles(6)
        let rows = AccountTileRow.rows(from: tiles, columns: 1)
        #expect(rows.count == 6)
        #expect(rows.allSatisfy { $0.tiles.count == 1 })
    }

    @Test func tileRowsHandleRaggedAndDegenerateInput() {
        let ragged = AccountTileRow.rows(from: makeTiles(5), columns: 2)
        #expect(ragged.map { $0.tiles.count } == [2, 2, 1])

        #expect(AccountTileRow.rows(from: [], columns: 2).isEmpty)

        let zeroColumns = AccountTileRow.rows(from: makeTiles(3), columns: 0)
        #expect(zeroColumns.map { $0.tiles.count } == [1, 1, 1])

        let negativeColumns = AccountTileRow.rows(from: makeTiles(3), columns: -3)
        #expect(negativeColumns.map { $0.tiles.count } == [1, 1, 1])
    }

    /// The §8.8 guard. A non-`@MainActor` test calling closure-bearing/extension-declared
    /// members from a nonisolated context. Dropping a `nonisolated` annotation in
    /// `AccountModels.swift` makes this suite stop compiling (a compile-time error, not a
    /// runtime trap, for this specific file) — do NOT annotate this suite `@MainActor` to "fix"
    /// a failure.
    @Test func modelFormattingRunsFromANonisolatedContext() {
        let tiles = makeTiles(4)
        let rows = AccountTileRow.rows(from: tiles, columns: 2)
        #expect(rows.count == 2)

        let profile = AccountProfile(givenName: "A", familyName: "B", emailState: .verified, phoneState: .pending)
        #expect(profile.badges.count == 2)

        let payment = PaymentMethod(brand: "Visa", last4: "4412")
        #expect(
            payment.summaryText(wallet: AccountWallet(balance: 1))
                == "Visa \u{00B7}\u{00B7}\u{00B7}\u{00B7} 4412 \u{00B7} 1,00\u{00A0}€")
    }
}

struct MockAccountContentProviderTests {
    @Test func mockProviderSeedsTheSixDesignedTiles() {
        let provider = MockAccountContentProvider()
        let tiles = provider.tiles()
        #expect(tiles.map(\.kind) == AccountTileKind.allCases)
        #expect(tiles.map(\.subtitle)[0] == "Nombre, foto, direcciones")
        #expect(tiles.map(\.subtitle)[1] == "Teléfono sin verificar")
        #expect(tiles.map(\.subtitle)[2] == "2FA desactivada")
        #expect(tiles.map(\.subtitle)[3] == "Push y email activos")
        #expect(tiles.map(\.subtitle)[4] == "Español · sin marketing")
        #expect(tiles.map(\.needsAttention) == [false, true, true, false, false, false])
    }

    @Test func mockIdentityTileAttentionMatchesPhoneState() {
        let provider = MockAccountContentProvider()
        let identidad = provider.tiles().first { $0.kind == .identidad }
        #expect(identidad?.needsAttention == (provider.profile().phoneState == .pending))
    }

    @Test func mockProfileStoresGivenAndFamilyNameSeparately() {
        let profile = MockAccountContentProvider().profile()
        #expect(profile.givenName == "Víctor")
        #expect(profile.familyName == "Arana")
        #expect(profile.emailState == .verified)
        #expect(profile.phoneState == .pending)
    }

    @Test func mockPagosSubtitleIsDerivedFromTheSameWallet() {
        let provider = MockAccountContentProvider()
        let pagos = provider.tiles().first { $0.kind == .pagos }
        // Re-derives the expected subtitle from the provider's own payment method and wallet, so
        // no hardcoded literal (e.g. replacing the derivation with a fixed string) could satisfy
        // this by coincidence.
        #expect(pagos?.subtitle == provider.paymentMethod().summaryText(wallet: provider.wallet()))
        #expect(provider.wallet().balance == 12.50)
    }
}

@MainActor
struct AccountViewModelTests {
    @Test func viewModelSurfacesInjectedProviderData() {
        let viewModel = AccountViewModel(provider: StubAccountContentProvider())
        #expect(viewModel.profile.givenName == "Estela")
        #expect(viewModel.tiles.count == 2)
        #expect(viewModel.wallet.balance == 3.05)
    }

    @Test func viewModelWithEmptyProviderHasNoTiles() {
        let viewModel = AccountViewModel(provider: EmptyAccountContentProvider())
        #expect(viewModel.tiles.isEmpty)
        #expect(AccountTileRow.rows(from: [], columns: 2).isEmpty)
    }
}

@MainActor
struct HomeTabViewModelAccountTests {
    @Test func homeTabViewModelOwnsAccountViewModel() {
        let viewModel = HomeTabViewModel()
        #expect(viewModel.account.tiles.count == 6)
        viewModel.selectedTab = .cuenta
        #expect(viewModel.selectedTab == .cuenta)
    }
}

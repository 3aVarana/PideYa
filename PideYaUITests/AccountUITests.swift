//
//  AccountUITests.swift
//  PideYaUITests
//
//  Created by Victor Arana on 16/8/26.
//

import XCTest

/// Covers `plan.md` acceptance criteria 2, 3, 4, 5, 6, 7, 8, 9, 10 and 12 for the Cuenta tab.
///
/// XCUITest is the one sanctioned XCTest exception; everything else in the app uses
/// `import Testing`. Every test navigates via `app.buttons["tabbar.cuenta"].tap()` first.
final class AccountUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchOnCuenta(accessibilitySize: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        if accessibilitySize {
            app.launchArguments += [
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL",
            ]
        }
        app.launch()
        app.buttons["tabbar.cuenta"].tap()
        return app
    }

    /// Acceptance criterion 2: routing works both ways and neither shipped tab regressed.
    @MainActor
    func testCuentaTabReplacesPlaceholderAndDoesNotBreakOtherTabs() {
        let app = launchOnCuenta()

        XCTAssertFalse(app.otherElements["placeholder.cuenta"].exists)
        for text in ["CUENTA", "MONEDERO", "Saldo y cupones"] {
            XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 5), "Missing text: \(text)")
        }

        app.buttons["tabbar.inicio"].tap()
        XCTAssertTrue(app.staticTexts["OFERTAS DE HOY"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["MONEDERO"].exists)

        app.buttons["tabbar.pedidos"].tap()
        XCTAssertTrue(app.staticTexts["EN CURSO"].waitForExistence(timeout: 5))
    }

    /// Acceptance criterion 3: the two-field, two-line name model, plus the badges as status.
    @MainActor
    func testNameRendersAsTwoSeparateLines() {
        let app = launchOnCuenta()

        XCTAssertTrue(app.staticTexts["Víctor"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Arana"].waitForExistence(timeout: 5))
        XCTAssertEqual(
            app.staticTexts.matching(NSPredicate(format: "label == %@", "Víctor Arana")).count,
            0
        )
    }

    /// Acceptance criterion 3: badges are status indicators, not controls.
    @MainActor
    func testBadgesAreStatusNotControls() {
        let app = launchOnCuenta()

        XCTAssertTrue(app.staticTexts["EMAIL VERIFICADO"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["TEL. PENDIENTE"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["EMAIL VERIFICADO"].exists)
    }

    /// Acceptance criterion 4: exactly six tile buttons with exact labels, and the identifier-
    /// cascade guards (the defect shipped by the previous feature).
    @MainActor
    func testSixTilesHaveExactLabelsAndUniqueIdentifiers() {
        let app = launchOnCuenta()
        XCTAssertTrue(app.staticTexts["CUENTA"].waitForExistence(timeout: 5))

        let tileButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "account.tile."))
        XCTAssertEqual(tileButtons.count, 6)

        let expectedLabels: [String: String] = [
            "account.tile.perfil": "Perfil. Nombre, foto, direcciones",
            "account.tile.identidad": "Identidad. Teléfono sin verificar",
            "account.tile.seguridad": "Seguridad. 2FA desactivada",
            "account.tile.notificaciones": "Notificaciones. Push y email activos",
            "account.tile.comunicacion": "Comunicación. Español · sin marketing",
            "account.tile.pagos": "Pagos. Visa \u{00B7}\u{00B7}\u{00B7}\u{00B7} 4412 \u{00B7} 12,50\u{00A0}€",
        ]
        for (identifier, expectedLabel) in expectedLabels {
            XCTAssertEqual(app.buttons[identifier].label, expectedLabel, "Mismatched label for \(identifier)")
        }

        for identifier in ["account.tile.perfil", "account.header", "account.grid", "account.badges", "account.wallet"]
        {
            XCTAssertEqual(
                app.descendants(matching: .any).matching(identifier: identifier).count,
                1,
                "\(identifier) must resolve to exactly one element."
            )
        }
    }

    /// Acceptance criterion 5: the balance appears once as a static text and once inside the
    /// Pagos tile's button label.
    @MainActor
    func testWalletShowsBalanceOnceAsTextAndOnceInThePagosTile() {
        let app = launchOnCuenta()

        let wallet = app.otherElements["account.wallet"]
        XCTAssertTrue(wallet.waitForExistence(timeout: 5))
        XCTAssertTrue(wallet.staticTexts["MONEDERO"].exists)
        XCTAssertTrue(wallet.staticTexts["Saldo y cupones"].exists)
        XCTAssertTrue(wallet.staticTexts["12,50\u{00A0}€"].exists)

        XCTAssertEqual(
            app.staticTexts.matching(NSPredicate(format: "label == %@", "12,50\u{00A0}€")).count,
            1,
            "The second occurrence lives inside the Pagos tile's button label, not a static text."
        )
    }

    /// Acceptance criterion 6: `Cerrar sesión`, all six tiles and the footer are no-ops.
    @MainActor
    func testTilesAndSignOutAreNoOps() {
        let app = launchOnCuenta()

        let signOut = app.buttons["account.signOutButton"]
        XCTAssertTrue(signOut.waitForExistence(timeout: 5))
        XCTAssertEqual(signOut.label, "Cerrar sesión")
        signOut.tap()

        for kind in ["perfil", "identidad", "seguridad", "notificaciones", "comunicacion", "pagos"] {
            app.buttons["account.tile.\(kind)"].tap()
        }

        XCTAssertTrue(app.otherElements["account.grid"].exists)
        XCTAssertTrue(app.staticTexts["MONEDERO"].exists)
        XCTAssertTrue(app.buttons["tabbar.cuenta"].isSelected)
    }

    /// Acceptance criterion 6: the footer is non-interactive text.
    @MainActor
    func testFooterIsNotInteractive() {
        let app = launchOnCuenta()

        XCTAssertTrue(app.staticTexts["PideYa 1.0 · Términos · Privacidad"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Términos"].exists)
    }

    /// Acceptance criterion 7: two equal columns at the default content size.
    @MainActor
    func testGridIsTwoEqualColumnsAtDefaultTextSize() {
        let app = launchOnCuenta()

        let perfil = app.buttons["account.tile.perfil"]
        let identidad = app.buttons["account.tile.identidad"]
        XCTAssertTrue(perfil.waitForExistence(timeout: 5))
        XCTAssertTrue(identidad.waitForExistence(timeout: 5))

        XCTAssertLessThan(abs(perfil.frame.minY - identidad.frame.minY), 1)
        XCTAssertLessThan(perfil.frame.minX, identidad.frame.minX)
        XCTAssertLessThan(abs(perfil.frame.height - identidad.frame.height), 1)
        // A tolerance of 0.1pt absorbs point/pixel floating-point rounding noise (observed as
        // 119.99999999999997 on-device), not a real height deficit.
        XCTAssertGreaterThanOrEqual(perfil.frame.height, 120 - 0.1)
    }

    /// Acceptance criterion 8: the grid collapses to one column at accessibility content sizes.
    @MainActor
    func testGridCollapsesToOneColumnAtAccessibilitySize() {
        let app = launchOnCuenta(accessibilitySize: true)

        let perfil = app.buttons["account.tile.perfil"]
        let identidad = app.buttons["account.tile.identidad"]
        XCTAssertTrue(perfil.waitForExistence(timeout: 5))
        XCTAssertTrue(identidad.waitForExistence(timeout: 5))

        XCTAssertLessThan(perfil.frame.minY, identidad.frame.minY)
        XCTAssertLessThan(abs(perfil.frame.minX - identidad.frame.minX), 1)

        let windowMaxX = app.windows.firstMatch.frame.maxX
        for kind in ["perfil", "identidad", "seguridad", "notificaciones", "comunicacion", "pagos"] {
            let tile = app.buttons["account.tile.\(kind)"]
            XCTAssertTrue(tile.waitForExistence(timeout: 5))
            XCTAssertLessThanOrEqual(tile.frame.maxX, windowMaxX + 1, "\(kind) overflows the window's right edge.")
        }
    }

    /// Acceptance criterion 9: `Cerrar sesión` and the footer are reachable above the tab bar at
    /// an accessibility content size — the `NavigationStack` bottom-inset regression guard.
    @MainActor
    func testSignOutIsReachableAboveTabBarAtAccessibilitySize() {
        let app = launchOnCuenta(accessibilitySize: true)

        for _ in 0..<8 {
            app.swipeUp()
        }

        let signOut = app.buttons["account.signOutButton"]
        XCTAssertTrue(signOut.waitForExistence(timeout: 5))
        XCTAssertTrue(signOut.isHittable)

        let tabBar = app.buttons["tabbar.cuenta"]
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(signOut.frame.maxY, tabBar.frame.minY)

        // Assert the footer, not just `Cerrar sesión` — it is the lowest element in
        // `AccountWalletView`, so it is the one whose clearance actually depends on the bottom
        // safe-area inset. A flush `<=` (no margin) let a 0.67pt regression through when the
        // inset was removed entirely; require a real 4pt gap so a small spacing tweak can't hide
        // that regression again.
        let footer = app.staticTexts["PideYa 1.0 · Términos · Privacidad"]
        XCTAssertTrue(footer.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(footer.frame.maxY, tabBar.frame.minY - 4)
    }

    /// Acceptance criterion 10: the header scrolls and is not pinned.
    @MainActor
    func testHeaderScrollsAndIsNotPinned() {
        let app = launchOnCuenta(accessibilitySize: true)

        let header = app.staticTexts["CUENTA"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        let originalHeaderMinY = header.frame.minY
        let grid = app.otherElements["account.grid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 5))
        let originalGridMinY = grid.frame.minY

        for _ in 0..<3 {
            app.swipeUp()
        }

        // A pinned header stays put while the rest of the screen scrolls under it; a scrolling
        // one either moves or is pushed off-screen entirely. Assert the disjunction explicitly
        // (no silently-vacuous `if header.exists` guard) and additionally require that
        // *something* — the grid — actually moved, so "nothing scrolled" cannot pass either path.
        XCTAssertTrue(
            !header.exists || header.frame.minY < originalHeaderMinY,
            "Header did not move while the screen scrolled."
        )
        XCTAssertLessThan(grid.frame.minY, originalGridMinY, "Screen did not scroll.")
    }

    /// Acceptance criterion 12: `MONEDERO` scales with Dynamic Type.
    @MainActor
    func testAccountTextScalesWithDynamicType() {
        let defaultApp = XCUIApplication()
        defaultApp.launch()
        defaultApp.buttons["tabbar.cuenta"].tap()
        let defaultText = defaultApp.staticTexts["MONEDERO"]
        XCTAssertTrue(defaultText.waitForExistence(timeout: 5))
        let defaultHeight = defaultText.frame.height
        defaultApp.terminate()

        let accessibilityApp = launchOnCuenta(accessibilitySize: true)
        let accessibilityText = accessibilityApp.staticTexts["MONEDERO"]
        XCTAssertTrue(accessibilityText.waitForExistence(timeout: 5))
        let accessibilityHeight = accessibilityText.frame.height
        accessibilityApp.terminate()

        let message = "Text did not grow at AccessibilityL (\(defaultHeight) -> \(accessibilityHeight))."
        XCTAssertGreaterThan(accessibilityHeight, defaultHeight, message)
    }
}

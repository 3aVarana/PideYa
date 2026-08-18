//
//  OrdersUITests.swift
//  PideYaUITests
//
//  Created by Victor Arana on 16/8/26.
//

import XCTest

/// Covers `plan.md` acceptance criteria 2, 3, 4, 5, 6, 7, 8, 10, 11 and 12 for the Pedidos tab.
///
/// XCUITest is the one sanctioned XCTest exception; everything else in the app uses
/// `import Testing`.
final class OrdersUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// The `ANTERIORES` list is a `LazyVStack`; rows below the fold are not created until
    /// scrolled into view. Local copy of `HomeFeedUITests`'s helper (that one is `private`).
    private func scrollUntilVisible(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 6) {
        var attempts = 0
        while !element.exists, attempts < maxSwipes {
            app.swipeUp()
            attempts += 1
        }
    }

    /// Acceptance criterion 2: routing works both ways and does not break Inicio.
    @MainActor
    func testPedidosTabShowsHeaderAndSections() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["tabbar.pedidos"].tap()

        for text in ["Pedidos", "1 en curso · 12 anteriores", "EN CURSO", "ANTERIORES"] {
            XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 5), "Missing text: \(text)")
        }
        XCTAssertTrue(app.buttons["orders.helpButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Filtrar"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["OFERTAS DE HOY"].exists)

        app.buttons["tabbar.inicio"].tap()
        XCTAssertTrue(app.staticTexts["OFERTAS DE HOY"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["EN CURSO"].exists)
    }

    /// Acceptance criterion 3: the active order card's content, including the U+00A0 total.
    @MainActor
    func testActiveOrderCardContent() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["tabbar.pedidos"].tap()

        let card = app.otherElements["orders.activeCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        for text in ["Taquería Norte", "3 artículos · Pedido #4821", "LLEGA 20:45", "24,60\u{00A0}€"] {
            XCTAssertTrue(card.staticTexts[text].waitForExistence(timeout: 5), "Missing card text: \(text)")
        }
    }

    /// Acceptance criterion 4: `EN CAMINO` appears exactly twice (band + progress label); the
    /// other three stage labels appear exactly once.
    @MainActor
    func testProgressTrackerLabelsAndCurrentStageDuplication() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["tabbar.pedidos"].tap()

        XCTAssertTrue(app.staticTexts["EN CAMINO"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", "EN CAMINO")).count, 2)
        for text in ["CONFIRMADO", "EN COCINA", "ENTREGADO"] {
            XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", text)).count, 1)
        }
    }

    /// `PastOrderRowView`'s `.accessibilityIdentifier` is keyed on its position in `ANTERIORES`
    /// (`"orders.past.row.<index>"`), not on mock-seed internals, so this selector survives a
    /// future data-source swap instead of duplicating `MockOrdersContentProvider.stableID`.
    private func pastOrderRowIdentifier(_ index: Int) -> String {
        "orders.past.row.\(index)"
    }

    /// Acceptance criterion 5: the first three `ANTERIORES` rows match DESIGN.md §6, **in that
    /// order** — scoped per-row via `pastOrderRowIdentifier(_:)` and asserted both for content
    /// and for vertical sequence, so a silent row-order regression (e.g. a reversed seed array)
    /// is caught rather than merely proving the nine strings exist somewhere on screen.
    @MainActor
    func testFirstThreePastOrdersMatchDesign() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["tabbar.pedidos"].tap()

        let forno = app.otherElements[pastOrderRowIdentifier(0)]
        let casa = app.otherElements[pastOrderRowIdentifier(1)]
        let sakura = app.otherElements[pastOrderRowIdentifier(2)]
        XCTAssertTrue(forno.waitForExistence(timeout: 5))
        XCTAssertTrue(casa.waitForExistence(timeout: 5))
        XCTAssertTrue(sakura.waitForExistence(timeout: 5))

        XCTAssertTrue(forno.staticTexts["Forno Bianco"].exists)
        XCTAssertTrue(forno.staticTexts["18,90\u{00A0}€"].exists)
        XCTAssertTrue(forno.staticTexts["12 ago · 2 artículos"].exists)
        XCTAssertTrue(casa.staticTexts["Casa Lola"].exists)
        XCTAssertTrue(casa.staticTexts["31,20\u{00A0}€"].exists)
        XCTAssertTrue(casa.staticTexts["9 ago · 4 artículos"].exists)
        XCTAssertTrue(sakura.staticTexts["Sakura Ramen"].exists)
        XCTAssertTrue(sakura.staticTexts["26,50\u{00A0}€"].exists)
        XCTAssertTrue(sakura.staticTexts["4 ago · 2 artículos"].exists)

        XCTAssertLessThan(forno.frame.minY, casa.frame.minY, "Forno Bianco does not precede Casa Lola.")
        XCTAssertLessThan(casa.frame.minY, sakura.frame.minY, "Casa Lola does not precede Sakura Ramen.")
    }

    /// Acceptance criterion 6: unrated rows show `VALORAR PEDIDO` with no `orders.rating`
    /// element; rated rows show `orders.rating` (labelled `5 de 5 estrellas`) and `5,0`, with no
    /// `VALORAR PEDIDO`. Also a regression guard for the `orders.rating` identifier cascade: it
    /// must resolve to exactly one element per rated row (8 of the 12 seeded past orders), never
    /// a second element stamped onto a sibling `Text`.
    @MainActor
    func testRatedAndUnratedRowsRenderDifferently() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["tabbar.pedidos"].tap()

        let casaLolaRow = app.otherElements[pastOrderRowIdentifier(1)]
        XCTAssertTrue(casaLolaRow.waitForExistence(timeout: 5))
        XCTAssertTrue(casaLolaRow.staticTexts["VALORAR PEDIDO"].exists)
        XCTAssertFalse(casaLolaRow.otherElements["orders.rating"].exists)

        let fornoBiancoRow = app.otherElements[pastOrderRowIdentifier(0)]
        XCTAssertTrue(fornoBiancoRow.waitForExistence(timeout: 5))
        let ratingElement = fornoBiancoRow.otherElements["orders.rating"]
        XCTAssertTrue(ratingElement.exists)
        XCTAssertEqual(ratingElement.label, "5 de 5 estrellas")
        XCTAssertTrue(fornoBiancoRow.staticTexts["5,0"].exists)
        XCTAssertFalse(fornoBiancoRow.staticTexts["VALORAR PEDIDO"].exists)

        // `ANTERIORES` is a `LazyVStack`; scroll through the whole list first so every row has
        // been materialized before counting `orders.rating` occurrences app-wide.
        let lastRow = app.staticTexts["2 jul · 1 artículo"]
        scrollUntilVisible(lastRow, in: app, maxSwipes: 12)
        XCTAssertTrue(lastRow.waitForExistence(timeout: 5))

        XCTAssertEqual(
            app.descendants(matching: .any).matching(identifier: "orders.rating").count,
            8,
            "orders.rating must resolve to exactly one element per rated row (8 of 12 seeded past orders)."
        )
    }

    /// Acceptance criterion 7: every action is wired but no-op.
    @MainActor
    func testAllActionsAreNoOps() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["tabbar.pedidos"].tap()

        XCTAssertTrue(app.buttons["orders.helpButton"].waitForExistence(timeout: 5))
        app.buttons["orders.helpButton"].tap()
        app.buttons["Filtrar"].tap()
        app.buttons["orders.trackButton"].tap()
        app.buttons["orders.quickActionButton"].tap()

        let repeatButtons = app.buttons.matching(NSPredicate(format: "label == %@", "REPETIR"))
        XCTAssertGreaterThan(repeatButtons.count, 0)
        repeatButtons.firstMatch.tap()

        XCTAssertTrue(app.otherElements["orders.activeCard"].exists)
        XCTAssertTrue(app.staticTexts["ANTERIORES"].exists)
    }

    /// Acceptance criterion 8: the icon-only bolt button carries an accessibility label.
    @MainActor
    func testQuickActionButtonHasAccessibilityLabel() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["tabbar.pedidos"].tap()

        let button = app.buttons["orders.quickActionButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        XCTAssertEqual(button.label, "Acciones rápidas")
    }

    /// Acceptance criterion 11: the twelfth past-order row is reachable above the tab bar,
    /// mirroring `HomeFeedUITests.testLastRecommendationRowIsReachableAboveTabBar`.
    @MainActor
    func testLastPastOrderRowIsReachableAboveTabBar() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["tabbar.pedidos"].tap()

        let lastRow = app.staticTexts["2 jul · 1 artículo"]
        scrollUntilVisible(lastRow, in: app, maxSwipes: 12)
        XCTAssertTrue(lastRow.waitForExistence(timeout: 5))

        for _ in 0..<6 {
            app.swipeUp()
        }

        XCTAssertTrue(lastRow.isHittable, "Last past-order row is not hittable at maximum scroll.")

        let tabBar = app.buttons["tabbar.pedidos"]
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertFalse(lastRow.frame.intersects(tabBar.frame), "Last row frame intersects the tab bar frame.")
        XCTAssertLessThanOrEqual(lastRow.frame.maxY, tabBar.frame.minY, "Last row extends into the tab bar.")
    }

    /// Acceptance criterion 12: the header stays pinned while the list scrolls.
    @MainActor
    func testHeaderStaysPinnedWhileListScrolls() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["tabbar.pedidos"].tap()

        let header = app.otherElements["orders.header"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        let originalMinY = header.frame.minY

        for _ in 0..<3 {
            app.swipeUp()
        }

        XCTAssertTrue(header.exists)
        XCTAssertEqual(header.frame.minY, originalMinY, "Header moved while the list scrolled.")
    }

    /// Acceptance criterion 10: `ANTERIORES` scales with Dynamic Type.
    @MainActor
    func testOrdersTextScalesWithDynamicType() {
        let defaultApp = XCUIApplication()
        defaultApp.launch()
        defaultApp.buttons["tabbar.pedidos"].tap()
        let defaultText = defaultApp.staticTexts["ANTERIORES"]
        XCTAssertTrue(defaultText.waitForExistence(timeout: 5))
        let defaultHeight = defaultText.frame.height
        defaultApp.terminate()

        let accessibilityApp = XCUIApplication()
        accessibilityApp.launchArguments += [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL",
        ]
        accessibilityApp.launch()
        accessibilityApp.buttons["tabbar.pedidos"].tap()
        let accessibilityText = accessibilityApp.staticTexts["ANTERIORES"]
        XCTAssertTrue(accessibilityText.waitForExistence(timeout: 5))
        let accessibilityHeight = accessibilityText.frame.height
        accessibilityApp.terminate()

        let message = "Text did not grow at .accessibility1 (\(defaultHeight) -> \(accessibilityHeight))."
        XCTAssertGreaterThan(accessibilityHeight, defaultHeight, message)
    }
}

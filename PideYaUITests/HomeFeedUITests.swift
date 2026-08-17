//
//  HomeFeedUITests.swift
//  PideYaUITests
//
//  Created by Victor Arana on 16/8/26.
//

import XCTest

/// Covers `plan.md` acceptance criteria 2, 3, 4, 6 and 7 for the Home Tab shell + Feed screen.
///
/// XCUITest is the one sanctioned XCTest exception (Swift Testing has no UI-automation
/// equivalent); everything else in the app uses `import Testing`.
final class HomeFeedUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// The recommendations list is a `LazyVStack`; rows below the fold are not created until
    /// scrolled into view. Swipes up until the element exists or the attempt budget is spent.
    private func scrollUntilVisible(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 6) {
        var attempts = 0
        while !element.exists, attempts < maxSwipes {
            app.swipeUp()
            attempts += 1
        }
    }

    /// Acceptance criterion 2: static texts and the search placeholder exist on first launch.
    @MainActor
    func testLaunchShowsStaticFeedTextsAndSearchPlaceholder() {
        let app = XCUIApplication()
        app.launch()

        for text in [
            "PIDEYA",
            "VA",
            "Calle Mayor 44",
            "OFERTAS DE HOY",
            "RECOMENDADOS PARA TI",
            "Según tus últimos pedidos",
        ] {
            XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 5), "Missing text: \(text)")
        }

        // "Ver todas" renders as a Button (SectionHeaderView's trailing action), not a static text.
        XCTAssertTrue(app.buttons["Ver todas"].waitForExistence(timeout: 5))

        XCTAssertTrue(app.textFields["Buscar restaurantes o platos"].waitForExistence(timeout: 5))
    }

    /// Acceptance criterion 3: tab bar identifiers exist, are hittable, and `inicio` is selected.
    @MainActor
    func testTabBarIdentifiersExistAndInicioIsSelected() {
        let app = XCUIApplication()
        app.launch()

        for tab in ["inicio", "buscar", "pedidos", "cuenta"] {
            let button = app.buttons["tabbar.\(tab)"]
            XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing tab: \(tab)")
            XCTAssertTrue(button.isHittable, "Tab not hittable: \(tab)")
        }

        XCTAssertTrue(app.buttons["tabbar.inicio"].isSelected)
    }

    /// Acceptance criterion 4: Inicio <-> Buscar round-trip shows/hides the right content, and
    /// `placeholder.buscar` resolves as a single queryable element (proves the
    /// `.accessibilityElement(children: .contain)` fix on `PlaceholderTabView`).
    @MainActor
    func testTabRoundTripSwapsInicioAndPlaceholderContent() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["OFERTAS DE HOY"].waitForExistence(timeout: 5))

        app.buttons["tabbar.buscar"].tap()
        XCTAssertTrue(app.otherElements["placeholder.buscar"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["OFERTAS DE HOY"].exists)

        app.buttons["tabbar.inicio"].tap()
        XCTAssertTrue(app.staticTexts["OFERTAS DE HOY"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["placeholder.buscar"].exists)
    }

    /// Acceptance criterion 5 (also exercised here since the recommendations are already on
    /// screen): es-ES fee formatting uses U+00A0 before the euro sign, not a plain space.
    @MainActor
    func testRecommendationFeesUseNonBreakingSpaceBeforeEuroSign() {
        let app = XCUIApplication()
        app.launch()

        for fee in ["1,90\u{00A0}€", "2,50\u{00A0}€", "0,00\u{00A0}€"] {
            let feeText = app.staticTexts[fee]
            scrollUntilVisible(feeText, in: app)
            XCTAssertTrue(feeText.waitForExistence(timeout: 5), "Missing fee text: \(fee)")
        }
    }

    /// Acceptance criterion 6: Casa Lola has exactly one chip, Taquería Norte has exactly two.
    @MainActor
    func testChipCountsPerRecommendationRow() {
        let app = XCUIApplication()
        app.launch()

        let casaLolaChips = app.otherElements["chips.Casa Lola"]
        scrollUntilVisible(casaLolaChips, in: app)
        XCTAssertTrue(casaLolaChips.waitForExistence(timeout: 5))
        XCTAssertEqual(casaLolaChips.staticTexts.count, 1)

        let taqueriaChips = app.otherElements["chips.Taquería Norte"]
        XCTAssertTrue(taqueriaChips.waitForExistence(timeout: 5))
        XCTAssertEqual(taqueriaChips.staticTexts.count, 2)
    }

    /// Acceptance criterion 7: before scrolling, the first card is 55-70% of the screen width;
    /// after a horizontal swipe, the second card (Forno Bianco) becomes fully visible.
    @MainActor
    func testCarouselPeekRatioAndHorizontalSwipeRevealsSecondCard() {
        let app = XCUIApplication()
        app.launch()

        let firstCard = app.otherElements["offerCard.Taquería Norte"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5))

        let screenWidth = app.frame.width
        let peekRatio = firstCard.frame.width / screenWidth
        XCTAssertGreaterThanOrEqual(peekRatio, 0.55)
        XCTAssertLessThanOrEqual(peekRatio, 0.70)

        let secondCard = app.otherElements["offerCard.Forno Bianco"]
        let carousel = app.scrollViews["offersCarousel"]
        XCTAssertTrue(carousel.waitForExistence(timeout: 5))

        var attempts = 0
        while !secondCard.isHittable, attempts < 5 {
            carousel.swipeLeft()
            attempts += 1
        }

        XCTAssertTrue(secondCard.isHittable, "Forno Bianco did not become fully visible after swiping.")
    }
}

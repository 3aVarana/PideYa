//
//  DesignSystemViewsTests.swift
//  PideYaTests
//
//  Created by Victor Arana on 17/8/26.
//

import Testing

@testable import PideYa

/// Covers the one piece of logic in `DesignSystemViews.swift`: `filledStars(score:outOf:)`,
/// `StarRatingView`'s clamping helper. Extracted to a free function specifically so it is
/// reachable here instead of being unreachable `private` state on a `View`.
struct FilledStarsTests {
    @Test func filledStarsClampsBelowZero() {
        #expect(filledStars(score: -3, outOf: 5) == 0)
    }

    @Test func filledStarsClampsAboveOutOf() {
        #expect(filledStars(score: 9, outOf: 5) == 5)
    }

    @Test func filledStarsRoundsHalfUpToOutOf() {
        #expect(filledStars(score: 4.5, outOf: 5) == 5)
    }

    @Test func filledStarsRoundsDownBelowHalf() {
        #expect(filledStars(score: 4.0, outOf: 5) == 4)
    }
}

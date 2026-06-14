//
//  SeededGenerator.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 14.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

/// A deterministic pseudo-random number generator implementing the **SplitMix64**
/// algorithm (Steele, Lea & Flood, 2014).
///
/// ## Why it exists
/// Monkey/stress UI tests pick random actions (tap, swipe, scroll…) from a pool.
/// Using the system `SystemRandomNumberGenerator` would make failures
/// non-reproducible because its output cannot be replayed. `SeededGenerator`
/// solves this: each test run logs its seed, so a failing run can be reproduced
/// by re-using the same seed value.
///
/// ## How it works
/// SplitMix64 maintains a single 64-bit `state`. On every call to ``next()``:
/// 1. The state is **incremented** by a large odd constant (the golden-ratio
///    constant `0x9E3779B97F4A7C15`), which guarantees a full 2^64 period.
/// 2. The updated state is passed through a three-stage **bijective mix function**
///    (xor-shift → multiply → xor-shift → multiply → xor-shift) that avalanches
///    the bits so the output passes standard randomness tests (BigCrush).
///
/// The algorithm is fast (a single 64-bit addition + three xor-shift-multiplies),
/// has zero heap allocation, and its full-period guarantee means every possible
/// `UInt64` value appears exactly once before the sequence repeats.
///
/// ## Usage
/// ```swift
/// var rng = SeededGenerator(seed: 42)
/// let randomIndex = Int.random(in: 0..<actions.count, using: &rng)
/// ```
struct SeededGenerator: RandomNumberGenerator {

    private var state: UInt64

    /// Creates a generator seeded with the given value.
    ///
    /// - Parameter seed: The initial state. If `0` is passed the generator
    ///   substitutes the golden-ratio constant to avoid the all-zero fixed point
    ///   of the mix function (mixing zero always produces zero).
    init(seed: UInt64) {
        state = seed != 0 ? seed : 0x9E37_79B9_7F4A_7C15
    }

    /// Returns the next pseudo-random `UInt64` and advances the internal state.
    ///
    /// The three-stage mix (xor-shift 30 then multiply, xor-shift 27 then
    /// multiply, xor-shift 31) is the standard SplitMix64 finaliser, identical to
    /// `java.util.SplittableRandom`.
    mutating func next() -> UInt64 {
        // 1. Weyl-sequence increment – ensures full 2^64 period.
        state = state &+ 0x9E37_79B9_7F4A_7C15
        // 2. Bijective mix – avalanches bits for statistical quality.
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }
}

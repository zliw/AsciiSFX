//
//  AsciiSFXTests.swift
//  AsciiSFXTests
//
//  Created by martin on 17/10/15.
//  Copyright © 2015 martin. All rights reserved.
//

import XCTest
@testable import AsciiSFX

class AsciiSFXTests: XCTestCase {
    let parser = CommandParser()

    func testParseInteger() {
        let chars = Array("1000".characters)
        let (value, index) = parser.parseInteger(chars)
        assert(value == 1000)
        assert(index == 4)
    }

    func testParseIntegerWithEmptyString() {
        let chars = Array("".characters)
        let (value, index) = parser.parseInteger(chars)
        assert(value == 0)
        assert(index == 0)
    }

    func testParseHexSequence() {
        let chars = Array("05a".characters)
        let (sequence, index) = parser.parseHexSequence(chars)
        assert(sequence.count == 3)
        assert(index == 3)
        assert(sequence[0] == 0)
        assert(sequence[1] == Float(5) / 15)
        assert(sequence[2] == Float(10) / 15)
    }

    func testParseHexSequence2() {
        let chars = Array("09f".characters)
        let (sequence, index) = parser.parseHexSequence(chars)
        assert(sequence.count == 3)
        assert(index == 3)
        assert(sequence[0] == 0)
        assert(sequence[1] == Float(9) / 15)
        assert(sequence[2] == Float(1))
    }

    func testParseHexSequenceWithEmptyString() {
        let chars = Array("".characters)
        let (sequence, index) = parser.parseHexSequence(chars)
        assert(sequence.count == 0)
        assert(index == 0)
    }

    func testToneSequence() {
        let chars = Array("+d-d2ec".characters)
        let (sequence, index) = parser.parseToneSequence(chars)
        assert(sequence.count == 4)
        assert(index == 7)

        assert(sequence[0].note == Character("d"))
        assert(sequence[0].octave == 5)
        assert(sequence[0].length == 1)

        assert(sequence[1].note == Character("d"))
        assert(sequence[1].octave == 4)
        assert(sequence[1].length == 2)

        assert(sequence[2].note == Character("e"))
        assert(sequence[2].octave == 4)
        assert(sequence[2].length == 1)

        assert(sequence[3].note == Character("c"))
        assert(sequence[3].octave == 4)
        assert(sequence[3].length == 1)
    }

    func testFrequency() {
        let tone = Tone(note: "a", octave: 4, length: 1)
        assert(tone.frequency() == 440)

        let tone2 = Tone(note: "a", octave: 5, length: 1)
        assert(tone2.frequency() == 880)

        let tone3 = Tone(note: "a", octave: 3, length: 1)
        assert(tone3.frequency() == 220)
    }


}

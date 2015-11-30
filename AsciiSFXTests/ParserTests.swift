//
//  ParserTests.swift
//  AsciiSFX
//
//  Created by martin on 22/11/15.
//  Copyright © 2015 martin. All rights reserved.
//

import XCTest
@testable import AsciiSFX

struct ObjectHelper {
    static func getClassName(object: AnyObject) -> String {
        let objectClass: AnyClass = object_getClass(object) as AnyClass
        return NSStringFromClass(objectClass)
    }
}

class ParserTests: XCTestCase {
    let parser = Parser()


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
        assert(sequence[0].from == 0)
        assert(sequence[1].from == Float(5) / 15)
        assert(sequence[2].from == Float(10) / 15)
    }

    func testParseHexSequence2() {
        let chars = Array("09f".characters)
        let (sequence, index) = parser.parseHexSequence(chars)
        assert(sequence.count == 3)
        assert(index == 3)
        assert(sequence[0].from == 0)
        assert(sequence[1].from == Float(9) / 15)
        assert(sequence[2].from == Float(1))
    }

    func testParseHexSequenceRange() {
        let chars = Array("0-f".characters)
        let (sequence, index) = parser.parseHexSequence(chars)
        assert(sequence.count == 1)
        assert(index == 3)
        assert(sequence[0].from == 0)
        assert(sequence[0].to == Float(1))
    }

    func testParseHexSequenceRange2() {
        let chars = Array("f-0".characters)
        let (sequence, index) = parser.parseHexSequence(chars)
        assert(sequence.count == 1)
        assert(index == 3)
        assert(sequence[0].from == Float(1))
        assert(sequence[0].to == 0)
    }

    func testParseHexSequenceRange3() {
        let chars = Array("0-f0-f".characters)
        let (sequence, index) = parser.parseHexSequence(chars)
        assert(sequence.count == 2)
        assert(index == 6)
        assert(sequence[0].from == 0)
        assert(sequence[0].to == Float(1))
        assert(sequence[1].from == 0)
        assert(sequence[1].to == Float(1))
    }

    func testParseHexSequenceRange4() {
        let chars = Array("0-fV".characters)
        let (sequence, index) = parser.parseHexSequence(chars)
        assert(sequence.count == 1)
        assert(index == 3)
        assert(sequence[0].from == 0)
        assert(sequence[0].to == Float(1))
    }

    func testParseHexSequenceSingleValue() {
        let chars = Array("0".characters)
        let (sequence, index) = parser.parseHexSequence(chars)
        assert(sequence.count == 1)
        assert(index == 1)
        assert(sequence[0].from == 0)
        assert(sequence[0].to == nil)
    }

    func testParseHexSequenceWithEmptyString() {
        let chars = Array("".characters)
        let (sequence, index) = parser.parseHexSequence(chars)
        assert(sequence.count == 0)
        assert(index == 0)
    }

    func testParseEmptyToneSequence() {
        let chars = Array("".characters)
        let (sequence, index) = parser.parseNoteSequence(chars)

        assert(sequence.count == 0)
        assert(index == 0)
    }

    func testToneSlide() {
        let chars = Array("d/-e".characters)
        let (sequence, index) = parser.parseNoteSequence(chars)

        assert(sequence.count == 1)
        assert(index == 4)

        assert(sequence[0].note == "d")
        assert(sequence[0].octave == 4)
        assert(sequence[0].length == 1)
        assert(sequence[0].toOctave == 3)
        assert(sequence[0].toNote == "e")

    }

    func testParseIntegerPair() {
        let chars = Array("1:2".characters)
        let (pair, index) = parser.parseIntegerPair(chars)
        assert(index == 2)

        let (first, second) = pair
        assert(first == 1)
        assert(second == 2)
    }

    func testParseIntegerPair2() {
        let chars = Array("01:02V".characters)
        let (pair, index) = parser.parseIntegerPair(chars)
        assert(index == 4)

        let (first, second) = pair
        assert(first == 1)
        assert(second == 2)
    }

    func testToneSequence() {
        let chars = Array("+d-d2.c".characters)
        let (sequence, index) = parser.parseNoteSequence(chars)
        assert(sequence.count == 4)
        assert(index == 7)

        assert(sequence[0].note == "d")
        assert(sequence[0].octave == 5)
        assert(sequence[0].length == 1)

        assert(sequence[1].note == "d")
        assert(sequence[1].octave == 4)
        assert(sequence[1].length == 2)

        assert(sequence[2].note == ".")
        assert(sequence[2].octave == 4)
        assert(sequence[2].length == 1)

        assert(sequence[3].note == "c")
        assert(sequence[3].octave == 4)
        assert(sequence[3].length == 1)
    }

    func testParserWithSquareWave() {
        let parser = Parser()
        let operations = parser.parse("SQ1000")
        assert(operations.count == 1)
        let operation = operations[0]
        assert(ObjectHelper.getClassName(operation as! AnyObject) == "AsciiSFX.SquareOscillator")
    }

    func testParserWithSineWave() {
        let parser = Parser()
        let operations = parser.parse("SI100")
        assert(operations.count == 1)
        let operation = operations[0]
        assert(ObjectHelper.getClassName(operation as! AnyObject) == "AsciiSFX.SinusOscillator")
    }

    func testParserWithSawWave() {
        let parser = Parser()
        let operations = parser.parse("SW100")
        assert(operations.count == 1)
        let operation = operations[0]
        assert(ObjectHelper.getClassName(operation as! AnyObject) == "AsciiSFX.SawtoothOscillator")
    }

    func testParserWithNoise() {
        let parser = Parser()
        let operations = parser.parse("SN100")
        assert(operations.count == 1)
        let operation = operations[0]
        assert(ObjectHelper.getClassName(operation as! AnyObject) == "AsciiSFX.NoiseOscillator")
    }

}
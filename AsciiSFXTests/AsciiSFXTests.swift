//
//  AsciiSFXTests.swift
//  AsciiSFXTests
//
//  Created by martin on 17/10/15.
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

class AsciiSFXTests: XCTestCase {
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

    func testEmptyToneSequence() {
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

    func testToneSequence() {
        let chars = Array("+d-d2ec".characters)
        let (sequence, index) = parser.parseNoteSequence(chars)
        assert(sequence.count == 4)
        assert(index == 7)

        assert(sequence[0].note == "d")
        assert(sequence[0].octave == 5)
        assert(sequence[0].length == 1)

        assert(sequence[1].note == "d")
        assert(sequence[1].octave == 4)
        assert(sequence[1].length == 2)

        assert(sequence[2].note == "e")
        assert(sequence[2].octave == 4)
        assert(sequence[2].length == 1)

        assert(sequence[3].note == "c")
        assert(sequence[3].octave == 4)
        assert(sequence[3].length == 1)
    }

    func testFrequencyCalculation() {
        let tone = Note(note: "a", octave: 4, length: 1)
        assert(tone.frequency() == 440)

        let tone2 = Note(note: "a", octave: 5, length: 1)
        assert(tone2.frequency() == 880)

        let tone3 = Note(note: "a", octave: 3, length: 1)
        assert(tone3.frequency() == 220)
    }

    func testLengthOfSectionsWithASingleSection() {
        var a = Array<UInt32>()
        a.append(1)
        let result = Helper().lengthOfSections(10, sequence: a)
        assert(result.count == 1)
        assert(result[0] == 10)
    }

    func testLengthOfSectionsWithNotes() {
        let t1 = Note(note:"a", octave: 5, length: 1)

        var a = Array<Note>()
        a.append(t1)
        a.append(t1)
        a.append(t1)

        let result = Helper().lengthOfSections(10, sequence: a)
        assert(result.count == 3)
        assert(result[0] == 4)
        assert(result[1] == 3)
        assert(result[2] == 3)
    }

    func testParserWithSquareWave() {
        let parser = Parser()
        parser.parse("SQ1000")
        assert(parser.frameCount == 44100)
        assert(parser.operations.count == 1)
        let operation = parser.operations[0]
        assert(ObjectHelper.getClassName(operation as! AnyObject) == "AsciiSFX.SquareOscillator")
    }

    func testParserWithSineWave() {
        let parser = Parser()
        parser.parse("SI100")
        assert(parser.frameCount == 4410)
        assert(parser.operations.count == 1)
        let operation = parser.operations[0]
        assert(ObjectHelper.getClassName(operation as! AnyObject) == "AsciiSFX.SinusOscillator")
    }

    func testParserWithSawWave() {
        let parser = Parser()
        parser.parse("SW100")
        assert(parser.frameCount == 4410)
        assert(parser.operations.count == 1)
        let operation = parser.operations[0]
        assert(ObjectHelper.getClassName(operation as! AnyObject) == "AsciiSFX.SawtoothOscillator")
    }

}

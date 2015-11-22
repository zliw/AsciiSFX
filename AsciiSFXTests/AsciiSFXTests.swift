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
}

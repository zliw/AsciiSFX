//
//  FrequencyBufferTests.swift
//  AsciiSFX
//
//  Created by martin on 22/11/15.
//  Copyright © 2015 martin. All rights reserved.
//

import XCTest
@testable import AsciiSFX


class FrequencyBufferTests: XCTestCase {

    func testRenderWithSingleNote() {
        let buffer = FrequencyBuffer(length:10)
        let note = Note(note: "a", octave: 4, length: 1)
        let sequence = Array<Note>(arrayLiteral: note)
        buffer.setNoteSequence(sequence)
        buffer.render()
        let data = buffer.buffer.floatChannelData.memory
        assert(data[0] == 440)
        assert(data[220] == 440)
        assert(data[440] == 440)
    }

    func testRenderWithSlide() {
        let buffer = FrequencyBuffer(length:10)
        var note = Note(note: "a", octave: 4, length: 1)
        note.toNote = "a"
        note.toOctave = 5

        let sequence = Array<Note>(arrayLiteral: note)
        buffer.setNoteSequence(sequence)
        buffer.render()
        let data = buffer.buffer.floatChannelData.memory
        assert(data[0] == 440)
        assert(data[440] > 870)
        assert(data[440] <= 880)
    }

    func testRenderWithPause() {
        let buffer = FrequencyBuffer(length:10)
        let note = Note(note: ".", octave: 4, length: 1)
        let sequence = Array<Note>(arrayLiteral: note)

        buffer.setNoteSequence(sequence)
        buffer.render()
        let data = buffer.buffer.floatChannelData.memory
        assert(data[0] == 0)
        assert(data[220] == 0)
        assert(data[440] == 0)
    }

}


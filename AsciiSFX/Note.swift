//
//  Tone.swift
//  AsciiSFX
//
//  Created by  Martin Wilz on 01/11/15.
//  Copyright © 2015  Martin Wilz. All rights reserved.
//

import Foundation

struct FrequencyTable {
    static let table:Dictionary<Character, Float> = [
        Character("c"): 261.63,
        Character("d"): 293.66,
        Character("e"): 329.63,
        Character("f"): 349.23,
        Character("g"): 392.00,
        Character("a"): 440.00,
        Character("b"): 493.88,
        Character("."): 0.0
    ]
}

struct Note {
    let note:Character
    let octave:UInt8
    var length:UInt8
    var toNote:Character?
    var toOctave:UInt8?

    init(note:Character, octave: UInt8) {
        self.note = note
        self.octave = octave
        self.length = 1
    }

    init(note:Character, octave: UInt8, length: UInt8) {
        self.note = note
        self.octave = octave
        self.length = length
    }

    private func _frequency(octave:UInt8, note:Character) -> Float {
        var o:Int16 = Int16(octave) - Int16(4)
        var f = FrequencyTable.table[note]!

        while (o < 0) {
            f /= 2
            o++
        }

        while (o > 0) {
            f *= 2
            o--
        }
        
        return f
    }

    func frequency() -> Float {
        return _frequency(self.octave, note: self.note)
    }

    func toFrequency() -> Float {
        if let _ = self.toOctave {
            if let _ = self.toNote {
                return _frequency(toOctave!, note: toNote!)
            }
        }
        return _frequency(self.octave, note: self.note)
    }

}
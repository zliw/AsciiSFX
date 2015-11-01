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
        Character("c"):  261.63,
        Character("d"):  293.66,
        Character("e"):  329.63,
        Character("f"):  349.23,
        Character("g"):  392.00,
        Character("a"):  440.00,
        Character("b"):  493.88
    ]
}

struct Tone {
    let note:Character;
    let octave:UInt8;
    var length:UInt8;

    func frequency() -> Float {

        var o:Int16 = Int16(self.octave) - Int16(4)
        var f = FrequencyTable.table[self.note]!

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
}
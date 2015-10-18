//
//  CommandParser.swift
//  AsciiSFX
//
//  Created by martin on 17/10/15.
//  Copyright © 2015 martin. All rights reserved.
//

import Foundation
import AVFoundation

let SampleRate = Float(44100)
let π = Float(M_PI)

protocol Operation {
    func setVolumeSequence(sequence:Array<UInt>)
    func render(buffer:AVAudioPCMBuffer) ->Bool
}

class SinusOscillator:Operation {
    var length:UInt64 = 1000
    var offset:UInt64 = 0

    init(length: UInt64) {
        self.length = length
    }

    func setVolumeSequence(sequence:Array<UInt>) {
    }
    func render(buffer:AVAudioPCMBuffer) -> Bool {
        var j:Int = 0;

        for (var i = UInt64(0); i < self.length; i++) {
            buffer.floatChannelData.memory[Int(i)] = 5.0 * sin(Float(j++) * π * 440 / SampleRate)
        }
        return false
    }
}

class CommandParser {
    var operations = Array<Operation>()

    internal func parseHexSequence(chars:Array<Character>) -> (Array<UInt>, Int) {
        var sequence = Array<UInt>()
        var index = 0

        while (index < chars.count) {
            //Swift string handling doesn't allow access to a Characters value directy -> convert back to string
            let tmp = String(chars[index]).unicodeScalars
            let code:UInt = UInt(tmp[tmp.startIndex].value)
            switch (code) {
                case 0x30..<0x39:        // 0 - 9
                    sequence.append(code - 0x30)
                    index++
                    break
                case 0x61 ..< 0x66:
                    sequence.append(code - 0x61 + 10)
                    index++
                default:
                    return (sequence, index)
            }
        }

        return (sequence, index)
    }

    internal func parseInteger(chars:Array<Character>) -> (UInt64, Int) {
        var index = 0
        var value:UInt64 = 0
        while (index < chars.count) {
            let c:UInt64? = UInt64(String(chars[index]))
            if (c == nil) {
                return (value, index)
            }
            value = value * 10 + c!
            index++
        }
        return (value, index)
    }

    func parse(command:String) -> Bool {
        print(command)
        let chars = Array(command.characters)
        var index = 0

        while (index < chars.count) {
            let c = chars[index++]

            switch c {
                case "S":
                    if (index >= chars.count) {
                        return false
                    }

                    let (length_in_ms, length) = parseInteger(Array(chars[index ..< chars.count]))

                    self.operations.append(SinusOscillator(length: length_in_ms))

                    index += length
                    continue
                case "V":
                    let (sequence, length) = parseHexSequence(Array(chars[index ..< chars.count]))
                    operations[-1].setVolumeSequence(sequence)
                    index += length
                    continue
                default:
                    return false
            }
        }

        return true
    }
}
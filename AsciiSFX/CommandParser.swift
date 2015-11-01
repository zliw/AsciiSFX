//
//  CommandParser.swift
//  AsciiSFX
//
//  Created by Martin Wilz on 17/10/15.
//  Copyright © 2015  Martin Wilz. All rights reserved.
//

import AVFoundation

class CommandParser {
    var operations = Array<BufferOperation>()
    var frameCount:UInt64 = UInt64(SampleRate)

    internal func parseHexSequence(chars:Array<Character>) -> (Array<Float>, Int) {
        var sequence = Array<Float>()
        var index = 0

        while (index < chars.count) {
            //Swift string handling doesn't allow access to a Characters value directy -> convert back to string
            let tmp = String(chars[index]).unicodeScalars
            let code:UInt = UInt(tmp[tmp.startIndex].value)

            switch (code) {
                case 0x30 ..< 0x40:         // 0 - 9
                    sequence.append(Float(code - 0x30) / 15)
                    index++
                    break
                case 0x61 ..< 0x67:         // a-f
                    sequence.append(Float(code - 0x61 + 10) / 15)
                    index++
                default:
                    return (sequence, index)
            }
        }

        return (sequence, index)
    }

    internal func parseToneSequence(chars:Array<Character>) -> (Array<Tone>, Int) {
        var sequence = Array<Tone>()
        var index = 0
        var octave = UInt8(4)
        var tone: Tone?

        while (index < chars.count) {
            //Swift string handling doesn't allow access to a Characters value directy -> convert back to string
            let tmp = String(chars[index]).unicodeScalars
            let code:UInt = UInt(tmp[tmp.startIndex].value)

            switch (code, chars[index]) {
            case (0x31 ..< 0x40, _) :         // 0 - 9
                if let _ = tone {
                    tone!.length = UInt8(code - 0x30)
                }
                index++
                break
            case (_ , "a" ):
                fallthrough
            case (_ , "b" ):
                fallthrough
            case (_ , "c" ):
                fallthrough
            case (_ , "d" ):
                fallthrough
            case (_ , "e" ):
                fallthrough
            case (_ , "f" ):
                fallthrough
            case (_ , "g" ):

                if let _ = tone {
                    sequence.append(tone!)
                }

                tone = Tone(note: chars[index], octave: octave, length: UInt8(1))

                index++
                break
            case (_ , "+" ):
                octave += 1

                index++
                break
            case (_ , "-" ):
                octave -= 1

                index++
                break
            default:

                if let _ = tone {
                    sequence.append(tone!)
                }

                return (sequence, index)
            }
        }

        if let _ = tone {
            sequence.append(tone!)
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
                    self.frameCount = UInt64(length_in_ms) * UInt64(SampleRate) / 1000

                    index += length
                    continue

                case "T":
                    let (sequence, length) = parseToneSequence(Array(chars[index ..< chars.count]))
                    operations.last!.setToneSequence(sequence)

                    index += length
                    continue

                case "V":
                    if (operations.count == 0) {
                        return false
                    }

                    let (sequence, length) = parseHexSequence(Array(chars[index ..< chars.count]))

                    operations.last!.setVolumeSequence(sequence)
                    index += length
                    continue

                default:
                    return false
            }
        }

        return true
    }

    func render(buffer: AVAudioPCMBuffer) {
        for operation in self.operations {
            operation.render(buffer)
        }
    }
}
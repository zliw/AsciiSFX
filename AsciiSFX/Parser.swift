//
//  CommandParser.swift
//  AsciiSFX
//
//  Created by Martin Wilz on 17/10/15.
//  Copyright © 2015  Martin Wilz. All rights reserved.
//

import AVFoundation


class Parser {
    internal func getCharCode(char:Character) ->UInt {
        //Swift string handling doesn't allow access to a Characters value directy -> convert back to string
        let tmp = String(char).unicodeScalars
        return UInt(tmp[tmp.startIndex].value)
    }

    internal func parseHexSequence(chars:Array<Character>) -> (Array<VolumeSegment>, Int) {
        var sequence = Array<VolumeSegment>()
        var index = 0
        var segment: VolumeSegment?
        var slide = false

        while (index < chars.count) {
            let code = getCharCode(chars[index])
            var value:Float = -1

            switch (code, chars[index]) {
                case (0x30 ..< 0x40, _):         // 0 - 9
                    value = Float(code - 0x30) / 15
                    index++
                    break
                case (0x61 ..< 0x67, _):         // a-f
                    value = Float(code - 0x61 + 10) / 15
                    index++
                    break
                case (_, "-"):
                    slide = true
                    index++
                    break
                default:
                    return (sequence, index)
            }

            if (slide && value < 0) {
                continue
            }

            if let _ = segment {
                if slide {
                    slide = false
                    segment = VolumeSegment(from: segment!.from, to: value)
                    continue
                }
                sequence.append(segment!)
            }

            segment = VolumeSegment(from: value, to: nil)
        }

        if let _ = segment {
            sequence.append(segment!)
        }


        return (sequence, index)
    }

    internal func parseNoteSequence(chars:Array<Character>) -> (Array<Note>, Int) {
        var sequence = Array<Note>()
        var index = 0
        var octave = UInt8(4)
        var note: Note?
        var slide = false

        while (index < chars.count) {
            let code = getCharCode(chars[index])

            switch (code, chars[index]) {
            case (0x31 ..< 0x40, _) :         // 0 - 9
                if let _ = note {
                    note!.length = UInt8(code - 0x30)
                }
                index++
                break
            case (_, "/"):
                slide = true
                index++
                break
            case (_, "a"):
                fallthrough
            case (_, "b"):
                fallthrough
            case (_ , "c"):
                fallthrough
            case (_ , "d"):
                fallthrough
            case (_ , "e"):
                fallthrough
            case (_ , "f"):
                fallthrough
            case (_ , "g"):
                fallthrough
            case (_ , "."):

                if let _ = note {
                    if (slide) {
                        note!.toNote = chars[index]
                        note!.toOctave = octave
                        slide = false
                        index++
                        break
                    }
                    else {
                        sequence.append(note!)
                    }
                }

                note = Note(note: chars[index], octave: octave, length: UInt8(1))

                index++
                break
            case (_ , "+"):
                octave += (octave <= 8) ? 1 : 0

                index++
                break
            case (_ , "-"):
                octave -= (octave >= 1) ? 1 : 0

                index++
                break
            default:

                if let _ = note {
                    sequence.append(note!)
                }

                return (sequence, index)
            }
        }

        if let _ = note {
            sequence.append(note!)
        }

        return (sequence, index)
    }

    internal func parseInteger(chars:Array<Character>) -> (UInt32, Int) {
        var index = 0
        var value:UInt32 = 0
        while (index < chars.count) {
            let c:UInt32? = UInt32(String(chars[index]))
            if (c == nil) {
                return (value, index)
            }

            if value < UInt32.max / 10 {
                value = value * 10 + c!
            }

            index++
        }
        return (value, index)
    }

    func parse(command:String) -> Array<BufferOperation> {
        var operations = Array<BufferOperation>()
        let chars = Array(command.characters)
        var index = 0

        while (index < chars.count) {
            let c = chars[index++]

            switch c {
                case "S":
                    if (index >= chars.count - 1) {
                        return Array<BufferOperation>()
                    }

                    let type = chars[index++]

                    let (length_in_ms, length) = parseInteger(Array(chars[index ..< chars.count]))

                    // limit the length of generated signals to sensible values e.g. 20ms and 60s
                    if length_in_ms < 20 && length_in_ms > 60000 {
                        return Array<BufferOperation>()
                    }

                    switch (type) {
                        case "I":
                            operations.append(SinusOscillator(length: length_in_ms))
                        case "Q":
                            operations.append(SquareOscillator(length: length_in_ms))
                        case "W":
                            operations.append(SawtoothOscillator(length: length_in_ms))
                        case "N":
                            operations.append(NoiseOscillator(length: length_in_ms))
                        default:
                            return Array<BufferOperation>()
                    }

                    index += length
                    continue

                case "N":
                    if operations.count == 0 {
                        return Array<BufferOperation>()
                    }
                    let lastOperation = operations.last!
                    let (sequence, length) = parseNoteSequence(Array(chars[index ..< chars.count]))
                    let frequencyBuffer = FrequencyBuffer(length: lastOperation.length)
                    frequencyBuffer.setNoteSequence(sequence)
                    operations.last!.setFrequencyBuffer(frequencyBuffer)

                    index += length
                    continue

                case "V":
                    if (operations.count == 0) {
                        return Array<BufferOperation>()
                    }

                    let lastOperation = operations.last!
                    let (sequence, length) = parseHexSequence(Array(chars[index ..< chars.count]))
                    let volumeBuffer = VolumeBuffer(length:lastOperation.length)
                    volumeBuffer.setSequence(sequence)
                    operations.last!.setVolumeBuffer(volumeBuffer)
                    index += length
                    continue

                default:
                    return Array<BufferOperation>()
            }
        }

        if operations.count > 1 {
            return Array<BufferOperation>(arrayLiteral: MixOperation(operations:operations))
        }

        return operations
    }
}
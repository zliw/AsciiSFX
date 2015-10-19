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
    func setVolumeSequence(sequence:Array<Float>)
    func render(buffer:AVAudioPCMBuffer) ->Bool
}

class SinusOscillator:Operation {
    private var length:UInt64 = 1000
    private var offset:UInt64 = 0
    private var volumeSequence = [Float(1), Float(1)]

    init(length: UInt64) {
        self.length = length
    }

    func setVolumeSequence(sequence:Array<Float>) {
        self.volumeSequence = sequence
    }

    func render(buffer:AVAudioPCMBuffer) -> Bool {
        let sampleCount = Int(self.length * UInt64(SampleRate) / 1000)
        let partitionCount = sampleCount / (volumeSequence.count - 1)
        var volumeIndex = 0

        var i = Int(0)

        while (volumeIndex < volumeSequence.count - 1) {
            let current = Float(volumeSequence[volumeIndex])
            let diff = Float(volumeSequence[volumeIndex + 1]) - current

            for (var j = Int(0); j < partitionCount; j++) {
                let volume = current + Float(j) * diff / Float(partitionCount)
                buffer.floatChannelData.memory[j + i] = volume * sin(Float(i + j) * π * 440 / SampleRate)
            }
            i += partitionCount
            volumeIndex++
        }

        return false
    }
}

class CommandParser {
    var operations = Array<Operation>()
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
//
//  Operations.swift
//  AsciiSFX
//
//  Created by  Martin Wilz on 01/11/15.
//  Copyright © 2015  Martin Wilz. All rights reserved.
//

import AVFoundation

let SampleRate = Float(44100)
let π = Float(M_PI)


protocol BufferOperation {
    func setVolumeSequence(sequence:Array<Float>)
    func setToneSequence(sequence:Array<Tone>)
    func render(buffer:AVAudioPCMBuffer) ->Bool
}

class SinusOscillator:BufferOperation {
    private var length:UInt64 = 1000
    private var offset:UInt64 = 0
    private var volumeSequence = [Float(1), Float(1)]
    private var toneSequence = Array<Tone>()
    private var frequencyTable = Array<Float>()

    init(length: UInt64) {
        self.length = length
    }

    func setVolumeSequence(sequence:Array<Float>) {
        self.volumeSequence = sequence
    }

    func lengthOfSections(totalLength:UInt32, sequence: Array<Tone>) -> Array<UInt32> {
        var sectionLength = Array<UInt32>()
        var sectionCount:UInt32 = 0

        for (var i = Int(0); i < sequence.count; i++) {
            sectionCount += UInt32(sequence[i].length)
        }

        var currentLength:UInt32 = 0;

        for (var i = Int(0); i < sequence.count; i++) {
            sectionLength.append(UInt32(sequence[i].length) * UInt32(totalLength / sectionCount))
            currentLength += sectionLength[i]
        }

        //spread rounding error
        var index = 0
        while (currentLength < totalLength) {
            sectionLength[index++ % sectionLength.count]++
            currentLength++
        }

        return sectionLength
    }

    private func renderFrequencyTable() {
        let sampleCount = UInt32(self.length * UInt64(SampleRate) / 1000)

        self.frequencyTable = Array<Float>()

        let sectionLength = lengthOfSections(sampleCount, sequence: self.toneSequence)

        for (var i = 0; i < sectionLength.count; i++) {
            let length = sectionLength[i]
            let frequency = self.toneSequence[i].frequency()

            for (var j:UInt32 = 0; j < length; j++) {
                frequencyTable.append(frequency)
            }
        }
    }

    func setToneSequence(sequence:Array<Tone>) {
        self.toneSequence = sequence

        self.renderFrequencyTable()
    }

    func render(buffer:AVAudioPCMBuffer) -> Bool {
        let sampleCount = Int(self.length * UInt64(SampleRate) / 1000)
        let partitionCount = sampleCount / (volumeSequence.count - 1)
        var volumeIndex = 0

        var i = Int(0)

        while (volumeIndex < volumeSequence.count - 1) {
            let current = Float(volumeSequence[volumeIndex])
            let diff = Float(volumeSequence[volumeIndex + 1]) - current

            if (self.frequencyTable.count == sampleCount) {
                for (var j = Int(0); j < partitionCount; j++) {
                    let volume = current + Float(j) * diff / Float(partitionCount)
                    let value = volume * sin(Float(i + j) * 2 * π * self.frequencyTable[i + j] / SampleRate)
                    buffer.floatChannelData.memory[j + i] = value
                    // second channel
                    buffer.floatChannelData.memory[sampleCount + j + i] = value
                }
            }
            else {
                for (var j = Int(0); j < partitionCount; j++) {
                    let volume = current + Float(j) * diff / Float(partitionCount)
                    let value = volume * sin(Float(i + j) * 2 * π * 440 / SampleRate)
                    buffer.floatChannelData.memory[j + i] = value
                    // second channel
                    buffer.floatChannelData.memory[sampleCount + j + i] = value
                }
            }
            i += partitionCount
            volumeIndex++
        }
        
        return false
    }
}
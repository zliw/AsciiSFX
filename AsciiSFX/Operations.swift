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

    private var frequencies = Array<Float>()
    private var volumes = Array<Float>()

    init(length: UInt64) {
        self.length = length
    }

    func setVolumeSequence(sequence:Array<Float>) {
        self.volumeSequence = sequence
        self.renderVolumes()
        self.renderFrequencies()
    }

    func lengthOfSections(totalLength:UInt32, sequence: Array<Tone>) -> Array<UInt32> {
        return lengthOfSections(totalLength, sequence: sequence.map({ (tone) -> UInt32 in
            UInt32(tone.length)
        }))
    }

    func lengthOfSections(totalLength:UInt32, sequence: Array<UInt32>) -> Array<UInt32> {
        var sectionLength = Array<UInt32>()
        var sectionCount:UInt32 = 0

        if (sequence.count == 0) {
            return Array<UInt32>()
        }

        for (var i = Int(0); i < sequence.count; i++) {
            sectionCount += sequence[i]
        }

        var currentLength:UInt32 = 0;

        for (var i = Int(0); i < sequence.count; i++) {
            sectionLength.append(UInt32(sequence[i]) * UInt32(totalLength / sectionCount))
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

    private func renderVolumes() {
        let sampleCount = UInt32(self.length * UInt64(SampleRate) / 1000)

        self.volumes = Array<Float>()

        let sectionLength = lengthOfSections(sampleCount, sequence: self.volumeSequence.map({ (volume) -> UInt32 in
                UInt32(1)
            }))

        for (var i = 0; i < sectionLength.count; i++) {
            let length = sectionLength[i]
            let volume = self.volumeSequence[i]

            for (var j:UInt32 = 0; j < length; j++) {
                volumes.append(volume)
            }
        }
    }

    private func renderFrequencies() {
        let sampleCount = UInt32(self.length * UInt64(SampleRate) / 1000)

        self.frequencies = Array<Float>()

        let sectionLength = lengthOfSections(sampleCount, sequence: self.toneSequence)

        for (var i = 0; i < sectionLength.count; i++) {
            let length = sectionLength[i]
            let frequency = self.toneSequence[i].frequency()

            for (var j:UInt32 = 0; j < length; j++) {
                frequencies.append(frequency)
            }
        }
    }

    func setToneSequence(sequence:Array<Tone>) {
        self.toneSequence = sequence

        self.renderVolumes()
        self.renderFrequencies()
    }

    func render(buffer:AVAudioPCMBuffer) -> Bool {
        let sampleCount = Int(self.length * UInt64(SampleRate) / 1000)

        if (self.frequencies.count == sampleCount) {
            for (var i = Int(0); i < sampleCount; i++) {
                let value = volumes[i] * sin(Float(i) * 2 * π * self.frequencies[i] / SampleRate)
                buffer.floatChannelData.memory[i] = value
                // second channel
                buffer.floatChannelData.memory[sampleCount + i] = value
            }
        }
        else {
            // fallback -> static frequency of 440hz
            for (var i = Int(0); i < sampleCount; i++) {
                let value = volumes[i] * sin(Float(i) * 2 * π * 440 / SampleRate)
                buffer.floatChannelData.memory[i] = value
                // second channel
                buffer.floatChannelData.memory[sampleCount + i] = value
            }
        }

        return false
    }
}
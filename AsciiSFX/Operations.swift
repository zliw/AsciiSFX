//
//  Operations.swift
//  AsciiSFX
//
//  Created by  Martin Wilz on 01/11/15.
//  Copyright © 2015  Martin Wilz. All rights reserved.
//

import AVFoundation

let SampleRate = Float(44100)
let fadeSampleCount = UInt32(220)   // 5ms
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

    private var frequencyBuffer:AVAudioPCMBuffer?
    private var volumeBuffer:AVAudioPCMBuffer?

    init(length: UInt64) {
        self.length = length
    }

    // create a buffer with oscillations length of float samples
    private func getBuffer() -> AVAudioPCMBuffer {
        let sampleCount = UInt32(self.length * UInt64(SampleRate) / 1000)

        return AVAudioPCMBuffer(PCMFormat: AVAudioFormat(standardFormatWithSampleRate: Double(SampleRate), channels: 1),
                                frameCapacity:AVAudioFrameCount(sampleCount))

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

        self.volumeBuffer = getBuffer()

        let sectionLength = lengthOfSections(sampleCount, sequence: self.volumeSequence.map({ (volume) -> UInt32 in
                UInt32(1)
            }))

        var counter = 0;
        for (var i = 0; i < sectionLength.count; i++) {
            let length = sectionLength[i]
            let volume = self.volumeSequence[i]

            for (var j:UInt32 = 0; j < length; j++) {
                volumeBuffer?.floatChannelData.memory[counter++] = volume
            }
        }
    }

    private func resetVolume() {
        let sampleCount = UInt32(self.length * UInt64(SampleRate) / 1000)

        self.volumeBuffer = getBuffer()

        for (var i:Int = 0; i < Int(sampleCount); i++) {
            self.volumeBuffer?.floatChannelData.memory[i] = Float(1)
        }
    }

    private func renderFadeIn(wantedStart:UInt32) {
        let sampleCount = UInt32(self.length * UInt64(SampleRate) / 1000)

        if (self.volumeBuffer?.frameLength < sampleCount) {
            resetVolume()
        }

        if (wantedStart >= sampleCount) {
            return
        }

        let start:Int = Int(wantedStart)
        let count:Int = (wantedStart + fadeSampleCount < sampleCount) ? Int(fadeSampleCount) : Int(sampleCount - wantedStart)

        for (var i = 0; i < count; i++) {
            self.volumeBuffer?.floatChannelData.memory[start +  i] *= (Float(i) / Float(count))
        }
    }

    private func renderFadeOut(wantedStart:UInt32) {
        let sampleCount = UInt32(self.length * UInt64(SampleRate) / 1000)

        if (self.volumeBuffer?.frameLength < sampleCount) {
            resetVolume()
        }

        let start:Int = wantedStart > fadeSampleCount ? Int(wantedStart - fadeSampleCount) : 0
        var count:Int = wantedStart > fadeSampleCount ? Int(fadeSampleCount) : Int(start)

        if (UInt32(start + count) > sampleCount) {
            count = Int(sampleCount - UInt32(start))
        }

        for (var i = 0; i < count; i++) {
            self.volumeBuffer?.floatChannelData.memory[start +  i] *= Float(1) - (Float(i) / Float(count))
        }

    }

    private func renderFrequencies() {
        let sampleCount = UInt32(self.length * UInt64(SampleRate) / 1000)

        self.frequencyBuffer = getBuffer()

        let sectionLength = lengthOfSections(sampleCount, sequence: self.toneSequence)

        var counter = 0
        for (var i = 0; i < sectionLength.count; i++) {
            let length = sectionLength[i]
            let frequency = self.toneSequence[i].frequency()

            renderFadeIn(UInt32(counter))
            renderFadeOut(UInt32(counter) + length)

            for (var j:UInt32 = 0; j < length; j++) {
                frequencyBuffer?.floatChannelData.memory[counter++] = frequency
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

        if (self.frequencyBuffer != nil) {
            for (var i = Int(0); i < sampleCount; i++) {
                let value = (volumeBuffer?.floatChannelData.memory[i])! * sin(Float(i) * 2 * π * (self.frequencyBuffer?.floatChannelData.memory[i])! / SampleRate)
                buffer.floatChannelData.memory[i] = value
                // second channel
                buffer.floatChannelData.memory[sampleCount + i] = value
            }
        }
        else {
            // fallback -> static frequency of 440hz

            if (self.volumeBuffer != nil) {
                for (var i = Int(0); i < sampleCount; i++) {
                    let value = (self.volumeBuffer?.floatChannelData.memory[i])! * sin(Float(i) * 2 * π * 440 / SampleRate)
                    buffer.floatChannelData.memory[i] = value
                    // second channel
                    buffer.floatChannelData.memory[sampleCount + i] = value
                }
            }
            else {
                // fallback -> fixed volume
                for (var i = Int(0); i < sampleCount; i++) {
                    let value = sin(Float(i) * 2 * π * 440 / SampleRate)
                    buffer.floatChannelData.memory[i] = value
                    // second channel
                    buffer.floatChannelData.memory[sampleCount + i] = value
                }
            }
        }

        return false
    }
}
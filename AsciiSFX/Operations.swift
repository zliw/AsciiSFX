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


protocol BufferOperation {
    var length:UInt64 { get }
    func setVolumeSequence(sequence:Array<Float>)
    func setNoteSequence(sequence:Array<Note>)
    func render(buffer:AVAudioPCMBuffer) ->Bool
}


class WavetableOscillator:BufferOperation {
    var length:UInt64
    private var offset:UInt64 = 0
    private var volumeSequence = [Float(1), Float(1)]
    private var toneSequence = Array<Note>()

    private var frequencyBuffer: AVAudioPCMBuffer?
    private var volumeBuffer: AVAudioPCMBuffer?
    private var wavetableBuffer: AVAudioPCMBuffer?
    private var wavetableLength: Int = 0

    init(length: UInt64) {
        self.length = length
    }

    // creates a buffer according to length and samplerate
    private func getBuffer() -> AVAudioPCMBuffer {
        let sampleCount = UInt32(self.length * UInt64(SampleRate) / 1000)

        return AVAudioPCMBuffer(PCMFormat: AVAudioFormat(standardFormatWithSampleRate: Double(SampleRate), channels: 1),
            frameCapacity:AVAudioFrameCount(sampleCount))

    }

    // create a buffer with oscillations length of float samples
    private func allocateWaveTable(sampleCount: UInt32) -> AVAudioPCMBuffer {
        wavetableLength = Int(sampleCount)
        return AVAudioPCMBuffer(PCMFormat: AVAudioFormat(standardFormatWithSampleRate: Double(SampleRate), channels: 1),
            frameCapacity:AVAudioFrameCount(sampleCount))
    }

    func setVolumeSequence(sequence:Array<Float>) {
        self.volumeSequence = sequence
        self.renderVolumes()

        // if there already is a frequencyBuffer, rerender it for fadein/out matches
        if let _ = frequencyBuffer {
            self.renderFrequencies()
        }
    }

    func lengthOfSections(totalLength:UInt32, sequence: Array<Note>) -> Array<UInt32> {
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

        if (self.volumeBuffer == nil || self.volumeBuffer?.frameCapacity < sampleCount) {
            resetVolume()
        }

        let sectionLength = lengthOfSections(sampleCount, sequence: self.toneSequence)

        var counter = 0
        for (var i = 0; i < sectionLength.count; i++) {
            let length = sectionLength[i]
            let start = self.toneSequence[i].frequency()
            let end = self.toneSequence[i].toFrequency()
            let diff = end - start

            print(start, end, diff)

            renderFadeIn(UInt32(counter))
            renderFadeOut(UInt32(counter) + length)

            for (var j:UInt32 = 0; j < length; j++) {
                frequencyBuffer?.floatChannelData.memory[counter++] = start + (diff * Float(j) / Float(length))
            }
        }
    }

    func setNoteSequence(sequence:Array<Note>) {
        self.toneSequence = sequence

        self.renderVolumes()
        self.renderFrequencies()
    }

    func render(buffer:AVAudioPCMBuffer) -> Bool {
        let sampleCount = Int(self.length * UInt64(SampleRate) / 1000)

        if (wavetableLength == 0) {
            return false;
        }

        if (buffer.format.channelCount != 2) {
            return false;
        }

        if (Int(buffer.frameCapacity) < sampleCount) {
            return false;
        }

        let periodLength = Float(wavetableLength)
        let wavetable = wavetableBuffer!.floatChannelData.memory

        if let _ = frequencyBuffer {
            let frequency = frequencyBuffer!.floatChannelData.memory
            let volume = volumeBuffer!.floatChannelData.memory
            var phase:Float = 0.0

            for (var i = Int(0); i < sampleCount; i++) {
                let freq = frequency[i]
                phase += periodLength * freq / SampleRate
                let value = volume[i] * wavetable[Int(phase) % wavetableLength]
                buffer.floatChannelData.memory[i] = value
                // second channel
                buffer.floatChannelData.memory[sampleCount + i] = value
            }
        }
        else if let _ = volumeBuffer {
            // fallback, fixed frequency of 440hz, using volume
            let volume = volumeBuffer!.floatChannelData.memory
            for (var i = Int(0); i < sampleCount; i++) {
                let value = (volume[i]) * wavetable[Int(Float(i) * periodLength * 440 / SampleRate) % wavetableLength]
                buffer.floatChannelData.memory[i] = value
                // second channel
                buffer.floatChannelData.memory[sampleCount + i] = value
            }
        }
        else {
            // fallback -> fixed volume
            for (var i = Int(0); i < sampleCount; i++) {
                let value = wavetable[Int(Float(i) * periodLength * 440 / SampleRate) % wavetableLength]
                buffer.floatChannelData.memory[i] = value
                // second channel
                buffer.floatChannelData.memory[sampleCount + i] = value
            }
        }

        return false
    }
}

class SinusOscillator:WavetableOscillator {

    override init(length: UInt64) {
        super.init(length: length)

        let length = 4096
        wavetableBuffer = allocateWaveTable(UInt32(length))

        for (var i:Int = 0; i < length; i++) {
            wavetableBuffer?.floatChannelData.memory[i] = sin(Float(i) * 2 * Float(M_PI) / Float(length))
        }
    }
}

class SquareOscillator:WavetableOscillator {

    override init(length: UInt64) {
        super.init(length: length)

        let length = 4096
        wavetableBuffer = allocateWaveTable(UInt32(length))

        for (var i:Int = 0; i < length / 2; i++) {
            wavetableBuffer?.floatChannelData.memory[i] = 1
        }

        for (var i:Int = length / 2; i < length; i++) {
            wavetableBuffer?.floatChannelData.memory[i] = -1
        }
    }
}

class SawtoothOscillator:WavetableOscillator {

    override init(length: UInt64) {
        super.init(length: length)

        let length = 4096
        wavetableBuffer = allocateWaveTable(UInt32(length))

        for (var i:Int = 0; i < length / 2; i++) {
            wavetableBuffer?.floatChannelData.memory[i] = 2 - 2 * (Float(i) / Float(length))
        }
    }
}
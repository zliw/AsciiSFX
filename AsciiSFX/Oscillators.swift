//
//  Oscillators.swift
//  AsciiSFX
//
//  Created by  Martin Wilz on 01/11/15.
//  Copyright © 2015  Martin Wilz. All rights reserved.
//

import AVFoundation

let SampleRate = Float(44100)

class WavetableOscillator:BufferOperation {
    var length:UInt32
    private let volumeBuffer: VolumeBuffer
    private var toneSequence = Array<Note>()

    private var frequencyBuffer: AVAudioPCMBuffer?
    private var wavetableBuffer: AVAudioPCMBuffer?
    private var wavetableLength: Int = 0

    init(length: UInt32) {
        self.length = length
        self.volumeBuffer = VolumeBuffer.init(length: length)
    }

    // create a buffer with oscillations length of float samples
    private func allocateWaveTable(sampleCount: UInt32) -> AVAudioPCMBuffer {
        wavetableLength = Int(sampleCount)
        return AVAudioPCMBuffer(PCMFormat: AVAudioFormat(standardFormatWithSampleRate: Double(SampleRate), channels: 1),
            frameCapacity:AVAudioFrameCount(sampleCount))
    }

    func setVolumeSequence(sequence:Array<Float>) {
        self.volumeBuffer.setSequence(sequence)
        self.volumeBuffer.render()

        // if there already is a frequencyBuffer, rerender it for fadein/out matches
        if let _ = frequencyBuffer {
            self.renderFrequencies()
        }
    }

    private func renderFrequencies() {
        let sampleCount = UInt32(self.length * UInt32(SampleRate) / 1000)

        self.frequencyBuffer = Helper().getBuffer(self.length)

        if (self.volumeBuffer.isEmpty) {
            self.volumeBuffer.reset()
        }

        let sectionLength = Helper().lengthOfSections(sampleCount, sequence: self.toneSequence)

        var counter = 0
        for (var i = 0; i < sectionLength.count; i++) {
            let length = sectionLength[i]
            let start = self.toneSequence[i].frequency()
            let end = self.toneSequence[i].toFrequency()
            let diff = end - start

            print(start, end, diff)

            self.volumeBuffer.fadeIn(UInt32(counter))
            self.volumeBuffer.fadeOut(UInt32(counter) + length)

            for (var j:UInt32 = 0; j < length; j++) {
                frequencyBuffer?.floatChannelData.memory[counter++] = start + (diff * Float(j) / Float(length))
            }
        }
    }

    func setNoteSequence(sequence:Array<Note>) {
        self.toneSequence = sequence

        self.volumeBuffer.render()
        self.renderFrequencies()
    }

    func render(buffer:AVAudioPCMBuffer) -> Bool {
        let sampleCount = Int(self.length * UInt32(SampleRate) / 1000)

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
            let volume = volumeBuffer.buffer.floatChannelData.memory
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
        else if !volumeBuffer.isEmpty {
            // fallback, fixed frequency of 440hz, using volume
            let volume = volumeBuffer.buffer.floatChannelData.memory
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

    override init(length: UInt32) {
        super.init(length: length)

        let length = 4096
        wavetableBuffer = allocateWaveTable(UInt32(length))

        for (var i:Int = 0; i < length; i++) {
            wavetableBuffer?.floatChannelData.memory[i] = sin(Float(i) * 2 * Float(M_PI) / Float(length))
        }
    }
}

class SquareOscillator:WavetableOscillator {

    override init(length: UInt32) {
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

    override init(length: UInt32) {
        super.init(length: length)

        let length = 4096
        wavetableBuffer = allocateWaveTable(UInt32(length))

        for (var i:Int = 0; i < length / 2; i++) {
            wavetableBuffer?.floatChannelData.memory[i] = 2 - 2 * (Float(i) / Float(length))
        }
    }
}
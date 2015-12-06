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
    let length:UInt32
    let parameterLength:UInt32
    let isGenerator = true

    private let frequencyBuffer: FrequencyBuffer

    private var wavetableBuffer: AVAudioPCMBuffer?
    private var wavetableLength: Int = 0

    init(length: UInt32, sequence:Array<Note>) {
        self.length = length
        self.parameterLength = length

        var s = sequence
        if (sequence.count == 0) {
            s = Array(arrayLiteral: Note(note: "a", octave: 4, length: 1))
        }

        self.frequencyBuffer = FrequencyBuffer(length:length, sequence: s)
    }

    // create a buffer with oscillations length of float samples
    private func allocateWaveTable(sampleCount: UInt32) -> AVAudioPCMBuffer {
        wavetableLength = Int(sampleCount)
        return AVAudioPCMBuffer(PCMFormat: AVAudioFormat(standardFormatWithSampleRate: Double(SampleRate), channels: 1),
            frameCapacity:AVAudioFrameCount(sampleCount))
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

        frequencyBuffer.render()

        let frequency = frequencyBuffer.buffer.floatChannelData[0]
        let volumes = frequencyBuffer.volumeBuffer.buffer.floatChannelData[0]
        var phase:Float = 0.0

        for (var i = Int(0); i < sampleCount; i++) {
            let freq = frequency[i]
            if freq == 0 {
                buffer.floatChannelData[0][i] = 0
                buffer.floatChannelData[1][i] = 0
            }
            else {
                phase += periodLength * freq / SampleRate
                let volume = volumes[i]
                let value = volume * wavetable[Int(phase) % wavetableLength]
                buffer.floatChannelData[0][i] = value
                buffer.floatChannelData[1][i] = value
            }
        }

        return true
    }
}

class SinusOscillator: WavetableOscillator {

    override init(length: UInt32, sequence:Array<Note>) {
        super.init(length: length, sequence: sequence)

        let length = 4096
        wavetableBuffer = allocateWaveTable(UInt32(length))

        for (var i:Int = 0; i < length; i++) {
            wavetableBuffer?.floatChannelData.memory[i] = sin(Float(i) * 2 * Float(M_PI) / Float(length))
        }
    }
}

class SquareOscillator: WavetableOscillator {

    override init(length: UInt32, sequence:Array<Note>) {
        super.init(length: length, sequence: sequence)

        let length = 4096
        wavetableBuffer = allocateWaveTable(UInt32(length))

        for (var i:Int = 0; i < length / 2; i++) {
            wavetableBuffer?.floatChannelData[0][i] = 1
        }

        for (var i:Int = length / 2; i < length; i++) {
            wavetableBuffer?.floatChannelData[0][i] = -1
        }
    }
}

class SawtoothOscillator: WavetableOscillator {

    override init(length: UInt32, sequence:Array<Note>) {
        super.init(length: length, sequence: sequence)

        let length = 4096
        wavetableBuffer = allocateWaveTable(UInt32(length))

        for (var i:Int = 0; i < length / 2; i++) {
            wavetableBuffer?.floatChannelData[0][i] = 2 - 2 * (Float(i) / Float(length))
        }
    }
}

class NoiseOscillator:WavetableOscillator {

    override init(length: UInt32, sequence:Array<Note>) {
        super.init(length: length, sequence: sequence)

        let length = 2048
        wavetableBuffer = allocateWaveTable(UInt32(length))

        for (var i:Int = 0; i < length; i++) {
            wavetableBuffer?.floatChannelData[0][i] = 2 * (Float(arc4random()) / 0xFFFFFFFF) - 1
        }
    }
}
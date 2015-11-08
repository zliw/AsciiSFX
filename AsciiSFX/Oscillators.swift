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

    private var volumeBuffer: VolumeBuffer?
    private var frequencyBuffer: FrequencyBuffer?

    private var wavetableBuffer: AVAudioPCMBuffer?
    private var wavetableLength: Int = 0

    init(length: UInt32) {
        self.length = length
    }

    // create a buffer with oscillations length of float samples
    private func allocateWaveTable(sampleCount: UInt32) -> AVAudioPCMBuffer {
        wavetableLength = Int(sampleCount)
        return AVAudioPCMBuffer(PCMFormat: AVAudioFormat(standardFormatWithSampleRate: Double(SampleRate), channels: 1),
            frameCapacity:AVAudioFrameCount(sampleCount))
    }

    func setFrequencyBuffer(frequencyBuffer:FrequencyBuffer) {
        self.frequencyBuffer = frequencyBuffer
    }

    func setVolumeBuffer(volumeBuffer:VolumeBuffer) {
        self.volumeBuffer = volumeBuffer
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
            frequencyBuffer?.render()

            let frequency = frequencyBuffer!.buffer.floatChannelData.memory
            let volumes = frequencyBuffer!.volumeBuffer.buffer.floatChannelData.memory
            var phase:Float = 0.0

            for (var i = Int(0); i < sampleCount; i++) {
                let freq = frequency[i]
                phase += periodLength * freq / SampleRate
                let volume = volumes[i]
                let value = volume * wavetable[Int(phase) % wavetableLength]
                buffer.floatChannelData.memory[i] = value
                // second channel
                buffer.floatChannelData.memory[sampleCount + i] = value
            }
        }
        else {
            // fallback -> fixed frequency
            for (var i = Int(0); i < sampleCount; i++) {
                let value = wavetable[Int(Float(i) * periodLength * 440 / SampleRate) % wavetableLength]
                buffer.floatChannelData.memory[i] = value
                // second channel
                buffer.floatChannelData.memory[sampleCount + i] = value
            }
        }

        if let _ = volumeBuffer {
            volumeBuffer?.render()

            let volumes = volumeBuffer!.buffer.floatChannelData.memory
            // fallback, fixed frequency of 440hz, using volume
            for (var i = Int(0); i < sampleCount; i++) {
                buffer.floatChannelData.memory[i] *= volumes[i]
                buffer.floatChannelData.memory[sampleCount + i] *= volumes[i]
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
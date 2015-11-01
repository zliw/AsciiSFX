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

    init(length: UInt64) {
        self.length = length
    }

    func setVolumeSequence(sequence:Array<Float>) {
        self.volumeSequence = sequence
    }

    func setToneSequence(sequence:Array<Tone>) {
        self.toneSequence = sequence
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
                let value = volume * sin(Float(i + j) * 2 * π * 440 / SampleRate)
                buffer.floatChannelData.memory[j + i] = value
                // second channel
                buffer.floatChannelData.memory[sampleCount + j + i] = value
            }
            i += partitionCount
            volumeIndex++
        }
        
        return false
    }
}
//
//  FilterBuffer.swift
//  AsciiSFX
//
//  Created by martin on 01/12/15.
//  Copyright © 2015 martin. All rights reserved.
//


import AVFoundation

let π = Float(3.1415296)

class LowPassFilterOperation:BufferOperation {
    let length:UInt32
    let parameterLength:UInt32
    let isGenerator = false
    let ratio = 16
    var volumeBuffer:VolumeBuffer
    var frequencyBuffer:FrequencyBuffer

    init(length: UInt32) {
        self.length = length
        self.parameterLength = 1 + length / UInt32(ratio)
        self.volumeBuffer = VolumeBuffer(length:parameterLength)
        self.volumeBuffer.setSequence([VolumeSegment(from:0.25, to: 0.25)])
        self.frequencyBuffer = FrequencyBuffer(length:parameterLength)
        self.frequencyBuffer.setNoteSequence([Note(note: "a", octave: 4), Note(note: "a", octave: 4)])
    }

    func setVolumeBuffer(volumeBuffer:VolumeBuffer) {
        self.volumeBuffer = volumeBuffer
    }

    func setFrequencyBuffer(frequencyBuffer:FrequencyBuffer) {
        self.frequencyBuffer = frequencyBuffer
    }

    func render(buffer:AVAudioPCMBuffer) -> Bool {
        let length = Int((Float(self.length) * SampleRate) / 1000)
        let plength = Int((Float(self.parameterLength) * SampleRate) / 1000)
        let volume = volumeBuffer.buffer.floatChannelData[0]
        let frequency = frequencyBuffer.buffer.floatChannelData[0]

        for var ch = 0; ch < 2; ch++  {
            var (o1, o2, o3, o4) = (Float(0), Float(0), Float(0), Float(0))
            var (i1, i2, i3, i4) = (Float(0), Float(0), Float(0), Float(0))
            let samples = buffer.floatChannelData[ch]

            var i = Int(0)
            for var p = 0; p < plength; p++ {
                //adapted from http://www.musicdsp.org/archive.php?classid=3#26

                let f = (1.16 * frequency[p] * 2) / SampleRate // cutoff, nearly linear [0, 1] -> [0, fs/2]
                let res = 4 * volume[p]                        // resonance [0, 4] -> [no resonance, self-oscillation
                let fb = res * (1.0 - 0.15 * f * f);
                let limit = min(ratio, length - i)

                for var k = 0; k < limit; k++ {
                    var input = samples[i]
                    input -= o4 * fb
                    input *= 0.35013 * (f * f) * (f * f)
                    o1 = input + 0.3 * i1 + (1 - f) * o1   // Pole 1
                    i1  = input
                    o2 = o1 + 0.3 * i2 + (1 - f) * o2   // Pole 2
                    i2  = o1
                    o3 = o2 + 0.3 * i3 + (1 - f) * o3;  // Pole 3
                    i3  = o2;
                    o4 = o3 + 0.3 * i4 + (1 - f) * o4;  // Pole 4
                    i4  = o3;
                    samples[i++] = o4
                }
            }
        }

        return true
    }
    
}
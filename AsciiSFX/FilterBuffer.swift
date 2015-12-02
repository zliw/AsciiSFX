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
    var length = UInt32(0)
    let isGenerator = false

    init(length: UInt32) {
        self.length = length
    }

    func setVolumeBuffer(volumeBuffer:VolumeBuffer) {
    }

    func setFrequencyBuffer(frequencyBuffer:FrequencyBuffer) {
    }

    func render(buffer:AVAudioPCMBuffer) -> Bool {
        let length = Int((Float(self.length) * SampleRate) / 1000)

        //adapted from http://www.musicdsp.org/archive.php?classid=3#26
        let fc = Float(0.2)    // cutoff, nearly linear [0, 1] -> [0, fs/2]
        let res = Float(1.5)   // resonance [0, 4] -> [no resonance, self-oscillation
        let f = fc * 1.16;
        let fb = res * (1.0 - 0.15 * f * f);
        var (o1, o2, o3, o4) = (Float(0), Float(0), Float(0), Float(0))
        var (i1, i2, i3, i4) = (Float(0), Float(0), Float(0), Float(0))

        for var j = 0; j < 2; j++  {
            let ch = buffer.floatChannelData[j]

            for var i = 0; i < length; i++ {
                var input = ch[i]
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
                ch[i] = o4
            }
        }

        return true
    }
    
}
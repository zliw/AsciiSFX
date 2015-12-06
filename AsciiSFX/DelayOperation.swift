//
//  DelayOperation.swift
//  AsciiSFX
//
//  Created by martin on 30/11/15.
//  Copyright © 2015 martin. All rights reserved.
//

import AVFoundation

class DelayOperation:BufferOperation {
    let delay:UInt32
    let level:UInt32
    let length:UInt32
    let parameterLength:UInt32
    let isGenerator = false

    init(length: UInt32, delay:UInt32 ,level: UInt32) {
        self.level = level
        self.delay = delay
        self.length = length
        self.parameterLength = length / 256
    }

    func render(buffer:AVAudioPCMBuffer) -> Bool {
        let cl = buffer.floatChannelData[0]
        let cr = buffer.floatChannelData[1]
        let delay = Int((Float(self.delay) * SampleRate) / 1000)
        let length = Int((Float(self.length) * SampleRate) / 1000)
        let level = Float(self.level) / 100.0

        for var i = length - delay - 1; i >= 0; i-- {
            cl[i + delay] += level * cl[i]
            cr[i + delay] += level * cr[i]
        }

        return true
    }

}
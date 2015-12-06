//
//  VolumeOperation.swift
//  AsciiSFX
//
//  Created by martin on 06/12/15.
//  Copyright © 2015 martin. All rights reserved.
//

import AVFoundation

class VolumeOperation: BufferOperation {
    internal var length:UInt32
    let parameterLength: UInt32
    let isGenerator = false
    let sequence: Array<VolumeSegment>

    init(length: UInt32, sequence: Array<VolumeSegment>) {
        self.length = length
        self.parameterLength = length
        self.sequence = sequence
    }

    func render(buffer:AVAudioPCMBuffer) -> Bool {
        let sampleCount = UInt32(self.length * UInt32(SampleRate) / 1000)

        let sectionLength = Helper().lengthOfSections(sampleCount, sequence: self.sequence.map({ (volume) -> UInt32 in
            UInt32(1)
        }))

        var counter = 0;
        for (var i = 0; i < sectionLength.count; i++) {
            let length = sectionLength[i]
            let volume = self.sequence[i]

            if let _ = volume.to {
                let diff = volume.to! - volume.from

                for (var j:UInt32 = 0; j < length; j++) {
                    buffer.floatChannelData[0][counter] *= volume.from + diff * Float(j) / Float(length)
                    buffer.floatChannelData[1][counter++] *= volume.from + diff * Float(j) / Float(length)
                }
            }
            else {
                for (var j:UInt32 = 0; j < length; j++) {
                    buffer.floatChannelData[0][counter] *= volume.from
                    buffer.floatChannelData[1][counter++] *= volume.from
                }
            }
        }
        return true
    }
}

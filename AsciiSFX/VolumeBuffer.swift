//
//  VolumeBuffer.swift
//  AsciiSFX
//
//  Created by martin on 07/11/15.
//  Copyright © 2015 martin. All rights reserved.
//

import AVFoundation

struct VolumeSegment {
    var from: Float
    var to: Float?
}

class VolumeBuffer {
    private var length:UInt32
    var buffer: AVAudioPCMBuffer
    var sequence: Array<VolumeSegment> = Array<VolumeSegment>(arrayLiteral: VolumeSegment(from: 1.0, to: 1.0))

    init(length: UInt32) {
        self.length = length
        self.buffer = Helper().getBuffer(length)
    }

    func setSequence(sequence: Array<VolumeSegment>) {
        self.sequence = sequence
    }

    func render() {
        let sampleCount = UInt32(self.length * UInt32(SampleRate) / 1000)

        self.buffer = Helper().getBuffer(self.length)

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
                    self.buffer.floatChannelData[0][counter++] = volume.from + diff * Float(j) / Float(length)
                }
            }
            else {
                for (var j:UInt32 = 0; j < length; j++) {
                    self.buffer.floatChannelData[0][counter++] = volume.from
                }
            }
        }
    }

    func reset() {
        let sampleCount = UInt32(self.length * UInt32(SampleRate) / 1000)

        self.buffer = Helper().getBuffer(self.length)

        for (var i:Int = 0; i < Int(sampleCount); i++) {
            self.buffer.floatChannelData[0][i] = Float(1)
        }
    }

    func fadeInFrom(wantedStart:UInt32, lengthInSamples:UInt32) {
        let sampleCount = UInt32(self.length * UInt32(SampleRate) / 1000)

        if (wantedStart >= sampleCount) {
            return
        }

        let start:Int = Int(wantedStart)
        let count:Int = (wantedStart + lengthInSamples < sampleCount) ? Int(lengthInSamples) : Int(sampleCount - wantedStart)

        for (var i = 0; i < count; i++) {
            self.buffer.floatChannelData[0][start +  i] *= (Float(i) / Float(count))
        }
    }

    func fadeOutTo(wantedEnd:UInt32, lengthInSamples:UInt32) {
        let sampleCount = UInt32(self.length * UInt32(SampleRate) / 1000)

        let start:Int = wantedEnd > lengthInSamples ? Int(wantedEnd - lengthInSamples) : 0
        var count:Int = wantedEnd > lengthInSamples ? Int(lengthInSamples) : Int(start)

        if (UInt32(start + count) > sampleCount) {
            count = Int(sampleCount - UInt32(start))
        }

        for (var i = 0; i < count; i++) {
            self.buffer.floatChannelData[0][start +  i] *= Float(1) - (Float(i) / Float(count))
        }
    }
}

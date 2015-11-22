//
//  MixBuffer.swift
//  AsciiSFX
//
//  Created by martin on 22/11/15.
//  Copyright © 2015 martin. All rights reserved.
//

// Mixbuffer is meant to be a mechanism to build operation trees
// all operations in a mix buffer are mixed together. mix buffer 
// allocates buffers foreach generator/effect chain
// and mixes them together in the final output
// buffer using the same volume for each buffer

import AVFoundation

class MixOperation:BufferOperation {
    private var operations =  Array<BufferOperation>()
    let isGenerator = true

    var length: UInt32 {
        get {
            if (operations.count == 0) {
                return 0
            }
            return operations.map({ $0.length }).maxElement()!
        }
    }

    init(operations: Array<BufferOperation>) {
        self.operations = operations
    }

    func setFrequencyBuffer(frequencyBuffer:FrequencyBuffer) {
        if operations.count > 0 {
            operations.last!.setFrequencyBuffer(frequencyBuffer)
        }
    }

    func setVolumeBuffer(volumeBuffer:VolumeBuffer) {
        if operations.count > 0 {
            operations.last!.setVolumeBuffer(volumeBuffer)
        }
    }

    private func mix(buffer:AVAudioPCMBuffer, other:AVAudioPCMBuffer, volume:Float, volume2:Float) {
        let sampleCount = Int(self.length * UInt32(SampleRate) / 1000)

        let cl1 = buffer.floatChannelData[0]
        let cl2 = other.floatChannelData[0]
        let cr1 = buffer.floatChannelData[1]
        let cr2 = other.floatChannelData[1]

        for (var i = 0; i < sampleCount; i++) {
            cl1[i] = volume * cl1[i] + volume2 * cl2[i]
            cr1[i] = volume * cr1[i] + volume2 * cr2[i]
        }
    }

    func render(buffer:AVAudioPCMBuffer) -> Bool {
        let generators = operations.filter({ $0.isGenerator })

        //premature optimization -> one buffer doesn't need mixing
        if generators.count == 1 {
            for operation in operations {
                let result = operation.render(buffer)
                if !result { return false }
            }
            return true
        }

        // render first buffer
        var result = operations[0].render(buffer)

        if !result { return false }

        var index = 1
        let channelRatio = Float(1) / Float(generators.count)
        var volume = channelRatio

        while index < operations.count && !operations[index].isGenerator {
            result = operations[index].render(buffer)
            if !result { return false }
            index++
        }

        let otherBuffer = Helper().getBuffer(self.length, format: buffer.format)

        // render mix loop
        while index < operations.count {
            result = operations[index].render(otherBuffer)
            if !result { return false }
            index++

            while index < operations.count && !operations[index].isGenerator {
                result = operations[index].render(otherBuffer)
                if !result { return false }
                index++
            }

            mix(buffer, other: otherBuffer, volume: volume, volume2: channelRatio)
            // after the first mix, the buffer volume is constant
            volume = 1
        }

        return true
    }
}


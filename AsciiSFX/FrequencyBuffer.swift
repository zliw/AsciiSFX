//
//  FrequencyBuffer.swift
//  AsciiSFX
//
//  Created by martin on 08/11/15.
//  Copyright © 2015 martin. All rights reserved.
//

import AVFoundation

class FrequencyBuffer {
    var length: UInt32
    let buffer: AVAudioPCMBuffer
    var volumeBuffer: VolumeBuffer
    private var noteSequence = Array<Note>()
    private let fadeSampleCount = UInt32(SampleRate / 200)   // 5ms

    init(length: UInt32) {
        self.length = length
        self.buffer = Helper().getBuffer(length)
        self.volumeBuffer = VolumeBuffer(length: length)
    }

    func render() {
        let sampleCount = UInt32(self.length * UInt32(SampleRate) / 1000)

        let sectionLength = Helper().lengthOfSections(sampleCount, sequence: self.noteSequence)

        self.volumeBuffer.render()

        var counter = 0
        for (var i = 0; i < sectionLength.count; i++) {
            let length = sectionLength[i]
            let start = self.noteSequence[i].frequency()
            let end = self.noteSequence[i].toFrequency()
            let diff = end - start

            self.volumeBuffer.fadeInFrom(UInt32(counter), lengthInSamples: fadeSampleCount)
            self.volumeBuffer.fadeOutTo(UInt32(counter) + length, lengthInSamples: fadeSampleCount)

            let buffer = self.buffer.floatChannelData[0]
            for (var j:UInt32 = 0; j < length; j++) {
                buffer[counter++] = start + (diff * Float(j) / Float(length))
            }
        }
    }

    func setNoteSequence(sequence:Array<Note>) {
        self.noteSequence = sequence
        self.render()
    }
}


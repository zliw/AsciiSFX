//
//  BufferOperation.swift
//  AsciiSFX
//
//  Created by martin on 07/11/15.
//  Copyright © 2015 martin. All rights reserved.
//

import AVFoundation

protocol BufferOperation {
    var length:UInt32 { get }
    func setVolumeSequence(sequence:Array<Float>)
    func setNoteSequence(sequence:Array<Note>)
    func render(buffer:AVAudioPCMBuffer) ->Bool
}

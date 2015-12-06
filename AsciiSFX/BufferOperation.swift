//
//  BufferOperation.swift
//  AsciiSFX
//
//  Created by martin on 07/11/15.
//  Copyright © 2015 martin. All rights reserved.
//

import AVFoundation

protocol BufferOperation {
    var length: UInt32 { get }
    var parameterLength: UInt32 { get }
    var isGenerator: Bool { get }
    func render(buffer:AVAudioPCMBuffer) -> Bool
}

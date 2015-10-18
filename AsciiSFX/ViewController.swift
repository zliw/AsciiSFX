//
//  ViewController.swift
//  AsciiSFX
//
//  Created by martin on 17/10/15.
//  Copyright © 2015 martin. All rights reserved.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController {
    @IBOutlet var textField:NSTextField?
    @IBOutlet var playButton:NSButton?
    let parser = CommandParser()

    let engine = AVAudioEngine()
    let player:AVAudioPlayerNode = AVAudioPlayerNode()

    override func viewDidLoad() {
        super.viewDidLoad()

        let mixer = engine.mainMixerNode
        engine.attachNode(player)
        engine.connect(player, to:mixer, format:mixer.outputFormatForBus(0))
        do {
            try engine.start()
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
    }

    @IBAction func play(sender:NSObject?) {
        let command = textField?.stringValue
        if ((command != nil && command?.lengthOfBytesUsingEncoding(NSASCIIStringEncoding) > 0)) {
            let valid = parser.parse(command!)
            if (valid) {
                self.playButton?.enabled = false

                let queue = NSOperationQueue()

                queue.addOperationWithBlock({
                    print("rendering")
                    let buffer = AVAudioPCMBuffer(PCMFormat: self.player.outputFormatForBus(0),
                                              frameCapacity:AVAudioFrameCount(self.parser.frameCount))
                    buffer.frameLength = AVAudioFrameCount(self.parser.frameCount)

                    self.parser.render(buffer)

                    print("scheduling")
                    self.player.scheduleBuffer(buffer,
                                               atTime:nil,
                                               options:.InterruptsAtLoop,
                                               completionHandler: {
                        self.playButton?.enabled = true
                        print("playing stopped")
                    })
                })
                player.play()
            }
        }
    }
}


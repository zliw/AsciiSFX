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

    @IBAction func save(sender:NSObject?) {
        if (!parse()) {
            let alert = NSAlert()
            alert.messageText = "parsing failed"
            alert.runModal()
            return
        }

        let url = NSURL(fileURLWithPath: "/tmp/out.wav");
        let format = self.player.outputFormatForBus(0)

        do {
            let file = try AVAudioFile(forWriting: url, settings: [AVFormatIDKey : NSNumber(unsignedInt: kAudioFormatLinearPCM),
                AVNumberOfChannelsKey : NSNumber(unsignedInt:format.channelCount),
                AVSampleRateKey : NSNumber(double:format.sampleRate),
                AVLinearPCMIsFloatKey: NSNumber(unsignedInt: 1)
                ])
            let buffer = AVAudioPCMBuffer(PCMFormat: format,
                frameCapacity:AVAudioFrameCount(self.parser.frameCount))
            buffer.frameLength = AVAudioFrameCount(self.parser.frameCount)

            self.parser.render(buffer)

            try file.writeFromBuffer(buffer)
        }
        catch let error as NSError {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    func parse() -> Bool {
        let command = textField?.stringValue
        if ((command != nil && command?.lengthOfBytesUsingEncoding(NSASCIIStringEncoding) > 0)) {
            return parser.parse(command!)
        }

        return false
    }

    @IBAction func play(sender:NSObject?) {
        if (parse()) {
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


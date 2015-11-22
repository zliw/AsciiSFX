//
//  ViewController.swift
//  AsciiSFX
//
//  Created by  Martin Wilz on 17/10/15.
//  Copyright © 2015  Martin Wilz. All rights reserved.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController {
    @IBOutlet var textField:NSTextField?
    @IBOutlet var playButton:NSButton?
    let parser = Parser()

    let engine = AVAudioEngine()
    let player:AVAudioPlayerNode = AVAudioPlayerNode()

    override func viewDidLoad() {
        super.viewDidLoad()

        let mixer = engine.mainMixerNode
        engine.attachNode(player)

        if mixer.outputFormatForBus(0).channelCount == 2 {
            engine.connect(player, to:mixer, format:mixer.outputFormatForBus(0))
            do {
                try engine.start()
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        else {
            print("2 channel output required - aborting")
        }
    }

    @IBAction func save(sender:NSObject?) {
        let operations = parse()

        if (operations.count == 0) {
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
            let frames = AVAudioFrameCount(UInt64(operations[0].length) * UInt64(SampleRate) / 1000)
            let buffer = AVAudioPCMBuffer(PCMFormat: format, frameCapacity:frames)
            buffer.frameLength = frames

            for operation in operations {
                operation.render(buffer)
            }

            try file.writeFromBuffer(buffer)
        }
        catch let error as NSError {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    func parse() -> Array<BufferOperation> {
        let command = textField?.stringValue

        if ((command != nil && command?.lengthOfBytesUsingEncoding(NSASCIIStringEncoding) > 0)) {
            return parser.parse(command!)
        }

        return Array<BufferOperation>()
    }

    @IBAction func play(sender:NSObject?) {

        let operations = parse()
        if (operations.count > 0) {
            self.playButton?.enabled = false

            let queue = NSOperationQueue()

            queue.addOperationWithBlock({
                print("rendering")

                let frames = AVAudioFrameCount(UInt64(operations[0].length) * UInt64(SampleRate) / 1000)
                let buffer = AVAudioPCMBuffer(PCMFormat: self.player.outputFormatForBus(0), frameCapacity:frames)
                buffer.frameLength = frames

                for operation in operations {
                    operation.render(buffer)
                }

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


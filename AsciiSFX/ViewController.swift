//
//  ViewController.swift
//  AsciiSFX
//
//  Created by martin on 17/10/15.
//  Copyright © 2015 martin. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var textField:NSTextField?
    @IBOutlet var playButton:NSButton?

    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

    @IBAction func play(sender:NSObject?) {
        playButton?.enabled = false
        
    }
}


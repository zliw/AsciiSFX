//
//  CommandParser.swift
//  AsciiSFX
//
//  Created by martin on 17/10/15.
//  Copyright © 2015 martin. All rights reserved.
//

import Foundation

class CommandParser {
    func parseInteger(chars:Array<Character>) -> (Int64, Int) {
        var index = 0
        var value:Int64 = 0
        while (index < chars.count) {
            let c:Int64? = Int64(String(chars[index]))
            if (c == nil) {
                return (value, index)
            }
            value = value * 10 + c!
            index++
        }
        return (value, index)
    }

    func parse(command:String) -> Bool {
        print(command)
        let chars = Array(command.characters)
        var index = 0

        while (index < chars.count) {
            let c = chars[index++]

            switch c {
                case "s":
                    if (index >= chars.count) {
                        return false
                    }

                    let end = (index + 5 < chars.count) ? index + 5 : chars.count
                    print (index, chars.count, end)
                    let (value, length) = parseInteger(Array(chars[index ..< end]))
                    print(value)

                    index += length
                    continue
                default:
                    return false
            }
        }

        return true
    }
}
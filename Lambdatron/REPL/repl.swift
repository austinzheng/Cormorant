//
//  repl.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/25/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

class replInstance {
  let descriptor : NSFileHandle
  internal var replContext = Context.globalContextInstance()

  init(descriptor: NSFileHandle) {
    self.descriptor = descriptor
  }

  func run() -> Bool {
    println("Started Lambdatron. Type '?quit' to exit, '?help' for help...")
    while true {
      print("> ")
      fflush(__stdoutp)
      // Read data from user
      // TODO: Strange characters are due to pressing keys like 'up' and 'down' in the input window.
      // TODO: replace this with libedit (see http://stackoverflow.com/questions/24004776/input-from-the-keyboard-in-command-line-application )
      let rawData = descriptor.availableData
      let optionalData : NSString? = NSString(data: rawData, encoding: NSUTF8StringEncoding)
      if let data = optionalData {
        if (data.length == 0
          || data.characterAtIndex(data.length-1) != UInt16(UnicodeScalar("\n").value)) {
            // Something wrong with the input
            return false
        }
        // Remove the trailing newline
        let trimmedData = data.substringToIndex(data.length-1)
        if let (command, args) = SpecialCommand.instanceWith(trimmedData) {
          let shouldReturn = command.execute(args, ctx: &replContext)
          if shouldReturn {
            return true
          }
        }
        else {
          let x = lex(trimmedData)
          switch x {
          case let .Success(lexedData):
//        println("Your entry lexes to: \(lexedData)")
            let c = parse(lexedData)
            if let actualC = c {
//          println("Your entry parses to: \(actualC)")
              let n = actualC.evaluate(replContext, .Normal)
              println(n.description)
            }
            else {
              println("Your entry didn't parse correctly")
            }
          case let .Failure(error): println("Your entry didn't lex correctly (error: \(error.description))")
          }
        }
      }
    }
  }
}


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
    // from http://stackoverflow.com/questions/24004776/input-from-the-keyboard-in-command-line-application
    // TODO use capabilities of EditLine
    let prompt: LineReader = LineReader(argv0: C_ARGV[0])
    
    while true {
      //print("> ")
      let rawData = prompt.gets()
      let optionalData : NSString? = NSString(CString: rawData, encoding: NSUTF8StringEncoding)
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
//            println("Your entry lexes to: \(lexedData)")
            let parsed = parse(lexedData, replContext)
            switch parsed {
            case let .Success(parsed):
//              println("Your entry parses to: \(parsed)")
              let re = parsed.readerExpand()
//              println("Your entry reader-expands to: \(re.description)")
              let n = re.evaluate(replContext, .Normal)
              switch n {
              case let .Success(n): println(n.describe(replContext))
              case let .Failure(f): println("Evaluation error \(f)")
              }
            case let .Failure(error):
              println("Parsing error \(error)")
            }
          case let .Failure(error): println("Lexing error \(error)")
          }
        }
      }
    }
  }
}


//
//  repl.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/25/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

class ReadEvaluatePrintLoop {
  let descriptor : NSFileHandle
  let interpreter = Interpreter()
  let logger = LoggingManager()

  init(descriptor: NSFileHandle) {
    self.descriptor = descriptor
  }

  func run() -> Bool {
    println("Started Lambdatron. Type '?quit' to exit, '?help' for help...")
    interpreter.setLoggingFunction(.Eval, function: logger.logEval)

    // from http://stackoverflow.com/questions/24004776/input-from-the-keyboard-in-command-line-application
    // TODO use capabilities of EditLine
    let prompt: LineReader = LineReader(argv0: C_ARGV[0])

    func getString() -> String {
      return prompt.gets() ?? ""
    }
    interpreter.readInput = getString

    while true {
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
          // REPL special command
          let shouldReturn = command.execute(args, logger: logger, repl: self)
          if shouldReturn {
            return true
          }
        }
        else {
          // Language form
          let result = interpreter.evaluate(trimmedData)
          switch result {
          case let .Success(v): println(interpreter.describe(v))
          case let .LexFailure(f): println("Lexing error \(f)")
          case let .ParseFailure(f): println("Parsing error \(f)")
          case let .ReaderFailure(f): println("Reader expansion error \(f)")
          case let .EvalFailure(f): println("Evaluation error \(f)")
          }
        }
      }
    }
  }
}

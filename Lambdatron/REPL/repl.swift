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
    let prompt: LineReader = LineReader(argv0: Process.unsafeArgv[0])

    func getString() -> String {
      return prompt.gets() ?? ""
    }
    interpreter.readInput = getString

    while true {
      let data = prompt.gets()
      if let string = String(CString: data, encoding: NSUTF8StringEncoding) {
        if string.isEmpty || string[string.endIndex.predecessor()] != "\n" {
            // Something wrong with the input
            return false
        }
        // Remove the trailing newline
        let trimmed = string[string.startIndex..<string.endIndex.predecessor()]
        if let (command, args) = SpecialCommand.instanceWith(trimmed) {
          // REPL special command
          let shouldReturn = command.execute(args, logger: logger, repl: self)
          if shouldReturn {
            return true
          }
        }
        else {
          // Language form
          let result = interpreter.evaluate(trimmed)
          switch result {
          case let .Success(v):
            switch interpreter.describe(v) {
            case let .Desc(d): println(d)
            case let .Error(err): println("Read error \(err)")
            }
          case let .ReadFailure(f): println("Read error \(f)")
          case let .EvalFailure(f): println("Evaluation error \(f)")
          }
        }
      }
    }
  }
}

//
//  repl.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/25/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation
import Lambdatron

class ReadEvaluatePrintLoop {
  let interpreter = Interpreter()
  let logger = LoggingManager()
  let processName : String

  func run() -> Bool {
    print("Started Lambdatron. Type '?quit' to exit, '?help' for help...")
    interpreter.setLoggingFunction(domain: .Eval, function: logger.logEval)

    // from http://stackoverflow.com/questions/24004776/input-from-the-keyboard-in-command-line-application
    // TODO use capabilities of EditLine
//    let prompt: LineReader = LineReader(argv0: Process.unsafeArgv[0])
    let prompt: LineReader = LineReader(argv0: (processName as NSString).utf8String!)

    func getString() -> String {
      return prompt.gets() ?? ""
    }
    interpreter.readInput = getString

    while true {
      // Each iteration of this loop represents one REPL loop
      // Update the prompt
      let nsName = interpreter.currentNamespaceName!
      prompt.setPrompt("\(nsName)-> ")

      if let data = prompt.gets() {
        let string = data // String(CString: data, encoding: String.Encoding.utf8)
        if string.isEmpty || string[string.index(before: string.endIndex)] != "\n" {
            // Something wrong with the input
            return false
        }
        // Remove the trailing newline
        let trimmed = string[string.startIndex..<string.index(before: string.endIndex)]
        if let (command, args) = SpecialCommand.instanceWith(input: trimmed) {
          // REPL special command
          let shouldReturn = command.execute(args: args, logger: logger, repl: self)
          if shouldReturn {
            return true
          }
        }
        else {
          // Language form
          let result = interpreter.evaluate(form: trimmed)
          switch result {
          case let .Success(v):
            switch interpreter.describe(form: v) {
            case let .Just(d): print(d)
            case let .Error(err): print("Read error \(err)")
            }
          case let .ReadFailure(f): print("Read error \(f)")
          case let .EvalFailure(f): print("Evaluation error \(f)")
          }
        }
      }
    }
  }

  init(processName: String) {
    self.processName = processName
  }
}

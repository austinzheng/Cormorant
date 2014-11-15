//
//  main.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

// Input
private let descriptor = NSFileHandle.fileHandleWithStandardInput()

// This is the global context
private var globalContext = Context.globalContextInstance()

private enum SpecialCommand : String {
  case Quit = "?quit"
  case Reset = "?reset"
  case Help = "?help"
  
  var allCommands : [SpecialCommand] {
    return [.Quit, .Reset, .Help]
  }
  
  func execute() {
    switch self {
    case .Quit:
      println("Goodbye")
      exit(EXIT_SUCCESS)
    case .Reset:
      println("Environment reset")
      globalContext = Context.globalContextInstance()
    case .Help:
      println("LAMBDATRON REPL HELP:\nEnter Lisp expressions at the prompt and press 'Enter' to evaluate them.")
      println("Special commands are:")
      for command in allCommands {
        println("  \(command.rawValue): \(command.helpText)")
      }
    }
  }
  
  var helpText : String {
    switch self {
    case .Quit: return "Quits the REPL."
    case .Reset: return "Resets the environment, clearing anything defined using 'def', 'defn', etc."
    case .Help: return "Prints a brief description of the REPL."
    }
  }
}

println("Started Lambdatron. Type '?quit' to exit, '?help' for help...")
while true {
  print("> ")
  // Read data from user
  // TODO: Strange characters are due to pressing keys like 'up' and 'down' in the input window.
  let rawData = descriptor.availableData
  let optionalData : NSString? = NSString(data: rawData, encoding: NSUTF8StringEncoding)
  if let data = optionalData {
    if (data.length == 0
      || data.characterAtIndex(data.length-1) != UInt16(UnicodeScalar("\n").value)) {
        // Something wrong with the input
        exit(EXIT_FAILURE)
    }
    // Remove the trailing newline
    let trimmedData = data.substringToIndex(data.length-1)
    if let command = SpecialCommand(rawValue: trimmedData) {
      command.execute()
    }
    else {
      let x = lex(trimmedData)
      if let actualX = x {
//        println("Your entry lexes to: \(actualX)")
        let c = parse(actualX)
        if let actualC = c {
//          println("Your entry parses to: \(actualC)")
          let n = actualC.evaluate(globalContext)
          println(n.description)
        }
        else {
          println("Your entry didn't parse correctly")
        }
      }
      else {
        println("Your entry didn't lex correctly")
      }
    }
  }
}

// Force the program to exit if something is wrong
@noreturn func fatal(message: String) {
  println("Fatal error: \(message)")
  exit(EXIT_FAILURE)
}

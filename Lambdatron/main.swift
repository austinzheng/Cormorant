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
// TODO: This needs to not be a global variable
internal var globalContext = Context.globalContextInstance()

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
    if let (command, args) = SpecialCommand.instanceWith(trimmedData) {
      command.execute(args)
    }
    else {
      let x = lex(trimmedData)
      switch x {
      case let .Success(lexedData):
//        println("Your entry lexes to: \(lexedData)")
        let c = parse(lexedData)
        if let actualC = c {
//          println("Your entry parses to: \(actualC)")
          let n = actualC.evaluate(globalContext, .Normal)
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

// Force the program to exit if something is wrong
@noreturn func fatal(message: String) {
  println("Fatal error: \(message)")
  exit(EXIT_FAILURE)
}

@noreturn func internalError(message: @autoclosure () -> String) {
  println("Internal error: \(message())")
  exit(EXIT_FAILURE)
}

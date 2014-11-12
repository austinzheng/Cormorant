//
//  main.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

println("Started Lambdatron. Type ':quit' to exit...")

// Input
let descriptor = NSFileHandle.fileHandleWithStandardInput()

// NOTE: this must be removed in a later iteration.
var TEMPORARY_globalContext = Context()

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
    if trimmedData == ":quit" {
      println("Goodbye")
      exit(EXIT_SUCCESS)
    }
    else {
//      println("You typed '\(trimmedData)'\n")
      // TEST: exercise the lexer
      let x = lex(trimmedData)
      if let actualX = x {
//        println("Your entry lexes to: \(actualX)")
        let c = parse(actualX)
        if let actualC = c {
//          println("Your entry parses to: \(actualC)")
          let (n, _) = actualC.evaluate()
          println("\(n)\n")
//          let expanded = c?.macroexpand()
//          if let actualExpanded = expanded {
//            let finalCons = Cons(actualExpanded)
//            println("Your entry macroexpands to \(finalCons)")
//          }
        }
        else {
          println("Your entry didn't parse correctly")
        }
      }
      else {
        println("ERROR: lexing failed")
      }
    }
  }
}

// Force the program to exit if something is wrong
@noreturn func fatal(message: String) {
  println("Fatal error: \(message)")
  exit(EXIT_FAILURE)
}

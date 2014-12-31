//
//  util.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/30/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

@noreturn func fatal(message: String) {
  println("Assertion: \(message)")
  exit(EXIT_FAILURE)
}

/// Force the program to exit if something is wrong. This function is intended only to represent bugs in the Lambdatron
/// interpreter and should never be invoked at runtime; if it is invoked there is a bug in the interpreter code.
@noreturn func internalError(message: @autoclosure () -> String) {
  println("Internal error: \(message())")
  exit(EXIT_FAILURE)
}

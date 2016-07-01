//
//  main.swift
//  Cormorant
//
//  Created by Austin Zheng on 6/30/16.
//  Copyright © 2016 Austin Zheng. All rights reserved.
//

import Cocoa
import CormorantREPL

func main() {
  // Application entry point
  let args = Process.arguments

  let argsSet = Set(args)
  if argsSet.contains("-c") {
    // Run the REPL from the command line
    CormorantREPL.runREPL(withArguments: args)
    exit(EXIT_SUCCESS)
  }

  _ = NSApplicationMain(Process.argc, Process.unsafeArgv)
}

main()

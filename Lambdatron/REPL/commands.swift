//
//  commands.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/22/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

internal enum SpecialCommand : String {
  case Quit = "?quit"
  case Reset = "?reset"
  case Help = "?help"
  case RunTests = "?runtests"
  case Logging = "?logging"

  var allCommands : [SpecialCommand] {
    return [.Quit, .Reset, .Help, .RunTests, .Logging]
  }

  static func instanceWith(input: String) -> (SpecialCommand, [String])? {
    let wsSet = NSCharacterSet.whitespaceCharacterSet()
    var items : [String] = input.componentsSeparatedByCharactersInSet(wsSet)
    if items.count > 0 {
      if let selfInstance = SpecialCommand(rawValue: items[0]) {
        items.removeAtIndex(0)
        return (selfInstance, items)
      }
    }
    return nil
  }

  func execute(args: [String], inout ctx: Context) -> Bool {
    switch self {
    case .Quit:
      println("Goodbye")
      return true
    case .Reset:
      println("Environment reset")
      ctx = Context.globalContextInstance()
    case .Help:
      println("LAMBDATRON REPL HELP:\nEnter Lisp expressions at the prompt and press 'Enter' to evaluate them.")
      println("Special commands are:")
      for command in allCommands {
        println("  \(command.rawValue): \(command.helpText)")
      }
    case .RunTests:
      // Run unit tests
      println("Running unit tests...")
      let results = runTests(readerExpandTests())
      println("RESULTS: \(results.pass) passed, \(results.fail) failed (\(results.total) total)")
      if results.total == 0 {
        println("Unit test error (no tests?)")
      }
      else {
        println(results.fail > 0  ? "Unit tests failed" : "Unit tests passed")
      }
    case .Logging:
      if args.count == 1 {
        // Global turning logging on or off
        processOnOff(args[0],
          { println("Turning all logging on")
            LoggingManager.sharedInstance.setAllLogging(true) },
          { println("Turning all logging off")
            LoggingManager.sharedInstance.setAllLogging(false) },
          { println("Error: specify either 'on' or 'off', or a domain and 'on' or 'off'.") })
      }
      else if args.count > 1 {
        // Turning logging on or off for a specific domain
        if let domain = LoggingDomain(rawValue: args[0]) {
          processOnOff(args[1],
            { println("Turning logging for domain '\(args[0])' on");
              LoggingManager.sharedInstance.setLoggingForDomain(domain, enabled: true) },
            { println("Turning logging for domain '\(args[0])' off")
              LoggingManager.sharedInstance.setLoggingForDomain(domain, enabled: false) },
            { println("Error: specify either 'on' or 'off'.") })
          return false
        }
        else {
          println("Error: unrecognized logging domain '\(args[0])'.")
        }
      }
      else {
        println("Error: cannot call '\(self.rawValue)' without at least one argument.")
      }
    }
    return false
  }

  var helpText : String {
    switch self {
    case .Quit: return "Quits the REPL."
    case .Reset: return "Resets the environment, clearing anything defined using 'def', 'defmacro', etc."
    case .Help: return "Prints a brief description of the REPL."
    case .RunTests: return "Run the built-in unit test suite for Lambdatron."
    case .Logging: return "Turns logging for a given domain on or off. Call with <domain> and either 'on' or 'off'."
    }
  }
}

private func processOnOff(arg: String, on: () -> (), off: () -> (), error: (() -> ())?) {
  switch arg.lowercaseString {
  case "on", "true", "1":
    on()
  case "off", "false", "0":
    off()
  default:
    if let actualError = error {
      actualError()
    }
  }
}

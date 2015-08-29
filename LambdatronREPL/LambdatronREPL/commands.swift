//
//  commands.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/22/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation
import Lambdatron

extension ReadEvaluatePrintLoop {

  /// Given an input string representing some code and a number of iterations, run a benchmark and print the results
  /// out for the user to see.
  func benchmark(form: String, iterations: Int) {
    if iterations < 1 {
      print("Error: benchmark must run at least once.")
      return
    }
    if let form = interpreter.readIntoForm(form) {
      var buffer : [NSTimeInterval] = []
      print("Benchmarking...")
      for _ in 0..<iterations {
        let start = NSDate.timeIntervalSinceReferenceDate()

        let result = interpreter.evaluate(form)
        switch result {
        case .Success: break
        default:
          print("Error: benchmark form failed to execute correctly. Ending benchmark.")
          return
        }

        let end = NSDate.timeIntervalSinceReferenceDate()
        let delta = end - start
        buffer.append(delta)
      }
      // Calculate the statistics
      let min = buffer.minElement() ?? 0 * 1000
      let max = buffer.maxElement() ?? 0 * 1000
      let average = 1000 * buffer.reduce(0, combine: +) / Double(iterations)
      print("Benchmark complete (\(iterations) iterations).")
      print("Average time: \(average) ms")
      print("Maximum time: \(max) ms")
      print("Minimum time: \(min) ms")
    }
    else {
      print("Error: unable to parse benchmark input form \"\(form)\".")
    }
  }
}

internal enum SpecialCommand : String {
  case Quit = "?quit"
  case Reset = "?reset"
  case Help = "?help"
  case Logging = "?logging"
  case Benchmark = "?benchmark"

  var allCommands : [SpecialCommand] {
    return [.Quit, .Reset, .Help, .Logging, .Benchmark]
  }

  static func instanceWith(input: String) -> (SpecialCommand, [String])? {
    let wsSet = NSCharacterSet.whitespaceCharacterSet()
    var items : [String] = input.componentsSeparatedByCharactersInSet(wsSet)
    if items.count > 0, let selfInstance = SpecialCommand(rawValue: items[0]) {
      items.removeAtIndex(0)
      return (selfInstance, items)
    }
    return nil
  }

  func execute(args: [String], logger: LoggingManager, repl: ReadEvaluatePrintLoop) -> Bool {
    switch self {
    case .Quit:
      print("Goodbye")
      return true
    case .Reset:
      print("Environment reset")
      repl.interpreter.reset()
    case .Help:
      print("LAMBDATRON REPL HELP:\nEnter Lisp expressions at the prompt and press 'Enter' to evaluate them.")
      print("Special commands are:")
      for command in allCommands {
        print("  \(command.rawValue): \(command.helpText)")
      }
    case .Logging:
      if args.count == 1 {
        // Global turning logging on or off
        processOnOff(args[0],
          on: {
            print("Turning all logging on")
            logger.setAllLogging(true)
          },
          off: {
            print("Turning all logging off")
            logger.setAllLogging(false)
          },
          error: {
            print("Error: specify either 'on' or 'off', or a domain and 'on' or 'off'.")
        })
      }
      else if args.count > 1 {
        // Turning logging on or off for a specific domain
        if let domain = LogDomain(rawValue: args[0]) {
          processOnOff(args[1],
            on: {
              print("Turning logging for domain '\(args[0])' on")
              logger.setLoggingForDomain(domain, enabled: true)
            },
            off: {
              print("Turning logging for domain '\(args[0])' off")
              logger.setLoggingForDomain(domain, enabled: false)
            },
            error: {
              print("Error: specify either 'on' or 'off'.")
          })
          return false
        }
        else {
          print("Error: unrecognized logging domain '\(args[0])'.")
        }
      }
      else {
        print("Error: cannot call '\(self.rawValue)' without at least one argument.")
      }
    case .Benchmark:
      if args.count < 2 {
        print("Error: benchmark must be called with a valid form and a number of iterations.")
        break
      }
      // Extract the count (last element)
      let count = args.last!
      let nf = NSNumberFormatter()
      nf.numberStyle = NSNumberFormatterStyle.NoStyle
      if let number = nf.numberFromString(count) {
        // The last argument is a count.
        let form = args[0..<args.count - 1].joinWithSeparator(" ")
        repl.benchmark(form, iterations: number.integerValue)
      }
      else {
        print("Error: benchmark must be called with a valid form and a number of iterations.")
        break
      }
    }
    return false
  }

  var helpText : String {
    switch self {
    case .Quit: return "Quits the REPL."
    case .Reset: return "Resets the environment, clearing anything defined using 'def', 'defmacro', etc."
    case .Help: return "Prints a brief description of the REPL."
    case .Logging: return "Turns logging for a given domain on or off. Call with <domain> and either 'on' or 'off'."
    case .Benchmark: return "Runs a benchmark. Enter a form to run and the number of times to run it."
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

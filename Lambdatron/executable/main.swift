//
//  main.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

private func fileDataForRawPath(p: String) -> String? {
  let fileURL = NSURL(fileURLWithPath: p.stringByExpandingTildeInPath)
  if let fileURL = fileURL {
    return NSString(contentsOfURL: fileURL, encoding: NSUTF8StringEncoding, error: nil)
  }
  return nil
}

private enum DoFormFileDataResult {
  case Success([ConsValue])
  case NoDataFailure
  case ParseFailure(ParseError)
  case ReaderExpandFailure(ReaderError)
}

private func doFormForFileData(d: String, ctx: Context) -> DoFormFileDataResult {
  if let segments = segmentsForFile(d) {
    var buffer : [ConsValue] = []
    for segment in segments {
      switch parse(segment, ctx) {
      case let .Success(parsedData):
        let expanded = parsedData.readerExpand()
        switch expanded {
        case let .Success(expanded): buffer.append(expanded)
        case let .Failure(f): return .ReaderExpandFailure(f)
        }
      case let .Failure(f): return .ParseFailure(f)
      }
    }
    return .Success(buffer)
  }
  return .NoDataFailure
}

// MARK: Entry point

func main() {
  // Retrieve command-line arguments
  let args = Process.arguments
  
  if args.count == 1 {
    // Run the REPL
    let handle = NSFileHandle.fileHandleWithStandardInput()
    let repl = replInstance(descriptor: handle)
    let result = repl.run()
    exit(result ? EXIT_SUCCESS : EXIT_FAILURE)
  }
  else if args.count == 3 && args[1] == "-f" {
    // Execute a file
    let fileName = args[2]
    if let fileInput = fileDataForRawPath(fileName) {
      let i = Interpreter()
      switch doFormForFileData(fileInput, i.context) {
      case let .Success(forms):
        let result = sf_do(forms, i.context)
        switch result {
        case let .Success(s):
          println(s.isRecurSentinel ? "Evaluation error \(EvalError.RecurMisuseError)" : s.describe(i.context))
        case let .Failure(f):
          println("Evaluation error \(f)")
        }
      case .NoDataFailure:
        println("Couldn't read data from input file, or input file was empty")
      case let .ParseFailure(f):
        println("Parse error \(f)")
      case let .ReaderExpandFailure(f):
        println("Reader macro expansion error \(f)")
      }
    }

    // Have the user type something in to quit
    let handle = NSFileHandle.fileHandleWithStandardInput()
    println("Evaluation complete. Press enter to quit...")
    let rawData = handle.availableData
  }
  else {
    // Print help
    println("Lambdatron - the amazingly slow pseudo-Clojure interpreter")
    println("Invoke without arguments to start the REPL, or with '-f FILENAME' to run a file.")
    // Have the user type something in to quit
    let handle = NSFileHandle.fileHandleWithStandardInput()
    println("Press enter to quit...")
    let rawData = handle.availableData
  }
}
main()

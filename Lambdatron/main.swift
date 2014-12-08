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

private func doFormForFileData(d: String) -> [ConsValue]? {
  if let segments = segmentsForFile(d) {
    var buffer : [ConsValue] = []
    for segment in segments {
      if let parsedData = parse(segment) {
        buffer.append(parsedData.readerExpand())
      }
      else {
        return nil
      }
    }
    return buffer
  }
  return nil
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
      if let forms = doFormForFileData(fileInput) {
        let result = sf_do(forms, Context.globalContextInstance(), .Normal)
        switch result {
        case let .Success(s):
          println(s.description)
        case let .Failure(f):
          println("Evaluation error: \(f.description)")
        }
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


// MARK: Special functions

/// Force the program to exit if something is wrong. This function is intended only to represent bugs in the Lambdatron
/// interpreter.
@noreturn func fatal(message: String) {
  println("Assertion: \(message)")
  exit(EXIT_FAILURE)
}

@noreturn func internalError(message: @autoclosure () -> String) {
  println("Internal error: \(message())")
  exit(EXIT_FAILURE)
}

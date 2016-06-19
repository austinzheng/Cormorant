//
//  system.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation
import Lambdatron

private func fileDataForRawPath(p: String) -> String? {
  if let fileURL = NSURL(string: (p as NSString).expandingTildeInPath) {
    return String(contentsOfURL: fileURL, encoding: String.Encoding.utf8)
  }
  return nil
}

//private enum DoFormFileDataResult {
//  case Success(Params)
//  case NoDataFailure
//  case ReadFailure(ReadError)
//}
//
//private func doFormForFileData(d: String, ctx: Context) -> DoFormFileDataResult {
//  if let segments = segmentsForFile(d) {
//    var buffer = Params()
//    for segment in segments {
//      switch parse(segment, ctx) {
//      case let .Success(parsedData):
//        let expanded = parsedData.expand(ctx)
//        switch expanded {
//        case let .Success(expanded): buffer.append(expanded)
//        case let .Failure(f): return .ReadFailure(f)
//        }
//      case let .Failure(f): return .ReadFailure(f)
//      }
//    }
//    return .Success(buffer)
//  }
//  return .NoDataFailure
//}

// MARK: Entry point

public class REPLWrapper : NSObject {
  public class func run(withArguments args: [String]) {
    interpreterMain(args: args)
  }
}

func interpreterMain(args: [String]) {
  // Retrieve command-line arguments
//  let args = Process.arguments

  #if DEBUG
    println("Lambdatron REPL: framework was built using DEBUG mode")
  #endif

  if args.count == 3 && args[1] == "-f" {
    // Execute a file
    print("Not yet implemented")
//    let fileName = args[2]
//    // TODO: This sucks, redo it
//    if let fileInput = fileDataForRawPath(fileName) {
//      let i = Interpreter()
//      let ctx = i.currentNamespace
//      switch doFormForFileData(fileInput, ctx) {
//      case let .Success(forms):
//        let result = sf_do(forms, ctx)
//        switch result {
//        case let .Success(s):
//          switch s.describe(ctx) {
//          case let .Desc(d): println(d)
//          case let .Error(err): println("Evaluation error \(err)")
//          }
//        case .Recur:
//          let error = EvalError(.RecurMisuseError)
//          println("Evaluation error \(error)")
//        case let .Failure(f):
//          println("Evaluation error \(f)")
//        }
//      case .NoDataFailure:
//        println("Couldn't read data from input file, or input file was empty")
//      case let .ReadFailure(f):
//        println("Read error \(f)")
//      }
//    }
//
//    // Have the user type something in to quit
//    let handle = NSFileHandle.fileHandleWithStandardInput()
//    println("Evaluation complete. Press enter to quit...")
//    let rawData = handle.availableData
  }
  else if args.count > 1 && args[1] == "-h" {
    // Print help
    print("Lambdatron - the amazingly slow pseudo-Clojure interpreter")
    print("Invoke without arguments to start the REPL, or with '-f FILENAME' to run a file.")
    // Have the user type something in to quit
    let handle = FileHandle.standardInput()
    print("Press enter to quit...")
    // TODO: (az) wtf
    let _ = handle.availableData
  }
  else if args.count > 0 {
    // Run the REPL
    let repl = ReadEvaluatePrintLoop(processName: args[0])
    let result = repl.run()
    exit(result ? EXIT_SUCCESS : EXIT_FAILURE)
  }
  else {
    print("Warning! Something is wrong. No args passed.")
  }
}

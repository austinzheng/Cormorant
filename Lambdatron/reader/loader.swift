//
//  loader.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/18/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

let stdlib_files : [String] = ["builtin", "core", "higherorder", "sequences", "flow", "math"]

// TODO: rewrite this.
func loadStdlibInto(context: Context, files: [String]) {
  for file in files {
    if let data = stringDataForBundledFile(file) {
      // Data loaded from file as string
      if let segments = segmentsForFile(data) {
        for s in segments {
          switch parse(s, context) {
          case let .Just(parsedData):
            // Data parsed successfully
            let re = parsedData.expand(context)
            switch re {
            case let .Success(re):
              switch evaluateForm(re, context) {
              case .Success: break
              case .Recur:
                // Stdlib file failed to evaluate successfully
                print("Unable to load stdlib: recur failure")
                exit(EXIT_FAILURE)
              case let .Failure(f):
                // Stdlib file failed to evaluate successfully
                print("Unable to load stdlib: \(f)")
                exit(EXIT_FAILURE)
              }
            case let .Failure(f):
              print("Unable to load stdlib: \(f)")
              exit(EXIT_FAILURE)
            }
          case let .Error(f):
            // Data failed to parse
            print("Unable to load stdlib: \(f)")
            exit(EXIT_FAILURE)
          }
        }
      }
    }
    else {
      print("Error! Stdlib file \"\(file).lbt\" could not be loaded.")
    }
  }
}

func stringDataForBundledFile(name: String) -> String? {
  guard let path = NSBundle(forClass: Interpreter.self).pathForResource(name, ofType: "lbt") else {
    return nil
  }
  do {
    return try String(contentsOfFile: path)
  } catch {
    return nil
  }
}

/// Return a segmented list of token lists for a given file's data
func segmentsForFile(data: String) -> ([[LexToken]])? {
  let lexResult = lex(data)
  switch lexResult {
  case let .Just(lexedData):
    return segment(lexedData)
  case .Error: return nil
  }
}

/// Segment a list of tokens into one or more lists of tokens, each list representing an individual form
// TODO: handle maps
func segment(input: [LexToken]) -> [[LexToken]] {
  enum State {
    case SingleToken, List, Vector
  }
  var state : State = .SingleToken
  var count = 0
  var allSegments : [[LexToken]] = []
  var currentSegment : [LexToken] = []
  
  func flushCurrentSegment() {
    if currentSegment.count > 0 {
      allSegments.append(currentSegment)
      currentSegment = []
    }
  }
  
  for token in input {
    switch state {
    case .SingleToken:
      switch token {
      case _ where token.isA(.LeftParentheses):
        flushCurrentSegment()
        count = 1
        state = .List
      case _ where token.isA(.RightParentheses):
        flushCurrentSegment()
        count = 1
        state = .Vector
      default:
        break
      }
      currentSegment.append(token)
    case .List:
      switch token {
      case _ where token.isA(.LeftParentheses):
        count += 1
        currentSegment.append(token)
      case _ where token.isA(.RightParentheses):
        count -= 1
        currentSegment.append(token)
        if count == 0 {
          flushCurrentSegment()
          state = .SingleToken
        }
      default:
        currentSegment.append(token)
      }
    case .Vector:
      switch token {
      case _ where token.isA(.LeftSquareBracket):
        count += 1
        currentSegment.append(token)
      case _ where token.isA(.RightSquareBracket):
        count -= 1
        currentSegment.append(token)
        if count == 0 {
          flushCurrentSegment()
          state = .SingleToken
        }
      default:
        currentSegment.append(token)
      }
    }
  }
  return allSegments
}

//
//  Loader.swift
//  Cormorant
//
//  Created by Austin Zheng on 11/18/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

let stdlib_files : [String] = ["builtin", "core", "higherorder", "sequences", "flow", "math"]

// TODO: rewrite this.
func loadStdlibInto(context: Context, files: [String]) {
  for file in files {
    if let contents = stringData(forBundleFileNamed: file) {
      // Data loaded from file as string
      if let segments = segments(forFileContents: contents) {
        for s in segments {
          switch parse(tokens: s, context) {
          case let .Just(parsedData):
            // Data parsed successfully
            let re = context.expand(parsedData)
            switch re {
            case let .Success(re):
              switch context.evaluate(value: re) {
              case .Success: break
              case .Recur:
                // Stdlib file failed to evaluate successfully
                print("Unable to load stdlib file '\(file)': recur failure")
                exit(EXIT_FAILURE)
              case let .Failure(f):
                // Stdlib file failed to evaluate successfully
                print("Unable to load stdlib file '\(file)': \(f)")
                exit(EXIT_FAILURE)
              }
            case let .Failure(f):
              print("Unable to load stdlib file '\(file)': \(f)")
              exit(EXIT_FAILURE)
            }
          case let .Error(f):
            // Data failed to parse
            print("Unable to load stdlib file '\(file)': \(f)")
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

func stringData(forBundleFileNamed name: String) -> String? {
  guard let path = Bundle(for: Interpreter.self).pathForResource(name, ofType: "lbt") else {
    return nil
  }
  do {
    return try String(contentsOfFile: path)
  } catch {
    return nil
  }
}

/// Return a segmented list of token lists for a given file's data
func segments(forFileContents contents: String) -> ([[LexToken]])? {
  let lexResult = lex(contents)
  switch lexResult {
  case let .Just(lexedContents):
    return segment(input: lexedContents)
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
      case _ where token.isA(.leftParentheses):
        flushCurrentSegment()
        count = 1
        state = .List
      case _ where token.isA(.rightParentheses):
        flushCurrentSegment()
        count = 1
        state = .Vector
      default:
        break
      }
      currentSegment.append(token)
    case .List:
      switch token {
      case _ where token.isA(.leftParentheses):
        count += 1
        currentSegment.append(token)
      case _ where token.isA(.rightParentheses):
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
      case _ where token.isA(.leftSquareBracket):
        count += 1
        currentSegment.append(token)
      case _ where token.isA(.rightSquareBracket):
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

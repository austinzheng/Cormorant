//
//  loader.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/18/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

let stdlib_files = ["core", "builtin"]

func loadStdlibInto(context: Context, files: [String]) {
  for file in files {
    if let data = stringDataForBundledFile(file) {
      // Data loaded from file as string
      if let segments = segmentsForFile(data) {
        for s in segments {
          if let parsedData = parse(s) {
            // First, perform reader expansion
            let re = parsedData.readerExpand()
            re.evaluate(context, .Normal)
          }
        }
      }
    }
  }
}

func stringDataForBundledFile(name: String) -> String? {
  let path = NSBundle.mainBundle().pathForResource(name, ofType:"lbt")
  if let path = path {
    let contents = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)
    return contents
  }
  return nil
}

/// Return a segmented list of token lists for a given file's data
func segmentsForFile(data: String) -> ([[LexToken]])? {
  let lexResult = lex(data)
  switch lexResult {
  case let .Success(lexedData):
    return segment(lexedData)
  case .Failure: return nil
  }
}

/// Segment a list of tokens into one or more lists of tokens, each list representing an individual form
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
      case .LeftParentheses:
        flushCurrentSegment()
        count = 1
        state = .List
      case .LeftSquareBracket:
        flushCurrentSegment()
        count = 1
        state = .Vector
      default:
        break
      }
      currentSegment.append(token)
    case .List:
      switch token {
      case .LeftParentheses:
        count += 1
        currentSegment.append(token)
      case .RightParentheses:
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
      case .LeftSquareBracket:
        count += 1
        currentSegment.append(token)
      case .RightSquareBracket:
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

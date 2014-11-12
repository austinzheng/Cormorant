//
//  parser.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

// TODO: Replace with an *actual* lexer/parser.

enum TokenCollectionType {
  case List, Vector
}

/// Collect a sequence of tokens representing a single collection type form (e.g. a single list).
func collectTokens(tokens: [LexToken], inout counter: Int, type: TokenCollectionType) -> [LexToken]? {
  // Check validity of first token
  switch tokens[counter] {
  case .LeftParentheses where type == .List: break
  case .LeftSquareBracket where type == .Vector: break
  default: fatal("test1: token was \(tokens[counter]), type was \(type)") //return nil
  }
  var count = 1
  var buffer : [LexToken] = []
  // Collect tokens
  for var i=counter+1; i<tokens.count; i++ {
    counter = i
    var currentToken = tokens[i]
    switch currentToken {
    case .LeftParentheses where type == .List:
      count++
      buffer.append(currentToken)
    case .RightParentheses where type == .List:
      count--
      if count > 0 {
        buffer.append(currentToken)
      }
    case .LeftSquareBracket where type == .Vector:
      count++
      buffer.append(currentToken)
    case .RightSquareBracket where type == .Vector:
      count--
      if count > 0 {
        buffer.append(currentToken)
      }
    default:
      buffer.append(currentToken)
    }
    if count == 0 {
      break
    }
  }
  return count == 0 ? buffer : nil
}

/// Take a list of LexTokens and return a list of ConsValues which can be transformed into a list, a vector, or another
/// collection type. This method recursively finds token sequences representing collections and calls the appropriate
/// constructor to build a valid ConsValue for that form
func processTokenList(tokens: [LexToken]) -> [ConsValue]? {
  // Create a new ConsValue array with all sub-structures properly processed
  var buffer : [ConsValue] = []
  var counter = 0
  while counter < tokens.count {
    let currentToken = tokens[counter]
    switch currentToken {
    case .LeftParentheses:
      if let newList = listWithTokens(collectTokens(tokens, &counter, .List)) {
        buffer.append(.ListLiteral(newList))
      }
      else {
        return nil
      }
    case .RightParentheses:
      return nil
    case .LeftSquareBracket:
      if let newVector = vectorWithTokens(collectTokens(tokens, &counter, .Vector)) {
        buffer.append(.VectorLiteral(newVector))
      }
      else {
        return nil
      }
    case .RightSquareBracket:
      return nil
    case .NilLiteral:
      buffer.append(.NilLiteral)
    case let .StringLiteral(s):
      buffer.append(.StringLiteral(s))
    case let .Number(n):
      buffer.append(.NumberLiteral(n))
    case let .Boolean(b):
      buffer.append(.BoolLiteral(b))
    case let .Keyword(k):
      fatal("Not supported yet")
    case let .Identifier(r):
      buffer.append(.Symbol(r))
    case let .Special(s):
      buffer.append(.Special(s))
    }
    counter++
  }
  return buffer
}

func listWithTokens(tokens: [LexToken]?) -> Cons? {
  if let tokens = tokens {
    if tokens.count == 0 {
      // Empty list: ()
      return Cons()
    }
    if let processedForms = processTokenList(tokens) {
      // Create the list itself
      let first = Cons(processedForms[0])
      var prev = first
      for var i=1; i<processedForms.count; i++ {
        let this = Cons(processedForms[i])
        prev.next = this
        prev = this
      }
      return first
    }
    return nil
  }
  return nil
}

func vectorWithTokens(tokens: [LexToken]?) -> [ConsValue]? {
  if let tokens = tokens {
    if tokens.count == 0 {
      // Empty vector: []
      return []
    }
    if let processedForms = processTokenList(tokens) {
      // Create the vector itself
      return processedForms
    }
    return nil
  }
  return nil
}

func parse(tokens: [LexToken]) -> ConsValue? {
  var index = 0
  // Figure out how to parse
  switch tokens[0] {
  case .LeftParentheses where tokens.count > 1:
    if let result = listWithTokens(collectTokens(tokens, &index, .List)) {
      return .ListLiteral(result)
    }
    return nil
  case .RightParentheses: return nil
  case .LeftSquareBracket where tokens.count > 1:
    if let result = vectorWithTokens(collectTokens(tokens, &index, .Vector)) {
      return .VectorLiteral(result)
    }
    return nil
  case .RightSquareBracket: return nil
  case _ where tokens.count > 1: return nil
  case .NilLiteral: return .NilLiteral
  case let .StringLiteral(s): return .StringLiteral(s)
  case let .Number(n): return .NumberLiteral(n)
  case let .Boolean(b): return .BoolLiteral(b)
  case let .Keyword(k):
    fatal("Not supported yet")
  case let .Identifier(r): return .Symbol(r)
  case let .Special(s): return .Special(s)
  default: fatal("Internal error")
  }
}

//
//  parser.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

// TODO: Replace with an *actual* lexer/parser.

// Take a raw string and parse it into an AST
func parse(raw: String) -> Cons? {
  // TODO: Implement this
  return nil
}

/// Tokens that come out of the lex() function
enum LexToken : Printable {
  case LeftP
  case RightP
  case NilLiteral
  case StringLiteral(String)
  case Number(Double)
  case Boolean(Bool)
  case Keyword(String)
  case Identifier(String)

  var description : String {
    get {
      switch self {
      case .LeftP: return "LeftP <(>"
      case .RightP: return "RightP <)>"
      case let .StringLiteral(x): return "String \"\(x)\""
      case let .NilLiteral: return "Nil"
      case let .Number(x): return "Number <\(x)>"
      case let .Boolean(x): return "Boolean <\(x)>"
      case let .Keyword(x): return "Keyword \(x)"
      case let .Identifier(x): return "Identifier <\(x)>"
      }
    }
  }
}

func lex(raw: String) -> [LexToken]? {
  enum RawLexToken {
    case LeftP
    case RightP
    case StringLiteral(String)
    case Unknown(String)
  }

  let wsSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

  // PHASE 1: raw lex
  var rawTokenBuffer : [RawLexToken] = []

  // currentToken can only contain either a StringLiteral or an Unknown token
  var currentToken : NSMutableString = ""

  /// Helper function - flush the current-in-progress token to the token buffer
  func flushTokenToBuffer() {
    if currentToken.length > 0 {
      rawTokenBuffer.append(.Unknown(currentToken))
    }
    currentToken = ""
  }

  // TODO: Support control sequences.
//  var controlSequenceActive = false
  // Whether or not the user is currently in a string
  var stringActive = false
  for char in raw {
    // Horrible, horrible hacks to turn a Character into a unichar
    var tChar = NSString(string: String(char)).characterAtIndex(0)

    if stringActive {
      // User currently in the context of a string
      if char == "\"" {
        // User ended the string with a closing "
        rawTokenBuffer.append(.StringLiteral(currentToken))
        currentToken = ""
        stringActive = false
      }
      else {
        // Any other token gets added to the buffer as a literal
        currentToken.appendString(String(char))
      }
    }
    else {
      // User currently NOT in the context of a string
      if char == "\"" {
        // User starting a string with an opening "
        flushTokenToBuffer()
        stringActive = true
      }
      else if char == "(" {
        // Left parentheses
        flushTokenToBuffer()
        rawTokenBuffer.append(.LeftP)
      }
      else if char == ")" {
        // Right parentheses
        flushTokenToBuffer()
        rawTokenBuffer.append(.RightP)
      }
      else if wsSet.characterIsMember(tChar) {
        // Whitespace/newline
        flushTokenToBuffer()
      }
      else {
        // Any other valid character
        currentToken.appendString(String(char))
      }
    }
  }

  if stringActive {
    // This is bad; a string was left dangling
    return nil
  }
  // If there's another token left, flush it
  flushTokenToBuffer()

  // PHASE 2: identify 'unknowns'
  var tokenBuffer : [LexToken] = []
  for rawToken in rawTokenBuffer {
    switch rawToken {
    case .LeftP: tokenBuffer.append(.LeftP)
    case .RightP: tokenBuffer.append(.RightP)
    case let .StringLiteral(sl): tokenBuffer.append(.StringLiteral(sl))
    case let .Unknown(u):
      // Possible type inference bug? Without the String() constructor it fails, even though 'u' is already a string
      let tValue = NSString(string: String(u))
      // Figure out what to do with the token
      if tValue.characterAtIndex(0) == UInt16(UnicodeScalar(":").value) && tValue.length > 1 {
        // This is a keyword (starts with ":" and has at least one other character)
        tokenBuffer.append(.Keyword(u))
      }
      else if tValue == "false" {
        // Literal bool
        tokenBuffer.append(.Boolean(false))
      }
      else if tValue == "true" {
        // Literal bool
        tokenBuffer.append(.Boolean(true))
      }
      else if let numberToken = buildNumberFromString(u) {
        // Literal number
        tokenBuffer.append(numberToken)
      }
      else {
        // Identifier
        tokenBuffer.append(.Identifier(u))
      }
    }
  }

  return tokenBuffer
}

func buildNumberFromString(str: String) -> LexToken? {
  // The classic 'isNumber()' function.
  // TODO: Replace this with a REAL number parser
  let nf = NSNumberFormatter()
  nf.numberStyle = NSNumberFormatterStyle.DecimalStyle
  let number = nf.numberFromString(str)
  if let actualNumber = number {
    let doubleVal = actualNumber.doubleValue
    return LexToken.Number(actualNumber.doubleValue)
  }
  return nil
}

func parse(tokens: [LexToken]) -> Cons? {
  /// A stack of the 'currentCons' value for the levels above the current level of the AST. The top object on this stack
  /// is always the Cons node to continue working with after the current subtree has been completely parsed.
  var consStack : [Cons] = []
  /// A reference to the Cons object we are currently working with. currentCons changes values in accordance with a
  /// depth-first traversal of the completed AST.
  var currentCons : Cons? = nil
  /// A reference to the top level Cons object (the root of the entire AST for this expression).
  var baseCons : Cons? = nil

  var needFirstInCons = false

  func addCons(v: ConsValue) {
    if needFirstInCons {
      // First element in a cons list
      currentCons?.value = v
      needFirstInCons = false
    }
    else {
      let newCons = Cons(v)
      currentCons?.next = newCons
      currentCons = newCons
    }
  }

  for token in tokens {
    switch token {
    case .LeftP:
      // Create a new Cons
      let newCons = Cons()
      if baseCons == nil {
        // If this is the very first node in the expression, capture a reference
        baseCons = newCons
      }
      if needFirstInCons {
        // Modify the current node, and then descend
        currentCons?.value = .Literal(.List(newCons))
        if let actualCons = currentCons {
          // Push the current Cons onto the stack, so we can continue from it when we go back up a level
          consStack.append(actualCons)
        }
      }
      else {
        // Add a final node, and then descend
        let finalCons = Cons(.Literal(.List(newCons)))
        currentCons?.next = finalCons
        consStack.append(finalCons)
      }
      currentCons = newCons
      needFirstInCons = true
    case .RightP:
      // Pop the previous Cons off the stack
      if consStack.count > 0 {
        currentCons = consStack.last
        consStack.removeLast()
      }
      // Otherwise, we're at the end; do nothing
      break
    case .NilLiteral:
      addCons(.Literal(.NilLiteral))
    case let .StringLiteral(s):
      addCons(.Literal(.StringLiteral(s)))
    case let .Number(n):
      addCons(.Literal(.NumberLiteral(n)))
    case let .Boolean(b):
      addCons(.Literal(.BoolLiteral(b)))
    case let .Keyword(k):
      fatal("Not supported yet")
    case let .Identifier(r):
      addCons(.Variable(r))
    }
  }

  if consStack.count > 0 {
    // We have too many left parentheses
    return nil
  }
  else if let actualBaseCons = baseCons {
    return actualBaseCons
  }
  else {
    return nil
  }
}

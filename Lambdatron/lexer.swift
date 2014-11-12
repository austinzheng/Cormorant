//
//  lexer.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/12/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// Tokens that come out of the lex() function
enum LexToken : Printable {
  case LeftParentheses            // left parentheses '('
  case RightParentheses           // right parentheses ')'
  case LeftSquareBracket          // left square bracket '['
  case RightSquareBracket         // right square bracket ']'
  case NilLiteral                 // nil
  case StringLiteral(String)      // string (denoted by double quotes)
  case Number(Double)             // floating-point number
  case Boolean(Bool)              // boolean (true or false)
  case Keyword(String)            // keyword (prefixed by ':')
  case Identifier(String)         // unknown identifier (function or variable name)
  case Special(SpecialForm)       // a special form (e.g. 'quote')
  
  var description : String {
    switch self {
    case .LeftParentheses: return "LeftP <(>"
    case .RightParentheses: return "RightP <)>"
    case .LeftSquareBracket: return "LeftSqBr <[>"
    case .RightSquareBracket: return "RightSqBr <]>"
    case let .StringLiteral(x): return "String \"\(x)\""
    case let .NilLiteral: return "Nil"
    case let .Number(x): return "Number <\(x)>"
    case let .Boolean(x): return "Boolean <\(x)>"
    case let .Keyword(x): return "Keyword \(x)"
    case let .Identifier(x): return "Identifier <\(x)>"
    case let .Special(x): return x.rawValue
    }
  }
}

func lex(raw: String) -> [LexToken]? {
  enum RawLexToken {
    case LeftP
    case RightP
    case LeftSqBr
    case RightSqBr
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
      switch char {
      case "\"":
        flushTokenToBuffer()                          // User starting a string with an opening "
        stringActive = true
      case "(":
        flushTokenToBuffer()                          // Left parentheses
        rawTokenBuffer.append(.LeftP)
      case ")":
        flushTokenToBuffer()                          // Right parentheses
        rawTokenBuffer.append(.RightP)
      case "[":
        flushTokenToBuffer()                          // Left square bracket
        rawTokenBuffer.append(.LeftSqBr)
      case "]":
        flushTokenToBuffer()                          // Right square bracket
        rawTokenBuffer.append(.RightSqBr)
      case _ where wsSet.characterIsMember(tChar):
        flushTokenToBuffer()                          // Whitespace/newline
      default:
        currentToken.appendString(String(char))       // Any other valid character
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
    case .LeftP: tokenBuffer.append(.LeftParentheses)
    case .RightP: tokenBuffer.append(.RightParentheses)
    case .LeftSqBr: tokenBuffer.append(.LeftSquareBracket)
    case .RightSqBr: tokenBuffer.append(.RightSquareBracket)
    case let .StringLiteral(sl): tokenBuffer.append(.StringLiteral(sl))
    case let .Unknown(u):
      // Possible type inference bug? Without the String() constructor it fails, even though 'u' is already a string
      let tValue = NSString(string: String(u))
      // Figure out what to do with the token
      if let specialForm = SpecialForm(rawValue: tValue) {
        // Special form
        tokenBuffer.append(.Special(specialForm))
      }
      else if tValue.characterAtIndex(0) == UInt16(UnicodeScalar(":").value) && tValue.length > 1 {
        // This is a keyword (starts with ":" and has at least one other character)
        tokenBuffer.append(.Keyword(u))
      }
      else if tValue == "nil" {
        // Literal nil
        tokenBuffer.append(.NilLiteral)
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

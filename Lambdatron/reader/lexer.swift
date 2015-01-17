//
//  lexer.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/12/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

enum LexResult {
  case Success([LexToken])
  case Failure(LexError)
}

/// An enum describing errors that can cause lexing of the input string to fail.
public enum LexError : String, Printable {
  case InvalidEscapeSequenceError = "InvalidEscapeSequenceError"
  case InvalidCharacterError = "InvalidCharacterError"
  case NonTerminatedStringError = "NonTerminatedStringError"

  public var description : String {
    let name = self.rawValue
    switch self {
    case .InvalidEscapeSequenceError: return "(\(name)): invalid or unfinished escape sequence"
    case .InvalidCharacterError: return "(\(name)): invalid or unfinished character literal"
    case .NonTerminatedStringError: return "(\(name)): strings weren't all terminated by end of input"
    }
  }
}

/// Tokens that come out of the lex() function
enum LexToken : Printable {
  case LeftParentheses            // left parentheses '('
  case RightParentheses           // right parentheses ')'
  case LeftSquareBracket          // left square bracket '['
  case RightSquareBracket         // right square bracket ']'
  case LeftBrace                  // left brace '{'
  case RightBrace                 // right brace '}'
  case Quote                      // single quote '''
  case Backquote                  // isolate grave accent '`'
  case Tilde                      // tilde '~'
  case TildeAt                    // tilde followed by at '~@'
  case NilLiteral                 // nil
  case CharLiteral(Character)     // character literal
  case StringLiteral(String)      // string (denoted by double quotes)
  case Integer(Int)               // integer number
  case FlPtNumber(Double)         // floating-point number
  case Boolean(Bool)              // boolean (true or false)
  case Keyword(String)            // keyword (prefixed by ':')
  case Identifier(String)         // unknown identifier (function or variable name)
  case Special(SpecialForm)       // a special form (e.g. 'quote')
  case BuiltInFunction(BuiltIn)   // a built-in function
  
  var description : String {
    switch self {
    case .LeftParentheses: return "LeftP <(>"
    case .RightParentheses: return "RightP <)>"
    case .LeftSquareBracket: return "LeftSqBr <[>"
    case .RightSquareBracket: return "RightSqBr <]>"
    case .LeftBrace: return "LeftBrace <{>"
    case .RightBrace: return "RightBrace <}>"
    case .Quote: return "Quote <'>"
    case .Backquote: return "Backquote <`>"
    case .Tilde: return "Tilde <~>"
    case .TildeAt: return "TildeAt <~@>"
    case let .CharLiteral(c): return "Character \"\(c)\""
    case let .StringLiteral(x): return "String \"\(x)\""
    case let .NilLiteral: return "Nil"
    case let .Integer(v): return "Integer <\(v)>"
    case let .FlPtNumber(x): return "FlPtNumber <\(x)>"
    case let .Boolean(x): return "Boolean <\(x)>"
    case let .Keyword(x): return "Keyword \(x)"
    case let .Identifier(x): return "Identifier <\(x)>"
    case let .Special(x): return "Special <\(x.rawValue)>"
    case let .BuiltInFunction(x): return "BuiltIn <\(x.rawValue)>"
    }
  }
}

private enum RawLexToken {
  case LeftP
  case RightP
  case LeftSqBr
  case RightSqBr
  case LeftBrace
  case RightBrace
  case Quote
  case Backquote
  case Tilde
  case TildeAt
  case CharLiteral(Character)
  case StringLiteral(String)
  case Unknown(String)
}

func processEscape(sequence: String) -> String? {
  switch sequence {
    case "r": return "\r"
    case "n": return "\n"
    case "t": return "\t"
    case "\"": return "\""
    case "\\": return "\\"
  default: return nil
  }
}

/// Given a raw input (as a string), lex it into individual tokens.
func lex(raw: String) -> LexResult {
  enum State {
    case Normal, String, Comment
  }
  
  // Whitespace character set; 'otherWsSet' is used for characters that should be ignored like whitespace
  let wsSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
  let otherWsSet = NSCharacterSet(charactersInString: ",")
  // Newline character set; only used for finding the newlines that terminate single-line comments
  let nlSet = NSCharacterSet.newlineCharacterSet()
  
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
  
  var state : State = .Normal
  
  var skipCount = 0
  let rawAsNSString = NSString(string: raw)
  for (idx, char) in enumerate(raw) {
    if skipCount > 0 {
      // Multi-character sequence detected previously. Don't run.
      skipCount--
      continue
    }
    
    // Horrible, horrible hacks to turn a Character into a unichar
    var tChar = NSString(string: String(char)).characterAtIndex(0)
    
    switch state {
    case .Normal:
      switch char {
      case ";":
        flushTokenToBuffer()                          // User starting a comment with a ;
        state = .Comment
      case "\"":
        flushTokenToBuffer()                          // User starting a string with an opening "
        state = .String
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
      case "{":
        flushTokenToBuffer()                          // Left brace
        rawTokenBuffer.append(.LeftBrace)
      case "}":
        flushTokenToBuffer()                          // Right brace
        rawTokenBuffer.append(.RightBrace)
      case "'":
        flushTokenToBuffer()                          // Single quote
        rawTokenBuffer.append(.Quote)
      case "`":
        flushTokenToBuffer()                          // Backquote
        rawTokenBuffer.append(.Backquote)
      case "~":
        flushTokenToBuffer()                          // Tilde can either signify ~ or ~@
        if idx < rawAsNSString.length - 1 {
          let nextChar = rawAsNSString.substringWithRange(NSRange(location: idx+1, length: 1))
          rawTokenBuffer.append(nextChar == "@" ? .TildeAt : .Tilde)
          skipCount = nextChar == "@" ? 1 : 0
        }
        else {
          rawTokenBuffer.append(.Tilde)
        }
      case "\\":
        flushTokenToBuffer()                          // Backslash represents a character literal
        if let result = parseCharacterLiteral(idx, rawAsNSString) {
          let (token, skip) = result
          rawTokenBuffer.append(token)
          skipCount = skip
        }
        else {
          // Backslash without anything following it, or invalid character literal name
          return .Failure(.InvalidCharacterError)
        }
      case _ where wsSet.characterIsMember(tChar) || otherWsSet.characterIsMember(tChar):
        flushTokenToBuffer()                          // Whitespace/newline or equivalent (e.g. commas)
      default:
        currentToken.appendString(String(char))       // Any other valid character
      }
    case .String:
      // Currently lexing characters forming a string literal
      if char == "\"" {
        // User ended the string with a closing "
        rawTokenBuffer.append(.StringLiteral(currentToken))
        currentToken = ""
        state = .Normal
      }
      else if (char == "\\") {
        if idx == rawAsNSString.length - 1 {
          // An escape character cannot be the last character in the input
          return .Failure(.InvalidEscapeSequenceError)
        }
        skipCount = 1
        // Get the next character
        let nextChar = rawAsNSString.substringWithRange(NSRange(location: idx+1, length: 1))
        if let escapeSeq = processEscape(nextChar) {
          currentToken.appendString(escapeSeq)
        }
        else {
          return .Failure(.InvalidEscapeSequenceError)
        }
      }
      else {
        // Any other token gets added to the buffer as a literal
        currentToken.appendString(String(char))
      }
    case .Comment:
      // Comments are completely ignored by the lexer, and are terminated by a newline
      switch char {
      case _ where nlSet.characterIsMember(tChar):
        // End of string
        state = .Normal
      default: break
      }
    }
  }
  
  if state == .String {
    // This is bad; a string was left dangling
    return .Failure(.NonTerminatedStringError)
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
    case .LeftBrace: tokenBuffer.append(.LeftBrace)
    case .RightBrace: tokenBuffer.append(.RightBrace)
    case .Quote: tokenBuffer.append(.Quote)
    case .Backquote: tokenBuffer.append(.Backquote)
    case .Tilde: tokenBuffer.append(.Tilde)
    case .TildeAt: tokenBuffer.append(.TildeAt)
    case let .CharLiteral(cl): tokenBuffer.append(.CharLiteral(cl))
    case let .StringLiteral(sl): tokenBuffer.append(.StringLiteral(sl))
    case let .Unknown(u):
      // Possible type inference bug? Without the String() constructor it fails, even though 'u' is already a string
      let tValue = NSString(string: String(u))
      // Figure out what to do with the token
      if let specialForm = SpecialForm(rawValue: tValue) {
        // Special form
        tokenBuffer.append(.Special(specialForm))
      }
      else if let builtIn = BuiltIn(rawValue: tValue) {
        // Built-in function
        tokenBuffer.append(.BuiltInFunction(builtIn))
      }
      else if tValue.characterAtIndex(0) == UInt16(UnicodeScalar(":").value) && tValue.length > 1 {
        // This is a keyword (starts with ":" and has at least one other character)
        tokenBuffer.append(.Keyword(u.substringWithRange(u.startIndex.successor()..<u.endIndex)))
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
  
  return .Success(tokenBuffer)
}

// Immutable utility items
private let nf = NSNumberFormatter()
private let nonTerminationSet = NSCharacterSet.lowercaseLetterCharacterSet()

func buildNumberFromString(str: String) -> LexToken? {
  enum NumberMode {
    case Integer, FloatingPoint
  }
  var mode : NumberMode = .Integer
  
  // Scan string for "."
  for item in str {
    if item == "." {
      switch mode {
      case .Integer:
        mode = .FloatingPoint
      case .FloatingPoint:
        // A second decimal point makes the number invalid
        return nil
      }
    }
  }
  
  // The classic 'isNumber()' function.
  // TODO: Replace this with a REAL number parser
  nf.numberStyle = NSNumberFormatterStyle.DecimalStyle
  let number = nf.numberFromString(str)
  if let actualNumber = number {
    switch mode {
    case .Integer:
      return LexToken.Integer(actualNumber.longValue)
    case .FloatingPoint:
      return LexToken.FlPtNumber(actualNumber.doubleValue)
    }
  }
  return nil
}

private func parseCharacterLiteral(start: Int, str: String) -> (RawLexToken, Int)? {
  // Precondition: start is the index of the "\" character in str that starts the character literal
  let strAsUtf16 = NSString(string: str)
  let strLength = strAsUtf16.length
  // Reject any character literals started at the end of the string
  if start == strLength - 1 {
    return nil
  }
  // Take single character
  if strAsUtf16.characterAtIndex(start + 1) == NSString(string: "\\").characterAtIndex(0) {
    // Special case: user entered "\\", which indicates the backslash literal
    return (.CharLiteral("\\"), 1)
  }
  else if start == strAsUtf16.length - 2 || !nonTerminationSet.characterIsMember(strAsUtf16.characterAtIndex(start + 2)) {
    // Single-character literal: either the character after the next terminates the literal, or it's at end of string
    // Note that single-character literals can be numbers, letters, or symbols (e.g. "\."), but multi-character literals
    //  always have names comprised of lowercase letters. Therefore, if we detect the prospective second character in
    //  the literal name to be a lowercase letter, then we scan for a literal name. Otherwise, we consider the literal
    //  a single-character literal.
    let rawUnichar = strAsUtf16.characterAtIndex(start + 1)
    let asStr = strAsUtf16.substringWithRange(NSRange(location: start + 1, length: 1))
    let character = Character(asStr)
    return (.CharLiteral(character), 1)
  }

  // Character literal with a character name (e.g. 'newline')
  var idx = start + 2
  while idx < strLength {
    if !nonTerminationSet.characterIsMember(strAsUtf16.characterAtIndex(idx)) {
      break
    }
    idx++
  }
  // The actual end is one prior to the end of the string or the termination character.
  idx -= 1
  let literalLength = idx - start
  assert(literalLength > 1)
  let literalName = strAsUtf16.substringWithRange(NSRange(location: start + 1, length: literalLength))

  switch literalName {
  case "space":
    return (.CharLiteral(" "), literalLength)
  case "tab":
    return (.CharLiteral("\t"), literalLength)
  case "newline":
    return (.CharLiteral("\n"), literalLength)
  case "return":
    return (.CharLiteral("\r"), literalLength)
  default:
    return nil
  }
}

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

private enum RawLexResult {
  case Success([RawLexToken])
  case Failure(LexError)
}

/// Tokens representing special syntax characters
enum SyntaxToken {
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
}

/// Tokens that come out of the lex() function
enum LexToken {
  case Syntax(SyntaxToken)
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

  var isLeftParentheses : Bool {
    switch self {
    case let .Syntax(s): switch s { case .LeftParentheses: return true; default: return false }
    default: return false
    }
  }

  var isRightParentheses : Bool {
    switch self {
    case let .Syntax(s): switch s { case .RightParentheses: return true; default: return false }
    default: return false
    }
  }

  var isLeftSquareBracket : Bool {
    switch self {
    case let .Syntax(s): switch s { case .LeftSquareBracket: return true; default: return false }
    default: return false
    }
  }

  var isRightSquareBracket : Bool {
    switch self {
    case let .Syntax(s): switch s { case .RightSquareBracket: return true; default: return false }
    default: return false
    }
  }

  var isLeftBrace : Bool {
    switch self {
    case let .Syntax(s): switch s { case .LeftBrace: return true; default: return false }
    default: return false
    }
  }

  var isRightBrace : Bool {
    switch self {
    case let .Syntax(s): switch s { case .RightBrace: return true; default: return false }
    default: return false
    }
  }
}

private enum RawLexToken {
  case Syntax(SyntaxToken)
  case CharLiteral(Character)
  case StringLiteral(String)
  case Unknown(String)
}

private func characterIsWhitespace(item: unichar) -> Bool {
  // Whitespace character set; 'misc' is used for characters that should be ignored like whitespace
  let ws = NSCharacterSet.whitespaceAndNewlineCharacterSet()
  let misc = NSCharacterSet(charactersInString: ",")
  return ws.characterIsMember(item) || misc.characterIsMember(item)
}

/// Perform the first phase of lexing. This takes in a string representing source code, and returns an array of
/// RawLexTokens.
private func lex1(raw: String) -> RawLexResult {
  enum State {
    case Normal, String, Comment
  }
  // Newline character set; only used for finding the newlines that terminate single-line comments
  let nlSet = NSCharacterSet.newlineCharacterSet()

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
        rawTokenBuffer.append(.Syntax(.LeftParentheses))
      case ")":
        flushTokenToBuffer()                          // Right parentheses
        rawTokenBuffer.append(.Syntax(.RightParentheses))
      case "[":
        flushTokenToBuffer()                          // Left square bracket
        rawTokenBuffer.append(.Syntax(.LeftSquareBracket))
      case "]":
        flushTokenToBuffer()                          // Right square bracket
        rawTokenBuffer.append(.Syntax(.RightSquareBracket))
      case "{":
        flushTokenToBuffer()                          // Left brace
        rawTokenBuffer.append(.Syntax(.LeftBrace))
      case "}":
        flushTokenToBuffer()                          // Right brace
        rawTokenBuffer.append(.Syntax(.RightBrace))
      case "'":
        flushTokenToBuffer()                          // Single quote
        rawTokenBuffer.append(.Syntax(.Quote))
      case "`":
        flushTokenToBuffer()                          // Backquote
        rawTokenBuffer.append(.Syntax(.Backquote))
      case "~":
        flushTokenToBuffer()                          // Tilde can either signify ~ or ~@
        if idx < rawAsNSString.length - 1 {
          let nextChar = rawAsNSString.substringWithRange(NSRange(location: idx+1, length: 1))
          rawTokenBuffer.append(.Syntax(nextChar == "@" ? .TildeAt : .Tilde))
          skipCount = nextChar == "@" ? 1 : 0
        }
        else {
          rawTokenBuffer.append(.Syntax(.Tilde))
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
          return .Failure(LexError(.InvalidCharacterError))
        }
      case _ where characterIsWhitespace(tChar):
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
          return .Failure(LexError(.InvalidEscapeSequenceError))
        }
        skipCount = 1
        // Get the next character
        let nextChar = rawAsNSString.substringWithRange(NSRange(location: idx+1, length: 1))
        if let escapeSeq = processEscape(nextChar) {
          currentToken.appendString(escapeSeq)
        }
        else {
          return .Failure(LexError(.InvalidEscapeSequenceError))
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
    return .Failure(LexError(.NonTerminatedStringError))
  }
  // If there's another token left, flush it
  flushTokenToBuffer()
  // Return the buffer
  return .Success(rawTokenBuffer)
}

/// Perform the second phase of lexing, taking RawLexTokens and turning them into LexTokens. This may involve taking
/// Unknown tokens and figuring out if they correspond to literals or other privileged forms.
private func lex2(rawTokenBuffer: [RawLexToken]) -> LexResult {
  var tokenBuffer : [LexToken] = []
  for rawToken in rawTokenBuffer {
    switch rawToken {
    case let .Syntax(s): tokenBuffer.append(.Syntax(s))
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

/// Given a raw input (as a string), lex it into individual tokens.
func lex(raw: String) -> LexResult {
  let result = lex1(raw)
  switch result {
  case let .Success(rawTokenBuffer):
    return lex2(rawTokenBuffer)
  case let .Failure(f): return .Failure(f)
  }
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

/// Given the second character in a two-character escape sequence (e.g. "n" in "\n"), return the character the escape
/// sequence corresponds to (if one exists).
private func processEscape(sequence: String) -> String? {
  switch sequence {
  case "r": return "\r"
  case "n": return "\n"
  case "t": return "\t"
  case "\"": return "\""
  case "\\": return "\\"
  default: return nil
  }
}

/// Given an input string, as well as a start index marking the position of a token within that string that starts with
/// a backslash (e.g. "hello world \a" and 12), try to parse the token into a character literal, and return either nil
/// (if the token can't be parsed correctly) or a tuple containing the character literal token and an index from whence
/// to resume parsing.
private func parseCharacterLiteral(start: Int, str: String) -> (RawLexToken, Int)? {
  // Precondition: start is the index of the "\" character in str that starts the character literal
  let strAsUtf16 = NSString(string: str)
  let strLength = strAsUtf16.length
  // Reject any character literals started at the end of the string
  if start == strLength - 1 {
    return nil
  }

  /// Check whether a character at a certain position is whitespace (if it exists). Returns true if the character is out
  /// of bounds.
  func isWhitespace(pos: Int) -> Bool {
    if pos >= strLength { return true }
    // A character can be adjacent to:
    // * Another character (e.g. \a\a)
    // * The start or end of a list (e.g. (\a))
    // * The start or end of a vector (e.g. \a[])
    // * The start or end of a bracketed form (e.g. \a{})
    // * The start of a string (e.g. \a"hello")
    // * The macro symbols `, @, or ~
    //
    // A character cannot touch a keyword (:), literal quote ('), hash (#), number, true, false, or nil.
    let canTouch = NSCharacterSet(charactersInString: "\\()[]{}\"`@~")
    let char = strAsUtf16.characterAtIndex(pos)
    return characterIsWhitespace(char) || canTouch.characterIsMember(char)
  }

  // Take single character
  if strAsUtf16.characterAtIndex(start + 1) == NSString(string: "\\").characterAtIndex(0) {
    // Special case: user entered "\\", which indicates the backslash literal
    if !isWhitespace(start + 2) { return nil }
    return (.CharLiteral("\\"), 1)
  }
  else if start == strAsUtf16.length - 2 || !nonTerminationSet.characterIsMember(strAsUtf16.characterAtIndex(start + 2)) {
    // Single-character literal: either the character after the next terminates the literal, or it's at end of string
    // Note that single-character literals can be numbers, letters, or symbols (e.g. "\."), but multi-character literals
    //  always have names comprised of lowercase letters. Therefore, if we detect the prospective second character in
    //  the literal name to be a lowercase letter, then we scan for a literal name. Otherwise, we consider the literal
    //  a single-character literal.
    if !isWhitespace(start + 2) { return nil }
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
  if !isWhitespace(idx) { return nil }
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
  case "backspace":
    let backspace = Character(UnicodeScalar(8))
    return (.CharLiteral(backspace), literalLength)
  case "formfeed":
    let formfeed = Character(UnicodeScalar(12))
    return (.CharLiteral(formfeed), literalLength)
  default:
    return nil
  }
}

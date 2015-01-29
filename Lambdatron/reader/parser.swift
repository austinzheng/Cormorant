//
//  parser.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

private enum TokenCollectionType {
  case List, Vector, Map
}

private enum NextFormTreatment {
  // This enum describes several special reader forms that affect the parsing of the form that follows immediately
  // afterwards. For example, something like '(1 2 3) should expand to (quote (1 2 3)).
  case None           // No special treatment
  case Quote          // Wrap next form with (quote)
  case SyntaxQuote
  case Unquote
  case UnquoteSplice
}

enum TokenCollectionResult {
  case Tokens([LexToken])
  case Error(ParseError)
}

/// Collect a sequence of tokens representing a single collection type form (e.g. a single list).
private func collectTokens(tokens: [LexToken], inout counter: Int, type: TokenCollectionType) -> TokenCollectionResult {
  // Check validity of first token
  switch tokens[counter] {
  case let x where x.isLeftParentheses && type == .List: break
  case let x where x.isLeftSquareBracket && type == .Vector: break
  case let x where x.isLeftBrace && type == .Map: break
  default: return .Error(.BadStartTokenError)
  }
  var count = 1
  var buffer : [LexToken] = []
  // Collect tokens
  for var i=counter+1; i<tokens.count; i++ {
    counter = i
    var currentToken = tokens[i]
    switch currentToken {
    case let x where x.isLeftParentheses && type == .List:
      count++
      buffer.append(currentToken)
    case let x where x.isRightParentheses && type == .List:
      count--
      if count > 0 {
        buffer.append(currentToken)
      }
    case let x where x.isLeftSquareBracket && type == .Vector:
      count++
      buffer.append(currentToken)
    case let x where x.isRightSquareBracket && type == .Vector:
      count--
      if count > 0 {
        buffer.append(currentToken)
      }
    case let x where x.isLeftBrace && type == .Map:
      count++
      buffer.append(currentToken)
    case let x where x.isRightBrace && type == .Map:
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
  return count == 0 ? .Tokens(buffer) : .Error(.MismatchedDelimiterError)
}

// Note that this function will *modify* wrapStack by removing elements.
private func wrappedConsItem(item: ConsValue, inout wrapStack: [NextFormTreatment]) -> ConsValue {
  let wrapType : NextFormTreatment = wrapStack.last ?? .None
  let wrappedItem : ConsValue = {
    switch wrapType {
    case .None:
      return item
    case .Quote:
      return .ListLiteral(Cons(.ReaderMacro(.Quote), next: Cons(item)))
    case .SyntaxQuote:
      return .ListLiteral(Cons(.ReaderMacro(.SyntaxQuote), next: Cons(item)))
    case .Unquote:
      return .ListLiteral(Cons(.ReaderMacro(.Unquote), next: Cons(item)))
    case .UnquoteSplice:
      return .ListLiteral(Cons(.ReaderMacro(.UnquoteSplice), next: Cons(item)))
    }
    }()
  if wrapStack.count > 0 {
    wrapStack.removeLast()
    return wrappedConsItem(wrappedItem, &wrapStack)
  }
  return wrappedItem
}

private enum TokenListResult {
  case Success([ConsValue])
  case Failure(ParseError)
}

/// Take a list of LexTokens and return a list of ConsValues which can be transformed into a list, a vector, or another
/// collection type. This method recursively finds token sequences representing collections and calls the appropriate
/// constructor to build a valid ConsValue for that form
private func processTokenList(tokens: [LexToken], ctx: Context) -> TokenListResult {
  var wrapStack : [NextFormTreatment] = []
  
  // Create a new ConsValue array with all sub-structures properly processed
  var buffer : [ConsValue] = []
  var counter = 0
  while counter < tokens.count {
    let currentToken = tokens[counter]
    switch currentToken {
    case let .Syntax(s):
      switch s {
      case .LeftParentheses:
        let list = listWithTokens(collectTokens(tokens, &counter, .List), ctx)
        switch list {
        case let .Success(list): buffer.append(wrappedConsItem(.ListLiteral(list), &wrapStack))
        case let .Failure(f): return .Failure(f)
        }
      case .RightParentheses:
        return .Failure(.MismatchedDelimiterError)
      case .LeftSquareBracket:
        let vector = vectorWithTokens(collectTokens(tokens, &counter, .Vector), ctx)
        switch vector {
        case let .Success(vector): buffer.append(wrappedConsItem(.VectorLiteral(vector), &wrapStack))
        case let .Failure(f): return .Failure(f)
        }
      case .RightSquareBracket:
        return .Failure(.MismatchedDelimiterError)
      case .LeftBrace:
        let map = mapWithTokens(collectTokens(tokens, &counter, .Map), ctx)
        switch map {
        case let .Success(map): buffer.append(wrappedConsItem(.MapLiteral(map), &wrapStack))
        case let .Failure(f): return .Failure(f)
        }
      case .RightBrace:
        return .Failure(.MismatchedDelimiterError)
      case .Quote:
        wrapStack.append(.Quote)
      case .Backquote:
        wrapStack.append(.SyntaxQuote)
      case .Tilde:
        wrapStack.append(.Unquote)
      case .TildeAt:
        wrapStack.append(.UnquoteSplice)
      }
    case .NilLiteral:
      buffer.append(wrappedConsItem(.NilLiteral, &wrapStack))
    case let .CharLiteral(c):
      buffer.append(wrappedConsItem(.CharacterLiteral(c), &wrapStack))
    case let .StringLiteral(s):
      buffer.append(wrappedConsItem(.StringLiteral(s), &wrapStack))
    case let .Integer(v):
      buffer.append(wrappedConsItem(.IntegerLiteral(v), &wrapStack))
    case let .FlPtNumber(n):
      buffer.append(wrappedConsItem(.FloatLiteral(n), &wrapStack))
    case let .Boolean(b):
      buffer.append(wrappedConsItem(.BoolLiteral(b), &wrapStack))
    case let .Keyword(k):
      let internedKeyword = ctx.keywordForName(k)
      buffer.append(wrappedConsItem(.Keyword(internedKeyword), &wrapStack))
    case let .Identifier(r):
      let internedSymbol = ctx.symbolForName(r)
      buffer.append(wrappedConsItem(.Symbol(internedSymbol), &wrapStack))
    case let .Special(s):
      buffer.append(wrappedConsItem(.Special(s), &wrapStack))
    case let .BuiltInFunction(bf):
      buffer.append(wrappedConsItem(.BuiltInFunction(bf), &wrapStack))
    }
    counter++
  }
  return .Success(buffer)
}

// We need all these small enums because "unimplemented IR generation feature non-fixed multi-payload enum layout" is
// still, annoyingly, a thing.
private enum ListResult {
  case Success(List<ConsValue>)
  case Failure(ParseError)
}

private func listWithTokens(tokens: TokenCollectionResult, ctx: Context) -> ListResult {
  switch tokens {
  case let .Tokens(tokens):
    if tokens.count == 0 {
      // Empty list: ()
      return .Success(Empty())
    }
    let processedForms = processTokenList(tokens, ctx)
    switch processedForms {
    case let .Success(processedForms):
      // Create the list itself
      var head : List<ConsValue> = Empty()
      for var i=processedForms.count - 1; i >= 0; i-- {
        let next = Cons(processedForms[i], next: head)
        head = next
      }
      return .Success(head)
    case let .Failure(f): return .Failure(f)
    }
  case let .Error(e): return .Failure(e)
  }
}

private enum VectorResult {
  case Success([ConsValue])
  case Failure(ParseError)
}

private func vectorWithTokens(tokens: TokenCollectionResult, ctx: Context) -> VectorResult {
  switch tokens {
  case let .Tokens(tokens):
    if tokens.count == 0 {
      // Empty vector: []
      return .Success([])
    }
    let processedForms = processTokenList(tokens, ctx)
    switch processedForms {
    case let .Success(processedForms): return .Success(processedForms)
    case let .Failure(f): return .Failure(f)
    }
  case let .Error(e): return .Failure(e)
  }
}

private enum MapResult {
  case Success(Map)
  case Failure(ParseError)
}

private func mapWithTokens(tokens: TokenCollectionResult, ctx: Context) -> MapResult {
  switch tokens {
  case let .Tokens(tokens):
    if tokens.count == 0 {
      // Empty map: []
      return .Success([:])
    }
    let processedForms = processTokenList(tokens, ctx)
    switch processedForms {
    case let .Success(processedForms):
      // Create the vector itself
      var newMap : Map = [:]
      if processedForms.count % 2 != 0 {
        // Invalid; need an even number of tokens
        return .Failure(.MapKeyValueMismatchError)
      }
      for var i=0; i<processedForms.count - 1; i += 2 {
        let key = processedForms[i]
        let value = processedForms[i+1]
        newMap[key] = value
      }
      return .Success(newMap)
    case let .Failure(f): return .Failure(f)
    }
  case let .Error(e): return .Failure(e)
  }
}

enum ParseResult {
  case Success(ConsValue)
  case Failure(ParseError)
}

func parse(tokens: [LexToken], ctx: Context) -> ParseResult {
  var index = 0
  var wrapStack : [NextFormTreatment] = []
  if tokens.count == 0 {
    return .Failure(.EmptyInputError)
  }

  /// Parse the entire top-level form and wrap it inside a reader macro.
  func createTopLevelReaderMacro(macroType: NextFormTreatment) -> ParseResult {
    if tokens.count > 1 {
      var restTokens = tokens
      restTokens.removeAtIndex(0)
      switch parse(restTokens, ctx) {
      case let .Success(result):
        wrapStack.append(macroType)
        return .Success(wrappedConsItem(result, &wrapStack))
      case let .Failure(f): return .Failure(f)
      }
    }
    return .Failure(.MismatchedReaderMacroError)
  }

  // Figure out how to parse
  switch tokens[0] {
  case let .Syntax(s):
    switch s {
    case .LeftParentheses:
      switch listWithTokens(collectTokens(tokens, &index, .List), ctx) {
      case let .Success(result): return .Success(.ListLiteral(result))
      case let .Failure(f): return .Failure(f)
      }
    case .RightParentheses:
      return .Failure(.BadStartTokenError)
    case .LeftSquareBracket:
      switch vectorWithTokens(collectTokens(tokens, &index, .Vector), ctx) {
      case let .Success(result): return .Success(.VectorLiteral(result))
      case let .Failure(f): return .Failure(f)
      }
    case .RightSquareBracket:
      return .Failure(.BadStartTokenError)
    case .LeftBrace:
      switch mapWithTokens(collectTokens(tokens, &index, .Map), ctx) {
      case let .Success(result): return .Success(.MapLiteral(result))
      case let .Failure(f): return .Failure(f)
      }
    case .RightBrace:
      return .Failure(.BadStartTokenError)
    case .Quote:
      return createTopLevelReaderMacro(.Quote)
    case .Backquote:
      return createTopLevelReaderMacro(.SyntaxQuote)
    case .Tilde:
      return createTopLevelReaderMacro(.Unquote)
    case .TildeAt:
      return createTopLevelReaderMacro(.UnquoteSplice)
    }
  case .NilLiteral: return .Success(.NilLiteral)
  case let .CharLiteral(c): return .Success(.CharacterLiteral(c))
  case let .StringLiteral(s): return .Success(.StringLiteral(s))
  case let .Integer(v): return .Success(.IntegerLiteral(v))
  case let .FlPtNumber(n): return .Success(.FloatLiteral(n))
  case let .Boolean(b): return .Success(.BoolLiteral(b))
  case let .Keyword(k):
    let internedKeyword = ctx.keywordForName(k)
    return .Success(.Keyword(internedKeyword))
  case let .Identifier(r):
    let internedSymbol = ctx.symbolForName(r)
    return .Success(.Symbol(internedSymbol))
  case let .Special(s): return .Success(.Special(s))
  case let .BuiltInFunction(b): return .Success(.BuiltInFunction(b))
  }
}

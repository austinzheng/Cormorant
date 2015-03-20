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

private enum TokenCollectionResult {
  case Tokens([LexToken]), Error(ReadError)
}

/// Given an array containing all lexical tokens, a starting index, and a type of collection (list, vector, or map), go
/// through the array to collect and return all tokens that make up the collection whose left delimiter is found at the
/// starting index. This function also updates the index to the position immediately following the token which closes
/// the collection.
private func collectTokens(tokens: [LexToken], inout idx: Int, type: TokenCollectionType) -> TokenCollectionResult {
  // Arguments:
  // tokens: an array of all the LexTokens being currently processed
  // idx: an index into `tokens` describing the start of the collection (must be a '(', '[', or '{' token, and the start
  //  token must correspond to the `type` argument)
  // type: the type of collection that collectTokens should return: a list, vector, or map

  // Check validity of first token. The first token must match with the `type` argument passed in.
  switch tokens[idx] {
  case let x where x.isA(.LeftParentheses) && type == .List: break
  case let x where x.isA(.LeftSquareBracket) && type == .Vector: break
  case let x where x.isA(.LeftBrace) && type == .Map: break
  default: return .Error(ReadError(.BadStartTokenError))
  }
  // The 'nesting level' of the delimiter token. For example, if we were processing a vector and we saw the tokens
  //  '[', '[', '[', ']', and '[', our nesting level would be 3. We use this to determine the end of the collection
  //  we're collecting tokens for.
  var count = 1
  var buffer : [LexToken] = []
  // Collect tokens
  for var i=idx+1; i<tokens.count; i++ {
    idx = i
    var currentToken = tokens[i]
    switch currentToken {
    case let x where x.isA(.LeftParentheses) && type == .List:
      count++
      buffer.append(currentToken)
    case let x where x.isA(.RightParentheses) && type == .List:
      count--
      if count > 0 {
        buffer.append(currentToken)
      }
    case let x where x.isA(.LeftSquareBracket) && type == .Vector:
      count++
      buffer.append(currentToken)
    case let x where x.isA(.RightSquareBracket) && type == .Vector:
      count--
      if count > 0 {
        buffer.append(currentToken)
      }
    case let x where x.isA(.LeftBrace) && type == .Map:
      count++
      buffer.append(currentToken)
    case let x where x.isA(.RightBrace) && type == .Map:
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
  return count == 0 ? .Tokens(buffer) : .Error(ReadError(.MismatchedDelimiterError))
}

/// Given a reader form and the 'wrapStack' array, pop a wrap command off the array and wrap the reader form within the
/// appropriate wrapper (for example, wrap a syntax-quited form inside a ReaderMacro object).
private func wrappedConsItem(item: ConsValue, inout wrapStack: [NextFormTreatment]) -> ConsValue {
  // IMPORTANT: Note that this function will *modify* wrapStack by removing elements.
  let wrapType : NextFormTreatment = wrapStack.last ?? .None
  let wrappedItem : ConsValue = {
    switch wrapType {
    case .None:
      return item
    case .Quote:
      return .ReaderMacroForm(ReaderMacro(type: .Quote, form: item))
    case .SyntaxQuote:
      return .ReaderMacroForm(ReaderMacro(type: .SyntaxQuote, form: item))
    case .Unquote:
      return .ReaderMacroForm(ReaderMacro(type: .Unquote, form: item))
    case .UnquoteSplice:
      return .ReaderMacroForm(ReaderMacro(type: .UnquoteSplice, form: item))
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
  case Failure(ReadError)
}

/// Given a list of LexTokens comprising the tokens *inside* a collection form (such as a list), return a list of
/// corresponding ConsValue items. These items can be used by the calling function to build the collection in question.
/// This method recursively finds token sequences representing collections and calls the appropriate function to build
/// a valid ConsValue for that collection.
private func processTokenList(tokens: [LexToken], ctx: Context) -> TokenListResult {
  // For example: listWithTokens() is called with the tokens <(>, <1>, <true>, <)>. This function is called with the
  //  constituent tokens [<1>, <true>], and returns [ConsValue.IntAtom(1), ConsValue.BoolAtom(true)].
  var wrapStack : [NextFormTreatment] = []
  
  // Create a new ConsValue array with all sub-structures properly processed
  var buffer : [ConsValue] = []
  // The current LexToken we're processing
  var idx = 0
  while idx < tokens.count {
    let currentToken = tokens[idx]
    switch currentToken {
    case let .Syntax(s):
      switch s {
      case .LeftParentheses:
        // We've detected the start of a list. Use collectTokens() to turn all the tokens making up the list into an
        //  actual List, and advance the idx as well.
        let list = listWithTokens(collectTokens(tokens, &idx, .List), ctx)
        switch list {
        case let .Success(list): buffer.append(wrappedConsItem(.Seq(list), &wrapStack))
        case let .Failure(f): return .Failure(f)
        }
      case .RightParentheses:
        // Note that this should fail because anytime we see a left parentheses, we call listWithToken(), which consumes
        //  all tokens up to and including the corresponding right parentheses.
        return .Failure(ReadError(.MismatchedDelimiterError))
      case .LeftSquareBracket:
        let vector = vectorWithTokens(collectTokens(tokens, &idx, .Vector), ctx)
        switch vector {
        case let .Success(vector): buffer.append(wrappedConsItem(.Vector(vector), &wrapStack))
        case let .Failure(f): return .Failure(f)
        }
      case .RightSquareBracket:
        return .Failure(ReadError(.MismatchedDelimiterError))
      case .LeftBrace:
        let map = mapWithTokens(collectTokens(tokens, &idx, .Map), ctx)
        switch map {
        case let .Success(map): buffer.append(wrappedConsItem(.Map(map), &wrapStack))
        case let .Failure(f): return .Failure(f)
        }
      case .RightBrace:
        return .Failure(ReadError(.MismatchedDelimiterError))
      case .Quote:
        wrapStack.append(.Quote)
      case .Backquote:
        wrapStack.append(.SyntaxQuote)
      case .Tilde:
        wrapStack.append(.Unquote)
      case .TildeAt:
        wrapStack.append(.UnquoteSplice)
      case .HashLeftBrace, .HashQuote, .HashLeftParentheses, .HashUnderscore:
        // TODO: Implement support for all of these
        return .Failure(ReadError(.UnimplementedFeatureError))
      }
    case .Nil:
      buffer.append(wrappedConsItem(.Nil, &wrapStack))
    case let .CharLiteral(c):
      buffer.append(wrappedConsItem(.CharAtom(c), &wrapStack))
    case let .StringLiteral(s):
      buffer.append(wrappedConsItem(.StringAtom(s), &wrapStack))
    case let .RegexPattern(s):
      switch constructRegex(s) {
      case let .Success(regex): buffer.append(wrappedConsItem(.Auxiliary(regex), &wrapStack))
      case let .Error(error): return .Failure(error)
      }
    case let .Integer(v):
      buffer.append(wrappedConsItem(.IntAtom(v), &wrapStack))
    case let .FlPtNumber(n):
      buffer.append(wrappedConsItem(.FloatAtom(n), &wrapStack))
    case let .Boolean(b):
      buffer.append(wrappedConsItem(.BoolAtom(b), &wrapStack))
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
    idx += 1
  }
  if wrapStack.count > 0 {
    // If there are still items in the wrapStack, this means that we have a dangling wrappable item (e.g. a dangling
    //  syntax quote).
    return .Failure(ReadError(.MismatchedReaderMacroError))
  }

  return .Success(buffer)
}

// We need all these small enums because "unimplemented IR generation feature non-fixed multi-payload enum layout" is
// still, annoyingly, a thing.
private enum ListResult {
  case Success(SeqType)
  case Failure(ReadError)
}

/// Given a list of tokens that corresponds to a single list (e.g. <(>, <1>, <2>, <)>), build a List data structure.
private func listWithTokens(tokens: TokenCollectionResult, ctx: Context) -> ListResult {
  switch tokens {
  case let .Tokens(tokens):
    if tokens.count == 0 {
      // Empty list: ()
      return .Success(Empty())
    }
    let processedForms = processTokenList(tokens, ctx)
    switch processedForms {
    case let .Success(processedForms): return .Success(sequence(processedForms))
    case let .Failure(f): return .Failure(f)
    }
  case let .Error(e): return .Failure(e)
  }
}

private enum VectorResult {
  case Success([ConsValue])
  case Failure(ReadError)
}

/// Given a list of tokens that corresponds to a single vector (e.g. <[>, <1>, <2>, <]>), build a Vector data structure.
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
  case Success(MapType)
  case Failure(ReadError)
}

/// Given a list of tokens that corresponds to a single map (e.g. <{>, <:a>, <100>, <}>), build a Map data structure.
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
      var newMap : MapType = [:]
      if processedForms.count % 2 != 0 {
        // Invalid; need an even number of tokens
        return .Failure(ReadError(.MapKeyValueMismatchError))
      }
      for (key, value) in PairSequence(processedForms) {
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
  case Failure(ReadError)
}

/// Given an array of lexical tokens, parse them into a ConsValue data structure, or return an error if this is not
/// possible.
func parse(tokens: [LexToken], ctx: Context) -> ParseResult {
  var index = 0
  var wrapStack : [NextFormTreatment] = []
  if tokens.count == 0 {
    return .Failure(ReadError(.EmptyInputError))
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
    return .Failure(ReadError(.MismatchedReaderMacroError))
  }

  // Figure out how to parse
  switch tokens[0] {
  case let .Syntax(s):
    switch s {
    case .LeftParentheses:
      switch listWithTokens(collectTokens(tokens, &index, .List), ctx) {
      case let .Success(result): return .Success(.Seq(result))
      case let .Failure(f): return .Failure(f)
      }
    case .RightParentheses:
      return .Failure(ReadError(.BadStartTokenError))
    case .LeftSquareBracket:
      switch vectorWithTokens(collectTokens(tokens, &index, .Vector), ctx) {
      case let .Success(result): return .Success(.Vector(result))
      case let .Failure(f): return .Failure(f)
      }
    case .RightSquareBracket:
      return .Failure(ReadError(.BadStartTokenError))
    case .LeftBrace:
      switch mapWithTokens(collectTokens(tokens, &index, .Map), ctx) {
      case let .Success(result): return .Success(.Map(result))
      case let .Failure(f): return .Failure(f)
      }
    case .RightBrace:
      return .Failure(ReadError(.BadStartTokenError))
    case .Quote:
      return createTopLevelReaderMacro(.Quote)
    case .Backquote:
      return createTopLevelReaderMacro(.SyntaxQuote)
    case .Tilde:
      return createTopLevelReaderMacro(.Unquote)
    case .TildeAt:
      return createTopLevelReaderMacro(.UnquoteSplice)
    case .HashLeftBrace, .HashQuote, .HashLeftParentheses, .HashUnderscore:
      // TODO: Implement support for all of these
      return .Failure(ReadError(.UnimplementedFeatureError))
    }
  case .Nil: return .Success(.Nil)
  case let .CharLiteral(c): return .Success(.CharAtom(c))
  case let .StringLiteral(s): return .Success(.StringAtom(s))
  case let .RegexPattern(s):
    switch constructRegex(s) {
    case let .Success(regex): return .Success(.Auxiliary(regex))
    case let .Error(error): return .Failure(error)
    }
  case let .Integer(v): return .Success(.IntAtom(v))
  case let .FlPtNumber(n): return .Success(.FloatAtom(n))
  case let .Boolean(b): return .Success(.BoolAtom(b))
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

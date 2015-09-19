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
  case Var
  case Deref
  case Quote          // Wrap next form with (quote)
  case SyntaxQuote
  case Unquote
  case UnquoteSplice
}

/// Given an array containing all lexical tokens, a starting index, and a type of collection (list, vector, or map), go
/// through the array to collect and return all tokens that make up the collection whose left delimiter is found at the
/// starting index. This function also updates the index to the position immediately following the token which closes
/// the collection.
private func collectTokens(tokens: [LexToken], inout idx: Int, type: TokenCollectionType) -> ReadOptional<[LexToken]> {
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
    let currentToken = tokens[i]
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
  return count == 0 ? .Just(buffer) : .Error(ReadError(.MismatchedDelimiterError))
}

/// Given a reader form and the 'wrapStack' array, pop a wrap command off the array and wrap the reader form within the
/// appropriate wrapper (for example, wrap a syntax-quoted form inside a ReaderMacro object).
private func wrappedConsItem(item: Value, inout _ wrapStack: [NextFormTreatment]) -> Value {
  // IMPORTANT: Note that this function will *modify* wrapStack by removing elements.
  let wrapType : NextFormTreatment = wrapStack.last ?? .None
  let wrappedItem : Value
  switch wrapType {
  case .None:
    wrappedItem = item
  case .Var:
    wrappedItem = .Seq(sequence(VAR, item))
  case .Deref:
    wrappedItem = .Seq(sequence(DEREF, item))
  case .Quote:
    wrappedItem = .Seq(sequence(QUOTE, item))
  case .SyntaxQuote:
    wrappedItem = .ReaderMacroForm(ReaderMacro(type: .SyntaxQuote, form: item))
  case .Unquote:
    wrappedItem = .ReaderMacroForm(ReaderMacro(type: .Unquote, form: item))
  case .UnquoteSplice:
    wrappedItem = .ReaderMacroForm(ReaderMacro(type: .UnquoteSplice, form: item))
  }

  if wrapStack.count > 0 {
    wrapStack.removeLast()
    return wrappedConsItem(wrappedItem, &wrapStack)
  }
  return wrappedItem
}

/// Given a list of LexTokens comprising the tokens *inside* a collection form (such as a list), return a list of
/// corresponding Value items. These items can be used by the calling function to build the collection in question. This
/// method recursively finds token sequences representing collections and calls the appropriate function to build a
/// valid Value for that collection.
private func processTokenList(tokens: [LexToken], _ ctx: Context) -> ReadOptional<[Value]> {
  // For example: listWithTokens() is called with the tokens <(>, <1>, <true>, <)>. This function is called with the
  //  constituent tokens [<1>, <true>], and returns [Value.IntAtom(1), Value.BoolAtom(true)].
  var wrapStack : [NextFormTreatment] = []
  
  // Create a new Value array with all sub-structures properly processed
  var buffer : [Value] = []
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
        let list = listWithTokens(collectTokens(tokens, idx: &idx, type: .List), ctx)
        switch list {
        case let .Just(list): buffer.append(wrappedConsItem(.Seq(list), &wrapStack))
        case let .Error(f): return .Error(f)
        }
      case .RightParentheses:
        // Note that this should fail because anytime we see a left parentheses, we call listWithToken(), which consumes
        //  all tokens up to and including the corresponding right parentheses.
        return .Error(ReadError(.MismatchedDelimiterError))
      case .LeftSquareBracket:
        let vector = vectorWithTokens(collectTokens(tokens, idx: &idx, type: .Vector), ctx)
        switch vector {
        case let .Just(vector): buffer.append(wrappedConsItem(.Vector(vector), &wrapStack))
        case let .Error(f): return .Error(f)
        }
      case .RightSquareBracket:
        return .Error(ReadError(.MismatchedDelimiterError))
      case .LeftBrace:
        let map = mapWithTokens(collectTokens(tokens, idx: &idx, type: .Map), ctx)
        switch map {
        case let .Just(map): buffer.append(wrappedConsItem(.Map(map), &wrapStack))
        case let .Error(f): return .Error(f)
        }
      case .RightBrace:
        return .Error(ReadError(.MismatchedDelimiterError))
      case .Quote:
        wrapStack.append(.Quote)
      case .Backquote:
        wrapStack.append(.SyntaxQuote)
      case .Tilde:
        wrapStack.append(.Unquote)
      case .TildeAt:
        wrapStack.append(.UnquoteSplice)
      case .At:
        wrapStack.append(.Deref)
      case .HashQuote:
        wrapStack.append(.Var)
      case .HashLeftBrace, .HashLeftParentheses, .HashUnderscore:
        // TODO: Implement support for all of these
        return .Error(ReadError(.UnimplementedFeatureError))
      }
    case .Nil:
      buffer.append(wrappedConsItem(.Nil, &wrapStack))
    case let .CharLiteral(c):
      buffer.append(wrappedConsItem(.CharAtom(c), &wrapStack))
    case let .StringLiteral(s):
      buffer.append(wrappedConsItem(.StringAtom(s), &wrapStack))
    case let .RegexPattern(s):
      switch constructRegex(s) {
      case let .Just(regex): buffer.append(wrappedConsItem(.Auxiliary(regex), &wrapStack))
      case let .Error(error): return .Error(error)
      }
    case let .Integer(v):
      buffer.append(wrappedConsItem(.IntAtom(v), &wrapStack))
    case let .FlPtNumber(n):
      buffer.append(wrappedConsItem(.FloatAtom(n), &wrapStack))
    case let .Boolean(b):
      buffer.append(wrappedConsItem(.BoolAtom(b), &wrapStack))
    case let .Keyword(k):
      switch splitKeyword(k, currentNamespace: ctx.root) {
      case let .Just(resultStruct):
        let internedKeyword = InternedKeyword(resultStruct.name, namespace: resultStruct.namespace, ivs: ctx.ivs)
        buffer.append(wrappedConsItem(.Keyword(internedKeyword), &wrapStack))
      case let .Error(err):
        return .Error(err)
      }
    case let .Identifier(sym):
      switch splitSymbol(sym) {
      case let .Just(resultStruct):
        let internedSymbol = InternedSymbol(resultStruct.name, namespace: resultStruct.namespace, ivs: ctx.ivs)
        buffer.append(wrappedConsItem(.Symbol(internedSymbol), &wrapStack))
      case let .Error(err):
        return .Error(err)
      }
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
    return .Error(ReadError(.MismatchedReaderMacroError))
  }

  return .Just(buffer)
}

/// Given a list of tokens that corresponds to a single list (e.g. <(>, <1>, <2>, <)>), build a List data structure.
private func listWithTokens(tokens: ReadOptional<[LexToken]>, _ ctx: Context) -> ReadOptional<SeqType> {
  return tokens.then { tokens in
    // No tokens --> empty list ()
    return tokens.isEmpty
      ? .Just(Empty())
      : processTokenList(tokens, ctx).then { .Just(sequenceFromItems($0)) }
  }
}

/// Given a list of tokens that corresponds to a single vector (e.g. <[>, <1>, <2>, <]>), build a Vector data structure.
private func vectorWithTokens(tokens: ReadOptional<[LexToken]>, _ ctx: Context) -> ReadOptional<[Value]> {
  return tokens.then { tokens in
    // No tokens --> empty vector []
    return tokens.isEmpty
      ? .Just([])
      : processTokenList(tokens, ctx).then { .Just($0) }
  }
}

/// Given a list of tokens that corresponds to a single map (e.g. <{>, <:a>, <100>, <}>), build a Map data structure.
private func mapWithTokens(tokens: ReadOptional<[LexToken]>, _ ctx: Context) -> ReadOptional<MapType> {
  return tokens.then { tokens in
    if tokens.isEmpty {
      // No tokens --> empty map {}
      return .Just([:])
    }
    return processTokenList(tokens, ctx).then { processedForms in
      guard processedForms.count % 2 == 0 else {
        // Invalid; need an even number of tokens
        return .Error(ReadError(.MapKeyValueMismatchError))
      }
      // Create the vector itself
      var newMap : MapType = [:]
      for (key, value) in PairSequence(processedForms) {
        newMap[key] = value
      }
      return .Just(newMap)
    }
  }
}

/// Given an array of lexical tokens, parse them into a Value data structure, or return an error if this is not
/// possible.
func parse(tokens: [LexToken], _ ctx: Context) -> ReadOptional<Value> {
  guard !tokens.isEmpty else {
    return .Error(ReadError(.EmptyInputError))
  }
  var index = 0
  var wrapStack : [NextFormTreatment] = []

  /// Parse the entire top-level form and wrap it inside a reader macro.
  func createTopLevelReaderMacro(macroType: NextFormTreatment) -> ReadOptional<Value> {
    if tokens.count > 1 {
      var restTokens = tokens
      restTokens.removeAtIndex(0)
      return parse(restTokens, ctx).then { result in
        wrapStack.append(macroType)
        return .Just(wrappedConsItem(result, &wrapStack))
      }
    }
    return .Error(ReadError(.MismatchedReaderMacroError))
  }

  // Figure out how to parse
  switch tokens[0] {
  case let .Syntax(s):
    switch s {
    case .LeftParentheses:
      return listWithTokens(collectTokens(tokens, idx: &index, type: .List), ctx).then { .Just(.Seq($0)) }
    case .RightParentheses:
      return .Error(ReadError(.BadStartTokenError))
    case .LeftSquareBracket:
      return vectorWithTokens(collectTokens(tokens, idx: &index, type: .Vector), ctx).then { .Just(.Vector($0)) }
    case .RightSquareBracket:
      return .Error(ReadError(.BadStartTokenError))
    case .LeftBrace:
      return mapWithTokens(collectTokens(tokens, idx: &index, type: .Map), ctx).then { .Just(.Map($0)) }
    case .RightBrace:
      return .Error(ReadError(.BadStartTokenError))
    case .Quote:
      return createTopLevelReaderMacro(.Quote)
    case .Backquote:
      return createTopLevelReaderMacro(.SyntaxQuote)
    case .Tilde:
      return createTopLevelReaderMacro(.Unquote)
    case .TildeAt:
      return createTopLevelReaderMacro(.UnquoteSplice)
    case .At:
      return createTopLevelReaderMacro(.Deref)
    case .HashQuote:
      return createTopLevelReaderMacro(.Var)
    case .HashLeftBrace, .HashLeftParentheses, .HashUnderscore:
      // TODO: Implement support for all of these
      return .Error(ReadError(.UnimplementedFeatureError))
    }
  case .Nil:
    return .Just(.Nil)
  case let .CharLiteral(c):
    return .Just(.CharAtom(c))
  case let .StringLiteral(s):
    return .Just(.StringAtom(s))
  case let .RegexPattern(pattern):
    return constructRegex(pattern).then { .Just(.Auxiliary($0)) }
  case let .Integer(v):
    return .Just(.IntAtom(v))
  case let .FlPtNumber(n):
    return .Just(.FloatAtom(n))
  case let .Boolean(b):
    return .Just(.BoolAtom(b))
  case let .Keyword(k):
    return splitKeyword(k, currentNamespace: ctx.root).then { resultStruct in
      return .Just(.Keyword(InternedKeyword(resultStruct.name, namespace: resultStruct.namespace, ivs: ctx.ivs)))
    }
  case let .Identifier(sym):
    return splitSymbol(sym).then { resultStruct in
      return .Just(.Symbol(InternedSymbol(resultStruct.name, namespace: resultStruct.namespace, ivs: ctx.ivs)))
    }
  case let .Special(s):
    return .Just(.Special(s))
  case let .BuiltInFunction(b):
    return .Just(.BuiltInFunction(b))
  }
}


// MARK: Private helper functions

struct SymbolSplitResult {
  let name : String, namespace : String?
}

//typealias SplitResult = ReadOptional<(name: String, namespace: String?)>    // breaks compiler in Xcode 6.0
typealias SplitResult = ReadOptional<SymbolSplitResult>

/// Given a symbol which may or may not be qualified by a forward slash, return either the components or an error.
func splitSymbol(symbol: String) -> SplitResult {
  if symbol.characters.count < 2 {
    // Automatically accept one-character symbols
    return .Just(SymbolSplitResult(name: symbol, namespace: nil))
  }
  let parts = symbol.characters.split(1, allowEmptySlices: true) { $0 == "/" }.map { String($0) }
  precondition(parts.count <= 2, "Symbol string can only be split into a maximum of two components")

  if parts.count == 2 {
    if parts[0].isEmpty {
      return .Error(ReadError(.InvalidNamespaceError))
    }
    else if parts[1].isEmpty {
      return .Error(ReadError(.SymbolParseFailureError))
    }
    else {
      return .Just(SymbolSplitResult(name: parts[1], namespace: parts[0]))
    }
  }
  // Only one part
  return parts[0].isEmpty
    ? .Error(ReadError(.SymbolParseFailureError))
    : .Just(SymbolSplitResult(name: parts[0], namespace: nil))
}

/// Given a keyword which may or may not be qualified by a forward slash, return either the components or an error.
func splitKeyword(keyword: String, currentNamespace: NamespaceContext) -> SplitResult {
  precondition(keyword.isEmpty == false, "Raw keyword string to split cannot be empty")
  if keyword.characters.count == 1 {
    // Keyword is one character long
    return .Just(SymbolSplitResult(name: keyword, namespace: nil))
  }
  if keyword[keyword.startIndex] == ":" {
    // Keyword is qualified by "::"
    if keyword.characters.count < 2 {
      // Can't have a keyword consisting of just "::"
      return .Error(ReadError(.KeywordParseFailureError))
    }
    let name = keyword.substringFromIndex(keyword.startIndex.successor())
    return .Just(SymbolSplitResult(name: name, namespace: currentNamespace.name))
  }
  // TODO: Additional checking? Maybe when NSCharacterSet isn't as painful to use

  let parts = keyword.characters.split(1, allowEmptySlices: true) { $0 == "/" }.map { String($0) }
  precondition(parts.count <= 2, "Keyword string can only be split into a maximum of two components")
  if parts.count == 2 {
    if parts[0].isEmpty {
      return .Error(ReadError(.InvalidNamespaceError))
    }
    else if parts[1].isEmpty {
      return .Error(ReadError(.KeywordParseFailureError))
    }
    else {
      return .Just(SymbolSplitResult(name: parts[1], namespace: parts[0]))
    }
  }
  // Only one part
  return parts[0].isEmpty
    ? .Error(ReadError(.KeywordParseFailureError))
    : .Just(SymbolSplitResult(name: parts[0], namespace: nil))
}

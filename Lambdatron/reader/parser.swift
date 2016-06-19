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
  case none           // No special treatment
  case varForm
  case deref
  case quote          // Wrap next form with (quote)
  case syntaxQuote
  case unquote
  case unquoteSplice
}

/// Given an array containing all lexical tokens, a starting index, and a type of collection (list, vector, or map), go
/// through the array to collect and return all tokens that make up the collection whose left delimiter is found at the
/// starting index. This function also updates the index to the position immediately following the token which closes
/// the collection.
private func collect(tokens: [LexToken], idx: inout Int, type: TokenCollectionType) -> ReadOptional<[LexToken]> {
  // Arguments:
  // tokens: an array of all the LexTokens being currently processed
  // idx: an index into `tokens` describing the start of the collection (must be a '(', '[', or '{' token, and the start
  //  token must correspond to the `type` argument)
  // type: the type of collection that collectTokens should return: a list, vector, or map

  // Check validity of first token. The first token must match with the `type` argument passed in.
  switch tokens[idx] {
  case let x where x.isA(.leftParentheses) && type == .List: break
  case let x where x.isA(.leftSquareBracket) && type == .Vector: break
  case let x where x.isA(.leftBrace) && type == .Map: break
  default: return .Error(ReadError(.BadStartTokenError))
  }
  // The 'nesting level' of the delimiter token. For example, if we were processing a vector and we saw the tokens
  //  '[', '[', '[', ']', and '[', our nesting level would be 3. We use this to determine the end of the collection
  //  we're collecting tokens for.
  var count = 1
  var buffer : [LexToken] = []
  // Collect tokens
  for i in (idx + 1)..<tokens.count {
    idx = i
    let currentToken = tokens[i]
    switch currentToken {
    case let x where x.isA(.leftParentheses) && type == .List:
      count += 1
      buffer.append(currentToken)
    case let x where x.isA(.rightParentheses) && type == .List:
      count -= 1
      if count > 0 {
        buffer.append(currentToken)
      }
    case let x where x.isA(.leftSquareBracket) && type == .Vector:
      count += 1
      buffer.append(currentToken)
    case let x where x.isA(.rightSquareBracket) && type == .Vector:
      count -= 1
      if count > 0 {
        buffer.append(currentToken)
      }
    case let x where x.isA(.leftBrace) && type == .Map:
      count += 1
      buffer.append(currentToken)
    case let x where x.isA(.rightBrace) && type == .Map:
      count -= 1
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
private func wrappedConsItem(_ item: Value, _ wrapStack: inout [NextFormTreatment]) -> Value {
  // IMPORTANT: Note that this function will *modify* wrapStack by removing elements.
  let wrapType : NextFormTreatment = wrapStack.last ?? .none
  let wrappedItem : Value
  switch wrapType {
  case .none:
    wrappedItem = item
  case .varForm:
    wrappedItem = .seq(sequence(VAR, item))
  case .deref:
    wrappedItem = .seq(sequence(DEREF, item))
  case .quote:
    wrappedItem = .seq(sequence(QUOTE, item))
  case .syntaxQuote:
    wrappedItem = .readerMacroForm(ReaderMacro(type: .SyntaxQuote, form: item))
  case .unquote:
    wrappedItem = .readerMacroForm(ReaderMacro(type: .Unquote, form: item))
  case .unquoteSplice:
    wrappedItem = .readerMacroForm(ReaderMacro(type: .UnquoteSplice, form: item))
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
private func process(tokens: [LexToken], _ ctx: Context) -> ReadOptional<[Value]> {
  // For example: listWithTokens() is called with the tokens <(>, <1>, <true>, <)>. This function is called with the
  //  constituent tokens [<1>, <true>], and returns [Value.int(1), Value.bool(true)].
  var wrapStack : [NextFormTreatment] = []
  
  // Create a new Value array with all sub-structures properly processed
  var buffer : [Value] = []
  // The current LexToken we're processing
  var idx = 0
  while idx < tokens.count {
    let currentToken = tokens[idx]
    switch currentToken {
    case let .syntax(s):
      switch s {
      case .leftParentheses:
        // We've detected the start of a list. Use collectTokens() to turn all the tokens making up the list into an
        //  actual List, and advance the idx as well.
        let theList = list(with: collect(tokens: tokens, idx: &idx, type: .List), ctx)
        switch theList {
        case let .Just(list): buffer.append(wrappedConsItem(.seq(list), &wrapStack))
        case let .Error(f): return .Error(f)
        }
      case .rightParentheses:
        // Note that this should fail because anytime we see a left parentheses, we call listWithToken(), which consumes
        //  all tokens up to and including the corresponding right parentheses.
        return .Error(ReadError(.MismatchedDelimiterError))
      case .leftSquareBracket:
        let theVector = vector(with: collect(tokens: tokens, idx: &idx, type: .Vector), ctx)
        switch theVector {
        case let .Just(vector): buffer.append(wrappedConsItem(.vector(vector), &wrapStack))
        case let .Error(f): return .Error(f)
        }
      case .rightSquareBracket:
        return .Error(ReadError(.MismatchedDelimiterError))
      case .leftBrace:
        let theMap = map(with: collect(tokens: tokens, idx: &idx, type: .Map), ctx)
        switch theMap {
        case let .Just(map): buffer.append(wrappedConsItem(.map(map), &wrapStack))
        case let .Error(f): return .Error(f)
        }
      case .rightBrace:
        return .Error(ReadError(.MismatchedDelimiterError))
      case .quote:
        wrapStack.append(.quote)
      case .backquote:
        wrapStack.append(.syntaxQuote)
      case .tilde:
        wrapStack.append(.unquote)
      case .tildeAt:
        wrapStack.append(.unquoteSplice)
      case .at:
        wrapStack.append(.deref)
      case .hashQuote:
        wrapStack.append(.varForm)
      case .hashLeftBrace, .hashLeftParentheses, .hashUnderscore:
        // TODO: Implement support for all of these
        return .Error(ReadError(.UnimplementedFeatureError))
      }
    case .nilToken:
      buffer.append(wrappedConsItem(.nilValue, &wrapStack))
    case let .charLiteral(c):
      buffer.append(wrappedConsItem(.char(c), &wrapStack))
    case let .stringLiteral(s):
      buffer.append(wrappedConsItem(.string(s), &wrapStack))
    case let .regexPattern(s):
      switch constructRegex(s) {
      case let .Just(regex): buffer.append(wrappedConsItem(.auxiliary(regex), &wrapStack))
      case let .Error(error): return .Error(error)
      }
    case let .integer(v):
      buffer.append(wrappedConsItem(.int(v), &wrapStack))
    case let .flPtNumber(n):
      buffer.append(wrappedConsItem(.float(n), &wrapStack))
    case let .boolean(b):
      buffer.append(wrappedConsItem(.bool(b), &wrapStack))
    case let .keyword(k):
      switch split(keyword: k, currentNamespace: ctx.root) {
      case let .Just(resultStruct):
        let internedKeyword = InternedKeyword(resultStruct.name, namespace: resultStruct.namespace, ivs: ctx.ivs)
        buffer.append(wrappedConsItem(.keyword(internedKeyword), &wrapStack))
      case let .Error(err):
        return .Error(err)
      }
    case let .identifier(sym):
      switch split(symbol: sym) {
      case let .Just(resultStruct):
        let internedSymbol = InternedSymbol(resultStruct.name, namespace: resultStruct.namespace, ivs: ctx.ivs)
        buffer.append(wrappedConsItem(.symbol(internedSymbol), &wrapStack))
      case let .Error(err):
        return .Error(err)
      }
    case let .special(s):
      buffer.append(wrappedConsItem(.special(s), &wrapStack))
    case let .builtInFunction(bf):
      buffer.append(wrappedConsItem(.builtInFunction(bf), &wrapStack))
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
private func list(with tokens: ReadOptional<[LexToken]>, _ ctx: Context) -> ReadOptional<SeqType> {
  return tokens.then { tokens in
    // No tokens --> empty list ()
    return tokens.isEmpty
      ? .Just(Empty())
      : process(tokens: tokens, ctx).then { .Just(sequence(fromItems: $0)) }
  }
}

/// Given a list of tokens that corresponds to a single vector (e.g. <[>, <1>, <2>, <]>), build a Vector data structure.
private func vector(with tokens: ReadOptional<[LexToken]>, _ ctx: Context) -> ReadOptional<[Value]> {
  return tokens.then { tokens in
    // No tokens --> empty vector []
    return tokens.isEmpty
      ? .Just([])
      : process(tokens: tokens, ctx).then { .Just($0) }
  }
}

/// Given a list of tokens that corresponds to a single map (e.g. <{>, <:a>, <100>, <}>), build a Map data structure.
private func map(with tokens: ReadOptional<[LexToken]>, _ ctx: Context) -> ReadOptional<MapType> {
  return tokens.then { tokens in
    if tokens.isEmpty {
      // No tokens --> empty map {}
      return .Just([:])
    }
    return process(tokens: tokens, ctx).then { processedForms in
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
  func createTopLevelReaderMacro(_ macroType: NextFormTreatment) -> ReadOptional<Value> {
    if tokens.count > 1 {
      var restTokens = tokens
      restTokens.remove(at: 0)
      return parse(tokens: restTokens, ctx).then { result in
        wrapStack.append(macroType)
        return .Just(wrappedConsItem(result, &wrapStack))
      }
    }
    return .Error(ReadError(.MismatchedReaderMacroError))
  }

  // Figure out how to parse
  switch tokens[0] {
  case let .syntax(s):
    switch s {
    case .leftParentheses:
      return list(with: collect(tokens: tokens, idx: &index, type: .List), ctx).then { .Just(.seq($0)) }
    case .rightParentheses:
      return .Error(ReadError(.BadStartTokenError))
    case .leftSquareBracket:
      return vector(with: collect(tokens: tokens, idx: &index, type: .Vector), ctx).then { .Just(.vector($0)) }
    case .rightSquareBracket:
      return .Error(ReadError(.BadStartTokenError))
    case .leftBrace:
      return map(with: collect(tokens: tokens, idx: &index, type: .Map), ctx).then { .Just(.map($0)) }
    case .rightBrace:
      return .Error(ReadError(.BadStartTokenError))
    case .quote:
      return createTopLevelReaderMacro(.quote)
    case .backquote:
      return createTopLevelReaderMacro(.syntaxQuote)
    case .tilde:
      return createTopLevelReaderMacro(.unquote)
    case .tildeAt:
      return createTopLevelReaderMacro(.unquoteSplice)
    case .at:
      return createTopLevelReaderMacro(.deref)
    case .hashQuote:
      return createTopLevelReaderMacro(.varForm)
    case .hashLeftBrace, .hashLeftParentheses, .hashUnderscore:
      // TODO: Implement support for all of these
      return .Error(ReadError(.UnimplementedFeatureError))
    }
  case .nilToken:
    return .Just(.nilValue)
  case let .charLiteral(c):
    return .Just(.char(c))
  case let .stringLiteral(s):
    return .Just(.string(s))
  case let .regexPattern(pattern):
    return constructRegex(pattern).then { .Just(.auxiliary($0)) }
  case let .integer(v):
    return .Just(.int(v))
  case let .flPtNumber(n):
    return .Just(.float(n))
  case let .boolean(b):
    return .Just(.bool(b))
  case let .keyword(k):
    return split(keyword: k, currentNamespace: ctx.root).then { resultStruct in
      return .Just(.keyword(InternedKeyword(resultStruct.name, namespace: resultStruct.namespace, ivs: ctx.ivs)))
    }
  case let .identifier(sym):
    return split(symbol: sym).then { resultStruct in
      return .Just(.symbol(InternedSymbol(resultStruct.name, namespace: resultStruct.namespace, ivs: ctx.ivs)))
    }
  case let .special(s):
    return .Just(.special(s))
  case let .builtInFunction(b):
    return .Just(.builtInFunction(b))
  }
}


// MARK: Private helper functions

struct SymbolSplitResult {
  let name : String, namespace : String?
}

//typealias SplitResult = ReadOptional<(name: String, namespace: String?)>    // breaks compiler in Xcode 6.0
typealias SplitResult = ReadOptional<SymbolSplitResult>

/// Given a symbol which may or may not be qualified by a forward slash, return either the components or an error.
func split(symbol: String) -> SplitResult {
  if symbol.characters.count < 2 {
    // Automatically accept one-character symbols
    return .Just(SymbolSplitResult(name: symbol, namespace: nil))
  }
  let parts = symbol.characters.split(maxSplits: 1, omittingEmptySubsequences: false) { $0 == "/" }.map { String($0) }
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
func split(keyword: String, currentNamespace: NamespaceContext) -> SplitResult {
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
    let name = keyword.substring(from: keyword.index(after: keyword.startIndex))
    return .Just(SymbolSplitResult(name: name, namespace: currentNamespace.name))
  }
  // TODO: Additional checking? Maybe when NSCharacterSet isn't as painful to use

  let parts = keyword.characters.split(maxSplits: 1, omittingEmptySubsequences: false) { $0 == "/" }.map { String($0) }
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

//
//  readerforms.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/17/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An opaque struct describing a reader macro and the form upon which it operates.
public struct ReaderMacro {
  internal enum ReaderMacroType {
    case SyntaxQuote
    case Unquote
    case UnquoteSplice
  }
  let type : ReaderMacroType
  private let internalForm : Box<Value>
  var form : Value { return internalForm[] }

  internal init(type: ReaderMacroType, form: Value) {
    self.type = type; self.internalForm = Box(form)
  }

  internal func equals(_ that: ReaderMacro) -> Bool {
    return type == that.type && form == that.form
  }

  internal var hashValue : Int { return type.hashValue }

  // Note that this 'describe' function is only for use while debugging.
  func debugDescribe(_ ctx: Context?) -> String {
    switch type {
    case .SyntaxQuote: return "`" + form.describe(ctx).forceUnwrap()
    case .Unquote: return "~" + form.describe(ctx).forceUnwrap()
    case .UnquoteSplice: return "~@" + form.describe(ctx).forceUnwrap()
    }
  }
}

enum ExpandResult {
  case Success(Value)
  case Failure(ReadError)
}

private enum ListExpandResult {
  case Success(SeqType)
  case Failure(ReadError)

  func buildIntoFormUsing(_ f: (SeqType) -> SeqType) -> ExpandResult {
    switch self {
    case let .Success(s): return .Success(.seq(f(s)))
    case let .Failure(err): return .Failure(err)
    }
  }
}

/// A helper object that tracks state and translates symbols found within a syntax-quoted expression. Qualified symbols
/// are returned as-is, unqualified symbols suffixed by a '#' are transformed into gensyms (with every symbol with that
/// name resolving to the same gensym), and normal unqualified symbols are qualified within the current namespace.
private final class SymbolGensymHelper {
  let context : Context
  let namespaceName : String
  var mappings = [UnqualifiedSymbol : UnqualifiedSymbol]()

  /// Given a symbol, return the qualified symbol or gensym symbol that should replace it instead.
  func symbolOrGensym(for symbol: InternedSymbol) -> InternedSymbol {
    if symbol.isUnqualified {
      // Get symbol name
      let name = symbol.nameComponent(context)
      if name.characters.count > 1 && name[name.characters.indexOfLastCharacter] == "#" {
        // Translate the symbol into a gensym
        if let gensymSymbol = mappings[symbol.unqualified] {
          return gensymSymbol
        }
        else {
          let gensymSymbol = context.ivs.produceGensym(prefix: stringWithoutLastCharacter(name) + "__",
                                                       suffix: "__auto__")
          mappings[symbol.unqualified] = gensymSymbol
          return gensymSymbol
        }
      }
      else {
        // Return the qualified version of the symbol, namespaced to the current namespace
        return InternedSymbol(name, namespace: namespaceName, ivs: context.ivs)
      }
    }
    else {
      // Qualified symbols are returned verbatim
      return symbol
    }
  }

  init(context: Context) {
    self.context = context
    namespaceName = context.interpreter.currentNsName.asString(context.ivs)
  }
}

// Public API entry point
extension Context {
  func expand(_ value: Value) -> ExpandResult {
    return readerExpand(value)
  }
}

private enum ReaderHelpers {
  /// Construct a sequence out of a map.
  static func sequence(from map: MapType) -> SeqType {
    var head : SeqType = Empty()
    for (key, item) in map {
      let n2 = cons(item, next: head)
      let n1 = cons(key, next: n2)
      head = n1
    }
    return head
  }
}

private extension Context {
  /// Given a list (a b c) which forms the list part of the syntax-quoted form `(a b c ...), return the expansion.
  private func expand(syntaxQuotedList list: SeqType, _ helper: SymbolGensymHelper) -> ListExpandResult {
    guard case let .Just(listOfSymbols) = collectSymbols(list) else {
      // TODO: (az) any way to avoid the optional?
      internalError("Could not collect symbols...")
    }

    var b : [Value] = []    // each element corresponds to a list element after transformation
    for element in listOfSymbols {
      switch element {
      case .nilValue, .bool, .int, .float, .char, .string, .keyword, .symbol, .special, .builtInFunction, .auxiliary:
        // Atomic items are wrapped in 'list': ATOM --> (list ATOM)
        // Symbols, etc are wrapped in 'list' and 'quote': sym --> (list (quote sym))
        let result = expandSyntaxQuote(for: element, helper)
        switch result {
        case let .Success(expanded): b.append(.seq(sequence(LIST, expanded)))
        case let .Failure(err): return .Failure(err)
        }
      case let .readerMacroForm(rm):
        switch rm.type {
        case .SyntaxQuote:
          let e = expandSyntaxQuote(for: rm.form)
          switch e {
          case let .Success(expanded):
            b.append(.seq(sequence(LIST, expanded)))
          case let .Failure(err):
            return .Failure(err)
          }
        case .Unquote:
          b.append(.seq(sequence(LIST, rm.form)))
        case .UnquoteSplice:
          b.append(rm.form)
        }
      case .seq, .vector, .map:
        let e = expandSyntaxQuote(for: element, helper)
        switch e {
        case let .Success(expanded):
          b.append(.seq(sequence(LIST, expanded)))
        case let .Failure(err):
          return .Failure(err)
        }
      case .macroLiteral, .functionLiteral, .namespace, .`var`:
        // function literals should never show up at this stage in the pipeline
        return .Failure(ReadError(.IllegalExpansionFormError))
      }
    }

    return .Success(sequence(fromItems: b))
  }

  /// Given a list (e.g. (a b c)), return an expanded version of the list where each element has been expanded itself.
  private func expand(list seq: ContiguousList) -> ExpandResult {
    if seq.backingArray.isEmpty {
      // The list is empty, return the empty list
      return .Success(.seq(Empty()))
    }
    // The list isn't empty. Make a copy of the list, then expand each element in the copy.
    var copy = seq.backingArray
    for (idx, value) in copy.enumerated() {
      // Go through the list and expand each item in turn
      let expanded = readerExpand(value)
      switch expanded {
      case let .Success(expanded):
        copy[idx] = expanded
      case .Failure: return expanded
      }
    }
    return .Success(.seq(sequence(fromItems: copy)))
  }

  /// Given a vector (e.g. [a b c]), return an expanded version of the vector where each element has been expanded itself.
  func expand(vector: VectorType) -> ExpandResult {
    if vector.count == 0 {
      return .Success(.vector([]))
    }
    var copy : VectorType = vector
    for (idx, item) in vector.enumerated() {
      let result = readerExpand(item)
      switch result {
      case let .Success(expanded):
        copy[idx] = expanded
      case .Failure:
        return result
      }
    }
    return .Success(.vector(copy))
  }

  /// Given a map (e.g. {k1 v1}), return an expanded version of the map where all keys and values have been expanded.
  func expand(map hashmap: MapType) -> ExpandResult {
    var copy : MapType = [:]
    for (key, value) in hashmap {
      let expandedKey = readerExpand(key)
      switch expandedKey {
      case let .Success(expandedKey):
        let expandedValue = readerExpand(value)
        switch expandedValue {
        case let .Success(expandedValue): copy[expandedKey] = expandedValue
        case .Failure: return expandedValue
        }
      case .Failure: return expandedKey
      }
    }
    return .Success(.map(copy))
  }

  func expand(readerMacro rm: ReaderMacro) -> ExpandResult {
    // First, expand the form contained within the reader macro
    let result = readerExpand(rm.form)
    switch result {
    case let .Success(s):
      // Next, expand the form according to the reader macro, or wrap and pass back up the stack (if unquote,
      //  unquote-splice, etc)
      switch rm.type {
      case .SyntaxQuote:
        return expandSyntaxQuote(for: s)
      case .Unquote:
        return .Success(.readerMacroForm(ReaderMacro(type: .Unquote, form: s)))
      case .UnquoteSplice:
        return .Success(.readerMacroForm(ReaderMacro(type: .UnquoteSplice, form: s)))
      }
    case .Failure:
      return result
    }
  }

  // NOTE: This will be the top-level syntax quote reader expansion method. It operates on an entire expression, NOT on
  // just e.g. the wrapped expression within a reader-quote form.
  private func readerExpand(_ value: Value) -> ExpandResult {
    //    println("DBG: calling 'readerExpand' with item \(describe(nil))")
    switch value {
    case .nilValue, .bool, .int, .float, .char, .string, .symbol, .keyword, .auxiliary, .special, .builtInFunction:
      return .Success(value)
    case let .readerMacroForm(rm):
      // 'form' represents a reader macro (e.g. `X or ~X)
      return expand(readerMacro: rm)
    case let .seq(seq):
      // Note that seqs that come out of the parser must all be ContiguousLists.
      if let seq = seq as? ContiguousList {
        return expand(list: seq)
      }
      if seq.isEmpty.forceUnwrap() {
        return .Success(.seq(seq))
      }
      // Put the seq in a list.
      let rseq = ContiguousList.sequence(from: seq)
      switch rseq {
      // TODO: Make sure that this is handled properly.
      case let .Just(seq):
        if let seq = seq as? ContiguousList {
          return expand(list: seq)
        }
        else {
          internalError("All sequences created by the parser should be contiguous lists")
        }
      case .Error: internalError("There should be no lazy sequences at the reader macro expansion phase")
      }
    case let .vector(vector):
      return expand(vector: vector)
    case let .map(map):
      return expand(map: map)
    case .macroLiteral, .functionLiteral, .namespace, .`var`:
      return .Failure(ReadError(.IllegalExpansionFormError))
    }
  }

  /// When expanding an expression in the form `a, this method is called on 'a'; it returns (seq (concat a)).
  private func expandSyntaxQuote(for value: Value, _ helper: SymbolGensymHelper? = nil) -> ExpandResult {
    //    println("DBG: calling 'expandWhenWithinSyntaxQuote' with item \(describe(nil))")

    // NOTE: each syntax-quote requires a new helper. However, re-entrant calls in the context of evaluating the same
    //  logical syntax-quote should use the same helper. This is why the method takes an optional existing helper as an
    //  argument.
    let thisHelper = helper ?? SymbolGensymHelper(context: self)

    // ` differs in behavior depending on exactly what a is; it is most complex when a is a sequence
    switch value {
    case .nilValue, .bool, .int, .float, .char, .string, .keyword:
      // Expanding `LIT always results in LIT
      return .Success(value)
    case let .symbol(sym):
      // Expanding `a results in (quote ns/a); we must qualify the symbol if it's unqualified
      let symbol = thisHelper.symbolOrGensym(for: sym)
      return .Success(.seq(sequence(QUOTE, .symbol(symbol))))
    case .special, .builtInFunction, .auxiliary:
      // Expanding `a results in (quote a)
      return .Success(.seq(sequence(QUOTE, value)))
    case let .readerMacroForm(rm):
      switch rm.type {
      case .SyntaxQuote:
        return .Success(.seq(sequence(QUOTE, value)))
      case .Unquote:
        return .Success(rm.form)
      case .UnquoteSplice:
        return .Failure(ReadError(.UnquoteSpliceMisuseError))
      }
    case let .seq(s):
      // We have a list, e.g. `(a b c d e)
      // We need to reader-expand each individual a, b, c, then wrap it all in a (seq (cons X))
      if s.isEmpty.forceUnwrap() {
        // `() --> (list)
        return .Success(.seq(sequence(LIST)))
      }
      else {
        // `(a b c) = (seq (concat (a1 b1 c1)))
        let result = expand(syntaxQuotedList: s, thisHelper)
        return result.buildIntoFormUsing {
          sequence(SEQ, .seq(cons(CONCAT, next: $0)))
        }
      }
    case let .vector(vector):
      // Turn the syntax-quoted vector `[a b] into (apply (vector `(a b)))
      let result = expand(syntaxQuotedList: sequence(fromItems: vector), thisHelper)
      return result.buildIntoFormUsing {
        sequence(APPLY, VECTOR, .seq(sequence(SEQ, .seq(cons(CONCAT, next: $0)))))
      }
    case let .map(m):
      // Turn the syntax-quoted map `{a b} into (apply (map `(a b)))
      let result = expand(syntaxQuotedList: ReaderHelpers.sequence(from: m), thisHelper)
      return result.buildIntoFormUsing {
        sequence(APPLY, HASHMAP, .seq(sequence(SEQ, .seq(cons(CONCAT, next: $0)))))
      }
    case .macroLiteral, .functionLiteral, .namespace, .`var`:
      return .Failure(ReadError(.IllegalExpansionFormError))
    }
  }
}

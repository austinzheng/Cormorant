//
//  readerforms.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/17/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An opaque struct describing a reader macro and the form upon which it operates.
public struct ReaderMacro : Hashable {
  internal enum ReaderMacroType {
    case Quote
    case SyntaxQuote
    case Unquote
    case UnquoteSplice
  }
  let type : ReaderMacroType
  private let internalForm : Box<ConsValue>
  var form : ConsValue { return internalForm[] }

  internal init(type: ReaderMacroType, form: ConsValue) {
    self.type = type; self.internalForm = Box(form)
  }

  public var hashValue : Int { return type.hashValue }

  func describe(ctx: Context?) -> String {
    switch type {
    case .Quote: return "'" + form.describe(ctx).force()
    case .SyntaxQuote: return "`" + form.describe(ctx).force()
    case .Unquote: return "~" + form.describe(ctx).force()
    case .UnquoteSplice: return "~@" + form.describe(ctx).force()
    }
  }
}

enum ExpandResult {
  case Success(ConsValue)
  case Failure(ReadError)
}

private enum ListExpandResult {
  case Success(SeqType)
  case Failure(ReadError)
}

/// Given a map, translate it directly into a list.
private func seqFromMap(m: MapType) -> SeqType {
  var head : SeqType = Empty()
  for (key, item) in m {
    let n2 = cons(item, next: head)
    let n1 = cons(key, next: n2)
    head = n1
  }
  return head
}

private func constructForm(result: ListExpandResult, f: SeqType -> SeqType) -> ExpandResult {
  switch result {
  case let .Success(s): return .Success(.Seq(f(s)))
  case let .Failure(err): return .Failure(err)
  }
}

/// Given a list (a b c) which forms the list part of the syntax-quoted form `(a b c ...), return the expansion.
private func expandSyntaxQuotedList(list: SeqType) -> ListExpandResult {
  var b : [ConsValue] = []    // each element corresponds to a list element after transformation

  for element in collectSymbols(list).force() {
    switch element {
    case .Nil, .BoolAtom, .IntAtom, .FloatAtom, .CharAtom, .StringAtom, .Keyword:
      // Atomic items are wrapped in 'list': ATOM --> (list ATOM)
      b.append(.Seq(sequence(LIST, element)))
    case .Symbol, .Special, .BuiltInFunction, .Auxiliary:
      // Symbols, etc are wrapped in 'list' and 'quote': sym --> (list (quote sym))
      b.append(.Seq(sequence(LIST, .Seq(sequence(QUOTE, element)))))
    case let .ReaderMacroForm(rm):
      switch rm.type {
      case .Quote, .SyntaxQuote:
        let e = rm.form.expandSyntaxQuote()
        switch e {
        case let .Success(expanded):
          b.append(.Seq(sequence(LIST, expanded)))
        case let .Failure(err):
          return .Failure(err)
        }
      case .Unquote:
        b.append(.Seq(sequence(LIST, rm.form)))
      case .UnquoteSplice:
        b.append(rm.form)
      }
    case let .Seq, .Vector, .Map:
      let e = element.expandSyntaxQuote()
      switch e {
      case let .Success(expanded):
        b.append(.Seq(sequence(LIST, expanded)))
      case let .Failure(err):
        return .Failure(err)
      }
    case .FunctionLiteral:
      // function literals should never show up at this stage in the pipeline
      return .Failure(ReadError(.IllegalExpansionFormError))
    }
  }

  return .Success(sequence(b))
}

/// Given a list (e.g. (a b c)), return an expanded version of the list where each element has been expanded itself.
private func expandList(seq: ContiguousList) -> ExpandResult {
  if seq.backingArray.isEmpty {
    // The list is empty, return the empty list
    return .Success(.Seq(Empty()))
  }
  // The list isn't empty. Make a copy of the list, then expand each element in the copy.
  var copy = seq.backingArray
  for (idx, value) in enumerate(copy) {
    // Go through the list and expand each item in turn
    let expanded = value.readerExpand()
    switch expanded {
    case let .Success(expanded):
      copy[idx] = expanded
    case .Failure: return expanded
    }
  }
  return .Success(.Seq(sequence(copy)))
}

/// Given a vector (e.g. [a b c]), return an expanded version of the vector where each element has been expanded itself.
private func expandVector(vector: VectorType) -> ExpandResult {
  if vector.count == 0 {
    return .Success(.Vector([]))
  }
  var copy : VectorType = vector
  for (idx, item) in enumerate(vector) {
    let result = item.readerExpand()
    switch result {
    case let .Success(expanded):
      copy[idx] = expanded
    case .Failure:
      return result
    }
  }
  return .Success(.Vector(copy))
}

/// Given a map (e.g. {k1 v1}), return an expanded version of the map where all keys and values have been expanded.
private func expandMap(hashmap: MapType) -> ExpandResult {
  var copy : MapType = [:]
  for (key, value) in hashmap {
    let expandedKey = key.readerExpand()
    switch expandedKey {
    case let .Success(expandedKey):
      let expandedValue = value.readerExpand()
      switch expandedValue {
      case let .Success(expandedValue): copy[expandedKey] = expandedValue
      case .Failure: return expandedValue
      }
    case .Failure: return expandedKey
    }
  }
  return .Success(.Map(copy))
}

private func expandReaderMacro(rm: ReaderMacro) -> ExpandResult {
  // First, expand the form contained within the reader macro
  let result = rm.form.readerExpand()
  switch result {
  case let .Success(s):
    // Next, expand the form according to the reader macro, or wrap and pass back up the stack (if unquote,
    //  unquote-splice, etc)
    switch rm.type {
    case .Quote:
      return s.expandQuote()
    case .SyntaxQuote:
      return s.expandSyntaxQuote()
    case .Unquote:
      return .Success(.ReaderMacroForm(ReaderMacro(type: .Unquote, form: s)))
    case .UnquoteSplice:
      return .Success(.ReaderMacroForm(ReaderMacro(type: .UnquoteSplice, form: s)))
    }
  case .Failure:
    return result
  }
}


extension ConsValue {

  func expand() -> ExpandResult {
    return readerExpand()
  }

  // NOTE: This will be the top-level syntax quote reader expansion method. It operates on an entire expression, NOT on
  // just e.g. the wrapped expression within a reader-quote form.
  private func readerExpand() -> ExpandResult {
//    println("DBG: calling 'readerExpand' with item \(describe(nil))")
    switch self {
    case .Nil, .BoolAtom, .IntAtom, .FloatAtom, .CharAtom, .StringAtom, .Symbol, .Keyword, .Auxiliary, .Special, .BuiltInFunction:
      return .Success(self)
    case let .ReaderMacroForm(rm):
      // 'form' represents a reader macro (e.g. `X or ~X)
      return expandReaderMacro(rm)
    case let .Seq(seq):
      // Note that seqs that come out of the parser must all be ContiguousLists.
      if let seq = seq as? ContiguousList {
        return expandList(seq)
      }
      if seq.isEmpty.force() {
        return .Success(.Seq(seq))
      }
      // Put the seq in a list.
      let rseq = ContiguousList.fromSequence(seq)
      switch rseq {
      case let .Seq(seq): return expandList(seq as ContiguousList)
      case .Error: internalError("There should be no lazy sequences at the reader macro expansion phase")
      }
    case let .Vector(vector):
      return expandVector(vector)
    case let .Map(m):
      return expandMap(m)
    case .FunctionLiteral:
      return .Failure(ReadError(.IllegalExpansionFormError))
    }
  }

  // If we are expanding an expression 'a, we call this method on a; it'll give us back (quote a)
  private func expandQuote() -> ExpandResult {
    // Expanding 'a always results in (quote a)
    return .Success(.Seq(sequence(QUOTE, self)))
  }

  /// When expanding an expression in the form `a, this method is called on 'a'; it returns (seq (concat a)).
  private func expandSyntaxQuote() -> ExpandResult {
//    println("DBG: calling 'expandWhenWithinSyntaxQuote' with item \(describe(nil))")
    // ` differs in behavior depending on exactly what a is; it is most complex when a is a sequence
    switch self {
    case .Nil, .BoolAtom, .IntAtom, .FloatAtom, .CharAtom, .StringAtom, .Keyword:
      // Expanding `LIT always results in LIT
      return .Success(self)
    case .Symbol, .Special, .BuiltInFunction, .Auxiliary:
      // Expanding `a results in (quote a)
      return .Success(.Seq(sequence(QUOTE, self)))
    case let .ReaderMacroForm(rm):
      switch rm.type {
      case .Quote, .SyntaxQuote:
        return .Success(.Seq(sequence(QUOTE, self)))
      case .Unquote:
        return .Success(rm.form)
      case .UnquoteSplice:
        return .Failure(ReadError(.UnquoteSpliceMisuseError))
      }
    case let .Seq(s):
      // We have a list, e.g. `(a b c d e)
      // We need to reader-expand each individual a, b, c, then wrap it all in a (seq (cons X))
      if s.isEmpty.force() {
        // `() --> (list)
        return .Success(.Seq(sequence(LIST)))
      }
      else {
        // `(a b c) = (seq (concat (a1 b1 c1)))
        let result = expandSyntaxQuotedList(s)
        return constructForm(result) {
          sequence(SEQ, .Seq(cons(CONCAT, next: $0)))
        }
      }
    case let .Vector(vector):
      // Turn the syntax-quoted vector `[a b] into (apply (vector `(a b)))
      let result = expandSyntaxQuotedList(sequence(vector))
      return constructForm(result) {
        sequence(APPLY, VECTOR, .Seq(sequence(SEQ, .Seq(cons(CONCAT, next: $0)))))
      }
    case let .Map(m):
      // Turn the syntax-quoted map `{a b} into (apply (map `(a b)))
      let result = expandSyntaxQuotedList(seqFromMap(m))
      return constructForm(result) {
        sequence(APPLY, HASHMAP, .Seq(sequence(SEQ, .Seq(cons(CONCAT, next: $0)))))
      }
    case .FunctionLiteral:
      return .Failure(ReadError(.IllegalExpansionFormError))
    }
  }
}

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
    case .Quote: return "'" + form.describe(ctx)
    case .SyntaxQuote: return "`" + form.describe(ctx)
    case .Unquote: return "~" + form.describe(ctx)
    case .UnquoteSplice: return "~@" + form.describe(ctx)
    }
  }
}

enum ExpandResult {
  case Success(ConsValue)
  case Failure(ReadError)
}

private enum ListExpandResult {
  case Success(ListType<ConsValue>)
  case Failure(ReadError)
}

/// Given a map, translate it directly into a list.
private func listFromMap(m: MapType) -> ListType<ConsValue> {
  var head : ListType<ConsValue> = Empty()
  for (key, item) in m {
    let n2 = Cons(item, next: head)
    let n1 = Cons(key, next: n2)
    head = n1
  }
  return head
}

private func constructForm(result: ListExpandResult, f: ListType<ConsValue> -> ListType<ConsValue>) -> ExpandResult {
  switch result {
  case let .Success(s): return .Success(.List(f(s)))
  case let .Failure(err): return .Failure(err)
  }
}

/// Given a list (a b c) which forms the list part of the syntax-quoted form `(a b c ...), return the expansion.
private func expandSyntaxQuotedList(list: ListType<ConsValue>) -> ListExpandResult {
  var b : [ConsValue] = []    // each element corresponds to a list element after transformation

  for element in collectSymbols(list) {
    switch element {
    case .Nil, .BoolAtom, .IntAtom, .FloatAtom, .CharAtom, .StringAtom, .Keyword:
      // Atomic items are wrapped in 'list': ATOM --> (list ATOM)
      b.append(.List(Cons(.BuiltInFunction(.List), next: Cons(element))))
    case .Symbol, .Special, .BuiltInFunction, .Auxiliary:
      // Symbols, etc are wrapped in 'list' and 'quote': sym --> (list (quote sym))
      b.append(.List(Cons(.BuiltInFunction(.List),
        next: Cons(.List(Cons(.Special(.Quote), next: Cons(element)))))))
    case let .ReaderMacroForm(rm):
      switch rm.type {
      case .Quote, .SyntaxQuote:
        let e = rm.form.expandSyntaxQuote()
        switch e {
        case let .Success(expanded):
          b.append(.List(listFromItems(LIST, expanded)))
        case let .Failure(err):
          return .Failure(err)
        }
      case .Unquote:
        b.append(.List(listFromItems(LIST, rm.form)))
      case .UnquoteSplice:
        b.append(rm.form)
      }
    case let .List, .Vector, .Map:
      let e = element.expandSyntaxQuote()
      switch e {
      case let .Success(expanded):
        b.append(.List(listFromItems(LIST, expanded)))
      case let .Failure(err):
        return .Failure(err)
      }
    case .FunctionLiteral:
      // function literals should never show up at this stage in the pipeline
      return .Failure(ReadError(.IllegalExpansionFormError))
    }
  }

  return .Success(listFromCollection(b))
}

/// Given a list (e.g. (a b c)), return an expanded version of the list where each element has been expanded itself.
private func expandList(list: ListType<ConsValue>) -> ExpandResult {
  switch list {
  case let list as Cons<ConsValue>:
    // 1. The list is non-empty. Make a copy of the list, then expand each element in the copy.
    var head : ListType<ConsValue> = list.copy()
    for (value, node) in ValueNodeList(head) {
      // Go through the list and expand each item in turn.
      let expanded = value.readerExpand()
      switch expanded {
      case let .Success(expanded): node.value = expanded
      case .Failure: return expanded
      }
    }
    return .Success(.List(head))
  default:
    // 2: The list is empty; return the empty list.
    return .Success(.List(list))
  }
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
    case let .List(list):
      return expandList(list)
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
    return .Success(.List(listFromItems(QUOTE, self)))
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
      return .Success(.List(listFromItems(QUOTE, self)))
    case let .ReaderMacroForm(rm):
      switch rm.type {
      case .Quote, .SyntaxQuote:
        return .Success(.List(listFromItems(QUOTE, self)))
      case .Unquote:
        return .Success(rm.form)
      case .UnquoteSplice:
        return .Failure(ReadError(.UnquoteSpliceMisuseError))
      }
    case let .List(list):
      // We have a list, e.g. `(a b c d e)
      // We need to reader-expand each individual a, b, c, then wrap it all in a (seq (cons X))
      if list.isEmpty {
        // `() --> (list)
        return .Success(.List(listFromItems(LIST)))
      }
      else {
        // `(a b c) = (seq (concat (a1 b1 c1)))
        let result = expandSyntaxQuotedList(list)
        return constructForm(result) {
          listFromItems(SEQ, .List(Cons(CONCAT, next: $0)))
        }
      }
    case let .Vector(v):
      // Turn the syntax-quoted vector `[a b] into (apply (vector `(a b)))
      let asList = listFromCollection(v)
      let result = expandSyntaxQuotedList(asList)
      return constructForm(result) {
        listFromItems(APPLY, VECTOR, .List(Cons(SEQ, next: Cons(CONCAT, next: $0))))
      }
    case let .Map(m):
      // Turn the syntax-quoted map `{a b} into (apply (map `(a b)))
      let asList = listFromMap(m)
      let result = expandSyntaxQuotedList(asList)
      return constructForm(result) {
        listFromItems(APPLY, HASHMAP, .List(Cons(SEQ, next: Cons(CONCAT, next: $0))))
      }
    case .FunctionLiteral:
      return .Failure(ReadError(.IllegalExpansionFormError))
    }
  }
}

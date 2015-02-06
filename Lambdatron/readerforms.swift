//
//  readerforms.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/17/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An enum describing all the reader forms recognized by the interpreter.
public enum ReaderForm : Printable {
  case Quote
  case SyntaxQuote
  case Unquote
  case UnquoteSplice
  
  public var description : String {
    switch self {
    case Quote: return "q*"
    case SyntaxQuote: return "syntax-quote*"
    case Unquote: return "unquote*"
    case UnquoteSplice: return "unquote-splice*"
    }
  }
}

enum ExpandResult {
  case Success(ConsValue)
  case Failure(ReaderError)
  
  /// Either invoke the actual 'expandSyntaxQuotedItem' method, or pass an error through
  func expandSyntaxQuotedItem() -> ExpandResult {
    switch self {
    case let .Success(value): return value.expandSyntaxQuotedItem()
    case .Failure: return self
    }
  }
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

/// Given an ExpandResult and a function describing a form to construct if the result was successful, return an
/// ExpandResult with either the constructed form or a prior failure.
private func constructForm(result: ExpandResult, successForm: ConsValue -> ConsValue) -> ExpandResult {
  switch result {
  case let .Success(s): return .Success(successForm(s))
  case .Failure: return result
  }
}

/// Given a List<ConsValue>, return the list unpackaged as a reader form, or nil otherwise.
private func asReaderForm(list: ListType<ConsValue>) -> ReaderForm? {
  switch list {
  case let list as Cons<ConsValue>:
    switch list.value {
    case let .ReaderMacro(r): return r
    default: return nil
    }
  default: return nil
  }
}

private func isSyntaxQuote(list: Cons<ConsValue>) -> Bool {
  if let readerForm = asReaderForm(list) {
    switch readerForm {
    case .SyntaxQuote: return true
    default: return false
    }
  }
  return false
}

func expandListForSyntaxQuote(list: ListType<ConsValue>) -> ExpandResult {
  switch list {
  case let list as Cons<ConsValue>:
    // The list is not empty
    if let readerForm = asReaderForm(list) {
      // This list represents a reader macro call
      let next = list.next
      if let nextValue = next.getValue() {
        switch readerForm {
        case .Quote:
          // `('a ...) -> `((list `'a) ...)
          let quotedValue = nextValue.expandQuotedItem().expandSyntaxQuotedItem()
          return constructForm(quotedValue) { .List(Cons(.BuiltInFunction(.List), next: Cons($0))) }
        case .SyntaxQuote:
          // `(`a ...) --> `(`(list `a) ...)
          let quotedValue = nextValue.expandSyntaxQuotedItem()
          let f = quotedValue.expandSyntaxQuotedItem()
          return constructForm(f) { .List(Cons(.BuiltInFunction(.List), next: Cons($0))) }
        case .Unquote:
          // `(~a ...) --> `((list a) ...)
          return .Success(.List(Cons(.BuiltInFunction(.List), next: Cons(nextValue))))
        case .UnquoteSplice:
          // `(~@a ...) --> `(a ...)
          return .Success(nextValue)
        }
      }
      return .Failure(.UnmatchedReaderMacroError)
    }
    else {
      // This list is a normal list, recursively syntax-quote it further
      // `(a ...) --> `((list `a) ...)
      let result = ConsValue.List(list).expandSyntaxQuotedItem()
      return constructForm(result) { .List(Cons(.BuiltInFunction(.List), next: Cons($0))) }
    }
  default:
    // The list is empty
    return .Success(.List(Cons(.BuiltInFunction(.List))))
  }
}

extension ConsValue {
  
  // NOTE: This will be the top-level reader expansion method
  func readerExpand() -> ExpandResult {
    switch self {
    case Nil, BoolAtom, IntAtom, FloatAtom, CharAtom, StringAtom:
      return .Success(self)
    case Symbol, Keyword, Special, BuiltInFunction:
      return .Success(self)
    case let List(list):
      // Only if the list literal is encapsulating a reader macro form does anything happen
      switch list {
      case let list as Cons<ConsValue>:
        // CASE 1: The list itself is a reader macro (e.g. (` X), (~ X))
        if let readerForm = asReaderForm(list) {
          if let nextValue = list.next.getValue() {
            switch readerForm {
            case .Quote:
              return nextValue.expandQuotedItem()
            case .SyntaxQuote:
              return nextValue.expandSyntaxQuotedItem()
            case .Unquote:
              return .Success(nextValue)
            case .UnquoteSplice:
              // Not allowed
              return .Failure(.UnquoteSpliceMisuseError)
            }
          }
          return .Failure(.UnmatchedReaderMacroError)
        }
        // CASE 2: The list is NOT a reader macro invocation, and contains one or more items (e.g. (a1 a2 a3))
        var head : ListType<ConsValue> = list
        for (value, node) in ValueNodeList(list) {
          // Go through the list and expand each item in turn.
          let expanded = value.readerExpand()
          switch expanded {
          case let .Success(expanded): node.value = expanded
          case .Failure: return expanded
          }
        }
        return .Success(self)
      default:
        // The list is empty
        return .Success(self)
      }

    case let Vector(v):
      if v.count == 0 {
        return .Success(self)
      }
      var copy : VectorType = v
      for var i=0; i<v.count; i++ {
        let expanded = v[i].readerExpand()
        switch expanded {
        case let .Success(expanded):
          copy[i] = expanded
        case .Failure:
          return expanded
        }
      }
      return .Success(.Vector(copy))
    case let Map(m):
      var newMap : MapType = [:]
      for (key, value) in m {
        let expandedKey = key.readerExpand()
        switch expandedKey {
        case let .Success(expandedKey):
          let expandedValue = value.readerExpand()
          switch expandedValue {
          case let .Success(expandedValue): newMap[expandedKey] = expandedValue
          case .Failure: return expandedValue
          }
        case .Failure: return expandedKey
        }
      }
      return .Success(.Map(newMap))
    case FunctionLiteral, ReaderMacro:
      return .Failure(.IllegalFormError)
    }
  }
  
  // If we are expanding an expression (' a), we call this method on 'a'; it'll give us back (quote a)
  func expandQuotedItem() -> ExpandResult {
    // Expanding (' a) always results in (quote a)
    let expansion : ExpandResult = {
      switch self {
      case let .List(list):
        // 'a' is a list
        switch list {
        case let list as Cons<ConsValue>:
          // 'a' is non-empty: a = (b c d ...)
          if let readerForm = asReaderForm(list) {
            // The list 'a' is a reader macro expression itself and thus must be expanded recursively.
            if let nextValue = list.next.getValue() {
              switch readerForm {
              case .Quote:
                return nextValue.expandQuotedItem()
              case .SyntaxQuote:
                return nextValue.expandSyntaxQuotedItem()
              case .Unquote:
                return .Success(nextValue)
              case .UnquoteSplice:
                return .Failure(.UnquoteSpliceMisuseError)
              }
            }
            // 'a' is a single-element list with only a reader macro; this is an error (e.g. a = (')).
            return .Failure(.UnmatchedReaderMacroError)
          }
          // 'a' is non-empty but not a reader macro expression.
          return .Success(self)
        default:
          // 'a' is the empty list.
          return .Success(self)
        }
      default:
        // 'a' can be quoted directly, since it's not a list.
        return .Success(self)
      }
    }()
    return constructForm(expansion) { .List(Cons(.Special(.Quote), next: Cons($0))) }
  }

  func expandSyntaxQuotedList(list: ListType<ConsValue>) -> ExpandResult {
    // We have a list, such that we have (` (a b c d e))
    // We need to reader-expand each individual a, b, c, then wrap it all in a (seq (cons X))
    switch list {
    case let list as Cons<ConsValue>:
      // CASE 1: The list itself is a reader macro (e.g. (` X), (~ X))
      if let readerForm = asReaderForm(list) {
        if let nextValue = list.next.getValue() {
          switch readerForm {
          case .Quote:
            return nextValue.expandQuotedItem().expandSyntaxQuotedItem()
          case .SyntaxQuote:
            return nextValue.expandSyntaxQuotedItem().expandSyntaxQuotedItem()
          case .Unquote:
            return .Success(nextValue)
          case .UnquoteSplice:
            return .Failure(.UnquoteSpliceMisuseError)
          }
        }
        // Otherwise, the list is empty
        return .Failure(.UnmatchedReaderMacroError)
      }

      // CASE 2: The list is NOT a reader macro invocation, and contains one or more items (e.g. (a1 a2 a3))
      let symbols = collectSymbols(list)
      var expansionBuffer : [ConsValue] = []
      for symbol in symbols {
        switch symbol {
        case Nil, BoolAtom, IntAtom, FloatAtom, CharAtom, StringAtom, Symbol, Keyword, Special, BuiltInFunction:
          // A literal or symbol in the list is recursively syntax-quoted
          let expanded = symbol.expandSyntaxQuotedItem()
          switch expanded {
          case let .Success(expanded):
            expansionBuffer.append(.List(Cons(.BuiltInFunction(.List), next: Cons(expanded))))
          case .Failure:
            return expanded
          }
        case let List(symbolAsList):
          // A 'list' in the list could represent a normal list or a nested reader macro
          let expanded = expandListForSyntaxQuote(symbolAsList)
          switch expanded {
          case let .Success(expanded):
            expansionBuffer.append(expanded)
          case .Failure:
            return expanded
          }
        case Vector, Map:
          let expanded = symbol.expandSyntaxQuotedItem()
          switch expanded {
          case let .Success(expanded):
            expansionBuffer.append(.List(Cons(.BuiltInFunction(.List), next: Cons(expanded))))
          case .Failure:
            return expanded
          }
        case FunctionLiteral, ReaderMacro:
          return .Failure(.IllegalFormError)
        }
      }

      // Create the seq-concat list
      assert(expansionBuffer.count > 0,
        "Internal error: expansion buffer contained no items, even for a non-empty list")
      var head : ListType<ConsValue> = listFromCollection(expansionBuffer, prefix: .BuiltInFunction(.Concat))
      let finalHead : ListType<ConsValue> = Cons(.BuiltInFunction(.Seq),
        next: Cons(.List(head)))
      return .Success(.List(finalHead))

    default:
      // `() --> (list)
      return .Success(.List(Cons(.BuiltInFunction(.List))))
    }
  }

  /// When expanding an expression in the form (` a), this method is called on 'a'; it returns (seq (concat a)).
  func expandSyntaxQuotedItem() -> ExpandResult {
    // ` differs in behavior depending on exactly what a is; it is most complex when a is a sequence
    switch self {
    case Nil, BoolAtom, IntAtom, FloatAtom, CharAtom, StringAtom, Keyword:
      // Expanding (` LIT) always results in LIT
      return .Success(self)
    case Symbol, Special, BuiltInFunction:
      // Expanding (` a) results in (quote a)
      return .Success(.List(Cons(.Special(.Quote), next: Cons(self))))
    case let List(list):
      // We have a list, such that we have (` (a b c d e))
      // We need to reader-expand each individual a, b, c, then wrap it all in a (seq (cons X))
      return self.expandSyntaxQuotedList(list)
    case let Vector(v):
      let asList : ListType<ConsValue> = Cons(.ReaderMacro(.SyntaxQuote), next: Cons(.List(listFromCollection(v))))
      let expanded = ConsValue.List(asList).readerExpand()
      return constructForm(expanded) {
        .List(Cons(.Special(.Apply), next: Cons(.BuiltInFunction(.Vector), next: Cons($0))))
      }
    case let Map(m):
      let asList : ListType<ConsValue> = Cons(.ReaderMacro(.SyntaxQuote), next: Cons(.List(listFromMap(m))))
      let expanded = ConsValue.List(asList).readerExpand()
      return constructForm(expanded) {
        .List(Cons(.Special(.Apply), next: Cons(.BuiltInFunction(.Hashmap), next: Cons($0))))
      }
    case FunctionLiteral, ReaderMacro:
      return .Failure(.IllegalFormError)
    }
  }
}

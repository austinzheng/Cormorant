//
//  readerforms.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/17/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An opaque struct describing a reader macro and the form upon which it operates.
public struct ReaderMacro : Printable, Hashable {
  internal enum ReaderMacroType : String {
    case Quote = "*quote"
    case SyntaxQuote = "*syntax-quote"
    case Unquote = "*unquote"
    case UnquoteSplice = "*unquote-splice"
  }
  let type : ReaderMacroType
  private let internalForm : Box<ConsValue>
  var form : ConsValue { return internalForm[] }

  internal init(type: ReaderMacroType, form: ConsValue) {
    self.type = type; self.internalForm = Box(form)
  }

  public var hashValue : Int { return type.hashValue }
  public var description : String { return type.rawValue }
}

enum ExpandResult {
  case Success(ConsValue)
  case Failure(ReadError)

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

func expandSyntaxQuotedList(list: ListType<ConsValue>) -> ExpandResult {
  // We have a list, such that we have `(a b c d e)
  // We need to reader-expand each individual a, b, c, then wrap it all in a (seq (cons X))
  switch list {
  case let list as Cons<ConsValue>:
    // The list is NOT a reader macro invocation, and contains one or more items (e.g. (a1 a2 a3))
    let symbols = collectSymbols(list)
    var expansionBuffer : [ConsValue] = []
    for symbol in symbols {
      switch symbol {
      case .Nil, .BoolAtom, .IntAtom, .FloatAtom, .CharAtom, .StringAtom:
        fallthrough
      case .Regex, .Symbol, .Keyword, .Special, .BuiltInFunction:
        // A literal or symbol in the list is recursively syntax-quoted
        let expanded = symbol.expandSyntaxQuotedItem()
        switch expanded {
        case let .Success(expanded):
          expansionBuffer.append(.List(Cons(.BuiltInFunction(.List), next: Cons(expanded))))
        case .Failure:
          return expanded
        }
      case let .ReaderMacroForm(rm):
        let form = rm.form
        let expanded : ExpandResult = {
          switch rm.type {
          case .Quote:
            // `('a ...) -> `((list `'a) ...)
            let quotedValue = form.expandQuotedItem().expandSyntaxQuotedItem()
            return constructForm(quotedValue) { .List(Cons(.BuiltInFunction(.List), next: Cons($0))) }
          case .SyntaxQuote:
            // `(`a ...) --> `(`(list `a) ...)
            let quotedValue = form.expandSyntaxQuotedItem()
            let f = quotedValue.expandSyntaxQuotedItem()
            return constructForm(f) { .List(Cons(.BuiltInFunction(.List), next: Cons($0))) }
          case .Unquote:
            // `(~a ...) --> `((list a) ...)
            return .Success(.List(Cons(.BuiltInFunction(.List), next: Cons(form))))
          case .UnquoteSplice:
            // `(~@a ...) --> `(a ...)
            return .Success(form)
          }
          }()
        switch expanded {
        case let .Success(expanded):
          expansionBuffer.append(expanded)
        case .Failure:
          return expanded
        }
      case let .List(symbolAsList):
        let expanded : ExpandResult = {
          switch symbolAsList {
          case let symbolAsList as Cons<ConsValue>:
            // Recursively syntax-quote this non-empty list: `(a ...) --> `((list `a) ...)
            let result = ConsValue.List(symbolAsList).expandSyntaxQuotedItem()
            return constructForm(result) { .List(Cons(.BuiltInFunction(.List), next: Cons($0))) }
          default:
            // The list is empty: `() --> (list)
            return .Success(.List(Cons(.BuiltInFunction(.List))))
          }
          }()
        switch expanded {
        case let .Success(expanded):
          expansionBuffer.append(expanded)
        case .Failure:
          return expanded
        }
      case .Vector, .Map:
        let expanded = symbol.expandSyntaxQuotedItem()
        switch expanded {
        case let .Success(expanded):
          expansionBuffer.append(.List(Cons(.BuiltInFunction(.List), next: Cons(expanded))))
        case .Failure:
          return expanded
        }
      case .FunctionLiteral:
        return .Failure(ReadError(.IllegalFormError))
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

extension ConsValue {
  
  // NOTE: This will be the top-level syntax quote reader expansion method
  func readerExpand() -> ExpandResult {
    switch self {
    case .Nil, .BoolAtom, .IntAtom, .FloatAtom, .CharAtom, .StringAtom:
      return .Success(self)
    case .Regex, .Symbol, .Keyword, .Special, .BuiltInFunction:
      return .Success(self)
    case let .ReaderMacroForm(rm):
      // 'form' represents a reader macro (e.g. `X or ~X)
      let form = rm.form
      switch rm.type {
      case .Quote:
        return form.expandQuotedItem()
      case .SyntaxQuote:
        return form.expandSyntaxQuotedItem()
      case .Unquote:
        return .Success(form)
      case .UnquoteSplice:
        // Not allowed
        return .Failure(ReadError(.UnquoteSpliceMisuseError))
      }
    case let .List(list):
      // Only if the list literal is encapsulating a reader macro form does anything happen
      switch list {
      case let list as Cons<ConsValue>:
        // The list is NOT a reader macro invocation, and contains one or more items (e.g. (a1 a2 a3))
        var head : ListType<ConsValue> = list
        // The list is NOT a reader macro invocation, and contains one or more items (e.g. (a1 a2 a3))
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
    case let .Vector(v):
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
    case let .Map(m):
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
    case .FunctionLiteral:
      return .Failure(ReadError(.IllegalFormError))
    }
  }
  
  // If we are expanding an expression 'a, we call this method on 'a'; it'll give us back (quote a)
  func expandQuotedItem() -> ExpandResult {
    // Expanding 'a always results in (quote a)
    let expansion : ExpandResult = {
      switch self {
      case .ReaderMacroForm:
        // The reader macro expression must be expanded recursively.
        return self.readerExpand()
      case let .List(list):
        // 'a' is a list
        switch list {
        case let list as Cons<ConsValue>:
          // 'a' is non-empty: a = (b c d ...)
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

  /// When expanding an expression in the form `a, this method is called on 'a'; it returns (seq (concat a)).
  func expandSyntaxQuotedItem() -> ExpandResult {
    // ` differs in behavior depending on exactly what a is; it is most complex when a is a sequence
    switch self {
    case .Nil, .BoolAtom, .IntAtom, .FloatAtom, .CharAtom, .StringAtom, .Keyword:
      // Expanding `LIT always results in LIT
      return .Success(self)
    case .Regex, .Symbol, .Special, .BuiltInFunction:
      // Expanding `a results in (quote a)
      return .Success(.List(Cons(.Special(.Quote), next: Cons(self))))
    case let .ReaderMacroForm(rm):
      // Recursively expand the inner reader macro.
      let form = rm.form
      switch rm.type {
      case .Quote:
        return form.expandQuotedItem().expandSyntaxQuotedItem()
      case .SyntaxQuote:
        return form.expandSyntaxQuotedItem().expandSyntaxQuotedItem()
      case .Unquote:
        return .Success(form)
      case .UnquoteSplice:
        return .Failure(ReadError(.UnquoteSpliceMisuseError))
      }
    case let .List(list):
      // We have a list, e.g. `(a b c d e)
      // We need to reader-expand each individual a, b, c, then wrap it all in a (seq (cons X))
      return expandSyntaxQuotedList(list)
    case let .Vector(v):
      let asList = listFromCollection(v)
      let expanded = ConsValue.ReaderMacroForm(ReaderMacro(type: .SyntaxQuote, form: .List(asList))).readerExpand()
      return constructForm(expanded) {
        .List(Cons(.Special(.Apply), next: Cons(.BuiltInFunction(.Vector), next: Cons($0))))
      }
    case let .Map(m):
      let asList = listFromMap(m)
      let expanded = ConsValue.ReaderMacroForm(ReaderMacro(type: .SyntaxQuote, form: .List(asList))).readerExpand()
      return constructForm(expanded) {
        .List(Cons(.Special(.Apply), next: Cons(.BuiltInFunction(.Hashmap), next: Cons($0))))
      }
    case .FunctionLiteral:
      return .Failure(ReadError(.IllegalFormError))
    }
  }
}

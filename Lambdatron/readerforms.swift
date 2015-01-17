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

/// Given an ExpandResult and a function describing a form to construct if the result was successful, return an
/// ExpandResult with either the constructed form or a prior failure.
private func constructForm(result: ExpandResult, successForm: ConsValue -> ConsValue) -> ExpandResult {
  switch result {
  case let .Success(s): return .Success(successForm(s))
  case .Failure: return result
  }
}

extension Cons {
  
  var isSyntaxQuote : Bool {
    if let readerForm = self.asReaderForm() {
      switch readerForm {
      case .SyntaxQuote: return true
      default: return false
      }
    }
    return false
  }

  // NOTE: this is ONLY called when `(a1 a2 a3 a4) is evaluated, when a_n is a list. This method determines whether
  //  or not this is a normal list, or a special item.
  // e.g. `(~a ...), which is actually `((~ a) ...); a_n would be the (~ a) sub-list (NOT the overall list being
  // syntax-quoted)
  func expansionForSyntaxQuote() -> ExpandResult {
    if let readerForm = self.asReaderForm() {
      // This list represents a reader macro call
      if let nextValue = next?.value {
        switch readerForm {
        case .Quote:
          // `('a ...) -> `((list `'a) ...)
          let quotedValue = nextValue.expandQuotedItem().expandSyntaxQuotedItem()
          return constructForm(quotedValue) { .ListLiteral(Cons(.BuiltInFunction(.List), next: Cons($0))) }
        case .SyntaxQuote:
          // `(`a ...) --> `(`(list `a) ...)
          let quotedValue = nextValue.expandSyntaxQuotedItem()
          let f = quotedValue.expandSyntaxQuotedItem()
          return constructForm(f) { .ListLiteral(Cons(.BuiltInFunction(.List), next: Cons($0))) }
        case .Unquote:
          // `(~a ...) --> `((list a) ...)
          return .Success(.ListLiteral(Cons(.BuiltInFunction(.List), next: Cons(nextValue))))
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
      if isEmpty {
        return .Success(.ListLiteral(Cons(.BuiltInFunction(.List))))
      }
      let result = ConsValue.ListLiteral(self).expandSyntaxQuotedItem()
      return constructForm(result) { .ListLiteral(Cons(.BuiltInFunction(.List), next: Cons($0))) }
    }
  }
}

extension ConsValue {
  
  var isNone : Bool {
    switch self {
    case .None: return true
    default: return false
    }
  }
  
  // NOTE: This will be the top-level reader expansion method
  func readerExpand() -> ExpandResult {
    switch self {
    case NilLiteral, BoolLiteral, IntegerLiteral, FloatLiteral, CharacterLiteral, StringLiteral, None:
      return .Success(self)
    case Symbol, Keyword, Special, BuiltInFunction:
      return .Success(self)
    case let ListLiteral(l):
      // Only if the list literal is encapsulating a reader macro form does anything happen
      // CASE 1: The list itself is a reader macro (e.g. (` X), (~ X))
      if let readerForm = l.asReaderForm() {
        if let next = l.next {
          switch readerForm {
          case .Quote:
            return next.value.expandQuotedItem()
          case .SyntaxQuote:
            return next.value.expandSyntaxQuotedItem()
          case .Unquote:
            return .Success(next.value)
          case .UnquoteSplice:
            // Not allowed
            return .Failure(.UnquoteSpliceMisuseError)
          }
        }
        return .Failure(.UnmatchedReaderMacroError)
      }
      // CASE 2: The list is NOT a reader macro invocation, and contains one or more items (e.g. (a1 a2 a3))
      var head : Cons? = l
      while let actualHead = head {
        let expanded = actualHead.value.readerExpand()
        switch expanded {
        case let .Success(expanded):
          actualHead.value = expanded
          head = actualHead.next
        case .Failure:
          return expanded
        }
      }
      return .Success(self)
    case let VectorLiteral(v):
      if v.count == 0 {
        return .Success(self)
      }
      var copy : Vector = v
      for var i=0; i<v.count; i++ {
        let expanded = v[i].readerExpand()
        switch expanded {
        case let .Success(expanded):
          copy[i] = expanded
        case .Failure:
          return expanded
        }
      }
      return .Success(.VectorLiteral(copy))
    case let MapLiteral(m):
      var newMap : Map = [:]
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
      return .Success(.MapLiteral(newMap))
    case FunctionLiteral, ReaderMacro:
      return .Failure(.IllegalFormError)
    }
  }
  
  // If we are expanding an expression (' a), we call this method on 'a'; it'll give us back (quote a)
  func expandQuotedItem() -> ExpandResult {
    // Expanding (' a) always results in (quote a)
    let expansion : ExpandResult = {
      switch self {
      case let .ListLiteral(l) where !l.isEmpty:
        if let readerForm = l.asReaderForm() {
          if let next = l.next {
            switch readerForm {
            case .Quote:
              return next.value.expandQuotedItem()
            case .SyntaxQuote:
              return next.value.expandSyntaxQuotedItem()
            case .Unquote:
              return .Success(next.value)
            case .UnquoteSplice:
              return .Failure(.UnquoteSpliceMisuseError)
            }
          }
          return .Failure(.UnmatchedReaderMacroError)
        }
        return .Success(self)
      default:
        return .Success(self)
      }
    }()
    return constructForm(expansion) { .ListLiteral(Cons(.Special(.Quote), next: Cons($0))) }
  }
  
  // If we are expanding an expression (` a), we call this method on 'a'; it'll give us back (seq (concat a))
  func expandSyntaxQuotedItem() -> ExpandResult {
    // ` differs in behavior depending on exactly what a is; it is most complex when a is a sequence
    switch self {
    case NilLiteral, BoolLiteral, IntegerLiteral, FloatLiteral, CharacterLiteral, StringLiteral, Keyword:
      // Expanding (` LIT) always results in LIT
      return .Success(self)
    case Symbol, Special, BuiltInFunction:
      // Expanding (` a) results in (quote a)
      return .Success(.ListLiteral(Cons(.Special(.Quote), next: Cons(self))))
    case let ListLiteral(l):
      // We have a list, such that we have (` (a b c d e))
      // We need to reader-expand each individual a, b, c, then wrap it all in a (seq (cons X))
      if l.isEmpty {
        // `() --> (list)
        return .Success(.ListLiteral(Cons(.BuiltInFunction(.List))))
      }
      // CASE 1: The list itself is a reader macro (e.g. (` X), (~ X))
      if let readerForm = l.asReaderForm() {
        if let next = l.next {
          switch readerForm {
          case .Quote:
            return next.value.expandQuotedItem().expandSyntaxQuotedItem()
          case .SyntaxQuote:
            return next.value.expandSyntaxQuotedItem().expandSyntaxQuotedItem()
          case .Unquote:
            return .Success(next.value)
          case .UnquoteSplice:
            return .Failure(.UnquoteSpliceMisuseError)
          }
        }
        return .Failure(.UnmatchedReaderMacroError)
      }
      
      // CASE 2: The list is NOT a reader macro invocation, and contains one or more items (e.g. (a1 a2 a3))
      let symbols = Cons.collectSymbols(l)
      var expansionBuffer : [ConsValue] = []
      for symbol in symbols {
        switch symbol {
        case NilLiteral, BoolLiteral, IntegerLiteral, FloatLiteral, CharacterLiteral, StringLiteral, Symbol, Keyword, Special, BuiltInFunction:
          // A literal or symbol in the list is recursively syntax-quoted
          let expanded = symbol.expandSyntaxQuotedItem()
          switch expanded {
          case let .Success(expanded):
            expansionBuffer.append(.ListLiteral(Cons(.BuiltInFunction(.List), next: Cons(expanded))))
          case .Failure:
            return expanded
          }
        case let ListLiteral(symbolAsList):
          // A 'list' in the list could represent a normal list or a nested reader macro
          let expanded = symbolAsList.expansionForSyntaxQuote()
          switch expanded {
          case let .Success(expanded):
            expansionBuffer.append(expanded)
          case .Failure:
            return expanded
          }
        case VectorLiteral, MapLiteral:
          let expanded = symbol.expandSyntaxQuotedItem()
          switch expanded {
          case let .Success(expanded):
            expansionBuffer.append(.ListLiteral(Cons(.BuiltInFunction(.List), next: Cons(expanded))))
          case .Failure:
            return expanded
          }
        case FunctionLiteral, ReaderMacro, None:
          return .Failure(.IllegalFormError)
        }
      }
      // Create the seq-concat list
      let concatHead = Cons(.BuiltInFunction(.Concat))
      var this = concatHead
      for bufferItem in expansionBuffer {
        let next = Cons(bufferItem)
        this.next = next
        this = next
      }
      let seqHead = Cons(.BuiltInFunction(.Seq), next: Cons(.ListLiteral(concatHead)))
      return .Success(.ListLiteral(seqHead))
    case let VectorLiteral(v):
      let asList = Cons(.ReaderMacro(.SyntaxQuote), next: Cons(.ListLiteral(Cons.listFromVector(v))))
      let expanded = ConsValue.ListLiteral(asList).readerExpand()
      return constructForm(expanded) {
        .ListLiteral(Cons(.Special(.Apply), next: Cons(.BuiltInFunction(.Vector), next: Cons($0))))
      }
    case let MapLiteral(m):
      let asList = Cons(.ReaderMacro(.SyntaxQuote), next: Cons(.ListLiteral(Cons.listFromMap(m))))
      let expanded = ConsValue.ListLiteral(asList).readerExpand()
      return constructForm(expanded) {
        .ListLiteral(Cons(.Special(.Apply), next: Cons(.BuiltInFunction(.Hashmap), next: Cons($0))))
      }
    case FunctionLiteral, ReaderMacro, None:
      return .Failure(.IllegalFormError)
    }
  }
}

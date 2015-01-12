//
//  core.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

typealias Vector = [ConsValue]
typealias Map = [ConsValue:ConsValue]

/// Represents a cons cell, an element in a linked list.
class Cons : Hashable {
  var next : Cons?
  var value : ConsValue
  
  var hashValue : Int {
    return value.hashValue
  }
  
  // MARK: Initializers
  
  class func listFromVector(v: Vector) -> Cons {
    if v.count == 0 {
      return Cons()
    }
    let head = Cons(v[0])
    var this = head
    for var i=1; i<v.count; i++ {
      let next = Cons(v[i])
      this.next = next
      this = next
    }
    return head
  }
  
  class func listFromMap(m: Map) -> Cons {
    if m.count == 0 {
      return Cons()
    }
    var head : Cons? = nil
    var this = head
    for (key, item) in m {
      let n2 = Cons(item)
      let n1 = Cons(key, next: n2)
      if let this = this {
        this.next = n1
      }
      else {
        // First key-value pair; need to set up head
        head = n1
      }
      this = n2
    }
    return head!
  }
  
  /// Create an empty list.
  init() {
    self.next = nil
    self.value = .None
  }
  
  /// Create a single-element list with a single item.
  init(_ value: ConsValue) {
    self.next = nil
    self.value = value
  }
  
  /// Create a list with a given value and another Cons cell following it.
  init(_ value: ConsValue, next: Cons?) {
    self.next = next
    self.value = value
  }
  
  /// Whether or not this list is the empty list ().
  var isEmpty : Bool {
    if next != nil {
      return false
    }
    switch value {
    case .None: return true
    default: return false
    }
  }
  
  func asSpecialForm() -> SpecialForm? {
    switch value {
    case let .Special(sf): return sf
    default: return nil
    }
  }
  
  func asReaderForm() -> ReaderForm? {
    switch value {
    case let .ReaderMacro(rf): return rf
    default: return nil
    }
  }
  
  func asMacro(ctx: Context) -> Macro? {
    switch value {
    case let .Symbol(identifier):
      let symbolValue = ctx[identifier]
      switch symbolValue {
      case let .BoundMacro(m): return m
      case .Invalid, .Unbound, .Param, .Literal: return nil
      }
    default: return nil
    }
  }
  
  /// Collect the evaluated values of all cells within a list, starting from a given first item. This method is intended
  /// to perform argument evaluation as part of the process of calling a function.
  class func collectValues(firstItem : Cons?, _ ctx: Context) -> CollectResult {
    var buffer : [ConsValue] = []
    var currentItem : Cons? = firstItem
    while let actualItem = currentItem {
      let thisValue = actualItem.value
      switch thisValue.evaluate(ctx) {
      case let .Success(result):
        if result.isRecurSentinel {
          // Cannot use 'recur' as a function argument
          return .Failure(.RecurMisuseError)
        }
        buffer.append(result)
      case let .Failure(f): return .Failure(f)
      }
      currentItem = actualItem.next
    }
    return .Success(buffer)
  }
  
  /// Collect the literal values of all cells within a list, starting from a given first item. This method is intended
  /// to collect symbols as part of the process of calling a macro or special form.
  class func collectSymbols(firstItem: Cons?) -> [ConsValue] {
    var symbolBuffer : [ConsValue] = []
    var currentItem : Cons? = firstItem
    while let actualItem = currentItem {
      let value = actualItem.value
      switch value {
      case .None: break
      default: symbolBuffer.append(actualItem.value)
      }
      currentItem = actualItem.next
    }
    return symbolBuffer
  }
}

/// Represents the value of an item in a single cons cell. ConsValues are comprised of atoms, collections, and sentinel
/// values (which should never leak into a normal evaluation context).
enum ConsValue : Hashable {
  case None
  case Symbol(InternedSymbol)
  case Keyword(InternedKeyword)
  case Special(SpecialForm)
  case BuiltInFunction(BuiltIn)
  case ReaderMacro(ReaderForm)
  case NilLiteral
  case BoolLiteral(Bool)
  case IntegerLiteral(Int)
  case FloatLiteral(Double)
  case CharacterLiteral(Character)
  case StringLiteral(String)
  case ListLiteral(Cons)
  case VectorLiteral(Vector)
  case MapLiteral(Map)
  case FunctionLiteral(Function)
  // A special sentinel case only to be used by the 'recur' special form. Its contents are new bindings.
  case RecurSentinel([ConsValue])
  
  var hashValue : Int {
    switch self {
    case None: return 0
    case let Symbol(s): return s.hashValue
    case let Keyword(k): return k.hashValue
    case let Special(sf): return sf.hashValue
    case let BuiltInFunction(bf): return bf.hashValue
    case let ReaderMacro(rf): return rf.hashValue
    case NilLiteral: return 0
    case let BoolLiteral(b): return b.hashValue
    case let IntegerLiteral(v): return v.hashValue
    case let FloatLiteral(d): return d.hashValue
    case let CharacterLiteral(c): return c.hashValue
    case let StringLiteral(s): return s.hashValue
    case let ListLiteral(l): return l.hashValue
    case let VectorLiteral(v): return v.count == 0 ? 0 : v[0].hashValue
    case let MapLiteral(m): return m.count
    case let FunctionLiteral(f): return 0
    case RecurSentinel: return 0
    }
  }
  
  func asInteger() -> Int? {
    switch self {
    case let .IntegerLiteral(v): return v
    default: return nil
    }
  }
  
  func asStringLiteral() -> String? {
    switch self {
    case let .StringLiteral(s): return s
    default: return nil
    }
  }
  
  func asSymbol() -> InternedSymbol? {
    switch self {
    case let .Symbol(s): return s
    default: return nil
    }
  }
  
  func asList() -> Cons? {
    switch self {
    case let .ListLiteral(l): return l
    default: return nil
    }
  }
  
  func asVector() -> Vector? {
    switch self {
    case let .VectorLiteral(v): return v
    default: return nil
    }
  }
  
  func asMap() -> Map? {
    switch self {
    case let .MapLiteral(m): return m
    default: return nil
    }
  }
  
  func asBuiltIn() -> LambdatronBuiltIn? {
    switch self {
    case let .BuiltInFunction(b): return b.function
    default: return nil
    }
  }
  
  func asFunction() -> Function? {
    switch self {
    case let .FunctionLiteral(f): return f
    default: return nil
    }
  }
  
  var isRecurSentinel : Bool {
    switch self {
    case .RecurSentinel: return true
    default: return false
    }
  }
}

//
//  ds.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

class Cons : Printable {
  var next : Cons?
  var value : ConsValue

  func asFunction() -> LambdatronFunction? {
    // TODO: This should accept closure type literals in the future as well
    switch value {
    case let .Variable(vname):
      let vExpr = TEMPORARY_globalContext[vname]
      switch vExpr {
      case .Invalid: return nil
      case .Literal: return nil
      case let .Function(f): return f
      }
    case .Literal:
      return nil
    case .None:
      fatal("Internal error")
    }
  }

  init() {
    self.next = nil
    self.value = .None
  }

  convenience init(_ value: ConsValue) {
    self.init(next: nil, value: value)
  }

  init(next: Cons?, value: ConsValue) {
    self.next = next
    self.value = value
  }

  func collectSymbols(symbols: [ConsValue]) -> [ConsValue] {
    let newSymbols = Array(symbols, appendedItem: value);
    if let nextItem = next {
      return nextItem.collectSymbols(newSymbols)
    }
    return newSymbols
  }

  func evaluate() -> LiteralValue {
    // First: is the item in the head actually a function type object?
    if let toExecuteFunction = asFunction() {
      var symbols = next?.collectSymbols([]) ?? []
      let result = toExecuteFunction(symbols)
      // TODO: Change function signature to accomodate returning closures (eventually)
      switch result {
      case .Variable: fatal("Something went wrong")
      case let .Literal(literalValue): return literalValue
      case .None: fatal("Internal error")
      }
    }
    fatal("Cannot call 'evaluate' on this cons list; first object isn't actually a function. Sorry.")
  }

  func collectDescriptions(descs: [String]) -> [String] {
    let newDescs = Array(descs, appendedItem: value.description)
    if let nextItem = next {
      return nextItem.collectDescriptions(newDescs)
    }
    return newDescs
  }

  var description : String {
    get {
      let rawDescs = collectDescriptions([])
      let finalDesc = join(" ", rawDescs)
      return "(\(finalDesc))"
    }
  }
}

/// Represents the value of an item in a single cons cell; either a variable or a literal of some sort
enum ConsValue : Printable {
  case Variable(String)
  case Literal(LiteralValue)
  case None

  var description : String {
    get {
      switch self {
      case let Variable(s): return s
      case let Literal(v): return v.description
      case None: return "<error>"
      }
    }
  }
}

/// Represents a literal value found within a ConsValue
enum LiteralValue : Printable {
  case NilLiteral
  case BoolLiteral(Bool)
  case NumberLiteral(Double)
  case StringLiteral(String)
  case List(Cons)
  case Vector([ConsValue])

  var isFalsy : Bool {
    get {
      switch self {
      case NilLiteral: return true
      case let BoolLiteral(b): return b == false
      case let NumberLiteral(n): return n == 0
      case let StringLiteral(s): return NSString(string: s).length == 0
      case List: return false
      case let Vector(v): return v.count == 0
      }
    }
  }

  var description : String {
    get {
      switch self {
      case NilLiteral: return "nil"
      case let BoolLiteral(b): return b.description
      case let NumberLiteral(n): return n.description
      case let StringLiteral(s): return "\"\(s)\""
      case let List(l): return l.description
      case let Vector(v): return "Vector"
      }
    }
  }
}

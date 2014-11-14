//
//  core.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// Represents a cons cell, an element in a linked list
class Cons : Printable {
  var next : Cons?
  var value : ConsValue
  
  // MARK: Initializers
  
  /// Create an empty list
  init() {
    self.next = nil
    self.value = .None
  }
  
  /// Create a list with a single item
  init(_ value: ConsValue) {
    self.next = nil
    self.value = value
  }
  
  init(_ value: ConsValue, next: Cons?) {
    self.next = next
    self.value = value
  }
  
  // MARK: API
  
  var isEmpty : Bool {
    if next != nil {
      return false
    }
    switch value {
    case .None: return true
    default: return false
    }
  }

  func asBuiltIn(ctx: Context) -> LambdatronBuiltIn? {
    switch value {
    case let .Symbol(vname):
      let vExpr = ctx[vname]
      switch vExpr {
      case let .BuiltIn(f): return f
      default: return nil
      }
    default: return nil
    }
  }
  
  func asSpecialForm() -> SpecialForm? {
    switch value {
    case let .Special(sf): return sf
    default: return nil
    }
  }

  func asFunction(ctx: Context) -> Fn? {
    switch value {
    case let .Function(f): return f
    case let .Symbol(vname):
      let fExpr = ctx[vname]
      switch fExpr {
      case let .Literal(l): return l.asFn()
      default: return nil
      }
    default: return nil
    }
  }
  
  // MARK: API - evaluate
  
  func evaluate(ctx: Context) -> (ConsValue, SpecialForm?) {
    func collectValues(firstItem : Cons?) -> [ConsValue]? {
      var valueBuffer : [ConsValue] = []
      var currentItem : Cons? = firstItem
      while let actualItem = currentItem {
        let thisValue = actualItem.value
        valueBuffer.append(thisValue.evaluate(ctx))
        currentItem = actualItem.next
      }
      return valueBuffer
    }
    
    func collectSymbols(firstItem: Cons?) -> [ConsValue]? {
      var symbolBuffer : [ConsValue] = []
      var currentItem : Cons? = firstItem
      while let actualItem = currentItem {
        symbolBuffer.append(actualItem.value)
        currentItem = actualItem.next
      }
      return symbolBuffer
    }
    
    if let toExecuteSpecialForm = asSpecialForm() {
      // Execute a special form
      if let symbols = collectSymbols(self.next) {
        let result = toExecuteSpecialForm.function(symbols, ctx)
        switch result {
        case let .Success(v): return (v, toExecuteSpecialForm)
        case let .Failure(f): fatal("Something went wrong: \(f)")
        }
      }
      fatal("something went wrong evaluating a special form")
    }
    else if let toExecuteBuiltIn = asBuiltIn(ctx) {
      // Execute a built-in primitive
      if let values = collectValues(self.next) {
        let result = toExecuteBuiltIn(values, ctx)
        switch result {
        case let .Success(v): return (v, nil)
        case let .Failure(f): fatal("Something went wrong: \(f)")
        }
      }
      else {
        fatal("Could not collect values")
      }
    }
    else if let toExecuteFunction = asFunction(ctx) {
      // Execute a normal function
      if let values = collectValues(self.next) {
        let result = toExecuteFunction.evaluate(values)
        switch result {
        case let .Success(v): return (v, nil)
        case let .Failure(f): fatal("Something went wrong: \(f)")
        }
      }
      else {
        fatal("Could not collect values")
      }
    }
    else {
      fatal("Cannot call 'evaluate' on this cons list, \(self); first object isn't actually a function. Sorry.")
    }
  }
  
  // MARK: API - describe
  
  var description : String {
    func collectDescriptions(firstItem : Cons?) -> [String] {
      var descBuffer : [String] = []
      var currentItem : Cons? = firstItem
      while let actualItem = currentItem {
        descBuffer.append(actualItem.value.description)
        currentItem = actualItem.next
      }
      return descBuffer
    }
    
    var descs = collectDescriptions(self)
    let finalDesc = join(" ", descs)
    return "(\(finalDesc))"
  }
}


/// Represents the value of an item in a single cons cell; either a variable or a literal of some sort
enum ConsValue : Equatable, Printable {
  case None
  case Function(Fn)
  case Symbol(String)
  case Special(SpecialForm)
  case NilLiteral
  case BoolLiteral(Bool)
  case NumberLiteral(Double)
  case StringLiteral(String)
  case ListLiteral(Cons)
  case VectorLiteral([ConsValue])
  
  func asSymbol() -> String? {
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
  
  func asVector() -> [ConsValue]? {
    switch self {
    case let .VectorLiteral(v): return v
    default: return nil
    }
  }
  
  func asFn() -> Fn? {
    switch self {
    case let .Function(f): return f
    default: return nil
    }
  }
  
  func evaluate(ctx: Context) -> ConsValue {
    switch self {
    case let Function(f): return self
    case let Symbol(v):
      // Look up the value of v
      let binding = ctx[v]
      switch binding {
      case .Invalid: fatal("Error; symbol '\(v)' doesn't seem to be valid")
      case .Unbound: fatal("Figure out how to handle unbound vars in evaluation")
      case let .Literal(l): return l.evaluate(ctx)
      case .BuiltIn: fatal("TODO")
      }
    case NilLiteral: return self
    case BoolLiteral: return self
    case NumberLiteral: return self
    case StringLiteral: return self
    case let ListLiteral(l):
      // Evaluate the value of the list 'l'
      // This is a two-step process:
      //  1. Evaluate the list as a function call. This will result in a ConsValue
      //  2. Recursively evaluate the ConsValue that resulted from step 1
      let (result, specialForm) = l.evaluate(ctx)
      if let actualSpecialForm = specialForm {
        // Execution was of a special form. Each form has different rules for what to do next
        switch actualSpecialForm {
        case .Quote: return result  // Quote does not perform any further execution of the resultant expression
        case .If: return result.evaluate(ctx)
        case .Do: return result.evaluate(ctx)
        case .Def: return result
        case .Let: return result.evaluate(ctx)
        case .Fn: return result.evaluate(ctx)
        }
      }
      else {
        // Execution was of a normal function. Evaluate recursively.
        return result.evaluate(ctx)
      }
    case let VectorLiteral(v):
      // Evaluate the value of the vector literal 'v'
      return .VectorLiteral(v.map({$0.evaluate(ctx)}))
    case Special: fatal("TODO")
    case None: fatal("TODO")
    }
  }

  var description : String {
    switch self {
    case let Function(f): return f.description
    case let Symbol(v): return v
    case NilLiteral: return "nil"
    case let BoolLiteral(b): return b.description
    case let NumberLiteral(n): return n.description
    case let StringLiteral(s): return "\"\(s)\""
    case let ListLiteral(l): return l.description
    case let VectorLiteral(v):
      let internals = join(" ", v.map({$0.description}))
      return "[\(internals)]"
    case let Special(s): return s.rawValue
    case None: return ""
    }
  }
}

func ==(lhs: Cons, rhs: [ConsValue]) -> Bool {
  if rhs.count == 0 {
    return lhs.isEmpty
  }

  var that : Cons = lhs
  // Walk through the list
  for var i=0; i<rhs.count; i++ {
    if that.value != rhs[i] {
      // Different values
      return false
    }
    if let next = lhs.next {
      that = next
    }
    else {
      if i < rhs.count - 1 {
        // List is shorter than vector
        return false
      }
    }
  }
  if that.next != nil {
    // List is longer than vector
    return false
  }
  return true
}

func ==(lhs: ConsValue, rhs: ConsValue) -> Bool {
  switch lhs {
  case .None:
    switch rhs {
    case .None: return true
    default: return false
    }
  case let .Function(f1):
    switch rhs {
    case let .Function(f2): return f1 === f2
    default: return false
    }
  case let .Symbol(v1):
    switch rhs {
    case let .Symbol(v2): return v1 == v2  // Can happen if comparing two quoted symbols
    default: return false
    }
  case let .Special(s1):
    switch rhs {
    case let .Special(s2): return s1 == s2
    default: return false
    }
  case .NilLiteral:
    switch rhs {
    case .NilLiteral: return true
    default: return false
    }
  case let .BoolLiteral(b1):
    switch rhs {
    case let .BoolLiteral(b2): return b1 == b2
    default: return false
    }
  case let .NumberLiteral(n1):
    switch rhs {
    case let .NumberLiteral(n2): return n1 == n2
    default: return false
    }
  case let .StringLiteral(s1):
    switch rhs {
    case let .StringLiteral(s2): return s1 == s2
    default: return false
    }
  case let .ListLiteral(l1):
    switch rhs {
    case let .ListLiteral(l2):
      var this = l1
      var that = l2
      // We have to walk through the lists
      while true {
        if this.value != that.value {
          // Different values
          return false
        }
        if this.next != nil && that.next == nil || this.next == nil && that.next != nil {
          // Different lengths
          return false
        }
        if this.next == nil && that.next == nil {
          // Same length, end of both lists
          return true
        }
        this = this.next!
        that = that.next!
      }
    case let .VectorLiteral(v2): return l1 == v2
    default: return false
    }
  case let .VectorLiteral(v1):
    switch rhs {
    case let .ListLiteral(l2): return l2 == v1
    case let .VectorLiteral(v2): return v1 == v2
    default: return false
    }
  }
}

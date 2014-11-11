//
//  core.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

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
    get {
      if next != nil {
        return false
      }
      switch value {
      case .NilLiteral: return true
      default: return false
      }
    }
  }

  func asFunction() -> LambdatronFunction? {
    // TODO: This should accept closure type literals in the future as well
    switch value {
    case let .Variable(vname):
      let vExpr = TEMPORARY_globalContext[vname]
      switch vExpr {
      case let .Function(f): return f
      default: return nil
      }
    default: return nil
    }
  }
  
  func asMacro() -> LambdatronMacro? {
    switch value {
    case let .Variable(vname):
      let vExpr = TEMPORARY_globalContext[vname]
      switch vExpr {
      case let .Macro(m): return m
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
  
  func macroexpand() -> ConsValue {
    func collectSymbols(firstItem : Cons?) -> [ConsValue]? {
      var symbolBuffer : [ConsValue] = []
      var currentItem : Cons? = firstItem
      while let actualItem = currentItem {
        let thisSymbol = actualItem.value
        symbolBuffer.append(thisSymbol.macroexpand())
        currentItem = actualItem.next
      }
      return symbolBuffer
    }
    
    if let toExecuteMacro = asMacro() {
      // First: is the item in the head actually a macro? If so, perform the macro expansion
      if let symbols = collectSymbols(next) {
        return toExecuteMacro(symbols)
      }
      else {
        fatal("error, todo")
      }
    }
    else {
      // Otherwise, return this item as-is
      return .ListLiteral(self)
    }
  }

  func evaluate() -> (ConsValue, SpecialForm?) {
    func collectValues(firstItem : Cons?) -> [ConsValue]? {
      var valueBuffer : [ConsValue] = []
      var currentItem : Cons? = firstItem
      while let actualItem = currentItem {
        let thisValue = actualItem.value
        valueBuffer.append(thisValue.evaluate())
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
    
    if let toExecuteSpecialForm = asSpecialForm()? {
      if let symbols = collectSymbols(self.next) {
//        println("DEBUG: executing special form with symbols: \(symbols)")
        let result = toExecuteSpecialForm.function(symbols)
//        println("DEBUG: result for executing special form is: \(result)")
        switch result {
        case let .Success(v): return (v, toExecuteSpecialForm)
        case let .Failure(f): fatal("Something went wrong: \(f)")
        }
      }
      fatal("something went wrong evaluating a special form")
    }
    else if let toExecuteFunction = asFunction() {
      // First: is the item in the head actually a function type object?
      if let values = collectValues(self.next) {
//        println("DEBUG: executing function with values: \(values)")
        // Second: do the arguments evaluate properly?
        let result = toExecuteFunction(values)
//        println("DEBUG: result for executing function is: \(result)")
        // TODO: Change function signature to accomodate returning closures (eventually)
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
  
  var description : String {
    get {
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
}

/// Represents the value of an item in a single cons cell; either a variable or a literal of some sort
enum ConsValue : Printable {
  case None
  case Variable(String)
  case Special(SpecialForm)
  case NilLiteral
  case BoolLiteral(Bool)
  case NumberLiteral(Double)
  case StringLiteral(String)
  case ListLiteral(Cons)
  case VectorLiteral([ConsValue])
  
  func macroexpand() -> ConsValue {
    switch self {
    case Variable: return self
    case NilLiteral: return self
    case BoolLiteral: return self
    case NumberLiteral: return self
    case StringLiteral: return self
    case let ListLiteral(l):
      let result = l.macroexpand()
      return result
    case VectorLiteral: return self
    case Special: fatal("TODO")
    case None: fatal("TODO")
    }
  }
  
  func evaluate() -> ConsValue {
    switch self {
    case let Variable(v):
      // Look up the value of v
      let binding = TEMPORARY_globalContext[v]
      switch binding {
      case .Invalid: fatal("error")
      case let .Literal(l): return l.evaluate()
      case .Macro: fatal("internal error")
      case .Function: fatal("TODO")
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
      let (result, specialForm) = l.evaluate()
      if let actualSpecialForm = specialForm {
        // Execution was of a special form. Each form has different rules for what to do next
        switch actualSpecialForm {
        case .Quote: return result  // Quote does not perform any further execution of the resultant expression
        }
      }
      else {
        // Execution was of a normal function. Evaluate recursively.
        return result.evaluate()
      }
    case VectorLiteral: return self
    case Special: fatal("TODO")
    case None: fatal("TODO")
    }
  }

  var description : String {
    get {
      switch self {
      case let Variable(v): return v
      case NilLiteral: return "nil"
      case let BoolLiteral(b): return b.description
      case let NumberLiteral(n): return n.description
      case let StringLiteral(s): return "\"\(s)\""
      case let ListLiteral(l): return l.description
      case let VectorLiteral(v): return "Vector"
      case let Special(s): return s.rawValue
      case None: return ""
      }
    }
  }
}

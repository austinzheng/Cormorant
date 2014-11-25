//
//  core.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// A container class allowing for references to value types.
class Box<T> {
  let value : T
  init(_ value: T) {
    self.value = value
  }
}

/// The environment under which an entity is executing. This might be either as a function call or a macro expansion.
enum EvalEnvironment {
  case Normal
  case Macro
}

/// Represents a cons cell, an element in a linked list.
class Cons : Printable {
  var next : Cons?
  var value : ConsValue
  
  
  // MARK: Initializers
  
  /// Create an empty list.
  init() {
    self.next = nil
    self.value = .None
  }
  
  /// Create a list with a single item.
  init(_ value: ConsValue) {
    self.next = nil
    self.value = value
  }
  
  /// Create a list with a given value and another Cons cell following it.
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

  func asFunction(ctx: Context) -> Function? {
    switch value {
    case let .Symbol(name):
      let fExpr = ctx[name]
      switch fExpr {
      case let .Literal(l): return l.asFunction()
      default: return nil
      }
    case let .FunctionLiteral(f): return f
    default: return nil
    }
  }
  
  func asMacro(ctx: Context) -> Macro? {
    switch value {
    case let .Symbol(name):
      let mExpr = ctx[name]
      switch mExpr {
      case let .BoundMacro(m): return m
      default: return nil
      }
    default: return nil
    }
  }
  
  
  // MARK: API - helpers
  
  class func collectValues(firstItem : Cons?, ctx: Context, env: EvalEnvironment) -> [ConsValue]? {
    var valueBuffer : [ConsValue] = []
    var currentItem : Cons? = firstItem
    while let actualItem = currentItem {
      let thisValue = actualItem.value
      valueBuffer.append(thisValue.evaluate(ctx, env))
      currentItem = actualItem.next
    }
    return valueBuffer
  }
  
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
  
  
  // MARK: API - evaluate
  
  func evaluate(ctx: Context, _ env: EvalEnvironment) -> (ConsValue, EvalType) {
    if let toExecuteSpecialForm = asSpecialForm() {
      logEval("evaluating as special form: \(self.description)")
      // Execute a special form
      // How it works:
      // 1. Arguments are passed in as-is
      // 2. The special form decides whether or not to evaluate or use the arguments
      // 3. The result may or may not be evaluated, depending on the special form
      let symbols = Cons.collectSymbols(next)
      let result = toExecuteSpecialForm.function(symbols, ctx, env)
      switch result {
      case let .Success(v): return (v, .Special(toExecuteSpecialForm))
      case let .Failure(f): fatal("Something went wrong: \(f)")
      }
    }
    else if let toExecuteBuiltIn = asBuiltIn(ctx) {
      logEval("evaluating as built-in function: \(self.description)")
      // Execute a built-in primitive
      // Works the exact same way as executing a normal function (see below)
      if let values = Cons.collectValues(next, ctx: ctx, env: env) {
        let result = toExecuteBuiltIn(values, ctx)
        switch result {
        case let .Success(v): return (v, .Function)
        case let .Failure(f): fatal("Something went wrong: \(f)")
        }
      }
      else {
        fatal("Could not collect values")
      }
    }
    else if let toExpandMacro = asMacro(ctx) {
      logEval("evaluating as macro expansion: \(self.description)")
      // Expand a macro
      // How it works:
      // 1. Arguments are passed in as-is
      // 2. The macro uses the arguments and its body to create a replacement form (piece of code) in its place
      // 3. This replacement form is then evaluated
      let symbols = Cons.collectSymbols(next)
      let expanded = toExpandMacro.macroexpand(symbols, env: env)
      switch expanded {
      case let .Success(v):
        logEval("macroexpansion complete; new form: \(v.description)")
        let result = v.evaluate(ctx, env)
        return (result, .Macro)
      case let .Failure(f): fatal("Something went wrong: \(f)")
      }
    }
    else if let toExecuteFunction = asFunction(ctx) {
      logEval("evaluating as function: \(self.description)")
      // Execute a normal function
      // How it works:
      // 1. Arguments are evaluated before the function is ever invoked
      // 2. The function only gets the results of the evaluated arguments, and never sees the literal argument forms
      // 3. The result is then used as-is
      if let values = Cons.collectValues(next, ctx: ctx, env: env) {
        let result = toExecuteFunction.evaluate(values, env: env)
        switch result {
        case let .Success(v): return (v, .Function)
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

enum EvalType {
  case Special(SpecialForm)
  case Macro
  case Function
}

/// Represents the value of an item in a single cons cell; either a variable or a literal of some sort
enum ConsValue : Equatable, Printable {
  case None
  case Symbol(String)
  case Special(SpecialForm)
  case NilLiteral
  case BoolLiteral(Bool)
  case NumberLiteral(Double)
  case StringLiteral(String)
  case ListLiteral(Cons)
  case VectorLiteral([ConsValue])
  case FunctionLiteral(Function)
  // A special sentinel case only to be used by the 'recur' special form. Its contents are new bindings.
  case RecurSentinel([ConsValue])
  // A special case only for use with macro arguments
  case MacroArgument(Box<ConsValue>)
  
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
  
  func evaluate(ctx: Context, _ env: EvalEnvironment) -> ConsValue {
    switch self {
    case FunctionLiteral: return self
    case let Symbol(v):
      // Look up the value of v
      let binding = ctx[v]
      switch binding {
      case .Invalid: fatal("Error; symbol '\(v)' doesn't seem to be valid")
      case .Unbound: fatal("Figure out how to handle unbound vars in evaluation")
      case let .Literal(l): return l
      case let .FunctionParam(fp): return fp
      case let .MacroParam(mp): return .MacroArgument(Box(mp))
      case .BoundMacro: fatal("TODO - taking the value of a macro should be invalid; we'll return an error")
      case .BuiltIn: return self
      }
    case NilLiteral: return self
    case BoolLiteral: return self
    case NumberLiteral: return self
    case StringLiteral: return self
    case let ListLiteral(l):
      // Evaluate the value of the list 'l'
      let (result, evalType) = l.evaluate(ctx, env)
      switch evalType {
      case .Special:
        // Once a special form is evaluated, its result is not evaluated again
        return result
      case .Function:
        // Once a function is evaluated, its result is not evaluated again (this is only relevant for functions that
        //  return lists)
        return result
      case .Macro:
        // Once a macro is evaluated, its product is expected to be a form (usually a list) which must be evaluated
        //  again, either to perform another macroexpansion or to execute a function
        return result.evaluate(ctx, env)
      }
    case let VectorLiteral(v):
      // Evaluate the value of the vector literal 'v'
      return .VectorLiteral(v.map({$0.evaluate(ctx, env)}))
    case Special: fatal("TODO - taking the value of a special form should be disallowed")
    case None: fatal("TODO - taking the value of None should be disallowed, since None is only valid for empty lists")
    case RecurSentinel: return self
    case let MacroArgument(ma):
      // A macro argument is either being evaluated in the environment of a macro definition (in which case it should be
      // not further evaluated), or in the normal environment (in which case it should be treated as a normal value)
      switch env {
      case .Normal: return ma.value.evaluate(ctx, env)
      case .Macro: return ma.value
      }
    }
  }

  var description : String {
    switch self {
    case let Symbol(v): return v
    case NilLiteral: return "nil"
    case let BoolLiteral(b): return b.description
    case let NumberLiteral(n): return n.description
    case let StringLiteral(s): return "\"\(s)\""
    case let ListLiteral(l): return l.description
    case let VectorLiteral(v):
      let internals = join(" ", v.map({$0.description}))
      return "[\(internals)]"
    case let FunctionLiteral(f): return f.description
    case let Special(s): return s.rawValue
    case None: return ""
    case RecurSentinel: internalError("RecurSentinel should never be in a situation where its value can be printed")
    case let MacroArgument(ma): return ma.value.description
    }
  }
}

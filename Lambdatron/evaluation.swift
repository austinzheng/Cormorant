//
//  evaluation.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/25/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// The result of evaluating a function, macro, or special form. Successfully returned values or error messages are
/// encapsulated in each case.
enum EvalResult {
  case Success(ConsValue)
  case Recur(Params)
  case Failure(EvalError)
}

/// The result of collecting arguments for function evaluation.
enum CollectResult {
  case Success(Params)
  case Failure(EvalError)
}

func next(input: EvalResult, action: ConsValue -> EvalResult) -> EvalResult {
  switch input {
  case let .Success(s): return action(s)
  case .Recur, .Failure: return input
  }
}

/// Evaluate a form and return either a success or failure
func evaluateForm(form: ConsValue, ctx: Context) -> EvalResult {
  let result = form.evaluate(ctx)
  switch result {
  case .Success: return result
  case .Recur: return .Failure(EvalError(.RecurMisuseError))
  case .Failure: return result
  }
}


// MARK: Parameter collection

/// Collect the evaluated values of all cells within a list, starting from a given first item. This method is intended
/// to perform argument evaluation as part of the process of calling a function.
func collectFunctionParams(list : ListType<ConsValue>, ctx: Context) -> CollectResult {
  var buffer = Params()
  for param in list {
    switch param.evaluate(ctx) {
    case let .Success(result):
      buffer.append(result)
    case .Recur:
      // Cannot use 'recur' as a function argument
      return .Failure(EvalError(.RecurMisuseError))
    case let .Failure(f):
      return .Failure(f)
    }
  }
  return .Success(buffer)
}

/// Collect the literal values of all cells within a list, starting from a given first item. This method is intended
/// to collect symbols as part of the process of calling a macro or special form.
func collectSymbols(list: ListType<ConsValue>) -> Params {
  var buffer = Params()
  for param in list {
    buffer.append(param)
  }
  return buffer
}


// MARK: List evaluation

/// Evaluate a list with a special form in function position.
private func evaluateSpecialForm(list: Cons<ConsValue>, specialForm: SpecialForm, ctx: Context) -> EvalResult {
  ctx.log(.Eval, message: "evaluating as special form: \(describeList(list, ctx))")
  // How it works:
  // 1. Arguments are passed in as-is
  // 2. The special form decides whether or not to evaluate or use the arguments
  // 3. The special form returns a value
  let symbols = collectSymbols(list.next)
  let result = specialForm.function(symbols, ctx)
  return result
}

/// Evaluate a list with a built-in function in function position.
private func evaluateBuiltIn(list: Cons<ConsValue>, builtIn: LambdatronBuiltIn, ctx: Context) -> EvalResult {
  ctx.log(.Eval, message: "evaluating as built-in function: \(describeList(list, ctx))")
  switch collectFunctionParams(list.next, ctx) {
  case let .Success(values): return builtIn(values, ctx)
  case let .Failure(f): return .Failure(f)
  }
}

/// Expand and evaluate a list with a macro in function position.
private func evaluateMacro(list: Cons<ConsValue>, macro: Macro, ctx: Context) -> EvalResult {
  ctx.log(.Eval, message: "evaluating as macro expansion: \(describeList(list,ctx))")
  // How it works:
  // 1. Arguments are passed in as-is
  // 2. The macro uses the arguments and its body to create a replacement form (piece of code) in its place
  // 3. This replacement form is then evaluated to return a value
  let symbols = collectSymbols(list.next)
  let expanded = macro.macroexpand(symbols)
  switch expanded {
  case let .Success(v):
    ctx.log(.Eval, message: "macroexpansion complete; new form: \(v.describe(ctx))")
    let result = v.evaluate(ctx)
    return result
  case .Recur, .Failure: return expanded
  }
}

/// Evaluate a list with a user-defined function in function position.
private func evaluateFunction(list: Cons<ConsValue>, function: Function, ctx: Context) -> EvalResult {
  ctx.log(.Eval, message: "evaluating as function: \(describeList(list, ctx))")
  // How it works:
  // 1. Arguments are evaluated before the function is ever invoked
  // 2. The function only gets the results of the evaluated arguments, and never sees the literal argument forms
  // 3. The function returns a value
  switch collectFunctionParams(list.next, ctx) {
  case let .Success(values): return function.evaluate(values)
  case let .Failure(f): return .Failure(f)
  }
}

/// Evaluate a list with a vector in function position.
private func evaluateVector(list: Cons<ConsValue>, vector: VectorType, ctx: Context) -> EvalResult {
  ctx.log(.Eval, message: "evaluating with vector in function position: \(describeList(list, ctx))")
  // How it works:
  // 1. (*vector* *pos*) is translated into (nth *vector* *pos*)
  // 2. Normal function call
  switch collectFunctionParams(list.next, ctx) {
  case let .Success(args):
    if args.count != 1 {
      // Using vector in fn position disallows the user from specifying a fallback. This is to match Clojure's
      // behavior.
      return .Failure(EvalError.arityError("1", actual: args.count, "(vector)"))
    }
    let allArgs = args.prefixedBy(.Vector(vector))
    return pr_nth(allArgs, ctx)
  case let .Failure(f): return .Failure(f)
  }
}

/// Evaluate a list with a map in function position.
private func evaluateMap(list: Cons<ConsValue>, map: MapType, ctx: Context) -> EvalResult {
  ctx.log(.Eval, message: "evaluating with map in function position: \(describeList(list, ctx))")
  // How it works:
  // 1. (*map* *args*...) is translated into (get *map* *args*...).
  // 2. Normal function call
  switch collectFunctionParams(list.next, ctx) {
  case let .Success(args):
    let allArgs = args.prefixedBy(.Map(map))
    return pr_get(allArgs, ctx)
  case let .Failure(f): return .Failure(f)
  }
}

/// Evaluate a list with a symbol or keyword in function position.
private func evaluateKeyType(list: Cons<ConsValue>, key: ConsValue, ctx: Context) -> EvalResult {
  ctx.log(.Eval, message: "evaluating symbol or keyword in function position: \(describeList(list, ctx))")
  // How it works:
  // 1. (*key* *map* *fallback*) is translated into (get *map* *key* *fallback*).
  // 2. Normal function call
  switch collectFunctionParams(list.next, ctx) {
  case let .Success(args):
    if !(args.count == 1 || args.count == 2) {
      return .Failure(EvalError.arityError("1 or 2", actual: args.count, "(key type)"))
    }
    let allArgs = args.count == 1 ? Params(args[0], key) : Params(args[0], key, args[1])
    return pr_get(allArgs, ctx)
  case let .Failure(f): return .Failure(f)
  }
}

/// Apply the values in the Params object 'args' to the function 'first'.
func apply(first: ConsValue, args: Params, ctx: Context, fn: String) -> EvalResult {
  if let builtIn = first.asBuiltIn() {
    ctx.log(.Eval, message: "applying arguments: \(args.describe(ctx)) to builtin \(first.describe(ctx))")
    return builtIn(args, ctx)
  }
  else if let function = first.asFunction() {
    ctx.log(.Eval, message: "applying arguments: \(args.describe(ctx)) to function \(first.describe(ctx))")
    return function.evaluate(args)
  }
  else if first.asVector() != nil {
    ctx.log(.Eval, message: "applying arguments: \(args.describe(ctx)) to vector \(first.describe(ctx))")
    return args.count == 1
      ? pr_nth(args.prefixedBy(first), ctx)
      : .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  else if first.asMap() != nil {
    ctx.log(.Eval, message: "applying arguments: \(args.describe(ctx)) to map \(first.describe(ctx))")
    return pr_get(args.prefixedBy(first), ctx)
  }
  else if first.asSymbol() != nil || first.asKeyword() != nil {
    ctx.log(.Eval, message: "applying arguments: \(args.describe(ctx)) to symbol or keyword \(first.describe(ctx))")
    if !(args.count == 1 || args.count == 2) {
      return .Failure(EvalError.arityError("1 or 2", actual: args.count, fn))
    }
    let allArgs = args.count == 1 ? Params(args[0], first) : Params(args[0], first, args[1])
    return pr_get(allArgs, ctx)
  }
  else {
    ctx.log(.Eval, message: "unable to apply arguments: \(args.describe(ctx)) to non-evalable \(first.describe(ctx))")
    return .Failure(EvalError(.NotEvalableError, fn))
  }
}

/// Evaluate this list, treating the first item in the list as something that can be eval'ed.
func evaluateList(list: ListType<ConsValue>, ctx: Context) -> EvalResult {
  // This method is run in order to evaluate a list form (a b c d).
  // 'a' must resolve to something that can be used in function position. 'b', 'c', and 'd' are arguments to the
  // function.

  switch list {
  case let list as Cons<ConsValue>:
    // 0: The list is a non-empty list.
    // 1: Decide whether 'a' is either a special form or a reference to a macro.
    if let specialForm = list.value.asSpecialForm() {
      // Special forms can't be returned by functions or macros, nor can they be evaluated themselves.
      return evaluateSpecialForm(list, specialForm, ctx)
    }
    else if let macro = list.value.asMacro(ctx) {
      // Macros can't be returned by functions or other macros, nor can they be evaluated themselves.
      return evaluateMacro(list, macro, ctx)
    }

    // 2: Evaluate the form 'a'.
    let fpItemResult = list.value.evaluate(ctx)
    switch fpItemResult {
    case let .Success(fpItem):
      // 3: Decide whether or not the evaluated form of 'a' is something that can be used in function position.
      if let builtIn = fpItem.asBuiltIn() {
        return evaluateBuiltIn(list, builtIn, ctx)
      }
      else if let function = fpItem.asFunction() {
        return evaluateFunction(list, function, ctx)
      }
      else if let vector = fpItem.asVector() {
        return evaluateVector(list, vector, ctx)
      }
      else if let map = fpItem.asMap() {
        return evaluateMap(list, map, ctx)
      }
      else if let symbol = fpItem.asSymbol() {
        return evaluateKeyType(list, .Symbol(symbol), ctx)
      }
      else if let keyword = fpItem.asKeyword() {
        return evaluateKeyType(list, .Keyword(keyword), ctx)
      }
      else {
        // 3a: 'a' is not something that can be used in function position (e.g. nil)
        return .Failure(EvalError(.NotEvalableError))
      }
    case .Recur:
      // 2a: Evaluating the form 'a' resulted in a recur sentinel; this is not acceptable.
      return .Failure(EvalError(.RecurMisuseError))
    case .Failure:
      // 2b: Evaluating the form 'a' failed; for example, it was a function that threw some error.
      return fpItemResult
    }
  default:
    // 0: An empty list just returns itself.
    return .Success(.List(list))
  }
}


// MARK: ConsValue evaluation

extension ConsValue {

  func evaluate(ctx: Context) -> EvalResult {
    switch self {
    case FunctionLiteral, BuiltInFunction: return .Success(self)
    case let Symbol(v):
      // Look up the value of v
      switch ctx[v] {
      case .Invalid:
        return .Failure(EvalError(.InvalidSymbolError, metadata: [.Symbol : ctx.nameForSymbol(v)]))
      case .Unbound:
        return .Failure(EvalError(.UnboundSymbolError, metadata: [.Symbol : ctx.nameForSymbol(v)]))
      case let .Literal(l):
        return .Success(l)
      case let .Param(p):
        return .Success(p)
      case .BoundMacro:
        return .Failure(EvalError(.EvaluatingMacroError))
      }
    case Nil, BoolAtom, IntAtom, FloatAtom, CharAtom, StringAtom, Keyword:
      return .Success(self)
    case let List(l):
      // Evaluate the value of the list 'l'
      return evaluateList(l, ctx)
    case let Vector(v):
      // Evaluate the value of the vector literal 'v'
      var buffer : [ConsValue] = []
      for form in v {
        let result = form.evaluate(ctx)
        switch result {
        case let .Success(result): buffer.append(result)
        case .Recur: return .Failure(EvalError(.RecurMisuseError))
        case .Failure: return result
        }
      }
      return .Success(.Vector(buffer))
    case let Map(m):
      // Evaluate the value of the map literal 'm'
      var newMap : MapType = [:]
      for (key, value) in m {
        let evaluatedKey = key.evaluate(ctx)
        switch evaluatedKey {
        case let .Success(k):
          let evaluatedValue = value.evaluate(ctx)
          switch evaluatedValue {
          case let .Success(v): newMap[k] = v
          case .Recur: return .Failure(EvalError(.RecurMisuseError))
          case .Failure: return evaluatedValue
          }
        case .Recur: return .Failure(EvalError(.RecurMisuseError))
        case .Failure: return evaluatedKey
        }
      }
      return .Success(.Map(newMap))
    case Special: return .Failure(EvalError(.EvaluatingSpecialFormError))
    case ReaderMacroForm: return .Failure(EvalError(.EvaluatingMacroError))
    }
  }
}

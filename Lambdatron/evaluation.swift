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

  func force() -> Params {
    switch self {
    case let .Success(s): return s
    case .Failure: internalError("CollectResult force method called improperly")
    }
  }
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
func collectFunctionParams(list : SeqType, ctx: Context) -> CollectResult {
  var buffer = Params()
  for param in SeqIterator(list) {
    switch param {
    case let .Success(param):
      switch param.evaluate(ctx) {
      case let .Success(result):
        buffer.append(result)
      case .Recur:
        // Cannot use 'recur' as a function argument
        return .Failure(EvalError(.RecurMisuseError))
      case let .Failure(f):
        // Param expression couldn't be evaluated successfully
        return .Failure(f)
      }
    case let .Error(err):
      // List failure during iteration (e.g. bad lazy seq)
      return .Failure(err)
    }
  }
  return .Success(buffer)
}

/// Collect the literal values of all cells within a list, starting from a given first item. This method is intended
/// to collect symbols as part of the process of calling a macro or special form.
func collectSymbols(list: SeqType) -> CollectResult {
  var buffer = Params()
  for param in SeqIterator(list) {
    switch param {
    case let .Success(param):
      buffer.append(param)
    case let .Error(err):
      // List failure during iteration (e.g. bad lazy seq)
      return .Failure(err)
    }
  }
  return .Success(buffer)
}


// MARK: List evaluation

/// Given a SeqResult that might contain a ListType, process the ListType if it exists, or just pass any error through.
private func unwrapAndProcessSeqResult(result: SeqResult, f: SeqType -> EvalResult) -> EvalResult {
  switch result {
  case let .Seq(sequence):
    return f(sequence)
  case let .Error(err):
    return .Failure(err)
  }
}

/// Evaluate a list with a special form in function position.
private func evaluateSpecialForm(specialForm: SpecialForm, parameters: SeqResult, ctx: Context) -> EvalResult {
//  ctx.log(.Eval) { "evaluating as special form: \(describeList(list, ctx))" }
  // How it works:
  // 1. Arguments are passed in as-is
  // 2. The special form decides whether or not to evaluate or use the arguments
  // 3. The special form returns a value
  return unwrapAndProcessSeqResult(parameters) { parameters in
    let symbols = collectSymbols(parameters)
    switch symbols {
    case let .Success(symbols):
      let result = specialForm.function(symbols, ctx)
      return result
    case let .Failure(err): return .Failure(err)
    }
  }
}

/// Evaluate a list with a built-in function in function position.
private func evaluateBuiltIn(builtIn: BuiltIn, arguments: SeqResult, ctx: Context) -> EvalResult {
//  ctx.log(.Eval) { "evaluating as built-in function: \(describeList(list, ctx))" }
  return unwrapAndProcessSeqResult(arguments) { arguments in
    switch collectFunctionParams(arguments, ctx) {
    case let .Success(values): return builtIn.function(values, ctx)
    case let .Failure(f): return .Failure(f)
    }
  }
}

/// Expand and evaluate a list with a macro in function position.
private func evaluateMacro(macro: Macro, parameters: SeqResult, ctx: Context) -> EvalResult {
//  ctx.log(.Eval) { "evaluating as macro expansion: \(describeList(list,ctx))" }
  // How it works:
  // 1. Arguments are passed in as-is
  // 2. The macro uses the arguments and its body to create a replacement form (piece of code) in its place
  // 3. This replacement form is then evaluated to return a value
  return unwrapAndProcessSeqResult(parameters) { parameters in
    let symbols = collectSymbols(parameters)
    switch symbols {
    case let .Success(symbols):
      // Perform macroexpansion
      let result = macro.evaluate(symbols)
      switch result {
      case let .Success(macroexpansion):
        ctx.interpreter.log(.Eval) { "macroexpansion complete; new form: \(macroexpansion.describe(ctx))" }
        // Now evaluate the result of the macroexpansion
        let result = macroexpansion.evaluate(ctx)
        return result
      case .Recur, .Failure: return result
      }
    case let .Failure(err): return .Failure(err)
    }
  }
}

/// Evaluate a list with a user-defined function in function position.
private func evaluateFunction(function: Function, arguments: SeqResult, ctx: Context) -> EvalResult {
//  ctx.log(.Eval, message: "evaluating as function: \(describeList(list, ctx))")
  // How it works:
  // 1. Arguments are evaluated before the function is ever invoked
  // 2. The function only gets the results of the evaluated arguments, and never sees the literal argument forms
  // 3. The function returns a value
  return unwrapAndProcessSeqResult(arguments) { arguments in
    switch collectFunctionParams(arguments, ctx) {
    case let .Success(values): return function.evaluate(values)
    case let .Failure(f): return .Failure(f)
    }
  }
}

/// Evaluate a list with a vector in function position.
private func evaluateVector(vector: VectorType, arguments: SeqResult, ctx: Context) -> EvalResult {
//  ctx.log(.Eval) { "evaluating with vector in function position: \(describeList(list, ctx))" }
  // How it works:
  // 1. (*vector* *pos*) is translated into (nth *vector* *pos*)
  // 2. Normal function call
  return unwrapAndProcessSeqResult(arguments) { arguments in
    switch collectFunctionParams(arguments, ctx) {
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
}

/// Evaluate a list with a map in function position.
private func evaluateMap(map: MapType, arguments: SeqResult, ctx: Context) -> EvalResult {
//  { "evaluating with map in function position: \(describeList(list, ctx))" }
  // How it works:
  // 1. (*map* *args*...) is translated into (get *map* *args*...).
  // 2. Normal function call
  return unwrapAndProcessSeqResult(arguments) { arguments in
    switch collectFunctionParams(arguments, ctx) {
    case let .Success(args):
      let allArgs = args.prefixedBy(.Map(map))
      return pr_get(allArgs, ctx)
    case let .Failure(f): return .Failure(f)
    }
  }
}

/// Evaluate a list with a symbol or keyword in function position.
private func evaluateKeyType(key: ConsValue, arguments: SeqResult, ctx: Context) -> EvalResult {
//  ctx.log(.Eval) { "evaluating symbol or keyword in function position: \(describeList(list, ctx))" }
  // How it works:
  // 1. (*key* *map* *fallback*) is translated into (get *map* *key* *fallback*).
  // 2. Normal function call
  return unwrapAndProcessSeqResult(arguments) { arguments in
    switch collectFunctionParams(arguments, ctx) {
    case let .Success(args):
      if !(args.count == 1 || args.count == 2) {
        return .Failure(EvalError.arityError("1 or 2", actual: args.count, "(key type)"))
      }
      let allArgs = args.count == 1 ? Params(args[0], key) : Params(args[0], key, args[1])
      return pr_get(allArgs, ctx)
    case let .Failure(f): return .Failure(f)
    }
  }
}

/// Apply the values in the Params object 'args' to the function 'first'.
func apply(first: ConsValue, args: Params, ctx: Context, fn: String) -> EvalResult {
  if let builtIn = first.asBuiltIn {
    ctx.interpreter.log(.Eval) { "applying arguments: \(args.describe(ctx)) to builtin \(first.describe(ctx))" }
    return builtIn.function(args, ctx)
  }
  else if let function = first.asFunction {
    ctx.interpreter.log(.Eval) { "applying arguments: \(args.describe(ctx)) to function \(first.describe(ctx))" }
    return function.evaluate(args)
  }
  else if first.asVector != nil {
    ctx.interpreter.log(.Eval) { "applying arguments: \(args.describe(ctx)) to vector \(first.describe(ctx))" }
    return args.count == 1
      ? pr_nth(args.prefixedBy(first), ctx)
      : .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  else if first.asMap != nil {
    ctx.interpreter.log(.Eval) { "applying arguments: \(args.describe(ctx)) to map \(first.describe(ctx))" }
    return pr_get(args.prefixedBy(first), ctx)
  }
  else if first.asSymbol != nil || first.asKeyword != nil {
    ctx.interpreter.log(.Eval) { "applying arguments: \(args.describe(ctx)) to symbol or keyword \(first.describe(ctx))" }
    if !(args.count == 1 || args.count == 2) {
      return .Failure(EvalError.arityError("1 or 2", actual: args.count, fn))
    }
    let allArgs = args.count == 1 ? Params(args[0], first) : Params(args[0], first, args[1])
    return pr_get(allArgs, ctx)
  }
  else {
    ctx.interpreter.log(.Eval) { "unable to apply arguments: \(args.describe(ctx)) to non-evalable \(first.describe(ctx))" }
    return .Failure(EvalError(.NotEvalableError, fn))
  }
}

/// Evaluate this list, treating the first item in the list as something that can be eval'ed.
func evaluateList(list: SeqType, ctx: Context) -> EvalResult {
  // This method is run in order to evaluate a list form (a b c d).
  // 'a' must resolve to something that can be used in function position. 'b', 'c', and 'd' are arguments to the
  // function.

  let result = list.first
  switch result {
  case let .Success(first):
    switch list.isEmpty {
    case let .Boolean(listIsEmpty):
      if listIsEmpty {
        // 0: An empty list just returns itself.
        return .Success(.Seq(list))
      }

      // 1: Decide whether 'a' is a special form.
      if let specialForm = first.asSpecialForm {
        // Special forms can't be returned by functions or macros, nor can they be evaluated themselves.
        return evaluateSpecialForm(specialForm, list.rest, ctx)
      }
//      else if let macro = first.asMacro {
//        // Macros can't be returned by functions or other macros, nor can they be evaluated themselves.
//        return evaluateMacro(macro, list.rest, ctx)
//      }

      // 2: Evaluate the form 'a'.
      let fpItemResult = first.evaluate(ctx, isFirstFormInSeq: true)
      switch fpItemResult {
      case let .Success(fpItem):
        // 3: Decide whether or not the evaluated form of 'a' is something that can be used in function position.
        if let macro = fpItem.asMacro {
          return evaluateMacro(macro, list.rest, ctx)
        }
        if let builtIn = fpItem.asBuiltIn {
          return evaluateBuiltIn(builtIn, list.rest, ctx)
        }
        else if let function = fpItem.asFunction {
          return evaluateFunction(function, list.rest, ctx)
        }
        else if let vector = fpItem.asVector {
          return evaluateVector(vector, list.rest, ctx)
        }
        else if let map = fpItem.asMap {
          return evaluateMap(map, list.rest, ctx)
        }
        else if let symbol = fpItem.asSymbol {
          return evaluateKeyType(.Symbol(symbol), list.rest, ctx)
        }
        else if let keyword = fpItem.asKeyword {
          return evaluateKeyType(.Keyword(keyword), list.rest, ctx)
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
    case let .Error(err):
      // Couldn't tell if list was empty
      return .Failure(err)
    }
  case let .Error(err):
    return .Failure(err)
  }
}


// MARK: ConsValue evaluation

extension ConsValue {

  func evaluate(ctx: Context, isFirstFormInSeq: Bool = false) -> EvalResult {
    switch self {
    case .FunctionLiteral, .BuiltInFunction: return .Success(self)
    case .MacroLiteral:
      return .Failure(EvalError(.EvaluatingMacroError))
    case let .Symbol(sym):
      if let result = ctx.resolveBindingForSymbol(sym) {
        if !isFirstFormInSeq && result.asMacro != nil {
          // A symbol is only allowed to resolve to a macro in the context of being the first item in a seq to evaluate
          return .Failure(EvalError(.EvaluatingMacroError))
        }
        return .Success(result)
      }
      return .Failure(EvalError(.InvalidSymbolError, metadata: [.Symbol : sym.fullName(ctx)]))
    case let .Keyword(k):
      // Keywords always evaluate to themselves, no matter whether or not they are namespaced
      return .Success(self)
    case .Nil, .BoolAtom, .IntAtom, .FloatAtom, .CharAtom, .StringAtom, .Namespace, .Var, .Auxiliary:
      return .Success(self)
    case let .Seq(seq):
      // Evaluate the value of the sequence
      return evaluateList(seq, ctx)
    case let .Vector(vector):
      // Evaluate the value of the vector literal 'v'
      var buffer : [ConsValue] = []
      for form in vector {
        let result = form.evaluate(ctx)
        switch result {
        case let .Success(result): buffer.append(result)
        case .Recur: return .Failure(EvalError(.RecurMisuseError))
        case .Failure: return result
        }
      }
      return .Success(.Vector(buffer))
    case let .Map(m):
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
    case .Special: return .Failure(EvalError(.EvaluatingSpecialFormError))
    case .ReaderMacroForm: return .Failure(EvalError(.EvaluatingMacroError))
    }
  }
}

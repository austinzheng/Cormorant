//
//  evaluation.swift
//  Cormorant
//
//  Created by Austin Zheng on 11/25/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

// MARK: Parameter collection

/// Collect the evaluated values of all cells within a list, starting from a given first item. This method is intended
/// to perform argument evaluation as part of the process of calling a function.
func collectFunctionParams(_ list : SeqType, _ ctx: Context) -> EvalOptional<Params> {
  var buffer = Params()
  for param in SeqIterator(list) {
    switch param {
    case let .Just(param):
      switch ctx.evaluate(value: param) {
      case let .Success(result):
        buffer.append(result)
      case .Recur:
        // Cannot use 'recur' as a function argument
        return .Error(EvalError(.RecurMisuseError))
      case let .Failure(f):
        // Param expression couldn't be evaluated successfully
        return .Error(f)
      }
    case let .Error(err):
      // List failure during iteration (e.g. bad lazy seq)
      return .Error(err)
    }
  }
  return .Just(buffer)
}

/// Collect the literal values of all cells within a list, starting from a given first item. This method is intended
/// to collect symbols as part of the process of calling a macro or special form.
func collectSymbols(_ list: SeqType) -> EvalOptional<Params> {
  var buffer = Params()
  for param in SeqIterator(list) {
    switch param {
    case let .Just(param):
      buffer.append(param)
    case let .Error(err):
      // List failure during iteration (e.g. bad lazy seq)
      return .Error(err)
    }
  }
  return .Just(buffer)
}

extension Context {

  func evaluate(value: Value, asFirstFormInSeq isFirst: Bool = false) -> EvalResult {
    switch value {
    case .functionLiteral, .builtInFunction: return .Success(value)
    case .macroLiteral:
      return .Failure(EvalError(.EvaluatingMacroError))
    case let .symbol(sym):
      if let result = resolveBinding(for: sym) {
        if !isFirst, case .macroLiteral = result {
          // A symbol is only allowed to resolve to a macro in the context of being the first item in a seq to evaluate
          return .Failure(EvalError(.EvaluatingMacroError))
        }
        return .Success(result)
      }
      return .Failure(EvalError(.InvalidSymbolError, metadata: [.Symbol : sym.fullName(self)]))
    case .keyword:
      // Keywords always evaluate to themselves, no matter whether or not they are namespaced
      return .Success(value)
    case .nilValue, .bool, .int, .float, .char, .string, .namespace, .`var`, .auxiliary:
      return .Success(value)
    case let .seq(seq):
      // Evaluate the value of the sequence
      return evaluate(list: seq)
    case let .vector(vector):
      // Evaluate the value of the vector literal 'v'
      var buffer : [Value] = []
      for form in vector {
        let result = evaluate(value: form)
        switch result {
        case let .Success(result): buffer.append(result)
        case .Recur: return .Failure(EvalError(.RecurMisuseError))
        case .Failure: return result
        }
      }
      return .Success(.vector(buffer))
    case let .map(m):
      // Evaluate the value of the map literal 'm'
      var newMap : MapType = [:]
      for (key, value) in m {
        let evaluatedKey = evaluate(value: key)
        switch evaluatedKey {
        case let .Success(k):
          let evaluatedValue = evaluate(value: value)
          switch evaluatedValue {
          case let .Success(v): newMap[k] = v
          case .Recur: return .Failure(EvalError(.RecurMisuseError))
          case .Failure: return evaluatedValue
          }
        case .Recur: return .Failure(EvalError(.RecurMisuseError))
        case .Failure: return evaluatedKey
        }
      }
      return .Success(.map(newMap))
    case .special: return .Failure(EvalError(.EvaluatingSpecialFormError))
    case .readerMacroForm: return .Failure(EvalError(.EvaluatingMacroError))
    }
  }

  /// Apply the values in the Params object 'args' to the function 'first'.
  func apply(arguments args: Params, toFunction first: Value, _ fn: String = "(none)") -> EvalResult {
    switch first {
    case let .builtInFunction(builtIn):
      // Built-in function
      interpreter.log(.Eval) { "applying arguments: \(args.describe(self)) to builtin \(first.describe(self))" }
      return builtIn.function(args, self)
    case let .functionLiteral(function):
      // User-defined function
      interpreter.log(.Eval) { "applying arguments: \(args.describe(self)) to function \(first.describe(self))" }
      return function.evaluate(arguments: args)
    case .vector:
      // Vector
      interpreter.log(.Eval) { "applying arguments: \(args.describe(self)) to vector \(first.describe(self))" }
      return args.count == 1
        ? pr_nth(args.prefixed(by: first), self)
        : .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
    case .map:
      // Map
      interpreter.log(.Eval) { "applying arguments: \(args.describe(self)) to map \(first.describe(self))" }
      return pr_get(args.prefixed(by: first), self)
    case .symbol, .keyword:
      // Symbol/keyword
      interpreter.log(.Eval) { "applying arguments: \(args.describe(self)) to symbol or keyword \(first.describe(self))" }
      if !(args.count == 1 || args.count == 2) {
        return .Failure(EvalError.arityError(expected: "1 or 2", actual: args.count, fn))
      }
      let allArgs = args.count == 1 ? Params(args[0], first) : Params(args[0], first, args[1])
      return pr_get(allArgs, self)
    default:
      // All others
      interpreter.log(.Eval) { "unable to apply arguments: \(args.describe(self)) to non-evalable \(first.describe(self))" }
      return .Failure(EvalError(.NotEvalableError, fn))
    }
  }
}

private extension Context {

  /// Evaluate a list with a special form in function position.
  func evaluate(specialForm: SpecialForm, parameters: EvalOptional<SeqType>) -> EvalResult {
    //  ctx.log(.Eval) { "evaluating as special form: \(describeList(list, ctx))" }
    // How it works:
    // 1. Arguments are passed in as-is
    // 2. The special form decides whether or not to evaluate or use the arguments
    // 3. The special form returns a value
    return parameters.then { parameters in
      let symbols = collectSymbols(parameters)
      switch symbols {
      case let .Just(symbols):
        let result = specialForm.function(symbols, self)
        return result
      case let .Error(err): return .Failure(err)
      }
    }
  }

  /// Evaluate a list with a built-in function in function position.
  func evaluate(builtIn: BuiltIn, arguments: EvalOptional<SeqType>) -> EvalResult {
    //  ctx.log(.Eval) { "evaluating as built-in function: \(describeList(list, ctx))" }
    return arguments.then { arguments in
      switch collectFunctionParams(arguments, self) {
      case let .Just(values): return builtIn.function(values, self)
      case let .Error(f): return .Failure(f)
      }
    }
  }

  /// Expand and evaluate a list with a macro in function position.
  func evaluate(macro: Macro, parameters: EvalOptional<SeqType>) -> EvalResult {
    //  ctx.log(.Eval) { "evaluating as macro expansion: \(describeList(list,ctx))" }
    // How it works:
    // 1. Arguments are passed in as-is
    // 2. The macro uses the arguments and its body to create a replacement form (piece of code) in its place
    // 3. This replacement form is then evaluated to return a value
    return parameters.then { parameters in
      let symbols = collectSymbols(parameters)
      switch symbols {
      case let .Just(symbols):
        // Perform macroexpansion
        let result = macro.evaluate(arguments: symbols)
        switch result {
        case let .Success(macroexpansion):
          interpreter.log(.Eval) { "macroexpansion complete; new form: \(macroexpansion.describe(self))" }
          // Now evaluate the result of the macroexpansion
          let result = evaluate(value: macroexpansion)
          return result
        case .Recur, .Failure: return result
        }
      case let .Error(err): return .Failure(err)
      }
    }
  }

  /// Evaluate a list with a user-defined function in function position.
  func evaluate(function: Function, arguments: EvalOptional<SeqType>) -> EvalResult {
    //  ctx.log(.Eval, message: "evaluating as function: \(describeList(list, ctx))")
    // How it works:
    // 1. Arguments are evaluated before the function is ever invoked
    // 2. The function only gets the results of the evaluated arguments, and never sees the literal argument forms
    // 3. The function returns a value
    return arguments.then { arguments in
      switch collectFunctionParams(arguments, self) {
      case let .Just(values): return function.evaluate(arguments: values)
      case let .Error(f): return .Failure(f)
      }
    }
  }

  /// Evaluate a list with a vector in function position.
  func evaluate(vector: VectorType, arguments: EvalOptional<SeqType>) -> EvalResult {
    //  ctx.log(.Eval) { "evaluating with vector in function position: \(describeList(list, ctx))" }
    // How it works:
    // 1. (*vector* *pos*) is translated into (nth *vector* *pos*)
    // 2. Normal function call
    return arguments.then { arguments in
      switch collectFunctionParams(arguments, self) {
      case let .Just(args):
        if args.count != 1 {
          // Using vector in fn position disallows the user from specifying a fallback. This is to match Clojure's
          // behavior.
          return .Failure(EvalError.arityError(expected: "1", actual: args.count, "(vector)"))
        }
        let allArgs = args.prefixed(by: .vector(vector))
        return pr_nth(allArgs, self)
      case let .Error(f): return .Failure(f)
      }
    }
  }

  /// Evaluate a list with a map in function position.
  func evaluate(map: MapType, arguments: EvalOptional<SeqType>) -> EvalResult {
    //  { "evaluating with map in function position: \(describeList(list, ctx))" }
    // How it works:
    // 1. (*map* *args*...) is translated into (get *map* *args*...).
    // 2. Normal function call
    return arguments.then { arguments in
      switch collectFunctionParams(arguments, self) {
      case let .Just(args):
        let allArgs = args.prefixed(by: .map(map))
        return pr_get(allArgs, self)
      case let .Error(f): return .Failure(f)
      }
    }
  }

  /// Evaluate a list with a symbol or keyword in function position.
  func evaluate(key: Value, arguments: EvalOptional<SeqType>) -> EvalResult {
    //  ctx.log(.Eval) { "evaluating symbol or keyword in function position: \(describeList(list, ctx))" }
    // How it works:
    // 1. (*key* *map* *fallback*) is translated into (get *map* *key* *fallback*).
    // 2. Normal function call
    return arguments.then { arguments in
      switch collectFunctionParams(arguments, self) {
      case let .Just(args):
        if !(args.count == 1 || args.count == 2) {
          return .Failure(EvalError.arityError(expected: "1 or 2", actual: args.count, "(key type)"))
        }
        let allArgs = args.count == 1 ? Params(args[0], key) : Params(args[0], key, args[1])
        return pr_get(allArgs, self)
      case let .Error(f): return .Failure(f)
      }
    }
  }

  /// Evaluate this list, treating the first item in the list as something that can be eval'ed.
  func evaluate(list: SeqType) -> EvalResult {
    // This method is run in order to evaluate a list form (a b c d).
    // 'a' must resolve to something that can be used in function position. 'b', 'c', and 'd' are arguments to the
    // function.

    let result = list.first
    switch result {
    case let .Just(first):
      switch list.isEmpty {
      case let .Just(listIsEmpty):
        if listIsEmpty {
          // 0: An empty list just returns itself.
          return .Success(.seq(list))
        }

        // 1: Decide whether 'a' is a special form.
        if case let .special(specialForm) = first {
          // Special forms can't be returned by functions or macros, nor can they be evaluated themselves.
          return evaluate(specialForm: specialForm, parameters: list.rest)
        }

        // 2: Evaluate the form 'a'.
        let fpItemResult = evaluate(value: first, asFirstFormInSeq: true)
        switch fpItemResult {
        case let .Success(fpItem):
          // 3: Decide whether or not the evaluated form of 'a' is something that can be used in function position.
          switch fpItem {
          case let .macroLiteral(macro):
            return evaluate(macro: macro, parameters: list.rest)
          case let .builtInFunction(builtIn):
            return evaluate(builtIn: builtIn, arguments: list.rest)
          case let .functionLiteral(function):
            return evaluate(function: function, arguments: list.rest)
          case let .vector(vector):
            return evaluate(vector: vector, arguments: list.rest)
          case let .map(map):
            return evaluate(map: map, arguments: list.rest)
          case let .symbol(symbol):
            return evaluate(key: .symbol(symbol), arguments: list.rest)
          case let .keyword(keyword):
            return evaluate(key: .keyword(keyword), arguments: list.rest)
          default:
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
}

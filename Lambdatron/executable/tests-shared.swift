//
//  tests-shared.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/8/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class SucceedOnEvalTest : LambdatronTest {
  var input : String
  var expected : ConsValue
  
  init(_ name: String, _ input: String, _ expected: ConsValue) {
    self.input = input
    self.expected = expected
    super.init(name: name)
  }
  
  class func test(name: String, input: String, shouldEvalTo expected: ConsValue) -> SucceedOnEvalTest {
    return SucceedOnEvalTest(name, input, expected)
  }
  
  override func run(ctx: Context) -> TestResult {
    // TODO: we need to NOT make a new global context instance every time a single test is run.
    let context = Context.globalContextInstance()
    let lexed = lex(input)
    switch lexed {
    case let .Success(lexed):
      let parsed = parse(lexed, context)
      switch parsed {
      case let .Success(parsed):
        let expanded = parsed.readerExpand()
        switch expanded {
        case let .Success(expanded):
          let evaled = evaluate(expanded, ctx)
          switch evaled {
          case let .Success(actual):
            return expected == actual
              ? .Pass
              : .Fail(expected: "\(expected.describe(ctx))", got: "\(actual.describe(ctx))")
          case let .Failure(e): return .Fail(expected: "\(expected.describe(ctx))", got: "error (\(e.name))")
          }
        case .Failure:
          return .Error("expansion failure")
        }
      case .Failure:
        return .Error("parse failure")
      }
    case .Failure:
      return .Error("lex failure")
    }
  }
}

/// A test case representing an input that should lex, parse, and expand properly, but produce an error when run.
class FailOnEvalTest : LambdatronTest {
  var input : String
  var error : EvalError
  
  init(_ name: String, _ input: String, _ error: EvalError) {
    self.input = input
    self.error = error
    super.init(name: name)
  }
  
  class func test(name: String, input: String, shouldCauseError error: EvalError) -> FailOnEvalTest {
    return FailOnEvalTest(name, input, error)
  }
  
  override func run(ctx: Context) -> TestResult {
    // TODO: we need to NOT make a new global context instance every time a single test is run.
    let context = Context.globalContextInstance()
    let lexed = lex(input)
    switch lexed {
    case let .Success(lexed):
      let parsed = parse(lexed, context)
      switch parsed {
      case let .Success(parsed):
        let expanded = parsed.readerExpand()
        switch expanded {
        case let .Success(expanded):
          let evaled = evaluate(expanded, ctx)
          switch evaled {
          case let .Success(s): return .Fail(expected: "error (\(error.name))", got: "\(s.describe(ctx))")
          case let .Failure(e):
            if e == error {
              return .Pass
            }
            else {
              return .Fail(expected: "error (\(error.name))", got: "error (\(e.name))")
            }
          }
        case .Failure:
          return .Error("expansion failure")
        }
      case .Failure:
        return .Error("parse failure")
      }
    case .Failure:
      return .Error("lex failure")
    }
  }
}

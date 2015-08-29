//
//  results.swift
//  Lambdatron
//
//  Created by Austin Zheng on 8/29/15.
//  Copyright © 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// The result of evaluating a function, macro, or special form. Successfully returned values or error messages are
/// encapsulated in each case.
enum EvalResult {
  case Success(Value)
  case Recur(Params)
  case Failure(EvalError)

  func then(next: Value -> EvalResult) -> EvalResult {
    switch self {
    case let .Success(s): return next(s)
    case .Recur, .Failure: return self
    }
  }
}

/// A generic result that can be either a value or an `EvalError`.
public enum EvalOptional<T> {
  typealias Element = T
  case Just(T)
  case Error(EvalError)

  func then(next: T -> EvalResult) -> EvalResult {
    switch self {
    case let .Just(s): return next(s)
    case let .Error(err): return .Failure(err)
    }
  }

  var rawStringValue : String {
    switch self {
    case let .Just(s as String): return s
    case let .Just(s): return "\(s)"
    case let .Error(err): return err.description
    }
  }

  func forceUnwrap() -> T {
    switch self {
    case let .Just(s): return s
    case .Error: internalError("forceUnwrap() used incorrectly on \(self)...")
    }
  }
}

/// A generic result that can be either a value or a `ReadError`.
enum ReadOptional<T> {
  case Just(T)
  case Error(ReadError)

  func then<U>(next: T -> ReadOptional<U>) -> ReadOptional<U> {
    switch self {
    case let .Just(s): return next(s)
    case let .Error(err): return .Error(err)
    }
  }

  func then(fn: String, next: T -> EvalResult) -> EvalResult {
    switch self {
    case let .Just(s): return next(s)
    case let .Error(err): return .Failure(EvalError.readError(forFn: fn, error: err))
    }
  }
}

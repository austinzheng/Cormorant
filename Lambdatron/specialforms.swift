//
//  specialforms.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/10/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An enum describing all the special forms recognized by the interpreter
enum SpecialForm : String {
  case Quote = "quote"
  
  var function : LambdatronSpecialForm {
    get {
      switch self {
      case .Quote: return quote
      }
    }
  }
}

func quote(args: [ConsValue]) -> EvalResult {
  if args.count == 0 {
    return .Success(.NilLiteral)
  }
  let first = args[0]
  return .Success(first)
}

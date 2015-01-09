//
//  primitives.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

typealias LambdatronBuiltIn = ([ConsValue], Context) -> EvalResult

/// An enum describing every built-in function included with the interpreter.
enum BuiltIn : String, Printable {
  
  // Collection-related
  case List = ".list"
  case Vector = ".vector"
  case Hashmap = ".hashmap"
  case Cons = ".cons"
  case First = ".first"
  case Rest = ".rest"
  case Next = ".next"
  case Concat = ".concat"
  case Nth = ".nth"
  case Seq = ".seq"
  case Get = ".get"
  case Assoc = ".assoc"
  case Dissoc = ".dissoc"
  
  // I/O
  case Print = ".print"
  
  // Querying
  case IsNil = ".nil?"
  case IsNumber = ".number?"
  case IsInteger = ".int?"
  case IsFloat = ".float?"
  case IsString = ".string?"
  case IsSymbol = ".symbol?"
  case IsFn = ".fn?"
  case IsEvalable = ".eval?"
  case IsTrue = ".true?"
  case IsFalse = ".false?"
  case IsList = ".list?"
  case IsVector = ".vector?"
  case IsMap = ".map?"
  case IsSeq = ".seq?"
  
  // Identity comparison
  case Equals = ".="
  
  // Numeric comparison
  case NumericEquals = ".=="
  case GreaterThan = ".>"
  case LessThan = ".<"
  
  // Arithmetic
  case Plus = ".+"
  case Minus = ".-"
  case Multiply = ".*"
  case Divide = "./"
  case Mod = ".mod"
  
  // Miscellaneous
  case Fail = ".fail"
  
  // TEMPORARY BOOTSTRAP
  case BootstrapPlus = ".B+"
  case BootstrapMinus = ".B-"
  case BootstrapMultiply = ".B*"
  case BootstrapDivide = ".B/"
  
  var function : LambdatronBuiltIn {
    switch self {
    case List: return pr_list
    case Vector: return pr_vector
    case Hashmap: return pr_hashmap
    case Cons: return pr_cons
    case First: return pr_first
    case Rest: return pr_rest
    case Next: return pr_next
    case Concat: return pr_concat
    case Nth: return pr_nth
    case Seq: return pr_seq
    case Get: return pr_get
    case Assoc: return pr_assoc
    case Dissoc: return pr_dissoc
    case Print: return pr_print
    case IsNil: return pr_isNil
    case IsNumber: return pr_isNumber
    case IsInteger: return pr_isInteger
    case IsFloat: return pr_isFloat
    case IsString: return pr_isString
    case IsSymbol: return pr_isSymbol
    case IsFn: return pr_isFunction
    case IsEvalable: return pr_isEvalable
    case IsTrue: return pr_isTrue
    case IsFalse: return pr_isFalse
    case IsList: return pr_isList
    case IsVector: return pr_isVector
    case IsMap: return pr_isMap
    case IsSeq: return pr_isSeq
    case Equals: return pr_equals
    case NumericEquals: return pr_numericEquals
    case GreaterThan: return pr_gt
    case LessThan: return pr_lt
    case Plus: return pr_plus
    case Minus: return pr_minus
    case Multiply: return pr_multiply
    case Divide: return pr_divide
    case Mod: return pr_mod
    case Fail: return pr_fail
      
    // TEMPORARY
    case BootstrapPlus: return bootstrap_plus
    case BootstrapMinus: return bootstrap_minus
    case BootstrapMultiply: return bootstrap_multiply
    case BootstrapDivide: return bootstrap_divide
    }
  }
  
  var description : String {
    return self.rawValue
  }
}

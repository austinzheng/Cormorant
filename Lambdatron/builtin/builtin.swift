//
//  builtin.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

typealias LambdatronBuiltIn = ([ConsValue], Context) -> EvalResult

/// An enum describing every built-in function included with the interpreter.
public enum BuiltIn : String, Printable {
  
  // Collection-related
  case List = ".list"
  case Vector = ".vector"
  case Hashmap = ".hashmap"
  case Cons = ".cons"
  case First = ".first"
  case Rest = ".rest"
  case Next = ".next"
  case Conj = ".conj"
  case Concat = ".concat"
  case Nth = ".nth"
  case Seq = ".seq"
  case Get = ".get"
  case Assoc = ".assoc"
  case Dissoc = ".dissoc"

  // Primitive-related
  case Symbol = ".symbol"
  case Keyword = ".keyword"
  case Int = ".int"
  case Double = ".double"

  // I/O
  case Read = ".read"
  case ReadString = ".read-string"
  case Print = ".print"
  case Println = ".println"
  
  // Querying
  case IsNil = ".nil?"
  case IsNumber = ".number?"
  case IsInteger = ".int?"
  case IsFloat = ".float?"
  case IsString = ".string?"
  case IsChar = ".char?"
  case IsSymbol = ".symbol?"
  case IsKeyword = ".keyword?"
  case IsFn = ".fn?"
  case IsEvalable = ".eval?"
  case IsTrue = ".true?"
  case IsFalse = ".false?"
  case IsList = ".list?"
  case IsVector = ".vector?"
  case IsMap = ".map?"
  case IsSeq = ".seq?"
  case IsPos = ".pos?"
  case IsNeg = ".neg?"
  case IsZero = ".zero?"
  case IsSubnormal = ".subnormal?"
  case IsInfinite = ".infinite?"
  case IsNaN = ".nan?"
  
  // Identity comparison
  case Equals = ".="
  
  // Numeric comparison
  case NumericEquals = ".=="
  case GreaterThan = ".>"
  case GreaterThanOrEqual = ".>="
  case LessThan = ".<"
  case LessThanOrEqual = ".<="

  // Arithmetic
  case Plus = ".+"
  case Minus = ".-"
  case Multiply = ".*"
  case Divide = "./"
  case Remainder = ".rem"
  case Quotient = ".quot"
  
  // Miscellaneous
  case Rand = ".rand"
  case Eval = ".eval"
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
    case Conj: return pr_conj
    case Concat: return pr_concat
    case Nth: return pr_nth
    case Seq: return pr_seq
    case Get: return pr_get
    case Assoc: return pr_assoc
    case Dissoc: return pr_dissoc
    case Symbol: return pr_symbol
    case Keyword: return pr_keyword
    case Int: return pr_int
    case Double: return pr_double
    case Read: return pr_read
    case ReadString: return pr_readString
    case Print: return pr_print
    case Println: return pr_println
    case IsNil: return pr_isNil
    case IsNumber: return pr_isNumber
    case IsInteger: return pr_isInteger
    case IsFloat: return pr_isFloat
    case IsString: return pr_isString
    case IsChar: return pr_isChar
    case IsSymbol: return pr_isSymbol
    case IsKeyword: return pr_isKeyword
    case IsFn: return pr_isFunction
    case IsEvalable: return pr_isEvalable
    case IsTrue: return pr_isTrue
    case IsFalse: return pr_isFalse
    case IsList: return pr_isList
    case IsVector: return pr_isVector
    case IsMap: return pr_isMap
    case IsSeq: return pr_isSeq
    case IsPos: return pr_isPos
    case IsNeg: return pr_isNeg
    case IsZero: return pr_isZero
    case IsSubnormal: return pr_isSubnormal
    case IsInfinite: return pr_isInfinite
    case IsNaN: return pr_isNaN
    case Equals: return pr_equals
    case NumericEquals: return pr_numericEquals
    case GreaterThan: return pr_gt
    case GreaterThanOrEqual: return pr_gteq
    case LessThan: return pr_lt
    case LessThanOrEqual: return pr_lteq
    case Plus: return pr_plus
    case Minus: return pr_minus
    case Multiply: return pr_multiply
    case Divide: return pr_divide
    case Remainder: return pr_rem
    case Quotient: return pr_quot
    case Rand: return pr_rand
    case Eval: return pr_eval
    case Fail: return pr_fail
      
    // TEMPORARY
    case BootstrapPlus: return bootstrap_plus
    case BootstrapMinus: return bootstrap_minus
    case BootstrapMultiply: return bootstrap_multiply
    case BootstrapDivide: return bootstrap_divide
    }
  }
  
  public var description : String {
    return self.rawValue
  }
}

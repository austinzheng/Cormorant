//
//  builtin.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

typealias LambdatronBuiltIn = (Params, Context) -> EvalResult

internal let LIST = ConsValue.BuiltInFunction(.List)
internal let VECTOR = ConsValue.BuiltInFunction(.Vector)
internal let HASHMAP = ConsValue.BuiltInFunction(.Hashmap)
internal let CONCAT = ConsValue.BuiltInFunction(.Concat)
internal let SEQ = ConsValue.BuiltInFunction(.Seq)
internal let DEREF = ConsValue.BuiltInFunction(.Deref)

/// An enum describing every built-in function included with the interpreter.
public enum BuiltIn : String, CustomStringConvertible {

  // Namespace-related
  case NsCreate = ".ns-create"
  case NsSet = ".ns-set"
  case NsGet = ".ns-get"
  case NsName = ".ns-name"
  case NsAll = ".ns-all"
  case NsFind = ".ns-find"
  case NsUnmap = ".ns-unmap"
  case NsAlias = ".ns-alias"
  case NsAliases = ".ns-aliases"
  case NsUnalias = ".ns-unalias"
  case NsRefer = ".ns-refer"
  case NsMap = ".ns-map"
  case NsInterns = ".ns-interns"
  case NsRefers = ".ns-refers"
  case NsResolve = ".ns-resolve"
  case NsRemove = ".ns-remove"

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
  case LazySeq = ".lazy-seq"
  case Get = ".get"
  case Assoc = ".assoc"
  case Dissoc = ".dissoc"
  case Count = ".count"
  case Reduce = ".reduce"

  // Primitive-related
  case Symbol = ".symbol"
  case Keyword = ".keyword"
  case Namespace = ".namespace"
  case Int = ".int"
  case Double = ".double"

  // String-related
  case Str = ".str"
  case Subs = ".subs"
  case Lowercase = ".lower-case"
  case Uppercase = ".upper-case"
  case Replace = ".replace"
  case ReplaceFirst = ".replace-first"

  // String builder
  case Sb = ".sb"
  case SbAppend = ".sb-append"
  case SbReverse = ".sb-reverse"

  // Regex
  case RegexPattern = ".re-pattern"
  case RegexFirst = ".re-first"
  case RegexSeq = ".re-seq"
  case RegexIterate = ".re-iterate"
  case RegexQuoteReplace = ".re-quote-replacement"

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
  case IsVar = ".var?"
  case IsSeq = ".seq?"
  case IsVector = ".vector?"
  case IsMap = ".map?"
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
  case Deref = ".deref"
  case Gensym = ".gensym"
  case Rand = ".rand"
  case Eval = ".eval"
  case Fail = ".fail"
  
  var function : LambdatronBuiltIn {
    switch self {
    case .NsCreate: return ns_create
    case .NsSet: return ns_set
    case .NsGet: return ns_get
    case .NsName: return ns_name
    case .NsAll: return ns_all
    case .NsFind: return ns_find
    case .NsUnmap: return ns_unmap
    case .NsAlias: return ns_alias
    case .NsAliases: return ns_aliases
    case .NsUnalias: return ns_unalias
    case .NsRefer: return ns_refer
    case .NsMap: return ns_map
    case .NsInterns: return ns_interns
    case .NsRefers: return ns_refers
    case .NsResolve: return ns_resolve
    case .NsRemove: return ns_remove
    case .List: return pr_list
    case .Vector: return pr_vector
    case .Hashmap: return pr_hashmap
    case .Cons: return pr_cons
    case .First: return pr_first
    case .Rest: return pr_rest
    case .Next: return pr_next
    case .Conj: return pr_conj
    case .Concat: return pr_concat
    case .Nth: return pr_nth
    case .Seq: return pr_seq
    case .LazySeq: return pr_lazyseq
    case .Get: return pr_get
    case .Assoc: return pr_assoc
    case .Dissoc: return pr_dissoc
    case .Count: return pr_count
    case .Reduce: return pr_reduce
    case .Symbol: return pr_symbol
    case .Keyword: return pr_keyword
    case .Namespace: return pr_namespace
    case .Int: return pr_int
    case .Double: return pr_double
    case .Str: return str_str
    case .Subs: return str_subs
    case .Lowercase: return str_lowercase
    case .Uppercase: return str_uppercase
    case .Replace: return str_replace
    case .ReplaceFirst: return str_replaceFirst
    case .Sb: return sb_sb
    case .SbAppend: return sb_append
    case .SbReverse: return sb_reverse
    case .RegexPattern: return re_pattern
    case .RegexFirst: return re_first
    case .RegexSeq: return re_seq
    case .RegexIterate: return re_iterate
    case .RegexQuoteReplace: return re_quoteReplacement
    case .Read: return pr_read
    case .ReadString: return pr_readString
    case .Print: return pr_print
    case .Println: return pr_println
    case .IsNil: return pr_isNil
    case .IsNumber: return pr_isNumber
    case .IsInteger: return pr_isInteger
    case .IsFloat: return pr_isFloat
    case .IsString: return pr_isString
    case .IsChar: return pr_isChar
    case .IsSymbol: return pr_isSymbol
    case .IsKeyword: return pr_isKeyword
    case .IsFn: return pr_isFunction
    case .IsEvalable: return pr_isEvalable
    case .IsTrue: return pr_isTrue
    case .IsFalse: return pr_isFalse
    case .IsVar: return pr_isVar
    case .IsSeq: return pr_isSeq
    case .IsVector: return pr_isVector
    case .IsMap: return pr_isMap
    case .IsPos: return pr_isPos
    case .IsNeg: return pr_isNeg
    case .IsZero: return pr_isZero
    case .IsSubnormal: return pr_isSubnormal
    case .IsInfinite: return pr_isInfinite
    case .IsNaN: return pr_isNaN
    case .Equals: return pr_equals
    case .NumericEquals: return pr_numericEquals
    case .GreaterThan: return pr_gt
    case .GreaterThanOrEqual: return pr_gteq
    case .LessThan: return pr_lt
    case .LessThanOrEqual: return pr_lteq
    case .Plus: return pr_plus
    case .Minus: return pr_minus
    case .Multiply: return pr_multiply
    case .Divide: return pr_divide
    case .Remainder: return pr_rem
    case .Quotient: return pr_quot
    case .Deref: return pr_deref
    case .Gensym: return pr_gensym
    case .Rand: return pr_rand
    case .Eval: return pr_eval
    case .Fail: return pr_fail
    }
  }
  
  public var description : String {
    return self.rawValue
  }
}

//
//  core.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An opaque type representing a Vector data structure.
public typealias Vector = [ConsValue]

/// An opaque type representing a Map data structure.
public typealias Map = [ConsValue:ConsValue]

/// Represents the value of an item in a single cons cell. ConsValues are comprised of atoms and collections.
public enum ConsValue : Printable, Hashable {
  case Symbol(InternedSymbol)
  case Keyword(InternedKeyword)
  case Special(SpecialForm)
  case BuiltInFunction(BuiltIn)
  case ReaderMacro(ReaderForm)
  case NilLiteral
  case BoolLiteral(Bool)
  case IntegerLiteral(Int)
  case FloatLiteral(Double)
  case CharacterLiteral(Character)
  case StringLiteral(String)
  case ListLiteral(List<ConsValue>)
  case VectorLiteral(Vector)
  case MapLiteral(Map)
  case FunctionLiteral(Function)
  
  public var hashValue : Int {
    switch self {
    case let Symbol(s): return s.hashValue
    case let Keyword(k): return k.hashValue
    case let Special(sf): return sf.hashValue
    case let BuiltInFunction(bf): return bf.hashValue
    case let ReaderMacro(rf): return rf.hashValue
    case NilLiteral: return 0
    case let BoolLiteral(b): return b.hashValue
    case let IntegerLiteral(v): return v.hashValue
    case let FloatLiteral(d): return d.hashValue
    case let CharacterLiteral(c): return c.hashValue
    case let StringLiteral(s): return s.hashValue
    case let ListLiteral(l): return l.hashValue
    case let VectorLiteral(v): return v.count == 0 ? 0 : v[0].hashValue
    case let MapLiteral(m): return m.count
    case let FunctionLiteral(f): return 0
    }
  }
  
  func asInteger() -> Int? {
    switch self {
    case let .IntegerLiteral(v): return v
    default: return nil
    }
  }
  
  func asStringLiteral() -> String? {
    switch self {
    case let .StringLiteral(s): return s
    default: return nil
    }
  }
  
  func asSymbol() -> InternedSymbol? {
    switch self {
    case let .Symbol(s): return s
    default: return nil
    }
  }

  func asKeyword() -> InternedKeyword? {
    switch self {
    case let .Keyword(k): return k
    default: return nil
    }
  }
  
  func asList() -> List<ConsValue>? {
    switch self {
    case let .ListLiteral(l): return l
    default: return nil
    }
  }
  
  func asVector() -> Vector? {
    switch self {
    case let .VectorLiteral(v): return v
    default: return nil
    }
  }
  
  func asMap() -> Map? {
    switch self {
    case let .MapLiteral(m): return m
    default: return nil
    }
  }
  
  func asBuiltIn() -> LambdatronBuiltIn? {
    switch self {
    case let .BuiltInFunction(b): return b.function
    default: return nil
    }
  }
  
  func asFunction() -> Function? {
    switch self {
    case let .FunctionLiteral(f): return f
    default: return nil
    }
  }

  func asMacro(ctx: Context) -> Macro? {
    switch self {
    case let .Symbol(identifier):
      let symbolValue = ctx[identifier]
      switch symbolValue {
      case let .BoundMacro(m): return m
      case .Invalid, .Unbound, .Param, .Literal: return nil
      }
    default: return nil
    }
  }

  func asSpecialForm() -> SpecialForm? {
    switch self {
    case let .Special(s): return s
    default: return nil
    }
  }

  public var description : String {
    return describe(nil)
  }

  var debugDescription : String {
    return describe(nil, debug: true)
  }
}

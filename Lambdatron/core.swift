//
//  core.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An opaque type representing a Vector data structure.
public typealias VectorType = [ConsValue]

/// An opaque type representing a Map data structure.
public typealias MapType = [ConsValue:ConsValue]

/// Represents the value of an item in a single cons cell. ConsValues are comprised of atoms and collections.
public enum ConsValue : IntegerLiteralConvertible, FloatLiteralConvertible, BooleanLiteralConvertible, Printable, DebugPrintable, Hashable {
  case Nil
  case BoolAtom(Bool)
  case IntAtom(Int)
  case FloatAtom(Double)
  case CharAtom(Character)
  case StringAtom(String)
  case Symbol(InternedSymbol)
  case Keyword(InternedKeyword)
  case Auxiliary(AuxiliaryType)
  case List(ListType<ConsValue>)
  case Vector(VectorType)
  case Map(MapType)
  case FunctionLiteral(Function)
  case BuiltInFunction(BuiltIn)
  case Special(SpecialForm)
  case ReaderMacroForm(ReaderMacro)

  public var hashValue : Int {
    switch self {
    case .Nil: return 0
    case let .BoolAtom(v): return v.hashValue
    case let .IntAtom(v): return v.hashValue
    case let .FloatAtom(v): return v.hashValue
    case let .CharAtom(c): return c.hashValue
    case let .StringAtom(s): return s.hashValue
    case let .Symbol(s): return s.hashValue
    case let .Keyword(k): return k.hashValue
    case let .Auxiliary(a): return a.hashValue
    case let .List(l): return l.hashValue
    case let .Vector(v): return v.count == 0 ? 0 : v[0].hashValue
    case let .Map(m): return m.count
    case let .FunctionLiteral(f): return 0
    case let .BuiltInFunction(bf): return bf.hashValue
    case let .Special(sf): return sf.hashValue
    case let .ReaderMacroForm(rf): return rf.hashValue
    }
  }

  public var description : String { return describe(nil) }
  public var debugDescription : String { return debugDescribe(nil) }

  public init(integerLiteral value: Int) { self = .IntAtom(value) }
  public init(floatLiteral value: Double) { self = .FloatAtom(value) }
  public init(booleanLiteral value: Bool) { self = .BoolAtom(value) }

  var asBool : Bool? {
    switch self {
    case let .BoolAtom(b): return b
    default: return nil
    }
  }

  var asInteger : Int? {
    switch self {
    case let .IntAtom(v): return v
    default: return nil
    }
  }

  var asString : String? {
    switch self {
    case let .StringAtom(s): return s
    default: return nil
    }
  }

  var asCharacter : Character? {
    switch self {
    case let .CharAtom(c): return c
    default: return nil
    }
  }

  var asSymbol : InternedSymbol? {
    switch self {
    case let .Symbol(s): return s
    default: return nil
    }
  }

  var asKeyword : InternedKeyword? {
    switch self {
    case let .Keyword(k): return k
    default: return nil
    }
  }

  var asList : ListType<ConsValue>? {
    switch self {
    case let .List(l): return l
    default: return nil
    }
  }

  var asVector : VectorType? {
    switch self {
    case let .Vector(v): return v
    default: return nil
    }
  }

  var asMap : MapType? {
    switch self {
    case let .Map(m): return m
    default: return nil
    }
  }
  
  var asBuiltIn : BuiltIn? {
    switch self {
    case let .BuiltInFunction(b): return b
    default: return nil
    }
  }
  
  var asFunction : Function? {
    switch self {
    case let .FunctionLiteral(f): return f
    default: return nil
    }
  }

  var asSpecialForm : SpecialForm? {
    switch self {
    case let .Special(s): return s
    default: return nil
    }
  }

  var asStringBuilder : StringBuilderType? {
    switch self {
    case let .Auxiliary(aux): return aux as? StringBuilderType
    default: return nil
    }
  }

  var asRegexPattern : NSRegularExpression? {
    switch self {
    case let .Auxiliary(aux): return aux as? NSRegularExpression
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

  /// Extract value into an equivalent NumericalType token.
  func extractNumber() -> NumericalType {
    switch self {
    case let .IntAtom(v): return .Integer(v)
    case let .FloatAtom(v): return .Float(v)
    default: return .Invalid
    }
  }

  /// Extract value into an integer, if possible.
  func extractInt() -> Int? {
    switch self {
    case let .IntAtom(v): return v
    case let .FloatAtom(v): return Int(v)
    default: return nil
    }
  }
}

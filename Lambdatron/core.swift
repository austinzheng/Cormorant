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

/// A wrapper for a Map that provides a different iterator for use with the interpreter. This iterator returns each
/// element as a Vector containing the key and value ConsValues.
struct MapSequence : SequenceType, GeneratorType {
  let map : MapType
  var generator : DictionaryGenerator<ConsValue, ConsValue>

  init(_ map: MapType) { self.map = map; self.generator = map.generate() }

  func generate() -> MapSequence { return self }

  /// If the wrapped map is not empty, return the first key-value pair in the MapSequence as a Vector.
  func first() -> ConsValue? {
    var t = self.generate()
    return t.next()
  }

  mutating func next() -> ConsValue? {
    if let (key, value) = generator.next() {
      return .Vector([key, value])
    }
    return nil
  }
}

/// Represents the value of an item in a single cons cell. ConsValues are comprised of atoms and collections.
public enum ConsValue : Printable, Hashable {
  case Nil
  case BoolAtom(Bool)
  case IntAtom(Int)
  case FloatAtom(Double)
  case CharAtom(Character)
  case StringAtom(String)
  case Symbol(InternedSymbol)
  case Keyword(InternedKeyword)
  case List(ListType<ConsValue>)
  case Vector(VectorType)
  case Map(MapType)
  case FunctionLiteral(Function)
  case BuiltInFunction(BuiltIn)
  case Special(SpecialForm)
  case ReaderMacro(ReaderForm)
  
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
    case let .List(l): return l.hashValue
    case let .Vector(v): return v.count == 0 ? 0 : v[0].hashValue
    case let .Map(m): return m.count
    case let .FunctionLiteral(f): return 0
    case let .BuiltInFunction(bf): return bf.hashValue
    case let .Special(sf): return sf.hashValue
    case let .ReaderMacro(rf): return rf.hashValue
    }
  }
  
  func asInteger() -> Int? {
    switch self {
    case let .IntAtom(v): return v
    default: return nil
    }
  }
  
  func asString() -> String? {
    switch self {
    case let .StringAtom(s): return s
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
  
  func asList() -> ListType<ConsValue>? {
    switch self {
    case let .List(l): return l
    default: return nil
    }
  }
  
  func asVector() -> VectorType? {
    switch self {
    case let .Vector(v): return v
    default: return nil
    }
  }
  
  func asMap() -> MapType? {
    switch self {
    case let .Map(m): return m
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

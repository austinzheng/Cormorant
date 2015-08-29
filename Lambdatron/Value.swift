//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An opaque type representing a Vector data structure.
public typealias VectorType = [Value]

/// An opaque type representing a Map data structure.
public typealias MapType = [Value : Value]

/// An opaque type representing a regular expression.
public typealias RegularExpressionType = NSRegularExpression

/// A sum type representing an atom, collection, or other fundamental Lambdatron type.
public enum Value {
  case Nil
  case BoolAtom(Bool)
  case IntAtom(Int)
  case FloatAtom(Double)
  case CharAtom(Character)
  case StringAtom(String)
  case Symbol(InternedSymbol)
  case Keyword(InternedKeyword)
  case Namespace(NamespaceContext)
  case Var(VarType)
  case Auxiliary(AuxiliaryType)
  case Seq(SeqType)
  case Vector(VectorType)
  case Map(MapType)
  case MacroLiteral(Macro)
  case FunctionLiteral(Function)
  case BuiltInFunction(BuiltIn)
  case Special(SpecialForm)
  case ReaderMacroForm(ReaderMacro)
}


// MARK: Var

/// An explicitly unbound representation of a Var. Note that an UnboundVar is not considered a Var.
final class UnboundVarObject : AuxiliaryType {
  let name : String
  var hashValue : Int { return name.hashValue }

  func describe() -> String { return "#<Unbound Unbound: #'\(name)>" }
  func debugDescribe() -> String { return "Object.UnboundVarObject(\(name))" }
  func toString() -> String { return describe() }

  func equals(that: AuxiliaryType) -> Bool {
    if let that = that as? UnboundVarObject {
      return self.name == that.name
    }
    return false
  }

  init(_ name: InternedSymbol, ctx: Context) {
    self.name = name.fullName(ctx)
  }
}

public func ==(lhs: VarType, rhs: VarType) -> Bool {
  return lhs.name == rhs.name && lhs.store == rhs.store
}

public final class VarType : Hashable {
  private(set) var store : Value? = nil

  /// A symbol used to determine how the Var is canonically named.
  let name : InternedSymbol

  public var hashValue : Int { return name.hashValue }

  /// Whether or not this Var is bound to a value.
  var isBound : Bool { return store != nil }

  func value(usingContext ctx: Context) -> Value {
    return store ?? .Auxiliary(UnboundVarObject(name, ctx: ctx))
  }

  /// Bind a new value to this Var
  func bindValue(value: Value) { store = value }

  init(_ name: InternedSymbol, value: Value? = nil) { self.name = name; store = value }
}

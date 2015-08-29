//
//  Created by Austin Zheng on 9/18/15.
//  Copyright © 2015 Austin Zheng. All rights reserved.
//

import Foundation

// MARK: Hashable

extension Value : Hashable {
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
    case let .Namespace(namespace): return namespace.name.hashValue
    case let .Var(v): return v.hashValue
    case let .Auxiliary(a): return a.hashValue
    case let .Seq(seq): return seq.hashValue
    case let .Vector(v): return v.count == 0 ? 0 : v[0].hashValue
    case let .Map(m): return m.count
    case let .MacroLiteral(macro): return macro.hashValue
    case let .FunctionLiteral(fn): return fn.hashValue
    case let .BuiltInFunction(bf): return bf.hashValue
    case let .Special(sf): return sf.hashValue
    case let .ReaderMacroForm(rf): return rf.hashValue
    }
  }
}


// MARK: Convertibility

extension Value : CustomStringConvertible {
  public var description : String {
    return describe(nil).rawStringValue
  }

  public var debugDescription : String {
    return debugDescribe(nil).rawStringValue
  }
}

extension Value : IntegerLiteralConvertible {
  public init(integerLiteral value: Int) {
    self = .IntAtom(value)
  }
}

extension Value : FloatLiteralConvertible {
  public init(floatLiteral value: Double) {
    self = .FloatAtom(value)
  }
}

extension Value : BooleanLiteralConvertible {
  public init(booleanLiteral value: Bool) {
    self = .BoolAtom(value)
  }
}


// MARK: Extractors

extension Value {

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

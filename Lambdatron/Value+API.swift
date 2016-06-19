//
//  Created by Austin Zheng on 9/18/15.
//  Copyright © 2015 Austin Zheng. All rights reserved.
//

import Foundation

// MARK: Hashable

extension Value : Hashable {
  public var hashValue : Int {
    switch self {
    case .nilValue: return 0
    case let .bool(v): return v.hashValue
    case let .int(v): return v.hashValue
    case let .float(v): return v.hashValue
    case let .char(c): return c.hashValue
    case let .string(s): return s.hashValue
    case let .symbol(s): return s.hashValue
    case let .keyword(k): return k.hashValue
    case let .namespace(namespace): return namespace.name.hashValue
    case let .`var`(v): return v.hashValue
    case let .auxiliary(a): return a.hashValue
    case let .seq(seq): return seq.hashValue
    case let .vector(v): return v.count == 0 ? 0 : v[0].hashValue
    case let .map(m): return m.count
    case let .macroLiteral(macro): return macro.hashValue
    case let .functionLiteral(fn): return fn.hashValue
    case let .builtInFunction(bf): return bf.hashValue
    case let .special(sf): return sf.hashValue
    case let .readerMacroForm(rf): return rf.hashValue
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
    self = .int(value)
  }
}

extension Value : FloatLiteralConvertible {
  public init(floatLiteral value: Double) {
    self = .float(value)
  }
}

extension Value : BooleanLiteralConvertible {
  public init(booleanLiteral value: Bool) {
    self = .bool(value)
  }
}


// MARK: Extractors

extension Value {

  /// Extract value into an equivalent NumericalType token.
  func extractNumber() -> NumericalType {
    switch self {
    case let .int(v): return .Integer(v)
    case let .float(v): return .Float(v)
    default: return .Invalid
    }
  }

  /// Extract value into an integer, if possible.
  func extractInt() -> Int? {
    switch self {
    case let .int(v): return v
    case let .float(v): return Int(v)
    default: return nil
    }
  }
}

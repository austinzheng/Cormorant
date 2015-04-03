//
//  description.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/19/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An enum containing either a description, or an error caused while trying to calculate the description.
public enum DescribeResult : Printable, StringLiteralConvertible {
  case Desc(String)
  case Error(EvalError)

  public var description : String { return asString }

  /// Return either the description, or a human-readable string representation of the error.
  public var asString : String {
    switch self {
    case let .Desc(s): return s
    case let .Error(err): return err.description
    }
  }

  func force() -> String {
    switch self {
    case let .Desc(s): return s
    case let .Error(err): internalError("DescribeResult's 'force' method used improperly")
    }
  }

  public init(extendedGraphemeClusterLiteral value: Character) { self = .Desc(String(value)) }
  public init(stringLiteral value: String) { self = .Desc(value) }
  public init(unicodeScalarLiteral value: Character) { self = .Desc(String(value)) }
}


// MARK: Describe

/// Given a list, return a description (e.g. "(a b c d e)" for a five-item list).
func describeSeq(seq: SeqType, ctx: Context?, debug: Bool = false) -> DescribeResult {
  var buffer : [String] = []
  for item in SeqIterator(seq) {
    switch item {
    case let .Success(item):
      // Successfully got the item out of the list, now describe it
      let result = debug ? item.debugDescribe(ctx) : item.describe(ctx)
      switch result {
      case let .Desc(item): buffer.append(item)
      case .Error: return result
      }
    case let .Error(err):
      return .Error(err)
    }
  }
  let final = join(" ", buffer)
  return .Desc("(\(final))")
}

/// Given a vector, return a description.
func describeVector(vector: VectorType, ctx: Context?, debug: Bool = false) -> DescribeResult {
  var buffer : [String] = []
  for item in vector {
    let result = debug ? item.debugDescribe(ctx) : item.describe(ctx)
    switch result {
    case let .Desc(item): buffer.append(item)
    case .Error: return result
    }
  }
  let final = join(" ", buffer)
  return .Desc("[\(final)]")
}

/// Given a map, return a description.
func describeMap(map: MapType, ctx: Context?, debug: Bool = false) -> DescribeResult {
  var buffer : [String] = []
  for (key, value) in map {
    let result = debug ? key.debugDescribe(ctx) : key.describe(ctx)
    switch result {
    case let .Desc(key):
      let result = debug ? value.debugDescribe(ctx) : value.describe(ctx)
      switch result {
      case let .Desc(value):
        buffer.append("\(key) \(value)")
      case .Error: return result
      }
    case .Error: return result
    }
  }
  let final = join(", ", buffer)
  return .Desc("{\(final)}")
}

extension ConsValue {

  /// Return the stringified version of an object.
  func toString(ctx: Context) -> DescribeResult {
    switch self {
    case let .Nil:
      return ""
    case let .CharAtom(char):
      return .Desc(String(char))
    case let .StringAtom(str):
      return .Desc(str)
    case let .Auxiliary(aux):
      return .Desc(aux.toString())
    default:
      return self.describe(ctx)
    }
  }

  /// Return a description of an object. If the object is a string, any constituent characters will be converted to the
  /// appropriate two-character escape sequence if necessary.
  func describe(ctx: Context?) -> DescribeResult {
    switch self {
    case .Nil:
      return "nil"
    case let .BoolAtom(bool):
      return .Desc(bool ? "true" : "false")
    case let .IntAtom(int):
      return .Desc(int.description)
    case let .FloatAtom(double):
      return .Desc(double.description)
    case let .CharAtom(char):
      return .Desc(charLiteralDesc(char))
    case let .StringAtom(str):
      return .Desc("\"" + stringByEscaping(str) + "\"")
    case let .Symbol(symbol):
      if let ctx = ctx { return .Desc(symbol.fullName(ctx)) }
      return .Desc("symbol:\(symbol.rawDescription)")
    case let .Keyword(keyword):
      if let ctx = ctx { return .Desc(keyword.fullName(ctx)) }
      return .Desc("keyword:\(keyword.rawDescription)")
    case let .Namespace(namespace):
      return .Desc("#<Namespace \(namespace.name)>")
    case let .Var(v):
      if let ctx = ctx { return .Desc("#'\(v.name.fullName(ctx))") }
      if let ns = v.name.ns { return .Desc("#<Var ns:\(ns.name)/id:\(v.name.identifier)>") }
      return .Desc("#<Var (error)>")
    case let .Auxiliary(aux):
      return .Desc(aux.describe())
    case let .Seq(list):
      return describeSeq(list, ctx, debug: false)
    case let .Vector(vector):
      return describeVector(vector, ctx, debug: false)
    case let .Map(map):
      return describeMap(map, ctx, debug: false)
    case .MacroLiteral: return "{{macro}}"
    case .FunctionLiteral: return "{{function}}"
    case let .BuiltInFunction(v):
      return .Desc(v.rawValue)
    case let .Special(v):
      return .Desc(v.rawValue)
    case let .ReaderMacroForm(v):
      return .Desc("{{reader_macro}}")
    }
  }

  /// Return a debug description of an object.
  func debugDescribe(ctx: Context?) -> DescribeResult {
    switch self {
    case .Nil:
      return "Object.Nil"
    case let .BoolAtom(bool):
      let desc = bool ? "true" : "false"
      return .Desc("Object.BoolAtom(\(desc))")
    case let .IntAtom(int):
      return .Desc("Object.IntAtom(\(int.description))")
    case let .FloatAtom(double):
      return .Desc("Object.FloatAtom(\(double.description))")
    case let .CharAtom(char):
      return .Desc("Object.CharAtom(\(charLiteralDesc(char)))")
    case let .StringAtom(str):
      return .Desc("Object.StringAtom(\"\(str)\")")
    case let .Symbol(symbol):
      if let ctx = ctx { return .Desc("Object.Symbol(\(symbol.fullName(ctx)))") }
      return .Desc("Object.Symbol(\(symbol.rawDescription))")
    case let .Keyword(keyword):
      if let ctx = ctx { return .Desc("Object.Keyword(\(keyword.fullName(ctx)))") }
      return .Desc("Object.Keyword(\(keyword.rawDescription))")
    case let .Namespace(namespace):
      return .Desc("Object.Namespace(\"\(namespace.name)\")")
    case let .Var(v):
      if let ctx = ctx { return .Desc("Object.Var(\(v.name.fullName(ctx)))") }
      if let ns = v.name.ns { return .Desc("Object.Var(ns:\(ns.name)/id:\(v.name.identifier))") }
      return .Desc("Object.Var(error)")
    case let .Auxiliary(aux):
      return .Desc(aux.debugDescribe())
    case let .Seq(seq):
      let result = describeSeq(seq, ctx, debug: true)
      switch result {
      case let .Desc(desc): return .Desc("Object.Seq( \(desc) )")
      case .Error: return result
      }
    case let .Vector(vector):
      let result = describeVector(vector, ctx, debug: true)
      switch result {
      case let .Desc(desc): return .Desc("Object.Vector( \(desc) )")
      case .Error: return result
      }
    case let .Map(map):
      let result = describeMap(map, ctx, debug: true)
      switch result {
      case let .Desc(desc): return .Desc("Object.Map( \(desc) )")
      case .Error: return result
      }
    case .MacroLiteral: return "Object.Macro"
    case .FunctionLiteral: return "Object.Function"
    case let .BuiltInFunction(v):
      return .Desc("Object.BuiltInFunction(\(v.rawValue))")
    case let .Special(v):
      return .Desc("Object.Special(\(v.rawValue))")
    case let .ReaderMacroForm(v):
      return .Desc(v.debugDescribe(ctx))
    }
  }
}


// MARK: Miscellaneous

// Description-related extension for the Params struct.
extension Params {

  func describe(ctx: Context?) -> DescribeResult {
    var buffer : [String] = []
    for param in self {
      let result = param.describe(ctx)
      switch result {
      case let .Desc(description): buffer.append(description)
      case .Error: return result
      }
    }
    return .Desc("Params: {{" + join(" ", buffer) + "}}")
  }
}


// MARK: Helper functions

/// Return the Clojure-style description of a character literal.
private func charLiteralDesc(char: Character) -> String {
  let backspace = Character(UnicodeScalar(8))
  let formfeed = Character(UnicodeScalar(12))

  let name : String
  switch char {
  case "\n": name = "newline"
  case "\r": name = "return"
  case " ": name = "space"
  case "\t": name = "tab"
  case backspace: name = "backspace"
  case formfeed: name = "formfeed"
  default: name = "\(char)"
  }

  return "\\" + name
}

/// Given a Swift string, return the same string with escape sequences escaped out.
func stringByEscaping(s: String) -> String {
  var buffer : String = ""
  for character in s {
    switch character {
    case "\\": buffer.extend("\\\\")
    case "\"": buffer.extend("\\\"")
    case "\t": buffer.extend("\\t")
    case "\r": buffer.extend("\\r")
    case "\n": buffer.extend("\\n")
    default: buffer.append(character)
    }
  }
  return buffer
}

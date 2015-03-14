//
//  description.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/19/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation


// MARK: Describe

/// Given a list, return a description (e.g. "(a b c d e)" for a five-item list).
func describeList(list: ListType<ConsValue>, c: Context?, debug: Bool = false) -> String {
  let descs = map(list) { debug ? $0.debugDescribe(c) : $0.describe(c) }
  let final = join(" ", descs)
  return "(\(final))"
}

/// Given a vector, return a description.
func describeVector(vector: VectorType, c: Context?, debug: Bool = false) -> String {
  let descs = map(vector) { debug ? $0.debugDescribe(c) : $0.describe(c) }
  let final = join(" ", descs)
  return "[\(final)]"
}

/// Given a map, return a description.
func describeMap(m: MapType, c: Context?, debug: Bool = false) -> String {
  let descs = map(m) {
    (debug ? $0.0.debugDescribe(c) : $0.0.describe(c)) + " " + (debug ? $0.1.debugDescribe(c) : $0.1.describe(c))
  }
  let final = join(", ", descs)
  return "{\(final)}"
}

extension ConsValue {

  /// Return the stringified version of an object.
  func toString(ctx: Context) -> String {
    switch self {
    case let .Nil:
      return ""
    case let .CharAtom(char):
      return String(char)
    case let .StringAtom(str):
      return str
    case let .Auxiliary(aux):
      return aux.toString()
    default:
      return self.describe(ctx)
    }
  }

  /// Return a description of an object. If the object is a string, any constituent characters will be converted to the
  /// appropriate two-character escape sequence if necessary.
  func describe(ctx: Context?) -> String {
    switch self {
    case .Nil:
      return "nil"
    case let .BoolAtom(bool):
      return bool ? "true" : "false"
    case let .IntAtom(int):
      return int.description
    case let .FloatAtom(double):
      return double.description
    case let .CharAtom(char):
      return charLiteralDesc(char)
    case let .StringAtom(str):
      return "\"" + stringByEscaping(str) + "\""
    case let .Symbol(symbol):
      if let ctx = ctx {
        return ctx.nameForSymbol(symbol)
      }
      return "symbol:\(symbol.identifier)"
    case let .Keyword(keyword):
      if let ctx = ctx {
        return ":" + ctx.nameForKeyword(keyword)
      }
      return "keyword:\(keyword.identifier)"
    case let .Auxiliary(aux):
      return aux.describe()
    case let .List(list):
      return describeList(list, ctx, debug: false)
    case let .Vector(vector):
      return describeVector(vector, ctx, debug: false)
    case let .Map(map):
      return describeMap(map, ctx, debug: false)
    case let .FunctionLiteral(v):
      return "{{function}}"
    case let .BuiltInFunction(v):
      return v.rawValue
    case let .Special(v):
      return v.rawValue
    case let .ReaderMacroForm(v):
      return v.describe(ctx)
    }
  }

  /// Return a debug description of an object.
  func debugDescribe(ctx: Context?) -> String {
    switch self {
    case .Nil:
      return "Object.Nil"
    case let .BoolAtom(bool):
      let desc = bool ? "true" : "false"
      return "Object.BoolAtom(\(desc))"
    case let .IntAtom(int):
      return "Object.IntAtom(\(int.description))"
    case let .FloatAtom(double):
      return "Object.FloatAtom(\(double.description))"
    case let .CharAtom(char):
      return "Object.CharAtom(\(charLiteralDesc(char)))"
    case let .StringAtom(str):
      return "Object.StringAtom(\"\(str)\")"
    case let .Symbol(symbol):
      if let ctx = ctx {
        return "Object.Symbol(\(ctx.nameForSymbol(symbol)))"
      }
      return "Object.Symbol(id:\(symbol.identifier))"
    case let .Keyword(keyword):
      if let ctx = ctx {
        return "Object.Keyword(:\(ctx.nameForKeyword(keyword)))"
      }
      return "Object.Keyword(id:\(keyword.identifier))"
    case let .Auxiliary(aux):
      return aux.debugDescribe()
    case let .List(list):
      let desc = describeList(list, ctx, debug: true)
      return "Object.List( \(desc) )"
    case let .Vector(vector):
      let desc = describeVector(vector, ctx, debug: true)
      return "Object.Vector( \(desc) )"
    case let .Map(map):
      let desc = describeMap(map, ctx, debug: true)
      return "Object.Map( \(desc) )"
    case let .FunctionLiteral(v):
      return "Object.FunctionLiteral"
    case let .BuiltInFunction(v):
      return "Object.BuiltInFunction(\(v.rawValue))"
    case let .Special(v):
      return "Object.Special(\(v.rawValue))"
    case let .ReaderMacroForm(v):
      return "Object.ReaderMacroForm"
    }
  }
}


// MARK: Miscellaneous

// Description-related extension for the Params struct.
extension Params {

  func describe(ctx: Context?) -> String {
    var buffer : [String] = []
    for param in self {
      buffer.append(param.describe(ctx))
    }
    return "Params: {{" + join(" ", buffer) + "}}"
  }
}


// MARK: Helper functions

/// Return the Clojure-style description of a character literal.
private func charLiteralDesc(char: Character) -> String {
  let backspace = Character(UnicodeScalar(8))
  let formfeed = Character(UnicodeScalar(12))
  let name : String = {
    switch char {
    case "\n": return "newline"
    case "\r": return "return"
    case " ": return "space"
    case "\t": return "tab"
    case backspace: return "backspace"
    case formfeed: return "formfeed"
    default: return "\(char)"
    }
    }()
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

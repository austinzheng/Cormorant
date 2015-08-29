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
func describeSeq(seq: SeqType, _ ctx: Context?, debug: Bool = false) -> EvalOptional<String> {
  var buffer : [String] = []
  for item in SeqIterator(seq) {
    switch item {
    case let .Just(item):
      // Successfully got the item out of the list, now describe it
      let result = debug ? item.debugDescribe(ctx) : item.describe(ctx)
      switch result {
      case let .Just(item): buffer.append(item)
      case .Error: return result
      }
    case let .Error(err):
      return .Error(err)
    }
  }
  let final = buffer.joinWithSeparator(" ")
  return .Just("(\(final))")
}

/// Given a vector, return a description.
func describeVector(vector: VectorType, _ ctx: Context?, debug: Bool = false) -> EvalOptional<String> {
  var buffer : [String] = []
  for item in vector {
    let result = debug ? item.debugDescribe(ctx) : item.describe(ctx)
    switch result {
    case let .Just(item): buffer.append(item)
    case .Error: return result
    }
  }
  let final = buffer.joinWithSeparator(" ")
  return .Just("[\(final)]")
}

/// Given a map, return a description.
func describeMap(map: MapType, _ ctx: Context?, debug: Bool = false) -> EvalOptional<String> {
  var buffer : [String] = []
  for (key, value) in map {
    let result = debug ? key.debugDescribe(ctx) : key.describe(ctx)
    switch result {
    case let .Just(key):
      let result = debug ? value.debugDescribe(ctx) : value.describe(ctx)
      switch result {
      case let .Just(value):
        buffer.append("\(key) \(value)")
      case .Error: return result
      }
    case .Error: return result
    }
  }
  let final = buffer.joinWithSeparator(" ")
  return .Just("{\(final)}")
}

extension Value {

  /// Return the stringified version of an object.
  func toString(ctx: Context) -> EvalOptional<String> {
    switch self {
    case .Nil:
      return .Just("")
    case let .CharAtom(char):
      return .Just(String(char))
    case let .StringAtom(str):
      return .Just(str)
    case let .Auxiliary(aux):
      return .Just(aux.toString())
    default:
      return self.describe(ctx)
    }
  }

  /// Return a description of an object. If the object is a string, any constituent characters will be converted to the
  /// appropriate two-character escape sequence if necessary.
  func describe(ctx: Context?) -> EvalOptional<String> {
    switch self {
    case .Nil:
      return .Just("nil")
    case let .BoolAtom(bool):
      return .Just(bool ? "true" : "false")
    case let .IntAtom(int):
      return .Just(int.description)
    case let .FloatAtom(double):
      return .Just(double.description)
    case let .CharAtom(char):
      return .Just(charLiteralDesc(char))
    case let .StringAtom(str):
      return .Just("\"" + stringByEscaping(str) + "\"")
    case let .Symbol(symbol):
      if let ctx = ctx {
        return .Just(symbol.fullName(ctx))
      }
      return .Just("symbol:\(symbol.rawDescription)")
    case let .Keyword(keyword):
      if let ctx = ctx {
        return .Just(keyword.fullName(ctx))
      }
      return .Just("keyword:\(keyword.rawDescription)")
    case let .Namespace(namespace):
      return .Just("#<Namespace \(namespace.name)>")
    case let .Var(v):
      if let ctx = ctx {
        return .Just("#'\(v.name.fullName(ctx))")
      }
      if let ns = v.name.ns {
        return .Just("#<Var ns:\(ns.name)/id:\(v.name.identifier)>")
      }
      return .Just("#<Var (error)>")
    case let .Auxiliary(aux):
      return .Just(aux.describe())
    case let .Seq(list):
      return describeSeq(list, ctx, debug: false)
    case let .Vector(vector):
      return describeVector(vector, ctx, debug: false)
    case let .Map(map):
      return describeMap(map, ctx, debug: false)
    case .MacroLiteral:
      return .Just("{{macro}}")
    case .FunctionLiteral:
      return .Just("{{function}}")
    case let .BuiltInFunction(v):
      return .Just(v.rawValue)
    case let .Special(v):
      return .Just(v.rawValue)
    case .ReaderMacroForm:
      return .Just("{{reader_macro}}")
    }
  }

  /// Return a debug description of an object.
  func debugDescribe(ctx: Context?) -> EvalOptional<String> {
    switch self {
    case .Nil:
      return .Just("Object.Nil")
    case let .BoolAtom(bool):
      let desc = bool ? "true" : "false"
      return .Just("Object.BoolAtom(\(desc))")
    case let .IntAtom(int):
      return .Just("Object.IntAtom(\(int.description))")
    case let .FloatAtom(double):
      return .Just("Object.FloatAtom(\(double.description))")
    case let .CharAtom(char):
      return .Just("Object.CharAtom(\(charLiteralDesc(char)))")
    case let .StringAtom(str):
      return .Just("Object.StringAtom(\"\(str)\")")
    case let .Symbol(symbol):
      if let ctx = ctx {
        return .Just("Object.Symbol(\(symbol.fullName(ctx)))")
      }
      return .Just("Object.Symbol(\(symbol.rawDescription))")
    case let .Keyword(keyword):
      if let ctx = ctx {
        return .Just("Object.Keyword(\(keyword.fullName(ctx)))")
      }
      return .Just("Object.Keyword(\(keyword.rawDescription))")
    case let .Namespace(namespace):
      return .Just("Object.Namespace(\"\(namespace.name)\")")
    case let .Var(v):
      if let ctx = ctx {
        return .Just("Object.Var(\(v.name.fullName(ctx)))")
      }
      if let ns = v.name.ns {
        return .Just("Object.Var(ns:\(ns.name)/id:\(v.name.identifier))")
      }
      return .Just("Object.Var(error)")
    case let .Auxiliary(aux):
      return .Just(aux.debugDescribe())
    case let .Seq(seq):
      let result = describeSeq(seq, ctx, debug: true)
      switch result {
      case let .Just(desc): return .Just("Object.Seq( \(desc) )")
      case .Error: return result
      }
    case let .Vector(vector):
      let result = describeVector(vector, ctx, debug: true)
      switch result {
      case let .Just(desc):
        return .Just("Object.Vector( \(desc) )")
      case .Error:
        return result
      }
    case let .Map(map):
      let result = describeMap(map, ctx, debug: true)
      switch result {
      case let .Just(desc):
        return .Just("Object.Map( \(desc) )")
      case .Error:
        return result
      }
    case .MacroLiteral:
      return .Just("Object.Macro")
    case .FunctionLiteral:
      return .Just("Object.Function")
    case let .BuiltInFunction(v):
      return .Just("Object.BuiltInFunction(\(v.rawValue))")
    case let .Special(v):
      return .Just("Object.Special(\(v.rawValue))")
    case let .ReaderMacroForm(v):
      return .Just(v.debugDescribe(ctx))
    }
  }
}


// MARK: Miscellaneous

// Description-related extension for the Params struct.
extension Params {

  func describe(ctx: Context?) -> EvalOptional<String> {
    var buffer : [String] = []
    for param in self {
      let result = param.describe(ctx)
      switch result {
      case let .Just(description): buffer.append(description)
      case .Error: return result
      }
    }
    return .Just("Params: {{" + buffer.joinWithSeparator(" ") + "}}")
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
  for character in s.characters {
    switch character {
    case "\\": buffer += "\\\\"
    case "\"": buffer += "\\\""
    case "\t": buffer += "\\t"
    case "\r": buffer += "\\r"
    case "\n": buffer += "\\n"
    default: buffer.append(character)
    }
  }
  return buffer
}

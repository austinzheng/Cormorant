//
//  description.swift
//  Cormorant
//
//  Created by Austin Zheng on 12/19/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

// MARK: Describe

extension SeqType {
  /// Given a list, return a description (e.g. "(a b c d e)" for a five-item list).
  func describe(using ctx: Context? = nil, debug: Bool = false) -> EvalOptional<String> {
    var buffer : [String] = []
    for item in SeqIterator(self) {
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
    let final = buffer.joined(separator: " ")
    return .Just("(\(final))")
  }
}

enum Description {
  // TODO: once Generic<T == Something> extensions are allowed, move these into extensions
  /// Given a vector, return a description.
  static func describe(vector: VectorType, using ctx: Context? = nil, debug: Bool = false) -> EvalOptional<String> {
    var buffer : [String] = []
    for item in vector {
      let result = debug ? item.debugDescribe(ctx) : item.describe(ctx)
      switch result {
      case let .Just(item): buffer.append(item)
      case .Error: return result
      }
    }
    let final = buffer.joined(separator: " ")
    return .Just("[\(final)]")
  }

  /// Given a map, return a description.
  static func describe(map: MapType, using ctx: Context? = nil, debug: Bool = false) -> EvalOptional<String> {
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
    let final = buffer.joined(separator: " ")
    return .Just("{\(final)}")
  }
}

extension Value {

  /// Return the stringified version of an object.
  func toString(_ ctx: Context) -> EvalOptional<String> {
    switch self {
    case .nilValue:
      return .Just("")
    case let .char(char):
      return .Just(String(char))
    case let .string(str):
      return .Just(str)
    case let .auxiliary(aux):
      return .Just(aux.toString())
    default:
      return self.describe(ctx)
    }
  }

  /// Return a description of an object. If the object is a string, any constituent characters will be converted to the
  /// appropriate two-character escape sequence if necessary.
  func describe(_ ctx: Context?) -> EvalOptional<String> {
    switch self {
    case .nilValue:
      return .Just("nil")
    case let .bool(bool):
      return .Just(bool ? "true" : "false")
    case let .int(int):
      return .Just(int.description)
    case let .float(double):
      return .Just(double.description)
    case let .char(char):
      return .Just(charLiteralDesc(char))
    case let .string(str):
      return .Just("\"" + stringByEscaping(str) + "\"")
    case let .symbol(symbol):
      if let ctx = ctx {
        return .Just(symbol.fullName(ctx))
      }
      return .Just("symbol:\(symbol.rawDescription)")
    case let .keyword(keyword):
      if let ctx = ctx {
        return .Just(keyword.fullName(ctx))
      }
      return .Just("keyword:\(keyword.rawDescription)")
    case let .namespace(namespace):
      return .Just("#<Namespace \(namespace.name)>")
    case let .`var`(v):
      if let ctx = ctx {
        return .Just("#'\(v.name.fullName(ctx))")
      }
      if let ns = v.name.ns {
        return .Just("#<Var ns:\(ns.name)/id:\(v.name.identifier)>")
      }
      return .Just("#<Var (error)>")
    case let .auxiliary(aux):
      return .Just(aux.describe())
    case let .seq(list):
      return list.describe(using: ctx, debug: false)
    case let .vector(vector):
      return Description.describe(vector: vector, using: ctx, debug: false)
    case let .map(map):
      return Description.describe(map: map, using: ctx, debug: false)
    case .macroLiteral:
      return .Just("{{macro}}")
    case .functionLiteral:
      return .Just("{{function}}")
    case let .builtInFunction(v):
      return .Just(v.rawValue)
    case let .special(v):
      return .Just(v.rawValue)
    case .readerMacroForm:
      return .Just("{{reader_macro}}")
    }
  }

  /// Return a debug description of an object.
  func debugDescribe(_ ctx: Context?) -> EvalOptional<String> {
    switch self {
    case .nilValue:
      return .Just("Object.Nil")
    case let .bool(bool):
      let desc = bool ? "true" : "false"
      return .Just("Object.bool(\(desc))")
    case let .int(int):
      return .Just("Object.int(\(int.description))")
    case let .float(double):
      return .Just("Object.float(\(double.description))")
    case let .char(char):
      return .Just("Object.char(\(charLiteralDesc(char)))")
    case let .string(str):
      return .Just("Object.string(\"\(str)\")")
    case let .symbol(symbol):
      if let ctx = ctx {
        return .Just("Object.symbol(\(symbol.fullName(ctx)))")
      }
      return .Just("Object.symbol(\(symbol.rawDescription))")
    case let .keyword(keyword):
      if let ctx = ctx {
        return .Just("Object.keyword(\(keyword.fullName(ctx)))")
      }
      return .Just("Object.keyword(\(keyword.rawDescription))")
    case let .namespace(namespace):
      return .Just("Object.namespace(\"\(namespace.name)\")")
    case let .`var`(v):
      if let ctx = ctx {
        return .Just("Object.`var`(\(v.name.fullName(ctx)))")
      }
      if let ns = v.name.ns {
        return .Just("Object.`var`(ns:\(ns.name)/id:\(v.name.identifier))")
      }
      return .Just("Object.`var`(error)")
    case let .auxiliary(aux):
      return .Just(aux.debugDescribe())
    case let .seq(seq):
      let result = seq.describe(using: ctx, debug: true)
      switch result {
      case let .Just(desc): return .Just("Object.seq( \(desc) )")
      case .Error: return result
      }
    case let .vector(vector):
      let result = Description.describe(vector: vector, using: ctx, debug: true)
      switch result {
      case let .Just(desc):
        return .Just("Object.vector( \(desc) )")
      case .Error:
        return result
      }
    case let .map(map):
      let result = Description.describe(map: map, using: ctx, debug: true)
      switch result {
      case let .Just(desc):
        return .Just("Object.map( \(desc) )")
      case .Error:
        return result
      }
    case .macroLiteral:
      return .Just("Object.Macro")
    case .functionLiteral:
      return .Just("Object.Function")
    case let .builtInFunction(v):
      return .Just("Object.builtInFunction(\(v.rawValue))")
    case let .special(v):
      return .Just("Object.special(\(v.rawValue))")
    case let .readerMacroForm(v):
      return .Just(v.debugDescribe(ctx))
    }
  }
}


// MARK: Miscellaneous

// Description-related extension for the Params struct.
extension Params : CustomStringConvertible {

  var description : String { return describe(nil).rawStringValue }

  func describe(_ ctx: Context?) -> EvalOptional<String> {
    var buffer : [
      String] = []
    for param in self {
      let result = param.describe(ctx)
      switch result {
      case let .Just(description): buffer.append(description)
      case .Error: return result
      }
    }
    return .Just("Params: {{" + buffer.joined(separator: " ") + "}}")
  }
}


// MARK: Helper functions

/// Return the Clojure-style description of a character literal.
private func charLiteralDesc(_ char: Character) -> String {
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
func stringByEscaping(_ s: String) -> String {
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

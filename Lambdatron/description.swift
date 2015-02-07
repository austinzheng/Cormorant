//
//  description.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/19/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// Given a list of ConsValue items, return a description (e.g. "(a b c d e)" for a five-item list).
func describeList(list: ListType<ConsValue>, ctx: Context?, debug: Bool = false) -> String {
  var descBuffer : [String] = []
  for item in list {
    descBuffer.append(item.describe(ctx, debug: debug))
  }
  let finalDesc = join(" ", descBuffer)
  return "(\(finalDesc))"
}

extension ConsValue {

  func describe(ctx: Context?) -> String {
    return describe(ctx, debug: false)
  }

  func describe(ctx: Context?, debug: Bool) -> String {
    switch self {
    case let Symbol(v):
      if let ctx = ctx {
        let name = ctx.nameForSymbol(v)
        return debug ? "ConsValue.Symbol(\(name))" : name
      }
      return debug ? "ConsValue.Symbol(id:\(v.identifier))" : "symbol:\(v.identifier)"
    case let Keyword(v):
      if let ctx = ctx {
        let name = ctx.nameForKeyword(v)
        return debug ? "ConsValue.Keyword(:\(name))" : ":" + name
      }
      return debug ? "ConsValue.Keyword(id:\(v.identifier))" : "keyword:\(v.identifier)"
    case Nil:
      return debug ? "ConsValue.Nil" : "nil"
    case let BoolAtom(v):
      return debug ? "ConsValue.BoolAtom(\(v))" : v.description
    case let IntAtom(v):
      return debug ? "ConsValue.IntAtom(\(v))" : v.description
    case let FloatAtom(v):
      return debug ? "ConsValue.FloatAtom(\(v)" : v.description
    case let CharAtom(v):
      let desc = charLiteralDesc(v)
      return debug ? "ConsValue.CharAtom(\(desc))" : "\(desc)"
    case let StringAtom(v):
      return debug ? "ConsValue.StringAtom(\"\(v)\")" : "\"\(v)\""
    case let List(list):
      let desc = describeList(list, ctx, debug: debug)
      return debug ? "ConsValue.List(\(desc))" : desc
    case let Vector(v):
      let internals = join(" ", v.map({$0.describe(ctx, debug: debug)}))
      return debug ? "ConsValue.Vector([\(internals)])" : "[\(internals)]"
    case let Map(m):
      var components : [String] = []
      for (key, value) in m {
        components.append(key.describe(ctx, debug: debug))
        components.append(value.describe(ctx, debug: debug))
      }
      let internals = join(" ", components)
      return debug ? "ConsValue.Map({\(internals)})" : "{\(internals)}"
    case let FunctionLiteral(v):
      return debug ? "ConsValue.FunctionLiteral(\(v.describe(ctx)))" : v.describe(ctx)
    case let Special(v):
      return debug ? "ConsValue.Special(\(v.rawValue))" : v.rawValue
    case let BuiltInFunction(v):
      return debug ? "ConsValue.BuiltInFunction(\(v.rawValue))" : v.rawValue
    case let ReaderMacroForm(v):
      return debug ? "ConsValue.ReaderMacroForm(\(v.description))" : v.description
    }
  }
}


// MARK: Functions

extension Function {
  
  func describe(ctx: Context?) -> String {
    var count = variadic == nil ? 0 : 1
    count += specificFns.count
    if count == 1 {
      // Only one arity
      let funcString : String = {
        if let v = self.variadic {
          return v.describe(ctx)
        }
        else {
          var generator = self.specificFns.generate()
          // FORCE UNWRAP: self.specificFns must have at least one object for this block to be run.
          let item = generator.next()!.1
          return item.describe(ctx)
        }
        }()
      return "(fn \(funcString))"
    }
    else {
      var descs : [String] = []
      for (_, fn) in specificFns {
        descs.append("(\(fn.describe(ctx)))")
      }
      if let variadic = variadic {
        descs.append("(\(variadic.describe(ctx)))")
      }
      let joined = join(" ", descs)
      return "(fn \(joined))"
    }
  }
}

extension SingleFn {
  
  func describe(ctx: Context?) -> String {
    // Print out the description. For example, "[a b] (print a) (+ a b 1)"
    var paramVector : [String] = []
    if let ctx = ctx {
      for p in parameters {
        paramVector.append(ctx.nameForSymbol(p))
      }
    }
    else {
      for p in parameters {
        paramVector.append("symbol:\(p.identifier)")
      }
    }
    if let v = variadicParameter {
      paramVector.append("%")
      if let ctx = ctx {
        paramVector.append(ctx.nameForSymbol(v))
      }
      else {
        paramVector.append("symbol:\(v.identifier)")
      }
    }
    
    let paramRaw = join(" ", paramVector)
    let paramString = "[\(paramRaw)]"
    let formsVector = forms.map({$0.describe(ctx)})
    var finalVector = [paramString] + formsVector
    return join(" ", finalVector)
  }
  
  var description : String {
    return describe(nil)
  }
}

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

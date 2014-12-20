//
//  description.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/19/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

extension Cons {

  private func describe(ctx: Context?, describer: (ConsValue, Context?) -> String) -> String {
    func collectDescriptions(firstItem : Cons?) -> [String] {
      var descBuffer : [String] = []
      var currentItem : Cons? = firstItem
      while let actualItem = currentItem {
        descBuffer.append(describer(actualItem.value, ctx))
        currentItem = actualItem.next
      }
      return descBuffer
    }
    
    var descs = collectDescriptions(self)
    let finalDesc = join(" ", descs)
    return "(\(finalDesc))"
  }
  
  var description : String {
    return describe(nil, describer: { $0.0.describe(false, ctx: $0.1) })
  }
  
  var debugDescription : String {
    return describe(nil, describer: { $0.0.describe(true, ctx: $0.1) })
  }
}

extension ConsValue {
  
  func describe(ctx: Context?) -> String {
    return describe(false, ctx: ctx)
  }
  
  private func describe(debug: Bool, ctx: Context?) -> String {
    switch self {
    case let Symbol(v):
      if let ctx = ctx {
        let name = ctx.nameForSymbol(v)
        return debug ? "ConsValue.Symbol(\(name))" : name
      }
      else {
        return debug ? "ConsValue.Symbol(id:\(v.identifier))" : "symbol:\(v.identifier)"
      }
    case NilLiteral:
      return debug ? "ConsValue.NilLiteral" : "nil"
    case let BoolLiteral(v):
      return debug ? "ConsValue.BoolLiteral(\(v))" : v.description
    case let IntegerLiteral(v):
      return debug ? "ConsValue.IntegerLiteral(\(v))" : v.description
    case let FloatLiteral(v):
      return debug ? "ConsValue.FloatLiteral(\(v)" : v.description
    case let StringLiteral(v):
      return debug ? "ConsValue.StringLiteral(\"\(v)\")" : "\"\(v)\""
    case let ListLiteral(v):
      let desc = v.describe(ctx, describer: { $0.0.describe(debug, ctx: $0.1) })
      return debug ? "ConsValue.ListLiteral(\(desc))" : desc
    case let VectorLiteral(v):
      let internals = join(" ", v.map({$0.describe(debug, ctx: ctx)}))
      return debug ? "ConsValue.VectorLiteral([\(internals)])" : "[\(internals)]"
    case let MapLiteral(m):
      var components : [String] = []
      for (key, value) in m {
        components.append(key.describe(debug, ctx: ctx))
        components.append(value.describe(debug, ctx: ctx))
      }
      let internals = join(" ", components)
      return debug ? "ConsValue.MapLiteral({\(internals)})" : "{\(internals)}"
    case let FunctionLiteral(v):
      return debug ? "ConsValue.FunctionLiteral(\(v.describe(ctx)))" : v.describe(ctx)
    case let Special(v):
      return debug ? "ConsValue.Special(\(v.rawValue))" : v.rawValue
    case let BuiltInFunction(v):
      return debug ? "ConsValue.BuiltInFunction(\(v.rawValue))" : v.rawValue
    case let ReaderMacro(v):
      return debug ? "ConsValue.ReaderMacro(\(v.description))" : v.description
    case None:
      return debug ? "ConsValue.None" : ""
    case RecurSentinel:
      internalError("RecurSentinel should never be in a situation where its value can be printed")
    case let MacroArgument(ma):
      let desc = ma.value.describe(debug, ctx: ctx)
      return debug ? "ConsValue.MacroArgument-->\(desc)" : desc
    }
  }
  
  var description : String {
    return describe(false, ctx: nil)
  }
  
  var debugDescription : String {
    return describe(true, ctx: nil)
  }
}

extension Function : Printable {
  
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
          for (_, item) in self.specificFns {
            return item.describe(ctx)
          }
        }
        internalError("an array with no objects reported itself as having at least one object")
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
  
  var description : String {
    return describe(nil)
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
    let formsVector = forms.map({$0.describe(false, ctx: ctx)})
    var finalVector = [paramString] + formsVector
    return join(" ", finalVector)
  }
  
  var description : String {
    return describe(nil)
  }
}
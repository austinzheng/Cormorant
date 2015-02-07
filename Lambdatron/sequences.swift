//
//  sequences.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/7/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// A wrapper for a ConsValue that provides an appropriate iterator.
struct ConsSequence : SequenceType {
  private let value : ConsValue
  private let prefix : ConsValue?

  init(_ value: ConsValue, prefix: ConsValue? = nil) {
    self.value = value; self.prefix = prefix
  }

  var isEmpty : Bool {
    if prefix == nil {
      switch value {
      case let .StringAtom(s): return s.isEmpty
      case let .List(list): return list.isEmpty
      case let .Vector(vector): return vector.isEmpty
      case let .Map(map): return map.isEmpty
      default: return true
      }
    }
    return false
  }

  func generate() -> ConsGenerator {
    switch value {
    case let .StringAtom(s): return ConsGenerator(string: s, prefix: prefix)
    case let .List(list): return ConsGenerator(list: list, prefix: prefix)
    case let .Vector(vector): return ConsGenerator(vector: vector, prefix: prefix)
    case let .Map(map): return ConsGenerator(map: map, prefix: prefix)
    default: return ConsGenerator(prefix: prefix)
    }
  }
}

struct ConsGenerator : GeneratorType {
  enum UnderlyingType {
    case Str(IndexingGenerator<String>)
    case List(ListGenerator<ConsValue>)
    case Vector(IndexingGenerator<Array<ConsValue>>)
    case Map(DictionaryGenerator<ConsValue, ConsValue>)
    case None
  }
  private var underlying : UnderlyingType
  private let prefix : ConsValue?
  private var prefixSeen = false

  private init(string: String, prefix: ConsValue?) {
    underlying = .Str(string.generate()); self.prefix = prefix
  }

  private init(list: ListType<ConsValue>, prefix: ConsValue?) {
    underlying = .List(list.generate()); self.prefix = prefix
  }

  private init(vector: VectorType, prefix: ConsValue?) {
    underlying = .Vector(vector.generate()); self.prefix = prefix
  }

  private init(map: MapType, prefix: ConsValue?) {
    underlying = .Map(map.generate()); self.prefix = prefix
  }

  private init(prefix: ConsValue?) {
    underlying = .None; self.prefix = prefix
  }

  mutating func next() -> ConsValue? {
    // If this is the very first time next() has been called, and there is a prefix, return the prefix.
    if !prefixSeen {
      if let prefix = prefix {
        prefixSeen = true
        return prefix
      }
    }
    // Otherwise, use the underlying generator to return a ConsValue.
    switch underlying {
    case let .Str(g):
      var nextGenerator = g
      let v = nextGenerator.next()
      underlying = .Str(nextGenerator)
      if let v = v {
        return .CharAtom(v)
      }
      return nil
    case let .List(g):
      var nextGenerator = g
      let v = nextGenerator.next()
      underlying = .List(nextGenerator)
      return v
    case let .Vector(g):
      var nextGenerator = g
      let v = nextGenerator.next()
      underlying = .Vector(nextGenerator)
      return v
    case let .Map(g):
      var nextGenerator = g
      let v = nextGenerator.next()
      underlying = .Map(nextGenerator)
      if let (key, value) = v {
        return .Vector([key, value])
      }
      return nil
    case .None:
      return nil
    }
  }
}

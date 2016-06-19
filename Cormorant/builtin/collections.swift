//
//  collections.swift
//  Cormorant
//
//  Created by Austin Zheng on 12/15/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// Given zero or more arguments, construct a list whose components are the arguments (or the empty list).
func pr_list(_ args: Params, _ ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Success(.seq(Empty()))
  }
  let list = sequence(fromItems: args.asArray)
  return .Success(.seq(list))
}

/// Given zero or more arguments, construct a vector whose components are the arguments (or the empty vector).
func pr_vector(_ args: Params, _ ctx: Context) -> EvalResult {
  return .Success(.vector(args.asArray))
}

/// Given zero or more arguments, construct a map whose components are the keys and values (or the empty map).
func pr_hashmap(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".hashmap"
  guard args.count % 2 == 0 else {
    // Must have an even number of arguments
    return .Failure(EvalError.arityError(expected: "even number", actual: args.count, fn))
  }
  var buffer : MapType = [:]
  for (key, value) in PairSequence(args) {
    buffer[key] = value
  }
  return .Success(.map(buffer))
}

/// Given a prefix and a list argument, return a new list where the prefix is followed by the list argument.
func pr_cons(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".cons"
  if args.count != 2 {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  let first = args[0]
  let second = args[1]
  switch second {
  case .nilValue:
    // Create a new list consisting of just the first object
    return .Success(.seq(sequence(first)))
  case let .string(str):
    // Create a new list consisting of the first object, followed by the seq of the string
    let seq = cons(first, next: StringSequenceView(str))
    return .Success(.seq(seq))
  case let .seq(seq):
    // Create a new list consisting of the first object followed by the second list (which can be empty)
    return .Success(.seq(cons(first, next: seq)))
  case let .vector(vector):
    // Create a new list consisting of the first object, followed by a list comprised of the vector's items
    let seq = cons(first, next: VectorSequenceView(vector))
    return .Success(.seq(seq))
  case let .map(m):
    // Create a new list consisting of the first object, followed by a list comprised of vectors containing the map's
    //  key-value pairs
    let seq = cons(first, next: HashmapSequenceView(m))
    return .Success(.seq(seq))
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "second argument must be a string, list, vector, map, or nil"))
  }
}

/// Given a sequence, return the first item.
func pr_first(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".first"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  let first = args[0]
  switch first {
  case .nilValue:
    return .Success(.nilValue)
  case let .string(s):
    switch StringSequenceView(s).first {
    case let .Just(s): return .Success(s)
    case let .Error(err): return .Failure(err)
    }
  case let .seq(seq):
    switch seq.first {
    case let .Just(s): return .Success(s)
    case let .Error(err): return .Failure(err)
    }
  case let .vector(v):
    return .Success(v.count == 0 ? .nilValue : v[0])
  case let .map(map):
    return .Success(MapSequence(map).first() ?? .nilValue)
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "first argument must be a string, list, vector, map, or nil"))
  }
}

/// Given a sequence, return the sequence comprised of all items but the first.
func pr_rest(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".rest"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  let first = args[0]
  switch first {
  case .nilValue:
    return .Success(.seq(Empty()))
  case let .string(s):
    switch StringSequenceView(s).rest {
    case let .Just(seq): return .Success(.seq(seq))
    case let .Error(err): return .Failure(err)
    }
  case let .seq(seq):
    // Ask the sequence what the rest of its items are
    switch seq.rest {
    case let .Just(seq): return .Success(.seq(seq))
    case let .Error(err): return .Failure(err)
    }
  case let .vector(vector):
    switch VectorSequenceView(vector).rest {
    case let .Just(seq): return .Success(.seq(seq))
    case let .Error(err): return .Failure(err)
    }
  case let .map(map):
    switch HashmapSequenceView(map).rest {
    case let .Just(seq): return .Success(.seq(seq))
    case let .Error(err): return .Failure(err)
    }
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "argument must be a string, list, vector, map, or nil"))
  }
}

/// Given a sequence, return the sequence comprised of all items but the first, or nil if there are no more items.
func pr_next(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".next"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  let first = args[0]
  switch first {
  case .nilValue: return .Success(.nilValue)
  case let .string(str):
    switch StringSequenceView(str).rest {
    case let .Just(rest):
      switch rest.isEmpty {
      case let .Just(listIsEmpty): return .Success(listIsEmpty ? .nilValue : .seq(rest))
      case let .Error(err): return .Failure(err)
      }
    case let .Error(err): return .Failure(err)
    }
  case let .seq(seq):
    switch seq.rest {
    case let .Just(rest):
      switch rest.isEmpty {
      case let .Just(listIsEmpty): return .Success(listIsEmpty ? .nilValue : .seq(rest))
      case let .Error(err): return .Failure(err)
      }
    case let .Error(err): return .Failure(err)
    }
  case let .vector(vector):
    switch VectorSequenceView(vector).rest {
    case let .Just(rest):
      switch rest.isEmpty {
      case let .Just(listIsEmpty): return .Success(listIsEmpty ? .nilValue : .seq(rest))
      case let .Error(err): return .Failure(err)
      }
    case let .Error(err): return .Failure(err)
    }
  case let .map(m):
    switch HashmapSequenceView(m).rest {
    case let .Just(rest):
      switch rest.isEmpty {
      case let .Just(listIsEmpty): return .Success(listIsEmpty ? .nilValue : .seq(rest))
      case let .Error(err): return .Failure(err)
      }
    case let .Error(err): return .Failure(err)
    }
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "argument must be a string, list, vector, map, or nil"))
  }
}

/// Given a single sequence, return nil (if empty) or a list built out of that sequence.
func pr_seq(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".seq"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  switch args[0] {
  case .nilValue: return .Success(.nilValue)
  case let .string(str):
    return .Success(str.isEmpty ? .nilValue : .seq(StringSequenceView(str)))
  case let .seq(seq):
    if let result = sequence(fromSeq: seq) {
      return result.then { .Success(.seq($0)) }
    }
    return .Success(.nilValue)     // Sequence was empty; return nil
  case let .vector(vector):
    return .Success(vector.isEmpty ? .nilValue : .seq(VectorSequenceView(vector)))
  case let .map(m):
    return .Success(m.isEmpty ? .nilValue : .seq(HashmapSequenceView(m)))
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "argument must be a string, list, vector, map, or nil"))
  }
}

/// Given a form to evaluate to create a sequence, return a corresponding lazy sequence.
func pr_lazyseq(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".lazy-seq"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  return .Success(.seq(LazySeq(args[0], ctx: ctx)))
}

/// Given a collection and an item to 'add' to the collection, return a new collection with the added item.
func pr_conj(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".conj"
  guard args.count == 2 else {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  let coll = args[0]
  let toAdd = args[1]
  switch coll {
  case .nilValue:
    return .Success(.seq(sequence(toAdd)))
  case .seq:
    return pr_cons(Params(toAdd, coll), ctx)
  case let .vector(vector):
    return .Success(.vector(vector + [toAdd]))
  case let .map(m):
    guard case let .vector(vector) = toAdd else {
      return .Failure(EvalError.invalidArgumentError(fn,
        message: "if first argument is a hashmap, second argument must be a vector"))
    }
    guard vector.count == 2 else {
      return .Failure(EvalError.invalidArgumentError(fn,
        message: "vector arg to map conj must be a two-element pair vector"))
    }
    var newMap = m
    newMap[vector[0]] = vector[1]
    return .Success(.map(newMap))
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be nil or a collection"))
  }
}

// TODO: This should return a lazy sequence in the future
/// Given zero or more arguments which are collections or nil, return a list created by concatenating the arguments.
func pr_concat(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".concat"
  if args.count == 0 {
    return .Success(.seq(Empty()))
  }
  var head : SeqType = Empty()

  // Go through the arguments in *reverse* order
  for (idx, item) in args.reversed().enumerated() {
    switch item {
    case .nilValue: continue
    case let .string(str):
      head = str.isEmpty ? head : StringSequenceView(str, next: head)
    case let .seq(seq):
      if idx == 0 {
        // If this is the first (really, the last) list, just use it.
        head = seq
      }
      else {
        switch seq.isEmpty {
        case let .Just(seqIsEmpty):
          if seqIsEmpty {
            // Skip empty seqs
            continue
          }
          // Make a copy of this list, connected to our in-progress list.
          switch ContiguousList.sequence(from: seq, next: head) {
          case let .Just(seq): head = seq
          case let .Error(err): return .Failure(err)
          }
        case let .Error(err): return .Failure(err)
        }
      }
    case let .vector(vector):
      head = vector.isEmpty ? head : VectorSequenceView(vector, next: head)
    case let .map(map):
      head = map.isEmpty ? head : HashmapSequenceView(map, next: head)
    default:
      return .Failure(EvalError.invalidArgumentError(fn,
        message: "arguments must be strings, lists, vectors, maps, or nil"))
    }
  }
  return .Success(.seq(head))
}

/// Given a sequence and an index, return the item at that index, or return an optional 'not found' value.
func pr_nth(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".nth"
  guard args.count == 2 || args.count == 3 else {
    return .Failure(EvalError.arityError(expected: "2 or 3", actual: args.count, fn))
  }
  if case let .int(idx) = args[1] {
    let fallback : Value? = args.count == 3 ? args[2] : nil
    if idx < 0 {
      // Index can't be negative
      if let fallback = fallback { return .Success(fallback) }
      return .Failure(EvalError.outOfBoundsError(fn, idx: idx))
    }

    switch args[0] {
    case let .string(s):
      // We have to walk the string
      if let character = characterAtIndex(s, idx: idx) {
        return .Success(.char(character))
      }
      else if let fallback = fallback {
        return .Success(fallback)
      }
      else {
        return .Failure(EvalError.outOfBoundsError(fn, idx: idx))
      }
    case let .seq(seq):
      for (ctr, item) in SeqIterator(seq).enumerated() {
        // Go through the list. If we can find the item at the right index without running into an error, return it.
        switch item {
        case let .Just(item):
          if ctr == idx { return .Success(item) }
        case let .Error(err):
          return .Failure(err)
        }
      }
      // The list is empty, or we reached the end of the list prematurely.
      if let fallback = fallback {
        return .Success(fallback)
      }
      else {
        return .Failure(EvalError.outOfBoundsError(fn, idx: idx))
      }
    case let .vector(v):
      if idx < v.count {
        return .Success(v[idx])
      }
      else if let fallback = fallback {
        return .Success(fallback)
      }
      else {
        return .Failure(EvalError.outOfBoundsError(fn, idx: idx))
      }
    default:
      // Not a valid type to call nth on.
      return .Failure(EvalError.invalidArgumentError(fn,
        message: "first argument must be a string, list, or vector"))
    }
  }
  // Second argument wasn't an integer.
  return .Failure(EvalError.invalidArgumentError(fn,
    message: "second argument must be an integer"))
}

/// Given a collection and a key, get the corresponding value, or return nil or an optional 'not found' value.
func pr_get(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".get"
  guard args.count == 2 || args.count == 3 else {
    return .Failure(EvalError.arityError(expected: "2 or 3", actual: args.count, fn))
  }
  let key = args[1]
  let fallback : Value = args.count == 3 ? args[2] : .nilValue
  
  switch args[0] {
  case let .string(s):
    if case let .int(idx) = key, let character = characterAtIndex(s, idx: idx) {
      return .Success(.char(character))
    }
    return .Success(fallback)
  case let .vector(v):
    if case let .int(idx) = key where idx >= 0 && idx < v.count {
      return .Success(v[idx])
    }
    return .Success(fallback)
  case let .map(m):
    return .Success(m[key] ?? fallback)
  default:
    return .Success(fallback)
  }
}

/// Given a supported collection and one or more key-value pairs, associate the new values with the keys.
func pr_assoc(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".assoc"
  // This function requires at least one collection/nil and one key/index-value pair
  guard args.count >= 3 else {
    return .Failure(EvalError.arityError(expected: "3 or more", actual: args.count, fn))
  }
  // Collect all arguments after the first one
  let rest = args.rest()
  guard rest.count % 2 == 0 else {
    // Must have an even number of key/index-value pairs
    return .Failure(EvalError.arityError(expected: "even number", actual: args.count, fn))
  }
  switch args[0] {
  case .nilValue:
    // Put key-value pairs in a new map
    var newMap : MapType = [:]
    for (key, value) in PairSequence(rest) {
      newMap[key] = value
    }
    return .Success(.map(newMap))
  case let .vector(vector):
    // Each pair is an index and a new value. Update a copy of the vector and return that.
    var copy = vector
    for (key, value) in PairSequence(rest) {
      if case let .int(idx) = key {
        if idx < 0 || idx > copy.count {
          return .Failure(EvalError.outOfBoundsError(fn, idx: idx))
        }
        else if idx == copy.count {
          copy.append(value)
        }
        else {
          copy[idx] = value
        }
      }
      else {
        return .Failure(EvalError.invalidArgumentError(fn,
          message: "key arguments must be integers if .assoc is called on a vector"))
      }
    }
    return .Success(.vector(copy))
  case let .map(m):
    // Update or add all keys with their corresponding values.
    var copy = m
    for (key, value) in PairSequence(rest) {
      copy[key] = value
    }
    return .Success(.map(copy))
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "first argument must be a vector, map, or nil"))
  }
}

/// Given a countable collection, return the number of items.
func pr_count(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".count"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }

  switch args[0] {
  case .nilValue:
    return .Success(0)
  case let .string(str):
    return .Success(.int(str.characters.count))
  case let .seq(seq):
    var count = 0
    for _ in SeqIterator(seq) {
      count += 1
    }
    return .Success(.int(count))
  case let .vector(vector):
    return .Success(.int(vector.count))
  case let .map(map):
    return .Success(.int(map.count))
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be nil, a collection, or a string"))
  }
}

/// Given a map and zero or more keys, return a map with the given keys and corresponding values removed.
func pr_dissoc(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".dissoc"
  guard !args.isEmpty else {
    return .Failure(EvalError.arityError(expected: "> 0", actual: args.count, fn))
  }
  if args.count == 1 {
    // If there are no values, just return the argument unchanged.
    return .Success(args[0])
  }
  switch args[0] {
  case .nilValue:
    return .Success(.nilValue)
  case let .map(m):
    var newMap = m
    for i in 1..<args.count {
      newMap.removeValue(forKey: args[i])
    }
    return .Success(.map(newMap))
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be nil or a map"))
  }
}

/// Given a collection, a function that takes two arguments, and an optional initial value, perform a reduction.
func pr_reduce(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".reduce"
  guard args.count == 2 || args.count == 3 else {
    return .Failure(EvalError.arityError(expected: "2 or 3", actual: args.count, fn))
  }

  let function = args[0]
  let coll = args.count == 3 ? args[2] : args[1]
  let first : Value? = args.count == 3 ? args[1] : nil

  guard let seq = SeqIterator(coll, prefix: first) else {
    // The type was incorrect.
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be nil or a collection"))
  }

  // The sequence was one of the supported types.
  var generator = seq.generate()
  let initial = generator.next()
  if let acc = initial {
    // There is at least one item.
    switch acc {
    case let .Just(acc):
      var accumulator = acc
      while let this = generator.next() {
        switch this {
        case let .Just(this):
          // Update accumulator with the value of (function accumulator this)
          let args = Params(accumulator, this)
          let result = ctx.apply(arguments: args, toFunction: function, fn)
          switch result {
          case let .Success(result):
            accumulator = result
          default: return result
          }
        case let .Error(err):
          // Subsequent item was a lazy sequence that failed to expand properly
          return .Failure(err)
        }
      }
      return .Success(accumulator)
    case let .Error(err):
      // First item was a lazy sequence that failed to expand properly
      return .Failure(err)
    }
  }
  else {
    // There are no items at all (initial was not provided). Return (function).
    return ctx.apply(arguments: Params(), toFunction: function, fn)
  }
}

//
//  collections.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/15/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// Given zero or more arguments, construct a list whose components are the arguments (or the empty list).
func pr_list(args: Params, ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Success(.Seq(Empty()))
  }
  let list = sequence(args.asArray)
  return .Success(.Seq(list))
}

/// Given zero or more arguments, construct a vector whose components are the arguments (or the empty vector).
func pr_vector(args: Params, ctx: Context) -> EvalResult {
  return .Success(.Vector(args.asArray))
}

/// Given zero or more arguments, construct a map whose components are the keys and values (or the empty map).
func pr_hashmap(args: Params, ctx: Context) -> EvalResult {
  let fn = ".hashmap"
  if args.count % 2 != 0 {
    // Must have an even number of arguments
    return .Failure(EvalError.arityError("even number", actual: args.count, fn))
  }
  var buffer : MapType = [:]
  for (key, value) in PairSequence(args) {
    buffer[key] = value
  }
  return .Success(.Map(buffer))
}

/// Given a prefix and a list argument, return a new list where the prefix is followed by the list argument.
func pr_cons(args: Params, ctx: Context) -> EvalResult {
  let fn = ".cons"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  let first = args[0]
  let second = args[1]
  switch second {
  case .Nil:
    // Create a new list consisting of just the first object
    return .Success(.Seq(sequence(first)))
  case let .StringAtom(str):
    // Create a new list consisting of the first object, followed by the seq of the string
    let seq = cons(first, next: StringSequenceView(str))
    return .Success(.Seq(seq))
  case let .Seq(seq):
    // Create a new list consisting of the first object followed by the second list (which can be empty)
    return .Success(.Seq(cons(first, next: seq)))
  case let .Vector(vector):
    // Create a new list consisting of the first object, followed by a list comprised of the vector's items
    let seq = cons(first, next: VectorSequenceView(vector))
    return .Success(.Seq(seq))
  case let .Map(m):
    // Create a new list consisting of the first object, followed by a list comprised of vectors containing the map's
    //  key-value pairs
    let seq = cons(first, next: HashmapSequenceView(m))
    return .Success(.Seq(seq))
  default: return .Failure(EvalError.invalidArgumentError(fn,
    message: "second argument must be a string, list, vector, map, or nil"))
  }
}

/// Given a sequence, return the first item.
func pr_first(args: Params, ctx: Context) -> EvalResult {
  let fn = ".first"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let first = args[0]
  switch first {
  case .Nil:
    return .Success(.Nil)
  case let .StringAtom(s):
    switch StringSequenceView(s).first {
    case let .Success(s): return .Success(s)
    case let .Error(err): return .Failure(err)
    }
  case let .Seq(seq):
    switch seq.first {
    case let .Success(s): return .Success(s)
    case let .Error(err): return .Failure(err)
    }
  case let .Vector(v):
    return .Success(v.count == 0 ? .Nil : v[0])
  case let .Map(map):
    return .Success(MapSequence(map).first() ?? .Nil)
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "first argument must be a string, list, vector, map, or nil"))
  }
}

/// Given a sequence, return the sequence comprised of all items but the first.
func pr_rest(args: Params, ctx: Context) -> EvalResult {
  let fn = ".rest"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let first = args[0]
  switch first {
  case .Nil:
    return .Success(.Seq(Empty()))
  case let .StringAtom(s):
    switch StringSequenceView(s).rest {
    case let .Seq(seq): return .Success(.Seq(seq))
    case let .Error(err): return .Failure(err)
    }
  case let .Seq(seq):
    // Ask the sequence what the rest of its items are
    switch seq.rest {
    case let .Seq(seq): return .Success(.Seq(seq))
    case let .Error(err): return .Failure(err)
    }
  case let .Vector(vector):
    switch VectorSequenceView(vector).rest {
    case let .Seq(seq): return .Success(.Seq(seq))
    case let .Error(err): return .Failure(err)
    }
  case let .Map(map):
    switch HashmapSequenceView(map).rest {
    case let .Seq(seq): return .Success(.Seq(seq))
    case let .Error(err): return .Failure(err)
    }
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "argument must be a string, list, vector, map, or nil"))
  }
}

/// Given a sequence, return the sequence comprised of all items but the first, or nil if there are no more items.
func pr_next(args: Params, ctx: Context) -> EvalResult {
  let fn = ".next"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let first = args[0]
  switch first {
  case .Nil: return .Success(.Nil)
  case let .StringAtom(str):
    switch StringSequenceView(str).rest {
    case let .Seq(rest):
      switch rest.isEmpty {
      case let .Boolean(listIsEmpty): return .Success(listIsEmpty ? .Nil : .Seq(rest))
      case let .Error(err): return .Failure(err)
      }
    case let .Error(err): return .Failure(err)
    }
  case let .Seq(seq):
    switch seq.rest {
    case let .Seq(rest):
      switch rest.isEmpty {
      case let .Boolean(listIsEmpty): return .Success(listIsEmpty ? .Nil : .Seq(rest))
      case let .Error(err): return .Failure(err)
      }
    case let .Error(err): return .Failure(err)
    }
  case let .Vector(vector):
    switch VectorSequenceView(vector).rest {
    case let .Seq(rest):
      switch rest.isEmpty {
      case let .Boolean(listIsEmpty): return .Success(listIsEmpty ? .Nil : .Seq(rest))
      case let .Error(err): return .Failure(err)
      }
    case let .Error(err): return .Failure(err)
    }
  case let .Map(m):
    switch HashmapSequenceView(m).rest {
    case let .Seq(rest):
      switch rest.isEmpty {
      case let .Boolean(listIsEmpty): return .Success(listIsEmpty ? .Nil : .Seq(rest))
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
func pr_seq(args: Params, ctx: Context) -> EvalResult {
  let fn = ".seq"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .Nil: return .Success(.Nil)
  case let .StringAtom(str):
    return .Success(str.isEmpty ? .Nil : .Seq(StringSequenceView(str)))
  case let .Seq(seq):
    if let result = sequence(seq) {
      switch result {
      case let .Seq(s): return .Success(.Seq(s))
      case let .Error(err): return .Failure(err)
      }
    }
    return .Success(.Nil)     // Sequence was empty; return nil
  case let .Vector(vector):
    return .Success(vector.isEmpty ? .Nil : .Seq(VectorSequenceView(vector)))
  case let .Map(m):
    return .Success(m.isEmpty ? .Nil : .Seq(HashmapSequenceView(m)))
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "argument must be a string, list, vector, map, or nil"))
  }
}

/// Given a form to evaluate to create a sequence, return a corresponding lazy sequence.
func pr_lazyseq(args: Params, ctx: Context) -> EvalResult {
  let fn = ".lazy-seq"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  return .Success(.Seq(LazySeq(args[0], ctx: ctx)))
}

/// Given a collection and an item to 'add' to the collection, return a new collection with the added item.
func pr_conj(args: Params, ctx: Context) -> EvalResult {
  let fn = ".conj"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  let coll = args[0]
  let toAdd = args[1]
  switch coll {
  case .Nil:
    return .Success(.Seq(sequence(toAdd)))
  case .Seq:
    return pr_cons(Params(toAdd, coll), ctx)
  case let .Vector(vector):
    return .Success(.Vector(vector + [toAdd]))
  case let .Map(m):
    if let vector = toAdd.asVector {
      if vector.count != 2 {
        return .Failure(EvalError.invalidArgumentError(fn,
          message: "vector arg to map conj must be a two-element pair vector"))
      }
      var newMap = m
      newMap[vector[0]] = vector[1]
      return .Success(.Map(newMap))
    }
    else {
      return .Failure(EvalError.invalidArgumentError(fn,
        message: "if first argument is a hashmap, second argument must be a vector"))
    }
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be nil or a collection"))
  }
}

// TODO: This should return a lazy sequence in the future
/// Given zero or more arguments which are collections or nil, return a list created by concatenating the arguments.
func pr_concat(args: Params, ctx: Context) -> EvalResult {
  let fn = ".concat"
  if args.count == 0 {
    return .Success(.Seq(Empty()))
  }
  var head : SeqType = Empty()

  // Go through the arguments in *reverse* order
  for (idx, item) in enumerate(reverse(args)) {
    switch item {
    case .Nil: continue
    case let .StringAtom(str):
      head = str.isEmpty ? head : StringSequenceView(str, next: head)
    case let .Seq(seq):
      if idx == 0 {
        // If this is the first (really, the last) list, just use it.
        head = seq
      }
      else {
        switch seq.isEmpty {
        case let .Boolean(seqIsEmpty):
          if seqIsEmpty {
            // Skip empty seqs
            continue
          }
          // Make a copy of this list, connected to our in-progress list.
          switch ContiguousList.fromSequence(seq, next: head) {
          case let .Seq(seq): head = seq
          case let .Error(err): return .Failure(err)
          }
        case let .Error(err): return .Failure(err)
        }
      }
    case let .Vector(vector):
      head = vector.isEmpty ? head : VectorSequenceView(vector, next: head)
    case let .Map(map):
      head = map.isEmpty ? head : HashmapSequenceView(map, next: head)
    default:
      return .Failure(EvalError.invalidArgumentError(fn,
        message: "arguments must be strings, lists, vectors, maps, or nil"))
    }
  }
  return .Success(.Seq(head))
}

/// Given a sequence and an index, return the item at that index, or return an optional 'not found' value.
func pr_nth(args: Params, ctx: Context) -> EvalResult {
  let fn = ".nth"
  if args.count < 2 || args.count > 3 {
    return .Failure(EvalError.arityError("2 or 3", actual: args.count, fn))
  }
  if let idx = args[1].asInteger {
    let fallback : ConsValue? = args.count == 3 ? args[2] : nil
    if idx < 0 {
      // Index can't be negative
      if let fallback = fallback { return .Success(fallback) }
      return .Failure(EvalError.outOfBoundsError(fn, idx: idx))
    }

    switch args[0] {
    case let .StringAtom(s):
      // We have to walk the string
      if let character = characterAtIndex(s, idx) {
        return .Success(.CharAtom(character))
      }
      else if let fallback = fallback {
        return .Success(fallback)
      }
      else {
        return .Failure(EvalError.outOfBoundsError(fn, idx: idx))
      }
    case let .Seq(seq):
      for (ctr, item) in enumerate(SeqIterator(seq)) {
        // Go through the list. If we can find the item at the right index without running into an error, return it.
        switch item {
        case let .Success(item):
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
    case let .Vector(v):
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
func pr_get(args: Params, ctx: Context) -> EvalResult {
  let fn = ".get"
  if args.count < 2 || args.count > 3 {
    return .Failure(EvalError.arityError("2 or 3", actual: args.count, fn))
  }
  let key = args[1]
  let fallback : ConsValue = args.count == 3 ? args[2] : .Nil
  
  switch args[0] {
  case let .StringAtom(s):
    if let idx = key.asInteger {
      if let character = characterAtIndex(s, idx) {
        return .Success(.CharAtom(character))
      }
    }
    return .Success(fallback)
  case let .Vector(v):
    if let idx = key.asInteger {
      if idx >= 0 && idx < v.count {
        return .Success(v[idx])
      }
    }
    return .Success(fallback)
  case let .Map(m):
    return .Success(m[key] ?? fallback)
  default:
    return .Success(fallback)
  }
}

/// Given a supported collection and one or more key-value pairs, associate the new values with the keys.
func pr_assoc(args: Params, ctx: Context) -> EvalResult {
  let fn = ".assoc"
  // This function requires at least one collection/nil and one key/index-value pair
  if args.count < 3 {
    return .Failure(EvalError.arityError("3 or more", actual: args.count, fn))
  }
  // Collect all arguments after the first one
  let rest = args.rest()
  if rest.count % 2 != 0 {
    // Must have an even number of key/index-value pairs
    return .Failure(EvalError.arityError("even number", actual: args.count, fn))
  }
  switch args[0] {
  case .Nil:
    // Put key-value pairs in a new map
    var newMap : MapType = [:]
    for (key, value) in PairSequence(rest) {
      newMap[key] = value
    }
    return .Success(.Map(newMap))
  case let .Vector(vector):
    // Each pair is an index and a new value. Update a copy of the vector and return that.
    var copy = vector
    for (key, value) in PairSequence(rest) {
      if let idx = key.asInteger {
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
    return .Success(.Vector(copy))
  case let .Map(m):
    // Update or add all keys with their corresponding values.
    var copy = m
    for (key, value) in PairSequence(rest) {
      copy[key] = value
    }
    return .Success(.Map(copy))
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "first argument must be a vector, map, or nil"))
  }
}

/// Given a countable collection, return the number of items.
func pr_count(args: Params, ctx: Context) -> EvalResult {
  let fn = ".count"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .Nil:
    return .Success(0)
  case let .StringAtom(str):
    return .Success(.IntAtom(countElements(str)))
  case let .Seq(seq):
    var count = 0
    for _ in SeqIterator(seq) {
      count++
    }
    return .Success(.IntAtom(count))
  case let .Vector(vector):
    return .Success(.IntAtom(vector.count))
  case let .Map(map):
    return .Success(.IntAtom(map.count))
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be nil, a collection, or a string"))
  }
}

/// Given a map and zero or more keys, return a map with the given keys and corresponding values removed.
func pr_dissoc(args: Params, ctx: Context) -> EvalResult {
  let fn = ".dissoc"
  if args.count == 0 {
    return .Failure(EvalError.arityError("> 0", actual: args.count, fn))
  }
  if args.count == 1 {
    // If there are no values, just return the argument unchanged.
    return .Success(args[0])
  }
  switch args[0] {
  case .Nil:
    return .Success(.Nil)
  case let .Map(m):
    var newMap = m
    for var i=1; i<args.count; i++ {
      newMap.removeValueForKey(args[i])
    }
    return .Success(.Map(newMap))
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be nil or a map"))
  }
}

/// Given a collection, a function that takes two arguments, and an optional initial value, perform a reduction.
func pr_reduce(args: Params, ctx: Context) -> EvalResult {
  let fn = ".reduce"
  if !(args.count == 2 || args.count == 3) {
    return .Failure(EvalError.arityError("2 or 3", actual: args.count, fn))
  }

  let function = args[0]
  let coll = args.count == 3 ? args[2] : args[1]
  let initial : ConsValue? = args.count == 3 ? args[1] : nil

  if let seq = SeqIterator(coll, prefix: initial) {
    // The sequence was one of the supported types.
    var generator = seq.generate()
    var initial = generator.next()
    if let acc = initial {
      // There is at least one item.
      switch acc {
      case let .Success(acc):
        var accumulator = acc
        var firstRun = true
        while let this = generator.next() {
          switch this {
          case let .Success(this):
            // Update accumulator with the value of (function accumulator this)
            let params = Params(accumulator, this)
            let result = apply(function, params, ctx, fn)
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
      return apply(function, Params(), ctx, fn)
    }
  }
  else {
    // The type was incorrect.
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be nil or a collection"))
  }
}

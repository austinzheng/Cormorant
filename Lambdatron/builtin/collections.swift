//
//  collections.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/15/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// Given zero or more arguments, construct a list whose components are the arguments (or the empty list).
func pr_list(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Success(.List(Empty()))
  }
  let list = listFromCollection(args)
  return .Success(.List(list))
}

/// Given zero or more arguments, construct a vector whose components are the arguments (or the empty vector).
func pr_vector(args: [ConsValue], ctx: Context) -> EvalResult {
  return .Success(.Vector(args))
}

/// Given zero or more arguments, construct a map whose components are the keys and values (or the empty map).
func pr_hashmap(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".hashmap"
  if args.count % 2 != 0 {
    // Must have an even number of arguments
    return .Failure(EvalError.arityError("even number", actual: args.count, fn))
  }
  var buffer : MapType = [:]
  for var i=0; i<args.count-1; i += 2 {
    let key = args[i]
    let value = args[i+1]
    buffer[key] = value
  }
  return .Success(.Map(buffer))
}

/// Given a prefix and a list argument, return a new list where the prefix is followed by the list argument.
func pr_cons(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".cons"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  let first = args[0]
  let second = args[1]
  switch second {
  case .Nil:
    // Create a new list consisting of just the first object
    return .Success(.List(Cons(first)))
  case let .StringAtom(s):
    // Create a new list consisting of the first object, followed by the seq of the string
    let list = listFromString(s)
    return pr_cons([first, list], ctx)
  case let .List(l):
    // Create a new list consisting of the first object followed by the second list (which can be empty)
    return .Success(.List(Cons(first, next: l)))
  case let .Vector(v):
    // Create a new list consisting of the first object, followed by a list comprised of the vector's items
    let list = listFromCollection(v, prefix: first)
    return .Success(.List(list))
  case let .Map(m):
    // Create a new list consisting of the first object, followed by a list comprised of vectors containing the map's
    //  key-value pairs
    let list : ListType<ConsValue> = listFromMappedCollection(m, postfix: nil) {
      let (key, value) = $0
      return .Vector([key, value])
    }
    return .Success(.List(Cons(first, next: list)))
  default: return .Failure(EvalError.invalidArgumentError(fn,
    message: "second argument must be a string, list, vector, map, or nil"))
  }
}

/// Given a sequence, return the first item.
func pr_first(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".first"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let first = args[0]
  switch first {
  case .Nil:
    return .Success(.Nil)
  case let .StringAtom(s):
    return pr_first([listFromString(s)], ctx)
  case let .List(l):
    return .Success(l.getValue() ?? .Nil)
  case let .Vector(v):
    return .Success(v.count == 0 ? .Nil : v[0])
  case let .Map(m):
    // Use a generator to get the first element out of the map.
    var generator = m.generate()
    if let (key, value) = generator.next() {
      return .Success(.Vector([key, value]))
    }
    return .Success(.Nil)
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "first argument must be a string, list, vector, map, or nil"))
  }
}

/// Given a sequence, return the sequence comprised of all items but the first.
func pr_rest(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".rest"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let first = args[0]
  switch first {
  case .Nil: return .Success(.List(Empty()))
  case let .StringAtom(s):
    return pr_rest([listFromString(s)], ctx)
  case let .List(list):
    switch list {
    case let list as Cons<ConsValue>:
      // List has one or more item; return 'next'
      return .Success(.List(list.next))
    default:
      // List has zero items; return the empty list.
      return .Success(.List(Empty()))
    }
  case let .Vector(vector):
    if vector.count < 2 {
      // Vector has zero or one items
      return .Success(.List(Empty()))
    }
    // Build a list out of the rest of the collection.
    let list = listFromCollection(vector[1..<vector.count])
    return .Success(.List(list))
  case let .Map(map):
    // Make a list containing all values...
    let list : ListType<ConsValue> = listFromMappedCollection(map, postfix: nil) {
      let (key, value) = $0
      return .Vector([key, value])
    }
    // ...then return the second (throwing away the first)
    switch list {
    case let list as Cons<ConsValue>:
      return .Success(.List(list.next))
    default:
      // Map has zero items
      return .Success(.List(Empty()))
    }
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "argument must be a string, list, vector, map, or nil"))
  }
}

/// Given a sequence, return the sequence comprised of all items but the first, or nil if there are no more items.
func pr_next(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".next"
  // NOTE: This function appears identical to pr_rest, except for returning .Nil instead of the empty list when there
  //  are no more items. I expect this code to diverge if/when lazy seqs are ever implemented, and so it is copied over
  //  verbatim rather than being refactored.
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let first = args[0]
  switch first {
  case .Nil: return .Success(.Nil)
  case let .StringAtom(s):
    return pr_next([listFromString(s)], ctx)
  case let .List(list):
    switch list {
    case let list as Cons<ConsValue>:
      return .Success(list.next.isEmpty ? .Nil : .List(list.next))
    default:
      // List has zero items; return the empty list.
      return .Success(.Nil)
    }
  case let .Vector(vector):
    if vector.count < 2 {
      // Vector has zero or one items
      return .Success(.Nil)
    }
    // Build a list out of the rest of the collection.
    let list = listFromCollection(vector[1..<vector.count])
    return .Success(.List(list))
  case let .Map(map):
    if map.count < 2 {
      return .Success(.Nil)
    }
    // Make a list containing all values...
    let list : ListType<ConsValue> = listFromMappedCollection(map, postfix: nil) {
      let (key, value) = $0
      return .Vector([key, value])
    }
    // ...then return the second
    switch list {
    case let list as Cons<ConsValue>:
      return .Success(.List(list.next))
    default:
      // Map has zero items
      return .Success(.List(Empty()))
    }
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "argument must be a string, list, vector, map, or nil"))
  }
}

/// Given a single sequence, return nil (if empty) or a list built out of that sequence.
func pr_seq(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".seq"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .Nil: return .Success(.Nil)
  case let .StringAtom(s):
    return .Success(listFromString(s))
  case let .List(l):
    return .Success(l.isEmpty ? .Nil : .List(l))
  case let .Vector(vector):
    // Turn the vector into a list
    return .Success(vector.isEmpty ? .Nil : .List(listFromCollection(vector)))
  case let .Map(m):
    // Turn the map into a list
    if m.isEmpty { return .Success(.Nil) }
    let list : ListType<ConsValue> = listFromMappedCollection(m, postfix: nil) {
      let (key, value) = $0
      return .Vector([key, value])
    }
    return .Success(.List(list))
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "argument must be a string, list, vector, map, or nil"))
  }
}

/// Given a collection and an item to 'add' to the collection, return a new collection with the added item.
func pr_conj(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".conj"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  let coll = args[0]
  let toAdd = args[1]
  switch coll {
  case .Nil:
    return .Success(.List(Cons(toAdd)))
  case .List:
    return pr_cons([toAdd, coll], ctx)
  case let .Vector(vector):
    return .Success(.Vector(vector + [toAdd]))
  case let .Map(m):
    if let vector = toAdd.asVector() {
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

/// Given zero or more arguments which are collections or nil, return a list created by concatenating the arguments.
func pr_concat(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".concat"
  if args.count == 0 {
    return .Success(.List(Empty()))
  }
  var head : ListType<ConsValue> = Empty()

  // Go through the arguments in *reverse* order
  for item in lazy(reverse(args)) {
    switch item {
    case .Nil: continue
    case let .StringAtom(s):
      // Attempt to take the string and turn it into a list which precedes whatever we've built so far.
      if let list = listFromString(s, postfix: head).asList() {
        head = list
      }
      // Otherwise, if nil just skip this string
    case let .List(list):
      // Make a copy of this list, connected to our in-progress list.
      head = list.copy(postfix: head)
    case let .Vector(vector):
      // Add all the items in the vector to our in-progress list.
      head = listFromCollection(vector, prefix: nil, postfix: head)
    case let .Map(map):
      // Add all the key-value pairs in the map to our in-progress list.
      head = listFromMappedCollection(map, postfix: head) {
        let (key, value) = $0
        return .Vector([key, value])
      }
    default:
      return .Failure(EvalError.invalidArgumentError(fn,
        message: "arguments must be strings, lists, vectors, maps, or nil"))
    }
  }
  return .Success(.List(head))
}

/// Given a sequence and an index, return the item at that index, or return an optional 'not found' value.
func pr_nth(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".nth"
  if args.count < 2 || args.count > 3 {
    return .Failure(EvalError.arityError("2 or 3", actual: args.count, fn))
  }
  if let idx = args[1].asInteger() {
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
    case let .List(l):
      for (ctr, item) in enumerate(l) {
        if ctr == idx {
          return .Success(item)
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
func pr_get(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".get"
  if args.count < 2 || args.count > 3 {
    return .Failure(EvalError.arityError("2 or 3", actual: args.count, fn))
  }
  let key = args[1]
  let fallback : ConsValue = args.count == 3 ? args[2] : .Nil
  
  switch args[0] {
  case let .StringAtom(s):
    if let idx = key.asInteger() {
      if let character = characterAtIndex(s, idx) {
        return .Success(.CharAtom(character))
      }
    }
    return .Success(fallback)
  case let .Vector(v):
    if let idx = key.asInteger() {
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
func pr_assoc(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".assoc"
  func updateMapFromArray(raw: [ConsValue], inout starting: MapType) {
    for var i=0; i<raw.count - 1; i += 2 {
      let key = raw[i]
      let value = raw[i+1]
      starting[key] = value
    }
  }

  func updateVectorFromArray(raw: [ConsValue], inout buffer: VectorType, count: Int) -> EvalError? {
    for var i=0; i<raw.count - 1; i += 2 {
      let idx = raw[i]
      if let idx = idx.asInteger() {
        if idx >= 0 && idx < count {
          let value = raw[i+1]
          buffer[idx] = value
        }
        else {
          return EvalError.outOfBoundsError(fn, idx: idx)
        }
      }
      else {
        return EvalError.invalidArgumentError(fn,
          message: "key arguments must be integers if .assoc is called on a vector")
      }
    }
    return nil
  }

  // This function requires at least one collection/nil and one key/index-value pair
  if args.count < 3 {
    return .Failure(EvalError.arityError("3 or more", actual: args.count, fn))
  }
  // Collect all arguments after the first one
  let rest = Array(args[1..<args.count])
  if rest.count % 2 != 0 {
    // Must have an even number of key/index-value pairs
    return .Failure(EvalError.arityError("even number", actual: args.count, fn))
  }
  switch args[0] {
  case .Nil:
    // Put key-value pairs in a new map
    var newMap : MapType = [:]
    updateMapFromArray(rest, &newMap)
    return .Success(.Map(newMap))
  case let .Vector(v):
    // Each pair is an index and a new value. Update a copy of the vector and return that.
    var newVector = v
    let possibleError = updateVectorFromArray(rest, &newVector, v.count)
    if let error = possibleError {
      return .Failure(error)
    }
    return .Success(.Vector(newVector))
  case let .Map(m):
    var newMap = m
    updateMapFromArray(rest, &newMap)
    return .Success(.Map(newMap))
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "first argument must be a vector, map, or nil"))
  }
}

/// Given a map and zero or more keys, return a map with the given keys and corresponding values removed.
func pr_dissoc(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".dissoc"
  if args.count < 1 {
    return .Failure(EvalError.arityError("> 1", actual: args.count, fn))
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

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
    return .Success(.ListLiteral(Cons()))
  }
  let first = Cons(args[0])
  var current = first
  for var i=1; i<args.count; i++ {
    let this = Cons(args[i])
    current.next = this
    current = this
  }
  return .Success(.ListLiteral(first))
}

/// Given zero or more arguments, construct a vector whose components are the arguments (or the empty vector).
func pr_vector(args: [ConsValue], ctx: Context) -> EvalResult {
  return .Success(.VectorLiteral(args))
}

/// Given zero or more arguments, construct a map whose components are the keys and values (or the empty map).
func pr_hashmap(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".hashmap"
  if args.count % 2 != 0 {
    // Must have an even number of arguments
    return .Failure(EvalError.arityError("even number", actual: args.count, fn))
  }
  var buffer : Map = [:]
  for var i=0; i<args.count-1; i += 2 {
    let key = args[i]
    let value = args[i+1]
    buffer[key] = value
  }
  return .Success(.MapLiteral(buffer))
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
  case .NilLiteral:
    // Create a new list consisting of just the first object
    return .Success(.ListLiteral(Cons(first)))
  case let .StringLiteral(s):
    // Create a new list consisting of the first object, followed by the seq of the string
    let list = listFromString(s)
    return pr_cons([first, list], ctx)
  case let .ListLiteral(l):
    // Create a new list consisting of the first object, followed by the second list (if not empty)
    return .Success(.ListLiteral(l.isEmpty ? Cons(first) : Cons(first, next: l)))
  case let .VectorLiteral(v):
    // Create a new list consisting of the first object, followed by a list comprised of the vector's items
    if v.count == 0 {
      return .Success(.ListLiteral(Cons(first)))
    }
    let head = Cons(first)
    var this = head
    for item in v {
      let next = Cons(item)
      this.next = next
      this = next
    }
    return .Success(.ListLiteral(head))
  case let .MapLiteral(m):
    // Create a new list consisting of the first object, followed by a list comprised of vectors containing the map's
    //  key-value pairs
    if m.count == 0 {
      return .Success(.ListLiteral(Cons(first)))
    }
    let head = Cons(first)
    var this = head
    for (key, value) in m {
      let next = Cons(.VectorLiteral([key, value]))
      this.next = next
      this = next
    }
    return .Success(.ListLiteral(head))
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
  case .NilLiteral:
    return .Success(.NilLiteral)
  case let .StringLiteral(s):
    return pr_first([listFromString(s)], ctx)
  case let .ListLiteral(l):
    return .Success(l.isEmpty ? .NilLiteral : l.value)
  case let .VectorLiteral(v):
    return .Success(v.count == 0 ? .NilLiteral : v[0])
  case let .MapLiteral(m):
    // Use a generator to get the first element out of the map.
    var generator = m.generate()
    if let (key, value) = generator.next() {
      return .Success(.VectorLiteral([key, value]))
    }
    return .Success(.NilLiteral)
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
  case .NilLiteral: return .Success(.ListLiteral(Cons()))
  case let .StringLiteral(s):
    return pr_rest([listFromString(s)], ctx)
  case let .ListLiteral(l):
    if let next = l.next {
      // List has more than one item
      return .Success(.ListLiteral(next))
    }
    else {
      // List has zero or one items, return the empty list
      return .Success(.ListLiteral(Cons()))
    }
  case let .VectorLiteral(v):
    if v.count < 2 {
      // Vector has zero or one items
      return .Success(.ListLiteral(Cons()))
    }
    let head = Cons(v[1])
    var this = head
    for var i=2; i<v.count; i++ {
      let next = Cons(v[i])
      this.next = next
      this = next
    }
    return .Success(.ListLiteral(head))
  case let .MapLiteral(m):
    if m.count < 2 {
      // Map has zero or one items
      return .Success(.ListLiteral(Cons()))
    }
    var head : Cons? = nil
    var this = head
    var skippedFirst = false
    for (key, value) in m {
      if !skippedFirst {
        skippedFirst = true
        continue
      }
      let next = Cons(.VectorLiteral([key, value]))
      if let this = this {
        this.next = next
      }
      else {
        head = next
      }
      this = next
    }
    return .Success(.ListLiteral(head!))
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "argument must be a string, list, vector, map, or nil"))
  }
}

/// Given a sequence, return the sequence comprised of all items but the first, or nil if there are no more items.
func pr_next(args: [ConsValue], ctx: Context) -> EvalResult {
  // NOTE: This function appears identical to pr_rest, except for returning .NilLiteral instead of Cons() when there are
  // no more items. I expect this code to diverge if/when lazy seqs are ever implemented, and so it is copied over
  // verbatim rather than being refactored.
  let fn = ".next"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let first = args[0]
  switch first {
  case .NilLiteral: return .Success(.ListLiteral(Cons()))
  case let .StringLiteral(s):
    return pr_next([listFromString(s)], ctx)
  case let .ListLiteral(l):
    if let actualNext = l.next {
      // List has more than one item
      return .Success(.ListLiteral(actualNext))
    }
    else {
      // List has zero or one items, return nil
      return .Success(.NilLiteral)
    }
  case let .VectorLiteral(v):
    if v.count < 2 {
      // Vector has zero or one items
      return .Success(.NilLiteral)
    }
    let head = Cons(v[1])
    var this = head
    for var i=2; i<v.count; i++ {
      let next = Cons(v[i])
      this.next = next
      this = next
    }
    return .Success(.ListLiteral(head))
  case let .MapLiteral(m):
    if m.count < 2 {
      // Map has zero or one items
      return .Success(.NilLiteral)
    }
    var head : Cons? = nil
    var this = head
    var skippedFirst = false
    for (key, value) in m {
      if !skippedFirst {
        skippedFirst = true
        continue
      }
      let next = Cons(.VectorLiteral([key, value]))
      if let this = this {
        this.next = next
      }
      else {
        head = next
      }
      this = next
    }
    return .Success(.ListLiteral(head!))
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
  case .NilLiteral: return .Success(args[0])
  case let .StringLiteral(s):
    return .Success(listFromString(s))
  case let .ListLiteral(l):
    return .Success(l.isEmpty ? .NilLiteral : .ListLiteral(l))
  case let .VectorLiteral(v):
    // Turn the vector into a list
    if v.count == 0 {
      return .Success(.NilLiteral)
    }
    let head = Cons(v[0])
    var this = head
    for var i=1; i<v.count; i++ {
      var next = Cons(v[i])
      this.next = next
      this = next
    }
    return .Success(.ListLiteral(head))
  case let .MapLiteral(m):
    if m.count == 0 {
      return .Success(.NilLiteral)
    }
    var head : Cons? = nil
    var this = head
    for (key, value) in m {
      let next = Cons(.VectorLiteral([key, value]))
      if let this = this {
        this.next = next
      }
      else {
        head = next
      }
      this = next
    }
    return .Success(.ListLiteral(head!))
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "argument must be a string, list, vector, map, or nil"))
  }
}

/// Given zero or more arguments which are collections or nil, return a list created by concatenating the arguments.
func pr_concat(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".concat"
  if args.count == 0 {
    return .Success(.ListLiteral(Cons()))
  }
  var headInitialized = false
  var head = Cons()
  var this = head

  // A helper function responsible for concatenating a list to the in-progress result list starting at 'head'.
  func concatList(list: Cons) {
    if list.isEmpty {
      return
    }
    var head : Cons? = list
    while let actualHead = head {
      if !headInitialized {
        this.value = actualHead.value
        headInitialized = true
      }
      else {
        let next = Cons(actualHead.value)
        this.next = next
        this = next
      }
      head = actualHead.next
    }
  }

  for arg in args {
    switch arg {
    case .NilLiteral: continue
    case let .StringLiteral(s):
      if let list = listFromString(s).asList() {
        concatList(list)
      }
      // Otherwise, if nil just skip this string
    case let .ListLiteral(l):
      concatList(l)
    case let .VectorLiteral(v):
      for item in v {
        if !headInitialized {
          this.value = item
          headInitialized = true
        }
        else {
          let next = Cons(item)
          this.next = next
          this = next
        }
      }
    case let .MapLiteral(m):
      for (key, value) in m {
        if !headInitialized {
          this.value = .VectorLiteral([key, value])
          headInitialized = true
        }
        else {
          let next = Cons(.VectorLiteral([key, value]))
          this.next = next
          this = next
        }
      }
    default:
      return .Failure(EvalError.invalidArgumentError(fn,
        message: "arguments must be strings, lists, vectors, maps, or nil"))
    }
  }
  return .Success(.ListLiteral(head))
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
    case let .StringLiteral(s):
      // We have to walk the string
      if let character = characterAtIndex(s, idx) {
        return .Success(.CharacterLiteral(character))
      }
      else if let fallback = fallback {
        return .Success(fallback)
      }
      else {
        return .Failure(EvalError.outOfBoundsError(fn, idx: idx))
      }
    case let .ListLiteral(l):
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
    case let .VectorLiteral(v):
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
  let fallback : ConsValue = args.count == 3 ? args[2] : .NilLiteral
  
  switch args[0] {
  case let .StringLiteral(s):
    if let idx = key.asInteger() {
      if let character = characterAtIndex(s, idx) {
        return .Success(.CharacterLiteral(character))
      }
    }
    return .Success(fallback)
  case let .VectorLiteral(v):
    if let idx = key.asInteger() {
      if idx >= 0 && idx < v.count {
        return .Success(v[idx])
      }
    }
    return .Success(fallback)
  case let .MapLiteral(m):
    return .Success(m[key] ?? fallback)
  default:
    return .Success(fallback)
  }
}

/// Given a supported collection and one or more key-value pairs, associate the new values with the keys.
func pr_assoc(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".assoc"
  func updateMapFromArray(raw: [ConsValue], inout starting: Map) {
    for var i=0; i<raw.count - 1; i += 2 {
      let key = raw[i]
      let value = raw[i+1]
      starting[key] = value
    }
  }

  func updateVectorFromArray(raw: [ConsValue], inout buffer: Vector, count: Int) -> EvalError? {
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
  case .NilLiteral:
    // Put key-value pairs in a new map
    var newMap : Map = [:]
    updateMapFromArray(rest, &newMap)
    return .Success(.MapLiteral(newMap))
  case let .VectorLiteral(v):
    // Each pair is an index and a new value. Update a copy of the vector and return that.
    var newVector = v
    let possibleError = updateVectorFromArray(rest, &newVector, v.count)
    if let error = possibleError {
      return .Failure(error)
    }
    return .Success(.VectorLiteral(newVector))
  case let .MapLiteral(m):
    var newMap = m
    updateMapFromArray(rest, &newMap)
    return .Success(.MapLiteral(newMap))
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
  case .NilLiteral:
    return .Success(.NilLiteral)
  case let .MapLiteral(m):
    var newMap = m
    for var i=1; i<args.count; i++ {
      newMap.removeValueForKey(args[i])
    }
    return .Success(.MapLiteral(newMap))
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be nil or a map"))
  }
}

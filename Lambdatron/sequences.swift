//
//  sequences.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/7/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

// MARK: Utility functions

/// Return a new sequence resulting from prepending the given item to an existing sequence.
func cons(_ item: Value, next seq: SeqType) -> SeqType {
  return Cons(item, next: seq)
}

/// Return a sequence from the given sequence, or nil if the sequence is empty. Lazy sequences will be forced.
func sequence(fromSeq seq: SeqType) -> EvalOptional<SeqType>? {
  let s : EvalOptional<SeqType>
  if let seq = seq as? LazySeq {
    s = seq.force()
  }
  else {
    s = .Just(seq)
  }

  switch s {
  case let .Just(seq):
    // Now check to see if it's empty
    switch seq.isEmpty {
    case let .Just(seqIsEmpty):
      return seqIsEmpty ? nil : s
    case let .Error(err):
      return .Error(err)
    }
  case .Error: return s
  }
}

/// Return a new single-element sequence.
func sequence(_ item: Value) -> SeqType {
  return Cons(item)
}

/// Return a new sequence consisting of two items.
func sequence(_ first: Value, _ second: Value) -> SeqType {
  return Cons(first, next: Cons(second))
}

/// Return a new sequence consisting of three items.
func sequence(_ first: Value, _ second: Value, _ third: Value) -> SeqType {
  return ContiguousList([first, second, third])
}

/// Return a new sequence containing multiple items.
func sequence(fromItems items: [Value]) -> SeqType {
  return items.isEmpty ? Empty() : ContiguousList(items)
}


// MARK: Protocol

/// A protocol representing sequence types.
public protocol SeqType {
  /// Return the first item within the sequence.
  var first : EvalOptional<Value> { get }

  /// Return the sequence comprised of all items except for the first item.
  var rest : EvalOptional<SeqType> { get }

  /// Return true if the sequence is empty.
  var isEmpty : EvalOptional<Bool> { get }

  var hashValue : Int { get }
}


// MARK: Sequence implementations

/// A sequence type representing a view into an immutable string.
struct StringSequenceView : SeqType {
  let underlying : String
  let this : String.Index
  let next : SeqType
  var hashValue : Int { return underlying.hashValue }

  var first : EvalOptional<Value> {
    if underlying.isEmpty {
      return .Just(.nilValue)
    }
    precondition(this < underlying.endIndex, "StringSequenceView violates precondition: index must be valid")
    return .Just(.char(underlying[this]))
  }

  var rest : EvalOptional<SeqType> {
    if underlying.isEmpty {
      // Cannot get beforeEndIndex for an empty string, so return early here.
      return .Just(next)
    }
    let beforeEndIndex = underlying.index(before: underlying.endIndex)
    if underlying.characters.count > 1 && this < beforeEndIndex {
      return .Just(StringSequenceView(underlying, next: next, position: underlying.index(after: this)))
    }
    return .Just(next)
  }

  var isEmpty : EvalOptional<Bool> {
    let empty = !(this < underlying.endIndex)
    return empty ? next.isEmpty : .Just(false)
  }

  init(_ string: String, next: SeqType = Empty(), position: String.Index? = nil) {
    underlying = string; self.next = next; this = position ?? string.startIndex
  }
}

/// A sequence type representing a view into an immutable vector.
struct VectorSequenceView : SeqType {
  let underlying : VectorType
  let this : VectorType.Index
  let next : SeqType
  var hashValue : Int { return underlying.isEmpty ? this : underlying[0].hashValue }

  var first : EvalOptional<Value> {
    if underlying.isEmpty {
      return .Just(.nilValue)
    }
    precondition(this < underlying.count, "VectorSequenceView violates precondition: index must be valid")
    return .Just(underlying[this])
  }

  var rest : EvalOptional<SeqType> {
    if this < underlying.count - 1 {
      return .Just(VectorSequenceView(underlying, next: next, position: this + 1))
    }
    return .Just(next)
  }

  var isEmpty : EvalOptional<Bool> {
    let empty = !(this < underlying.count)
    return empty ? next.isEmpty : .Just(false)
  }

  init(_ vector: VectorType, next: SeqType = Empty(), position: Int = 0) {
    underlying = vector; self.next = next; this = position
  }
}

/// A sequence type representing a view into an immutable hashmap.
struct HashmapSequenceView : SeqType {
  let underlying : MapType
  let this : MapType.Index
  let next : SeqType
  var hashValue : Int { return underlying.count }

  var first : EvalOptional<Value> {
    if underlying.isEmpty {
      return .Just(.nilValue)
    }
    precondition(this < underlying.endIndex, "HashmapSequenceView violates precondition: index must be valid")
    let (key, value) = underlying[this]
    return .Just(.vector([key, value]))
  }

  var rest : EvalOptional<SeqType> {
    let nextIndex = underlying.index(after: this)
    if underlying.count > 1 && nextIndex < underlying.endIndex {
      return .Just(HashmapSequenceView(underlying, next: next, position: nextIndex))
    }
    return .Just(next)
  }

  var isEmpty : EvalOptional<Bool> {
    let empty = !(this < underlying.endIndex)
    return empty ? next.isEmpty : .Just(false)
  }

  init(_ m: MapType, next: SeqType = Empty(), position: MapType.Index? = nil) {
    underlying = m; self.next = next; this = position ?? m.startIndex
  }
}

/// A sequence type representing an immutable non-empty persistent list whose items are stored adjacent to each other.
final class ContiguousList : SeqType {
  private let items : [Value]
  let next : SeqType
  var hashValue : Int { return items[0].hashValue }

  var first : EvalOptional<Value> {
    return .Just(items[0])
  }

  var rest : EvalOptional<SeqType> {
    return items.count > 1 ? .Just(VectorSequenceView(items, next: next, position: 1)) : .Just(next)
  }

  var backingArray : [Value] {
    return items
  }

  var isEmpty : EvalOptional<Bool> { return .Just(false) }

  /// Build a ContiguousList out of another sequence.
  static func sequence(from seq: SeqType, next: SeqType = Empty()) -> EvalOptional<SeqType> {
    var buffer : [Value] = []
    for item in SeqIterator(seq) {
      switch item {
      case let .Just(s): buffer.append(s)
      case let .Error(err): return .Error(err)
      }
    }
    return .Just(ContiguousList(buffer, next: next))
  }

  init(_ items : [Value], next: SeqType = Empty()) {
    precondition(!items.isEmpty, "ContiguousList cannot be created with an empty array of items")
    self.items = items; self.next = next
  }
}

/// A sequence type representing a lazy seq, which lazily evaluates a thunk to produce its sequence.
final class LazySeq : SeqType {
  private enum State {
    case Thunk(Value, Context)
    case Cached(SeqType)
  }
  private var state : State

  var hashValue : Int { return ObjectIdentifier(self).hashValue }

  /// Compute or retrieve the value of the sequence as a realized list.
  private func force() -> EvalOptional<SeqType> {
    switch state {
    case let .Thunk(thunk, context):
      let result = context.apply(arguments: Params(), toFunction: thunk, "LazySeq-thunk")
      switch result {
      case let .Success(item):
        if case .nilValue = item {
          // If the thunk returns nil, we should return the empty list
          state = .Cached(Empty())
          return .Just(Empty())
        }
        // Turn the item into a sequence
        let result = pr_seq(Params(item), context)
        switch result {
        case let .Success(item):
          if case let .seq(seq) = item {
            state = .Cached(seq)
            return .Just(seq)
          }
          else if case .nilValue = item {
            state = .Cached(Empty())
            return .Just(Empty())
          }
          state = .Cached(Empty())
          return .Error(EvalError.invalidArgumentError("LazySeq-thunk",
            message: "Lazy sequence thunk did not return a sequence"))
        case .Recur:
          // Never valid here
          state = .Cached(Empty())
          return .Error(EvalError(.RecurMisuseError))
        case let .Failure(err):
          // Item wasn't something that could be converted to a sequence
          state = .Cached(Empty())
          return .Error(err)
        }
      case .Recur:
        // Never valid here
        state = .Cached(Empty())
        return .Error(EvalError(.RecurMisuseError))
      case let .Failure(err):
        state = .Cached(Empty())
        return .Error(err)
      }
    case let .Cached(seq):
      // No need to do anything. We already got the sequence.
      return .Just(seq)
    }
  }

  var isEmpty : EvalOptional<Bool> {
    let result = force()
    switch result {
    case let .Just(list): return list.isEmpty
    case let .Error(err): return .Error(err)
    }
  }

  var first : EvalOptional<Value> {
    let result = force()
    switch result {
    case let .Just(list): return list.first
    case let .Error(err): return .Error(err)
    }
  }

  var rest : EvalOptional<SeqType> {
    let result = force()
    switch result {
    case let .Just(list): return list.rest
    case .Error: return result
    }
  }

  init(_ form: Value, ctx: Context) {
    state = .Thunk(form, ctx)
  }
}

/// A sequence type representing a cons cell prepended onto other sequence types.
final class Cons : SeqType {
  private var value : Value
  private var next : SeqType

  var hashValue : Int { return value.hashValue }

  var first : EvalOptional<Value> { return .Just(value) }
  var rest : EvalOptional<SeqType> { return .Just(next) }
  var isEmpty : EvalOptional<Bool> { return .Just(false) }

  // Initialize a list constructed from an element preceding an existing list.
  private init(_ value: Value, next: SeqType = Empty()) {
    self.value = value; self.next = next
  }
}

/// A sequence type representing an empty list.
struct Empty : SeqType {
  var hashValue : Int { return 0 }

  var first : EvalOptional<Value> { return .Just(.nilValue) }
  var rest : EvalOptional<SeqType> { return .Just(self) }
  var isEmpty : EvalOptional<Bool> { return .Just(true) }
}


// MARK: Sequence iterator

/// An iterator that allows Swift iteration through a sequence type.
struct SeqIterator : Sequence, IteratorProtocol {
  private var seq : SeqType
  private var prefix : Value?

  func generate() -> SeqIterator {
    return self
  }

  mutating func next() -> EvalOptional<Value>? {
    if let pfx = prefix {
      // Handle the prefix, if any
      prefix = nil
      return .Just(pfx)
    }
    switch seq.isEmpty {
    case let .Just(sequenceIsEmpty):
      // Check if the sequence is empty or not
      if sequenceIsEmpty {
        return nil
      }
      let first = seq.first
      switch first {
      case let .Just(value):
        // Got the current item. Now, try to get the rest of the sequence.
        switch seq.rest {
        case let .Just(sequence):
          seq = sequence
          return .Just(value)
        case let .Error(err):
          // Could not successfully get the rest of the sequence
          seq = Empty()
          return .Error(err)
        }
      case .Error:
        // Could not successfully get the current item
        seq = Empty(); return first
      }
    case let .Error(err):
      // Could not successfully check if the sequence is empty or not
      seq = Empty()
      return .Error(err)
    }
  }

  init(_ value: SeqType) {
    seq = value
  }

  init?(_ value: Value, prefix: Value? = nil) {
    self.prefix = prefix
    switch value {
    case .nilValue: seq = Empty()
    case let .seq(s): seq = s
    case let .string(string): seq = StringSequenceView(string)
    case let .vector(vector): seq = VectorSequenceView(vector)
    case let .map(map): seq = HashmapSequenceView(map)
    default: return nil
    }
  }
}

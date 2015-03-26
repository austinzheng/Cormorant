//
//  sequences.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/7/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

// MARK: Result enums

public enum BoolOrEvalError : BooleanLiteralConvertible {
  case Boolean(Bool)
  case Error(EvalError)

  public init(booleanLiteral value: Bool) { self = .Boolean(value) }

  /// Unboxes the boolean value. This will crash the interpreter if used improperly (i.e. an error is being stored).
  func force() -> Bool {
    switch self {
    case let .Boolean(b): return b
    case .Error: internalError("BoolOrEvalError's 'force' method called improperly")
    }
  }
}

public enum SeqResult {
  case Seq(SeqType)
  case Error(EvalError)
}

public enum ObjectResult {
  case Success(ConsValue)
  case Error(EvalError)
}


// MARK: Utility functions

/// Return a new sequence resulting from prepending the given item to an existing sequence.
func cons(item: ConsValue, next seq: SeqType) -> SeqType {
  return Cons(item, next: seq)
}

/// Return a sequence from the given sequence, or nil if the sequence is empty. Lazy sequences will be forced.
func sequence(seq: SeqType) -> SeqResult? {
  let s : SeqResult
  if let seq = seq as? LazySeq {
    s = seq.force()
  }
  else {
    s = .Seq(seq)
  }

  switch s {
  case let .Seq(seq):
    // Now check to see if it's empty
    switch seq.isEmpty {
    case let .Boolean(seqIsEmpty):
      return seqIsEmpty ? nil : s
    case let .Error(err):
      return .Error(err)
    }
  case let .Error: return s
  }
}

/// Return a new single-element sequence.
func sequence(item: ConsValue) -> SeqType {
  return Cons(item)
}

/// Return a new sequence consisting of two items.
func sequence(first: ConsValue, second: ConsValue) -> SeqType {
  return Cons(first, next: Cons(second))
}

/// Return a new sequence consisting of three items.
func sequence(first: ConsValue, second: ConsValue, third: ConsValue) -> SeqType {
  return ContiguousList([first, second, third])
}

/// Return a new sequence containing multiple items.
func sequence(items: [ConsValue]) -> SeqType {
  return items.isEmpty ? Empty() : ContiguousList(items)
}


// MARK: Protocol

/// A protocol representing sequence types.
public protocol SeqType {
  /// Return the first item within the sequence.
  var first : ObjectResult { get }

  /// Return the sequence comprised of all items except for the first item.
  var rest : SeqResult { get }

  /// Return true if the sequence is empty.
  var isEmpty : BoolOrEvalError { get }

  var hashValue : Int { get }
}


// MARK: Sequence implementations

/// A sequence type representing a view into an immutable string.
struct StringSequenceView : SeqType {
  let underlying : String
  let this : String.Index
  let next : SeqType
  var hashValue : Int { return underlying.hashValue }

  var first : ObjectResult {
    if underlying.isEmpty {
      return .Success(.Nil)
    }
    precondition(this < underlying.endIndex, "StringSequenceView violates precondition: index must be valid")
    return .Success(.CharAtom(underlying[this]))
  }

  var rest : SeqResult {
    if count(underlying) > 1 && this < underlying.endIndex.predecessor() {
      return .Seq(StringSequenceView(underlying, next: next, position: this.successor()))
    }
    return .Seq(next)
  }

  var isEmpty : BoolOrEvalError {
    let empty = !(this < underlying.endIndex)
    return empty ? next.isEmpty : .Boolean(false)
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

  var first : ObjectResult {
    if underlying.isEmpty {
      return .Success(.Nil)
    }
    precondition(this < underlying.count, "VectorSequenceView violates precondition: index must be valid")
    return .Success(underlying[this])
  }

  var rest : SeqResult {
    if this < underlying.count - 1 {
      return .Seq(VectorSequenceView(underlying, next: next, position: this + 1))
    }
    return .Seq(next)
  }

  var isEmpty : BoolOrEvalError {
    let empty = !(this < underlying.count)
    return empty ? next.isEmpty : .Boolean(false)
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

  var first : ObjectResult {
    if underlying.isEmpty {
      return .Success(.Nil)
    }
    precondition(this < underlying.endIndex, "HashmapSequenceView violates precondition: index must be valid")
    let (key, value) = underlying[this]
    return .Success(.Vector([key, value]))
  }

  var rest : SeqResult {
    if underlying.count > 1 && this.successor() < underlying.endIndex {
      return .Seq(HashmapSequenceView(underlying, next: next, position: this.successor()))
    }
    return .Seq(next)
  }

  var isEmpty : BoolOrEvalError {
    let empty = !(this < underlying.endIndex)
    return empty ? next.isEmpty : .Boolean(false)
  }

  init(_ m: MapType, next: SeqType = Empty(), position: MapType.Index? = nil) {
    underlying = m; self.next = next; this = position ?? m.startIndex
  }
}

/// A sequence type representing an immutable non-empty persistent list whose items are stored adjacent to each other.
final class ContiguousList : SeqType {
  private let items : [ConsValue]
  let next : SeqType
  var hashValue : Int { return items[0].hashValue }

  var first : ObjectResult {
    return .Success(items[0])
  }

  var rest : SeqResult {
    if items.count > 1 {
      return .Seq(VectorSequenceView(items, next: next, position: 1))
    }
    return .Seq(next)
  }

  var backingArray : [ConsValue] {
    return items
  }

  var isEmpty : BoolOrEvalError { return false }

  /// Build a ContiguousList out of another sequence.
  class func fromSequence(seq: SeqType, next: SeqType = Empty()) -> SeqResult {
    var buffer : [ConsValue] = []
    for item in SeqIterator(seq) {
      switch item {
      case let .Success(s): buffer.append(s)
      case let .Error(err): return .Error(err)
      }
    }
    return .Seq(ContiguousList(buffer, next: next))
  }

  init(_ items : [ConsValue], next: SeqType = Empty()) {
    precondition(!items.isEmpty, "ContiguousList cannot be created with an empty array of items")
    self.items = items; self.next = next
  }
}

/// A sequence type representing a lazy seq, which lazily evaluates a thunk to produce its sequence.
final class LazySeq : SeqType {
  private enum State {
    case Thunk(ConsValue, Context)
    case Cached(SeqType)
  }
  private var state : State

  var hashValue : Int { return ObjectIdentifier(self).hashValue }

  /// Compute or retrieve the value of the sequence as a realized list.
  private func force() -> SeqResult {
    switch state {
    case let .Thunk(thunk, context):
      let result = apply(thunk, Params(), context, "LazySeq-thunk")
      switch result {
      case let .Success(item):
        if item.isNil {
          // If the thunk returns nil, we should return the empty list
          state = .Cached(Empty())
          return .Seq(Empty())
        }
        // Turn the item into a sequence
        let result = pr_seq(Params(item), context)
        switch result {
        case let .Success(item):
          if let seq = item.asSeq {
            state = .Cached(seq)
            return .Seq(seq)
          }
          else if item.isNil {
            state = .Cached(Empty())
            return .Seq(Empty())
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
      return .Seq(seq)
    }
  }

  var isEmpty : BoolOrEvalError {
    let result = force()
    switch result {
    case let .Seq(list): return list.isEmpty
    case let .Error(err): return .Error(err)
    }
  }

  var first : ObjectResult {
    let result = force()
    switch result {
    case let .Seq(list): return list.first
    case let .Error(err): return .Error(err)
    }
  }

  var rest : SeqResult {
    let result = force()
    switch result {
    case let .Seq(list): return list.rest
    case .Error: return result
    }
  }

  init(_ form: ConsValue, ctx: Context) {
    state = .Thunk(form, ctx)
  }
}

/// A sequence type representing a cons cell prepended onto other sequence types.
final class Cons : SeqType {
  private var value : ConsValue
  private var next : SeqType

  var hashValue : Int { return value.hashValue }

  var first : ObjectResult { return .Success(value) }
  var rest : SeqResult { return .Seq(next) }
  var isEmpty : BoolOrEvalError { return false }

  // Initialize a list constructed from an element preceding an existing list.
  private init(_ value: ConsValue, next: SeqType = Empty()) {
    self.value = value; self.next = next
  }
}

/// A sequence type representing an empty list.
struct Empty : SeqType {
  var hashValue : Int { return 0 }

  var first : ObjectResult { return .Success(.Nil) }
  var rest : SeqResult { return .Seq(self) }
  var isEmpty : BoolOrEvalError { return true }
}


// MARK: Sequence iterator

/// An iterator that allows Swift iteration through a sequence type.
struct SeqIterator : SequenceType, GeneratorType {
  private var seq : SeqType
  private var prefix : ConsValue?

  func generate() -> SeqIterator {
    return self
  }

  mutating func next() -> ObjectResult? {
    if let pfx = prefix {
      // Handle the prefix, if any
      prefix = nil
      return .Success(pfx)
    }
    switch seq.isEmpty {
    case let .Boolean(sequenceIsEmpty):
      // Check if the sequence is empty or not
      if sequenceIsEmpty {
        return nil
      }
      let first = seq.first
      switch first {
      case let .Success(value):
        // Got the current item. Now, try to get the rest of the sequence.
        switch seq.rest {
        case let .Seq(sequence):
          seq = sequence
          return .Success(value)
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

  init?(_ value: ConsValue, prefix: ConsValue? = nil) {
    self.prefix = prefix
    switch value {
    case let .Nil: seq = Empty()
    case let .Seq(s): seq = s
    case let .StringAtom(string): seq = StringSequenceView(string)
    case let .Vector(vector): seq = VectorSequenceView(vector)
    case let .Map(map): seq = HashmapSequenceView(map)
    default: return nil
    }
  }
}

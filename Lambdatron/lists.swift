//
//  lists.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/29/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Given a sequence and an optional prefix element, build a new list.
func listFromCollection<T, U : SequenceType where T == U.Generator.Element>(coll: U, prefix: T? = nil, postfix: ListType<T>? = nil) -> ListType<T> {
  let tail : ListType<T> = postfix ?? Empty()
  var head : Cons<T>? = {
    if let prefix = prefix { return Cons(prefix, next: tail) }
    return nil
  }()
  var this : Cons<T>? = head
  // Note: lazy reverse iteration is broken, so we need to use this slightly less elegant approach.
  for item in coll {
    if let initializedThis = this {
      let next = Cons(item, next: tail)
      initializedThis.next = next
      this = next
    }
    else {
      // Need to make the first head
      head = Cons(item, next: tail)
      this = head
    }
  }
  // If the list is completely empty, return the tail value instead.
  return head ?? tail
}

/// Given a sequence and a mapping function from the sequence's element type to the desired list element type, build
/// a new list.
func listFromMappedCollection<T, U : SequenceType, V where T == U.Generator.Element>(coll: U, postfix: ListType<V>? = nil, map: T -> V) -> ListType<V> {
  let tail : ListType<V> = postfix ?? Empty()
  var head : Cons<V>?, this : Cons<V>? = nil

  for item in coll {
    let mapped = map(item)
    if let initializedThis = this {
      let next = Cons(mapped, next: tail)
      initializedThis.next = next
      this = next
    }
    else {
      head = Cons(mapped, next: tail)
      this = head
    }
  }
  return head ?? tail
}

/// A convenience function that builds a list from a variable number of similarly-typed arguments.
func listFromItems<T>(items: T...) -> ListType<T> {
  return listFromCollection(items)
}

/// An abstract class representing a linked list.
public class ListType<T : Hashable> : Hashable, SequenceType {
  public var hashValue : Int { return 0 }

  public final var isEmpty : Bool {
    return self is Empty
  }

  public final func getValue() -> T? {
    switch self {
    case let cons as Cons<T>:
      return cons.value
    default:
      return nil
    }
  }

  /// Return a new copy of this list.
  final func copy(postfix: ListType<T>? = nil) -> ListType<T> {
    return listFromCollection(self, prefix: nil, postfix: postfix)
  }

  private init() { }

  public final func generate() -> ListGenerator<T> {
    return ListGenerator(head: self)
  }
}

/// A non-empty node in a linked list.
public final class Cons<T : Hashable> : ListType<T> {
  // Should really be let, but this makes certain internal operations less cumbersome.
  private(set) var next : ListType<T>
  public var value: T

  override public var hashValue : Int { return value.hashValue }

  // Initialize a single-element list.
  init(_ value: T) {
    self.value = value; self.next = Empty()
  }

  // Initialize a list constructed from an element preceding an existing list.
  init(_ value: T, next: ListType<T>) {
    self.value = value; self.next = next
  }
}

/// An empty linked list.
public final class Empty<T : Hashable> : ListType<T> { }

/// A struct representing a generator for lists.
public struct ListGenerator<T : Hashable> : GeneratorType {
  var currentNode : ListType<T>

  init(head: ListType<T>) {
    currentNode = head
  }

  public mutating func next() -> T? {
    switch currentNode {
    case let node as Cons<T>:
      let value = node.value
      currentNode = node.next
      return value
    default:
      return nil
    }
  }
}

/// A struct wrapping a linked list; iterating through a ValueNodeList produces a tuple of both values as well as the
/// associated nodes.
struct ValueNodeList<T : Hashable> : SequenceType {
  let list : ListType<T>
  init(_ list : ListType<T>) { self.list = list }

  func generate() -> ValueNodeListGenerator<T> {
    return ValueNodeListGenerator(head: list)
  }
}

struct ValueNodeListGenerator<T : Hashable> : GeneratorType {
  var currentNode : ListType<T>
  init(head: ListType<T>) { currentNode = head }

  mutating func next() -> (T, Cons<T>)? {
    switch currentNode {
    case let node as Cons<T>:
      let value = node.value
      currentNode = node.next
      return (value, node)
    default:
      return nil
    }
  }
}

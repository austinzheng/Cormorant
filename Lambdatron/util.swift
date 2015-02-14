//
//  util.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/30/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// Force the program to exit if something is wrong. This function is intended only to represent bugs in the Lambdatron
/// interpreter and should never be invoked at runtime; if it is invoked there is a bug in the interpreter code.
@noreturn func internalError(message: @autoclosure () -> String) {
  println("Internal error: \(message())")
  exit(EXIT_FAILURE)
}

// MARK: Reference wrapper for structs

final class Box<T> {
  let value : T
  init(_ value: T) { self.value = value }

  subscript() -> T {
    return value
  }
}


// MARK: Swift string helpers

/// Return whether or not a Swift character is a member of an NSCharacterSet.
func characterIsMemberOfSet(c: Character, set: NSCharacterSet) -> Bool {
  let primitive = String(c).utf16[0] as unichar
  return set.characterIsMember(primitive)
}

/// Retrieve a character within a Swift string, or nil if the provided index is out of bounds. This is an O(n)
/// operation with respect to the length of the string.
func characterAtIndex(s: String, idx: Int) -> Character? {
  for (stringIdx, character) in enumerate(s) {
    if stringIdx == idx {
      return character
    }
  }
  return nil
}

/// Retrieve the first character in a Swift string.
func firstCharacter(s: String) -> Character {
  // Precondition: string is not empty
  assert(!s.isEmpty)
  return characterAtIndex(s, 0)!
}

/// Build a list out of a string, or return the nil literal if the string is empty.
func listFromString(s: String, postfix: ListType<ConsValue>? = nil) -> ConsValue {
  if s.isEmpty {
    return .Nil
  }
  // The 'map' takes each character and wraps it in a CharAtom().
  let list : ListType<ConsValue> = listFromMappedCollection(s, postfix: postfix) { .CharAtom($0) }
  return .List(list)
}

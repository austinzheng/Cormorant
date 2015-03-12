//
//  TestAssoc.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/15/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the '.assoc' built-in function.
class TestAssocBuiltin : InterpreterTest {

  /// .assoc should properly build a map when its first argument is nil.
  func testWithNil() {
    expectThat("(.assoc nil \"foo\" 1)", shouldEvalTo: mapWithItems((.StringAtom("foo"), 1)))
    expectThat("(.assoc nil \\a 10 \\b 20 \\c 30)", shouldEvalTo:
      mapWithItems((.CharAtom("a"), 10), (.CharAtom("b"), 20), (.CharAtom("c"), 30)))
  }

  /// .assoc should properly add key-value pairs to a map.
  func testMapsWithNewKeys() {
    expectThat("(.assoc {} 1 true 2 false 3 true)", shouldEvalTo:
      mapWithItems((1, true), (2, false), (3, true)))
    expectThat("(.assoc {\\a \"foo\"} \"bar\" nil true 152)", shouldEvalTo:
      mapWithItems((.CharAtom("a"), .StringAtom("foo")), (.StringAtom("bar"), .Nil), (true, 152)))
  }

  /// .assoc should properly update key-value pairs in a map.
  func testMapsWithUpdatedValues() {
    expectThat("(.assoc {\\a \"foo\" \\b \"bar\"} \\a \"baz\")", shouldEvalTo:
      mapWithItems((.CharAtom("a"), .StringAtom("baz")), (.CharAtom("b"), .StringAtom("bar"))))
    expectThat("(.assoc {true 152 nil 99.18 false 999} true 32 false \\z nil nil)", shouldEvalTo:
      mapWithItems((true, 32), (false, .CharAtom("z")), (.Nil, .Nil)))
    expectThat("(.assoc {true 9} true \"foobar\" true \"baz\")", shouldEvalTo: mapWithItems((true, .StringAtom("baz"))))
  }

  /// .assoc should append a value if called with a key equal to the vector length.
  func testVectorsWithAppendedValues() {
    expectThat("(.assoc [] 0 true)", shouldEvalTo: vectorWithItems(ConsValue.BoolAtom(true)))
    expectThat("(.assoc [1 2] 2 \"foo\")", shouldEvalTo: vectorWithItems(1, 2, .StringAtom("foo")))
    expectThat("(.assoc [1 2] 2 \"foo\" 2 \"bar\" 3 \"baz\" 4 \"qux\")", shouldEvalTo:
      vectorWithItems(1, 2, .StringAtom("bar"), .StringAtom("baz"), .StringAtom("qux")))
  }

  /// .assoc should properly update values in a vector.
  func testVectorsWithUpdatedValues() {
    expectThat("(.assoc [1 2 3] 0 true)", shouldEvalTo: vectorWithItems(true, 2, 3))
    expectThat("(.assoc [1 2 3] 0 true 1 false 2 nil)", shouldEvalTo: vectorWithItems(true, false, .Nil))
    expectThat("(.assoc [\"foo\", \"bar\", \"baz\"] 1 \"foobar\" 2 \\newline)", shouldEvalTo:
      vectorWithItems(.StringAtom("foo"), .StringAtom("foobar"), .CharAtom("\n")))
  }

  /// .assoc should reject keys that are out of bounds when called with a vector.
  func testVectorsWithOutOfBoundKeys() {
    expectThat("(.assoc [1 2 3] 4 true)", shouldFailAs: .OutOfBoundsError)
    expectThat("(.assoc [1 2 3] -1 true)", shouldFailAs: .OutOfBoundsError)
    expectThat("(.assoc [1 2 3] 2 true 4 false)", shouldFailAs: .OutOfBoundsError)
  }

  /// .assoc should reject non-integer keys when called with a vector.
  func testVectorsWithInvalidKeys() {
    expectThat("(.assoc [1 2 3] true true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc [1 2 3] false true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc [1 2 3] 1.000 true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc [1 2 3] true true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc [1 2 3] \"1\" true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc [1 2 3] :foo true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc [1 2 3] 'foo true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc [1 2 3] #\"[0-9]+\" true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc [1 2 3] .assoc true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc [1 2 3] '(1) true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc [1 2 3] [1] true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc [1 2 3] {1 1} true)", shouldFailAs: .InvalidArgumentError)
  }

  /// .assoc should reject first arguments that aren't nil, maps, or vectors.
  func testWithInvalidCollections() {
    expectThat("(.assoc true :a 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc false :a 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc -5992 :a 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc 0.0001 :a 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc \"hello\" :a 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc \\z :a 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc :foobar :a 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc 'foobar :a 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc '(1 2 3) 0 :a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc #\"[0-9]+\" :a 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.assoc .assoc :a 1)", shouldFailAs: .InvalidArgumentError)
  }

  /// .assoc should take a collection and at least one key-value pair, but reject keys without values.
  func testArity() {
    expectArityErrorFrom("(.assoc)")
    expectArityErrorFrom("(.assoc {})")
    expectArityErrorFrom("(.assoc {} :a)")
    expectArityErrorFrom("(.assoc {} :a 1 :b 2 :c)")
  }
}

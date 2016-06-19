//
//  TestAssoc.swift
//  Cormorant
//
//  Created by Austin Zheng on 2/15/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
@testable import Cormorant

/// Test the '.assoc' built-in function.
class TestAssocBuiltin : InterpreterTest {

  /// .assoc should properly build a map when its first argument is nil.
  func testWithNil() {
    expectThat("(.assoc nil \"foo\" 1)", shouldEvalTo: map(containing: (.string("foo"), 1)))
    expectThat("(.assoc nil \\a 10 \\b 20 \\c 30)", shouldEvalTo:
      map(containing: (.char("a"), 10), (.char("b"), 20), (.char("c"), 30)))
  }

  /// .assoc should properly add key-value pairs to a map.
  func testMapsWithNewKeys() {
    expectThat("(.assoc {} 1 true 2 false 3 true)", shouldEvalTo:
      map(containing: (1, true), (2, false), (3, true)))
    expectThat("(.assoc {\\a \"foo\"} \"bar\" nil true 152)", shouldEvalTo:
      map(containing: (.char("a"), .string("foo")), (.string("bar"), .nilValue), (true, 152)))
  }

  /// .assoc should properly update key-value pairs in a map.
  func testMapsWithUpdatedValues() {
    expectThat("(.assoc {\\a \"foo\" \\b \"bar\"} \\a \"baz\")", shouldEvalTo:
      map(containing: (.char("a"), .string("baz")), (.char("b"), .string("bar"))))
    expectThat("(.assoc {true 152 nil 99.18 false 999} true 32 false \\z nil nil)", shouldEvalTo:
      map(containing: (true, 32), (false, .char("z")), (.nilValue, .nilValue)))
    expectThat("(.assoc {true 9} true \"foobar\" true \"baz\")", shouldEvalTo: map(containing: (true, .string("baz"))))
  }

  /// .assoc should append a value if called with a key equal to the vector length.
  func testVectorsWithAppendedValues() {
    expectThat("(.assoc [] 0 true)", shouldEvalTo: vector(containing: .bool(true)))
    expectThat("(.assoc [1 2] 2 \"foo\")", shouldEvalTo: vector(containing: 1, 2, .string("foo")))
    expectThat("(.assoc [1 2] 2 \"foo\" 2 \"bar\" 3 \"baz\" 4 \"qux\")", shouldEvalTo:
      vector(containing: 1, 2, .string("bar"), .string("baz"), .string("qux")))
  }

  /// .assoc should properly update values in a vector.
  func testVectorsWithUpdatedValues() {
    expectThat("(.assoc [1 2 3] 0 true)", shouldEvalTo: vector(containing: true, 2, 3))
    expectThat("(.assoc [1 2 3] 0 true 1 false 2 nil)", shouldEvalTo: vector(containing: true, false, .nilValue))
    expectThat("(.assoc [\"foo\", \"bar\", \"baz\"] 1 \"foobar\" 2 \\newline)", shouldEvalTo:
      vector(containing: .string("foo"), .string("foobar"), .char("\n")))
  }

  /// .assoc should reject keys that are out of bounds when called with a vector.
  func testVectorsWithOutOfBoundKeys() {
    expectThat("(.assoc [1 2 3] 4 true)", shouldFailAs: .OutOfBoundsError)
    expectThat("(.assoc [1 2 3] -1 true)", shouldFailAs: .OutOfBoundsError)
    expectThat("(.assoc [1 2 3] 2 true 4 false)", shouldFailAs: .OutOfBoundsError)
  }

  /// .assoc should reject non-integer keys when called with a vector.
  func testVectorsWithInvalidKeys() {
    expectInvalidArgumentErrorFrom("(.assoc [1 2 3] true true)")
    expectInvalidArgumentErrorFrom("(.assoc [1 2 3] false true)")
    expectInvalidArgumentErrorFrom("(.assoc [1 2 3] 1.000 true)")
    expectInvalidArgumentErrorFrom("(.assoc [1 2 3] true true)")
    expectInvalidArgumentErrorFrom("(.assoc [1 2 3] \"1\" true)")
    expectInvalidArgumentErrorFrom("(.assoc [1 2 3] :foo true)")
    expectInvalidArgumentErrorFrom("(.assoc [1 2 3] 'foo true)")
    expectInvalidArgumentErrorFrom("(.assoc [1 2 3] #\"[0-9]+\" true)")
    expectInvalidArgumentErrorFrom("(.assoc [1 2 3] .assoc true)")
    expectInvalidArgumentErrorFrom("(.assoc [1 2 3] '(1) true)")
    expectInvalidArgumentErrorFrom("(.assoc [1 2 3] [1] true)")
    expectInvalidArgumentErrorFrom("(.assoc [1 2 3] {1 1} true)")
  }

  /// .assoc should reject first arguments that aren't nil, maps, or vectors.
  func testWithInvalidCollections() {
    expectInvalidArgumentErrorFrom("(.assoc true :a 1)")
    expectInvalidArgumentErrorFrom("(.assoc false :a 1)")
    expectInvalidArgumentErrorFrom("(.assoc -5992 :a 1)")
    expectInvalidArgumentErrorFrom("(.assoc 0.0001 :a 1)")
    expectInvalidArgumentErrorFrom("(.assoc \"hello\" :a 1)")
    expectInvalidArgumentErrorFrom("(.assoc \\z :a 1)")
    expectInvalidArgumentErrorFrom("(.assoc :foobar :a 1)")
    expectInvalidArgumentErrorFrom("(.assoc 'foobar :a 1)")
    expectInvalidArgumentErrorFrom("(.assoc '(1 2 3) 0 :a)")
    expectInvalidArgumentErrorFrom("(.assoc #\"[0-9]+\" :a 1)")
    expectInvalidArgumentErrorFrom("(.assoc .assoc :a 1)")
  }

  /// .assoc should take a collection and at least one key-value pair, but reject keys without values.
  func testArity() {
    expectArityErrorFrom("(.assoc)")
    expectArityErrorFrom("(.assoc {})")
    expectArityErrorFrom("(.assoc {} :a)")
    expectArityErrorFrom("(.assoc {} :a 1 :b 2 :c)")
  }
}

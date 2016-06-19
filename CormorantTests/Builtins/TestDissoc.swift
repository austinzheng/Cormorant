//
//  TestDissoc.swift
//  Cormorant
//
//  Created by Austin Zheng on 2/15/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

// Test the '.dissoc' built-in function
class TestDissocBuiltin : InterpreterTest {

  /// .dissoc should, if called with one argument, return that argument verbatim.
  func testEchoingArg() {
    expectThat("(.dissoc nil)", shouldEvalTo: .nilValue)
    expectThat("(.dissoc 1529)", shouldEvalTo: 1529)
    expectThat("(.dissoc true)", shouldEvalTo: true)
    expectThat("(.dissoc \"foobar\")", shouldEvalTo: .string("foobar"))
    expectThat("(.dissoc '(1 2 3))", shouldEvalTo: list(containing: 1, 2, 3))
    expectThat("(.dissoc [1 2 3])", shouldEvalTo: vector(containing: 1, 2, 3))
    expectThat("(.dissoc {1 2 3 4})", shouldEvalTo: map(containing: (1, 2), (3, 4)))
  }

  /// .dissoc should return nil if called with keys on nil.
  func testWithNil() {
    expectThat("(.dissoc nil 0)", shouldEvalTo: .nilValue)
    expectThat("(.dissoc nil \"foo\" :bar 'baz)", shouldEvalTo: .nilValue)
  }

  /// .dissoc should remove keys from maps if called with valid keys.
  func testWithValidKeys() {
    expectThat("(.dissoc {1 \"one\" 2 \"two\" 3 \"three\"} 1)",
               shouldEvalTo: map(containing: (2, .string("two")), (3, .string("three"))))
    expectThat("(.dissoc {1 \"one\" 2 \"two\" 3 \"three\"} 2)",
               shouldEvalTo: map(containing: (1, .string("one")), (3, .string("three"))))
    expectThat("(.dissoc {1 \"one\" 2 \"two\" 3 \"three\"} 1 3)",
               shouldEvalTo: map(containing: (2, .string("two"))))
    expectThat("(.dissoc {1 \"one\" 2 \"two\" 3 \"three\"} 1 2 3)",
               shouldEvalTo: map())
  }

  /// .dissoc should function correctly if passed in duplicate keys.
  func testWithDuplicateKeys() {
    expectThat("(.dissoc {1 \"one\" 2 \"two\" 3 \"three\"} 1 1 1)",
               shouldEvalTo: map(containing: (2, .string("two")), (3, .string("three"))))
    expectThat("(.dissoc {1 \"one\" 2 \"two\" 3 \"three\"} 2 2)",
               shouldEvalTo: map(containing: (1, .string("one")), (3, .string("three"))))
    expectThat("(.dissoc {1 \"one\" 2 \"two\" 3 \"three\"} 1 3 3 3)",
               shouldEvalTo: map(containing: (2, .string("two"))))
    expectThat("(.dissoc {1 \"one\" 2 \"two\" 3 \"three\"} 1 2 3 3 1 2 3 1 1 3 2)",
               shouldEvalTo: map())
  }

  /// .dissoc should leave key-value pairs in maps if called with invalid keys.
  func testWithInvalidKeys() {
    expectThat("(.dissoc {1 \"one\" 2 \"two\" 3 \"three\"} 4)",
               shouldEvalTo: map(containing: (1, .string("one")), (2, .string("two")), (3, .string("three"))))
    expectThat("(.dissoc {1 \"one\" 2 \"two\" 3 \"three\"} \"1\" :2 \\3)",
               shouldEvalTo: map(containing: (1, .string("one")), (2, .string("two")), (3, .string("three"))))
    expectThat("(.dissoc {} nil)", shouldEvalTo: map())
  }

  /// .dissoc should properly remove keys when given both valid and invalid keys.
  func testWithValidAndInvalidKeys() {
    expectThat("(.dissoc {1 \"one\" 2 \"two\" 3 \"three\"} 1 4)",
               shouldEvalTo: map(containing: (2, .string("two")), (3, .string("three"))))
    expectThat("(.dissoc {1 \"one\" 2 \"two\" 3 \"three\"} 8 2 5)",
               shouldEvalTo: map(containing: (1, .string("one")), (3, .string("three"))))
    expectThat("(.dissoc {1 \"one\" 2 \"two\" 3 \"three\"} 9 10 1 5 3)",
               shouldEvalTo: map(containing: (2, .string("two"))))
    expectThat("(.dissoc {1 \"one\" 2 \"two\" 3 \"three\"} 12 1 2 3 12 18)",
               shouldEvalTo: map())
  }

  /// .dissoc should reject non-map arguments if called with at least one key.
  func testWithInvalidArgs() {
    expectInvalidArgumentErrorFrom("(.dissoc true 0)")
    expectInvalidArgumentErrorFrom("(.dissoc false 0)")
    expectInvalidArgumentErrorFrom("(.dissoc \"foobar\" 0)")
    expectInvalidArgumentErrorFrom("(.dissoc \\c 0)")
    expectInvalidArgumentErrorFrom("(.dissoc :c 0)")
    expectInvalidArgumentErrorFrom("(.dissoc 'c 0)")
    expectInvalidArgumentErrorFrom("(.dissoc #\"[0-9]+\" 0)")
    expectInvalidArgumentErrorFrom("(.dissoc [1 2 3 4 5] 0)")
    expectInvalidArgumentErrorFrom("(.dissoc '(1 2 3 4 5) 0)")
    expectInvalidArgumentErrorFrom("(.dissoc .dissoc 0)")
  }

  /// .dissoc should take at least one argument.
  func testArity() {
    expectArityErrorFrom("(.dissoc)")
  }
}

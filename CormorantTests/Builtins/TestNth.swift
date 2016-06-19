//
//  TestNth.swift
//  Cormorant
//
//  Created by Austin Zheng on 1/16/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestVectorNth : InterpreterTest {
  /// nth should return the proper item when called on a vector with an in-bounds index.
  func testValidIndex() {
    expectThat("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] 2)", shouldEvalTo: .string("baz"))
  }

  /// nth should fail with an out-of-bounds error when called on an empty vector.
  func testEmptyVector() {
    expectThat("(.nth [] 0)", shouldFailAs: .OutOfBoundsError)
  }

  /// nth should fail with an out-of-bounds error when called on a vector with a negative index.
  func testNegativeIndex() {
    expectThat("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] -1)", shouldFailAs: .OutOfBoundsError)
  }

  /// nth should fail with an out-of-bounds error when called on a vector with an out-of-bounds positive index.
  func testTooLargeIndex() {
    expectThat("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] 4)", shouldFailAs: .OutOfBoundsError)
  }

  /// nth should fail when called on a vector with an non-integer index.
  func testInvalidTypedIndex() {
    expectInvalidArgumentErrorFrom("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] [1 2 3])")
  }

  /// nth should return the proper item when called on a vector with an in-bounds index, even if there is a fallback.
  func testValidIndexWithFallback() {
    expectThat("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] 2 999)", shouldEvalTo: .string("baz"))
  }

  /// nth should return the fallback when called on a vector with a negative index.
  func testNegativeIndexWithFallback() {
    expectThat("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] -10 999)", shouldEvalTo: 999)
  }

  /// nth should return the fallback when called on a vector with an out-of-bounds positive index.
  func testTooLargeIndexWithFallback() {
    expectThat("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] 108 998)", shouldEvalTo: 998)
  }

  /// nth should fail when called on a vector with a non-integer index, even if there is a fallback.
  func testInvalidTypeOfIndexWithFallback() {
    expectInvalidArgumentErrorFrom("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] [1 2 3] nil)")
  }
}

class TestListNth : InterpreterTest {
  /// nth should return the proper item when called on a list with an in-bounds index.
  func testValidIndex() {
    expectThat("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") 2)", shouldEvalTo: .string("baz"))
  }

  /// nth should fail with an out-of-bounds error when called on an empty list.
  func testEmptyList() {
    expectThat("(.nth () 0)", shouldFailAs: .OutOfBoundsError)
  }

  /// nth should fail with an out-of-bounds error when called on a list with a negative index.
  func testNegativeIndex() {
    expectThat("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") -1)", shouldFailAs: .OutOfBoundsError)
  }

  /// nth should fail with an out-of-bounds error when called on a list with an out-of-bounds positive index.
  func testTooLargeIndex() {
    expectThat("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") 4)", shouldFailAs: .OutOfBoundsError)
  }

  /// nth should fail when called on a list with an non-integer index.
  func testInvalidTypedIndex() {
    expectInvalidArgumentErrorFrom("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") [1 2 3])")
  }

  /// nth should return the proper item when called on a list with an in-bounds index, even if there is a fallback.
  func testValidIndexWithFallback() {
    expectThat("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") 2 999)", shouldEvalTo: .string("baz"))
  }

  /// nth should return the fallback when called on a list with a negative index.
  func testNegativeIndexWithFallback() {
    expectThat("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") -10 997)", shouldEvalTo: 997)
  }

  /// nth should return the fallback when called on a list with an out-of-bounds positive index.
  func testTooLargeIndexWithFallback() {
    expectThat("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") 108 996)", shouldEvalTo: 996)
  }

  /// nth should fail when called on a list with a non-integer index, even if there is a fallback.
  func testInvalidTypeOfIndexWithFallback() {
    expectInvalidArgumentErrorFrom("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") [1 2 3] nil)")
  }
}

class TestStringNth : InterpreterTest {
  /// nth should return the proper item when called on a string with an in-bounds index.
  func testValidIndex() {
    expectThat("(.nth \"the quick brown fox\" 10)", shouldEvalTo: .char("b"))
  }

  /// nth should fail with an out-of-bounds error when called on an empty string.
  func testEmptyString() {
    expectThat("(.nth \"\" 0)", shouldFailAs: .OutOfBoundsError)
  }

  /// nth should fail with an out-of-bounds error when called on a string with a negative index.
  func testNegativeIndex() {
    expectThat("(.nth \"the quick brown fox\" -10)", shouldFailAs: .OutOfBoundsError)
  }

  /// nth should fail with an out-of-bounds error when called on a string with an out-of-bounds positive index.
  func testTooLargeIndex() {
    expectThat("(.nth \"the quick brown fox\" 500)", shouldFailAs: .OutOfBoundsError)
  }

  /// nth should fail when called on a string with an non-integer index.
  func testInvalidTypedIndex() {
    expectInvalidArgumentErrorFrom("(.nth \"the quick brown fox\" [1 2 3])")
  }

  /// nth should return the proper item when called on a string with an in-bounds index, even if there is a fallback.
  func testValidIndexWithFallback() {
    expectThat("(.nth \"the quick brown fox\" 2 999)", shouldEvalTo: .char("e"))
  }

  /// nth should return the fallback when called on a string with a negative index.
  func testNegativeIndexWithFallback() {
    expectThat("(.nth \"the quick brown fox\" -10 995)", shouldEvalTo: 995)
  }

  /// nth should return the fallback when called on a string with an out-of-bounds positive index.
  func testTooLargeIndexWithFallback() {
    expectThat("(.nth \"the quick brown fox\" 108 994)", shouldEvalTo: 994)
  }

  /// nth should fail when called on a string with a non-integer index, even if there is a fallback.
  func testInvalidTypeOfIndexWithFallback() {
    expectInvalidArgumentErrorFrom("(.nth \"the quick brown fox\" [1 2 3] nil)")
  }
}

class TestInvalidTypesNth : InterpreterTest {
  /// nth should fail if called with a hash map instead of a valid collection.
  func testMapArg() {
    expectInvalidArgumentErrorFrom("(.nth {\"one\" 1, \"two\" 2} 0)")
  }

  /// nth should fail if called with a character instead of a collection.
  func testCharArg() {
    expectInvalidArgumentErrorFrom("(.nth \\a 0)")
  }

  /// nth should fail if called with a symbol instead of a collection.
  func testSymbolArg() {
    expectInvalidArgumentErrorFrom("(.nth 'badarg 0)")
  }

  /// nth should fail if called with a keyword instead of a collection.
  func testKeywordArg() {
    expectInvalidArgumentErrorFrom("(.nth :badarg 0)")
  }

  /// nth should fail if called with an integer value instead of a collection.
  func testIntegerArg() {
    expectInvalidArgumentErrorFrom("(.nth 12345 0)")
  }

  /// nth should fail if called with a floating-point value instead of a collection.
  func testFloatingPointArg() {
    expectInvalidArgumentErrorFrom("(.nth 3.141592 0)")
  }
}

class TestNthArity : InterpreterTest {
  /// nth should fail if called with zero arguments.
  func testZeroArity() {
    expectArityErrorFrom("(.nth)")
  }

  /// nth should fail if called with only one argument.
  func testOneArity() {
    expectArityErrorFrom("(.nth [0 1 2])")
  }

  /// nth should fail if called with more than two arguments.
  func testThreeArity() {
    expectArityErrorFrom("(.nth [0 1 2] 0 \\a nil)")
  }
}

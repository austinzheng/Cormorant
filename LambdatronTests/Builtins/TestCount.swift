//
//  TestCount.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/23/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the '.count' built-in function.
class TestCountBuiltin : InterpreterTest {

  // .count should return 0 when passed nil.
  func testNil() {
    expectThat("(.count nil)", shouldEvalTo: 0)
  }

  // .count should return the length of a string.
  func testString() {
    expectThat("(.count \"\")", shouldEvalTo: 0)
    expectThat("(.count \"foobar\")", shouldEvalTo: 6)
    expectThat("(.count \"the quick brown fox JUMPS over THE lazy dog\")", shouldEvalTo: 43)
  }

  // .count should return the length of a list.
  func testList() {
    expectThat("(.count ())", shouldEvalTo: 0)
    expectThat("(.count '(:foo))", shouldEvalTo: 1)
    expectThat("(.count '(:foo 'bar [\"hello\" true] \\w \\o \\r \\l \\d 15 nil))", shouldEvalTo: 10)
  }

  // .count should return the length of a vector.
  func testVector() {
    expectThat("(.count [])", shouldEvalTo: 0)
    expectThat("(.count [:foo])", shouldEvalTo: 1)
    expectThat("(.count [:foo 'bar '(\"hello\" true) \\w \\o \\r \\l \\d 15 nil])", shouldEvalTo: 10)
  }

  // .count should return the length of a map.
  func testMap() {
    expectThat("(.count {})", shouldEvalTo: 0)
    expectThat("(.count {:foo \\f})", shouldEvalTo: 1)
    expectThat("(.count {:foo \\f 'bar 'bar true {:uno \"one\"} '(1 2 3) :baz 1999 nil})", shouldEvalTo: 5)
  }

  // .count should reject arguments that aren't nil, strings, or collections.
  func testInvalidArgument() {
    expectThat("(.count true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.count false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.count 152)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.count -0.02954)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.count \\c)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.count :c)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.count 'c)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.count #\"hello\")", shouldFailAs: .InvalidArgumentError)
  }

  // .count should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.count)")
    expectArityErrorFrom("(.count \"hello\" \"world\")")
  }
}

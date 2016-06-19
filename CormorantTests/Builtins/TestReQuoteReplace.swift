//
//  TestReQuoteReplace.swift
//  Cormorant
//
//  Created by Austin Zheng on 3/14/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the '.re-quote-replacement' built-in function.
class TestReQuoteReplacementBuiltin : InterpreterTest {

  /// .re-quote-replacement should turn strings into escaped pattern strings.
  func testQuotingTemplates() {
    expectThat("(.re-quote-replacement \"foobar\")", shouldEvalTo: .string("foobar"))
    expectThat("(.re-quote-replacement \"abc\\\\\")", shouldEvalTo: .string("abc\\\\"))
    expectThat("(.re-quote-replacement \"\\\\hello world\\n\")", shouldEvalTo: .string("\\\\hello world\n"))
  }

  /// .re-quote-replacement should reject non-string arguments.
  func testInvalidArguments() {
    expectInvalidArgumentErrorFrom("(.re-quote-replacement nil)")
    expectInvalidArgumentErrorFrom("(.re-quote-replacement true)")
    expectInvalidArgumentErrorFrom("(.re-quote-replacement false)")
    expectInvalidArgumentErrorFrom("(.re-quote-replacement 0)")
    expectInvalidArgumentErrorFrom("(.re-quote-replacement 1.000)")
    expectInvalidArgumentErrorFrom("(.re-quote-replacement #\"[0-9]+\")")
    expectInvalidArgumentErrorFrom("(.re-quote-replacement \\c)")
    expectInvalidArgumentErrorFrom("(.re-quote-replacement :foobar)")
    expectInvalidArgumentErrorFrom("(.re-quote-replacement 'foobar)")
    expectInvalidArgumentErrorFrom("(.re-quote-replacement '(1 2 3))")
    expectInvalidArgumentErrorFrom("(.re-quote-replacement [1 2 3])")
    expectInvalidArgumentErrorFrom("(.re-quote-replacement {:foo :bar})")
    expectInvalidArgumentErrorFrom("(.re-quote-replacement .re-quote-replacement)")
  }

  /// .re-quote-replacement should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.re-quote-replacement)")
    expectArityErrorFrom("(.re-quote-replacement \"abc\" \"def\")")
  }
}

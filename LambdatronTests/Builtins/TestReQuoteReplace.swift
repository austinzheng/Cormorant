//
//  TestReQuoteReplace.swift
//  Lambdatron
//
//  Created by Austin Zheng on 3/14/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the '.re-quote-replacement' built-in function.
class TestReQuoteReplacementBuiltin : InterpreterTest {

  /// .re-quote-replacement should turn strings into escaped pattern strings.
  func testQuotingTemplates() {
    expectThat("(.re-quote-replacement \"foobar\")", shouldEvalTo: .StringAtom("foobar"))
    expectThat("(.re-quote-replacement \"abc\\\\\")", shouldEvalTo: .StringAtom("abc\\\\"))
    expectThat("(.re-quote-replacement \"\\\\hello world\\n\")", shouldEvalTo: .StringAtom("\\\\hello world\n"))
  }

  /// .re-quote-replacement should reject non-string arguments.
  func testInvalidArguments() {
    expectThat("(.re-quote-replacement nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.re-quote-replacement true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.re-quote-replacement false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.re-quote-replacement 0)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.re-quote-replacement 1.000)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.re-quote-replacement #\"[0-9]+\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.re-quote-replacement \\c)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.re-quote-replacement :foobar)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.re-quote-replacement 'foobar)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.re-quote-replacement '(1 2 3))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.re-quote-replacement [1 2 3])", shouldFailAs: .InvalidArgumentError)
    expectThat("(.re-quote-replacement {:foo :bar})", shouldFailAs: .InvalidArgumentError)
    expectThat("(.re-quote-replacement .re-quote-replacement)", shouldFailAs: .InvalidArgumentError)
  }

  /// .re-quote-replacement should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.re-quote-replacement)")
    expectArityErrorFrom("(.re-quote-replacement \"abc\" \"def\")")
  }
}

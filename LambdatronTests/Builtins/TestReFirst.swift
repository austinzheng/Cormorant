//
//  TestReFirst.swift
//  Lambdatron
//
//  Created by Austin Zheng on 3/14/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the '.re-first' built-in function.
class TestReFirstBuiltin : InterpreterTest {

  /// .re-first should work with literal patterns containing no regex logic.
  func testLiteralPattern() {
    expectThat("(.re-first #\"ee\" \"meela\")", shouldEvalTo: .StringAtom("ee"))
    expectThat("(.re-first #\"ee\" \"jyaku\")", shouldEvalTo: .Nil)
    expectThat("(.re-first #\"s\" \"mississippi\")", shouldEvalTo: .StringAtom("s"))
    expectThat("(.re-first #\"s\" \"indiana\")", shouldEvalTo: .Nil)
  }

  /// .re-first should work with patterns containing regex logic.
  func testAdvancedPattern() {
    expectThat("(.re-first #\"\\d\\d\" \"a12b34c56\")", shouldEvalTo: .StringAtom("12"))
    expectThat("(.re-first #\"\\d*\" \"foobar\")", shouldEvalTo: .StringAtom(""))
    expectThat("(.re-first #\"\\d+\" \"foobar\")", shouldEvalTo: .Nil)
    expectThat("(.re-first #\"[a-z]+\" \"3.1415nine2six5three\")", shouldEvalTo: .StringAtom("nine"))
    expectThat("(.re-first #\"[a-z]+\" \"3.141592653\")", shouldEvalTo: .Nil)
  }

  /// .re-first should work with patterns defining capture groups.
  func testCaptureGroupsPattern() {
    expectThat("(.re-first #\"\\d(\\d)\" \"a12b34c56\")",
      shouldEvalTo: vectorWithItems(.StringAtom("12"), .StringAtom("2")))
    expectThat("(.re-first #\"(\\d*)\" \"foobar\")",
      shouldEvalTo: vectorWithItems(.StringAtom(""), .StringAtom("")))
    expectThat("(.re-first #\"(\\d+)\" \"foobar\")", shouldEvalTo: .Nil)
    expectThat("(.re-first #\"([a-z]+)\" \"3.1415nine2six5three\")",
      shouldEvalTo: vectorWithItems(.StringAtom("nine"), .StringAtom("nine")))
    expectThat("(.re-first #\"th([a-z]+)\" \"3.1415nine2six5three\")",
      shouldEvalTo: vectorWithItems(.StringAtom("three"), .StringAtom("ree")))
  }

  /// .re-first should reject pattern arguments that aren't regex patterns.
  func testInvalidPatterns() {
    expectInvalidArgumentErrorFrom("(.re-first nil \"foobar\")")
    expectInvalidArgumentErrorFrom("(.re-first 152 \"foobar\")")
    expectInvalidArgumentErrorFrom("(.re-first true \"foobar\")")
    expectInvalidArgumentErrorFrom("(.re-first false \"foobar\")")
    expectInvalidArgumentErrorFrom("(.re-first \\a \"foobar\")")
    expectInvalidArgumentErrorFrom("(.re-first :a \"foobar\")")
    expectInvalidArgumentErrorFrom("(.re-first 'a \"foobar\")")
    expectInvalidArgumentErrorFrom("(.re-first \"foo\" \"foobar\")")
    expectInvalidArgumentErrorFrom("(.re-first [#\"foo\" #\"bar\"] \"foobar\")")
    expectInvalidArgumentErrorFrom("(.re-first .re-first \"foobar\")")
  }

  /// .re-first should reject string arguments that aren't strings.
  func testInvalidStrings() {
    expectInvalidArgumentErrorFrom("(.re-first #\"\\d+\" nil)")
    expectInvalidArgumentErrorFrom("(.re-first #\"\\d+\" true)")
    expectInvalidArgumentErrorFrom("(.re-first #\"\\d+\" false)")
    expectInvalidArgumentErrorFrom("(.re-first #\"\\d+\" 592)")
    expectInvalidArgumentErrorFrom("(.re-first #\"\\d+\" -0.92871)")
    expectInvalidArgumentErrorFrom("(.re-first #\"\\d+\" \\h)")
    expectInvalidArgumentErrorFrom("(.re-first #\"\\d+\" :foo5092bar)")
    expectInvalidArgumentErrorFrom("(.re-first #\"\\d+\" 'foo68172bar)")
    expectInvalidArgumentErrorFrom("(.re-first #\"\\d+\" #\"124f52oobar\")")
    expectInvalidArgumentErrorFrom("(.re-first #\"\\d+\" '())")
    expectInvalidArgumentErrorFrom("(.re-first #\"\\d+\" [])")
    expectInvalidArgumentErrorFrom("(.re-first #\"\\d+\" {})")
    expectInvalidArgumentErrorFrom("(.re-first #\"\\d+\" .re-first)")
  }

  /// .re-first should take exactly two arguments.
  func testArity() {
    expectArityErrorFrom("(.re-first #\"ee\")")
    expectArityErrorFrom("(.re-first #\"ee\" \"meela\" \"jyaku\")")
  }
}

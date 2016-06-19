//
//  TestCaseChange.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/23/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the '.upper-case' built-in function.
class TestUppercaseBuiltin : InterpreterTest {

  /// .upper-case should turn strings uppercase.
  func testStrings() {
    expectThat("(.upper-case \"\")", shouldEvalTo: .string(""))
    expectThat("(.upper-case \"foobar baz\")", shouldEvalTo: .string("FOOBAR BAZ"))
    expectThat("(.upper-case \"foObAr bAz\")", shouldEvalTo: .string("FOOBAR BAZ"))
    expectThat("(.upper-case \"FOOBAR BAZ\")", shouldEvalTo: .string("FOOBAR BAZ"))
    expectThat("(.upper-case \"$!(@*c#)\\\\a\")", shouldEvalTo: .string("$!(@*C#)\\A"))
  }

  /// .upper-case should implicitly convert argument and turn resulting string uppercase.
  func testNonStrings() {
    expectThat("(.upper-case :foObAr)", shouldEvalTo: .string(":FOOBAR"))
    expectThat("(.upper-case 'FoobaR)", shouldEvalTo: .string("FOOBAR"))
    expectThat("(.upper-case \\a)", shouldEvalTo: .string("A"))
    expectThat("(.upper-case #\"[a-z]\")", shouldEvalTo: .string("[A-Z]"))
  }

  /// .upper-case should take exactly one argument
  func testArity() {
    expectArityErrorFrom("(.upper-case \"hello\" \"world\")")
  }
}

/// Test the '.lower-case' built-in function.
class TestLowercaseBuiltin : InterpreterTest {

  /// .lower-case should turn strings lowercase.
  func testStrings() {
    expectThat("(.lower-case \"\")", shouldEvalTo: .string(""))
    expectThat("(.lower-case \"foobar baz\")", shouldEvalTo: .string("foobar baz"))
    expectThat("(.lower-case \"foObAr bAz\")", shouldEvalTo: .string("foobar baz"))
    expectThat("(.lower-case \"FOOBAR BAZ\")", shouldEvalTo: .string("foobar baz"))
    expectThat("(.lower-case \"$!(@*C#)\\\\A\")", shouldEvalTo: .string("$!(@*c#)\\a"))
  }

  /// .lower-case should implicitly convert argument and turn resulting string lowercase.
  func testNonStrings() {
    expectThat("(.lower-case :foObAr)", shouldEvalTo: .string(":foobar"))
    expectThat("(.lower-case 'FoobaR)", shouldEvalTo: .string("foobar"))
    expectThat("(.lower-case \\Q)", shouldEvalTo: .string("q"))
    expectThat("(.lower-case #\"[A-Z]\")", shouldEvalTo: .string("[a-z]"))
  }

  /// .lower-case should take exactly one argument
  func testArity() {
    expectArityErrorFrom("(.lower-case \"hello\" \"world\")")
  }
}

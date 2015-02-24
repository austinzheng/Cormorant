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
    expectThat("(.upper-case \"\")", shouldEvalTo: .StringAtom(""))
    expectThat("(.upper-case \"foobar baz\")", shouldEvalTo: .StringAtom("FOOBAR BAZ"))
    expectThat("(.upper-case \"foObAr bAz\")", shouldEvalTo: .StringAtom("FOOBAR BAZ"))
    expectThat("(.upper-case \"FOOBAR BAZ\")", shouldEvalTo: .StringAtom("FOOBAR BAZ"))
    expectThat("(.upper-case \"$!(@*c#)\\\\a\")", shouldEvalTo: .StringAtom("$!(@*C#)\\A"))
  }

  /// .upper-case should implicitly convert argument and turn resulting string uppercase.
  func testNonStrings() {
    expectThat("(.upper-case :foObAr)", shouldEvalTo: .StringAtom(":FOOBAR"))
    expectThat("(.upper-case 'FoobaR)", shouldEvalTo: .StringAtom("FOOBAR"))
    expectThat("(.upper-case \\a)", shouldEvalTo: .StringAtom("A"))
    expectThat("(.upper-case #\"[a-z]\")", shouldEvalTo: .StringAtom("[A-Z]"))
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
    expectThat("(.lower-case \"\")", shouldEvalTo: .StringAtom(""))
    expectThat("(.lower-case \"foobar baz\")", shouldEvalTo: .StringAtom("foobar baz"))
    expectThat("(.lower-case \"foObAr bAz\")", shouldEvalTo: .StringAtom("foobar baz"))
    expectThat("(.lower-case \"FOOBAR BAZ\")", shouldEvalTo: .StringAtom("foobar baz"))
    expectThat("(.lower-case \"$!(@*C#)\\\\A\")", shouldEvalTo: .StringAtom("$!(@*c#)\\a"))
  }

  /// .lower-case should implicitly convert argument and turn resulting string lowercase.
  func testNonStrings() {
    expectThat("(.lower-case :foObAr)", shouldEvalTo: .StringAtom(":foobar"))
    expectThat("(.lower-case 'FoobaR)", shouldEvalTo: .StringAtom("foobar"))
    expectThat("(.lower-case \\Q)", shouldEvalTo: .StringAtom("q"))
    expectThat("(.lower-case #\"[A-Z]\")", shouldEvalTo: .StringAtom("[a-z]"))
  }

  /// .lower-case should take exactly one argument
  func testArity() {
    expectArityErrorFrom("(.lower-case \"hello\" \"world\")")
  }
}

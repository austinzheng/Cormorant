//
//  TestComparisons.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/15/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the '.==' built-in function.
class testNumericEqualsBuiltin : InterpreterTest {

  /// .== should properly compare two integers.
  func testInts() {
    expectThat("(.== 0 0)", shouldEvalTo: true)
    expectThat("(.== 15 15)", shouldEvalTo: true)
    expectThat("(.== -659 -659)", shouldEvalTo: true)
    expectThat("(.== 15 -15)", shouldEvalTo: false)
    expectThat("(.== 10 11)", shouldEvalTo: false)
  }

  /// .== should properly compare two floating-point values.
  func testFloats() {
    expectThat("(.== 0.0 0.0)", shouldEvalTo: true)
    expectThat("(.== 0.1929395 0.1929395)", shouldEvalTo: true)
    expectThat("(.== -6099701.2 -6099701.2)", shouldEvalTo: true)
    expectThat("(.== 1.1115 -1.1115)", shouldEvalTo: false)
    expectThat("(.== 7.0 7.0000000001)", shouldEvalTo: false)
  }

  /// .== should properly compare integers against floating-point values.
  func testMixed() {
    expectThat("(.== 0.0 0)", shouldEvalTo: true)
    expectThat("(.== 15 15.0)", shouldEvalTo: true)
    expectThat("(.== -65.000 -65)", shouldEvalTo: true)
    expectThat("(.== -612.23 612)", shouldEvalTo: false)
    expectThat("(.== 88 88.0001)", shouldEvalTo: false)
  }

  /// .== should reject non-numeric arguments.
  func testNonNumeric() {
    expectThat("(.== 0 \\0)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.== 0 \"0\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.== 0 :0)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.== 0 nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.== 0 true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.== 0 false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.== 0 #\"[0]\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.== 0 '(0))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.== 0 [0])", shouldFailAs: .InvalidArgumentError)
  }

  /// .== should take exactly two arguments.
  func testArity() {
    expectArityErrorFrom("(.==)")
    expectArityErrorFrom("(.== 1)")
    expectArityErrorFrom("(.== 1 1 1)")
  }
}

/// Test the '.<' built-in function.
class testLtBuiltin : InterpreterTest {

  /// .< should properly compare two integers.
  func testInts() {
    expectThat("(.< 5 6)", shouldEvalTo: true)
    expectThat("(.< 6 5)", shouldEvalTo: false)
    expectThat("(.< -10 1)", shouldEvalTo: true)
    expectThat("(.< -12 -11)", shouldEvalTo: true)
    expectThat("(.< 10 10)", shouldEvalTo: false)
  }

  /// .< should properly compare two floating-point values.
  func testFloats() {
    expectThat("(.< 5.0 6.98)", shouldEvalTo: true)
    expectThat("(.< 6.000001 5.99999)", shouldEvalTo: false)
    expectThat("(.< -123069.2 0.0023)", shouldEvalTo: true)
    expectThat("(.< -7991.2 -7814.1)", shouldEvalTo: true)
    expectThat("(.< 10.0 10.0)", shouldEvalTo: false)
  }

  /// .< should properly compare integers against floating-point values.
  func testMixed() {
    expectThat("(.< 5.0 6)", shouldEvalTo: true)
    expectThat("(.< 6 5.0)", shouldEvalTo: false)
    expectThat("(.< -10 1.1234)", shouldEvalTo: true)
    expectThat("(.< -12.105 -11.0091)", shouldEvalTo: true)
    expectThat("(.< 199.0 199)", shouldEvalTo: false)
  }

  /// .< should reject non-numeric arguments.
  func testNonNumeric() {
    expectThat("(.< 0 \\0)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.< 0 \"0\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.< 0 :0)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.< 0 nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.< 0 true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.< 0 false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.< 0 #\"[0]\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.< 0 '(0))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.< 0 [0])", shouldFailAs: .InvalidArgumentError)
  }

  /// .< should take exactly two arguments.
  func testArity() {
    expectArityErrorFrom("(.<)")
    expectArityErrorFrom("(.< 1)")
    expectArityErrorFrom("(.< 1 1 1)")
  }
}

/// Test the '.<=' built-in function.
class testLteqBuiltin : InterpreterTest {

  /// .<= should properly compare two integers.
  func testInts() {
    expectThat("(.<= 5 6)", shouldEvalTo: true)
    expectThat("(.<= 6 5)", shouldEvalTo: false)
    expectThat("(.<= -10 1)", shouldEvalTo: true)
    expectThat("(.<= -12 -11)", shouldEvalTo: true)
    expectThat("(.<= 10 10)", shouldEvalTo: true)
  }

  /// .<= should properly compare two floating-point values.
  func testFloats() {
    expectThat("(.<= 5.0 6.98)", shouldEvalTo: true)
    expectThat("(.<= 6.000001 5.99999)", shouldEvalTo: false)
    expectThat("(.<= -123069.2 0.0023)", shouldEvalTo: true)
    expectThat("(.<= -7991.2 -7814.1)", shouldEvalTo: true)
    expectThat("(.<= 10.0 10.0)", shouldEvalTo: true)
  }

  /// .<= should properly compare integers against floating-point values.
  func testMixed() {
    expectThat("(.<= 5.0 6)", shouldEvalTo: true)
    expectThat("(.<= 6 5.0)", shouldEvalTo: false)
    expectThat("(.<= -10 1.1234)", shouldEvalTo: true)
    expectThat("(.<= -12.105 -11.0091)", shouldEvalTo: true)
    expectThat("(.<= 199.0 199)", shouldEvalTo: true)
  }

  /// .<= should reject non-numeric arguments.
  func testNonNumeric() {
    expectThat("(.<= 0 \\0)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.<= 0 \"0\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.<= 0 :0)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.<= 0 nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.<= 0 true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.<= 0 false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.<= 0 #\"[0]\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.<= 0 '(0))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.<= 0 [0])", shouldFailAs: .InvalidArgumentError)
  }

  /// .<= should take exactly two arguments.
  func testArity() {
    expectArityErrorFrom("(.<=)")
    expectArityErrorFrom("(.<= 1)")
    expectArityErrorFrom("(.<= 1 1 1)")
  }
}

/// Test the '.>' built-in function.
class testGtBuiltin : InterpreterTest {

  /// .> should properly compare two integers.
  func testInts() {
    expectThat("(.> 10 6)", shouldEvalTo: true)
    expectThat("(.> 6 10)", shouldEvalTo: false)
    expectThat("(.> -956 -1002)", shouldEvalTo: true)
    expectThat("(.> -23 99182)", shouldEvalTo: false)
    expectThat("(.> -4 -4)", shouldEvalTo: false)
  }

  /// .> should properly compare two floating-point values.
  func testFloats() {
    expectThat("(.> 10.152 6.008)", shouldEvalTo: true)
    expectThat("(.> 6.008 10.152)", shouldEvalTo: false)
    expectThat("(.> -0.599297 -0.599298)", shouldEvalTo: true)
    expectThat("(.> -69981823.60901 1892773.29)", shouldEvalTo: false)
    expectThat("(.> -4.0 -4.0)", shouldEvalTo: false)
  }

  /// .> should properly compare integers against floating-point values.
  func testMixed() {
    expectThat("(.> 10.0 6)", shouldEvalTo: true)
    expectThat("(.> 6 10.0)", shouldEvalTo: false)
    expectThat("(.> 12 9.827)", shouldEvalTo: true)
    expectThat("(.> -69.552 -12)", shouldEvalTo: false)
    expectThat("(.> -4 -4.0)", shouldEvalTo: false)
  }

  /// .> should reject non-numeric arguments.
  func testNonNumeric() {
    expectThat("(.> 0 \\0)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.> 0 \"0\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.> 0 :0)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.> 0 nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.> 0 true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.> 0 false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.> 0 #\"[0]\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.> 0 '(0))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.> 0 [0])", shouldFailAs: .InvalidArgumentError)
  }

  /// .> should take exactly two arguments.
  func testArity() {
    expectArityErrorFrom("(.>)")
    expectArityErrorFrom("(.> 1)")
    expectArityErrorFrom("(.> 1 1 1)")
  }
}

/// Test the '.>=' built-in function.
class testGteqBuiltin : InterpreterTest {

  /// .>= should properly compare two integers.
  func testInts() {
    expectThat("(.>= 10 6)", shouldEvalTo: true)
    expectThat("(.>= 6 10)", shouldEvalTo: false)
    expectThat("(.>= -956 -1002)", shouldEvalTo: true)
    expectThat("(.>= -23 99182)", shouldEvalTo: false)
    expectThat("(.>= -4 -4)", shouldEvalTo: true)
  }

  /// .>= should properly compare two floating-point values.
  func testFloats() {
    expectThat("(.>= 10.152 6.008)", shouldEvalTo: true)
    expectThat("(.>= 6.008 10.152)", shouldEvalTo: false)
    expectThat("(.>= -0.599297 -0.599298)", shouldEvalTo: true)
    expectThat("(.>= -69981823.60901 1892773.29)", shouldEvalTo: false)
    expectThat("(.>= -4.0 -4.0)", shouldEvalTo: true)
  }

  /// .>= should properly compare integers against floating-point values.
  func testMixed() {
    expectThat("(.>= 10.0 6)", shouldEvalTo: true)
    expectThat("(.>= 6 10.0)", shouldEvalTo: false)
    expectThat("(.>= 12 9.827)", shouldEvalTo: true)
    expectThat("(.>= -69.552 -12)", shouldEvalTo: false)
    expectThat("(.>= -4 -4.0)", shouldEvalTo: true)
  }

  /// .>= should reject non-numeric arguments.
  func testNonNumeric() {
    expectThat("(.>= 0 \\0)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.>= 0 \"0\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.>= 0 :0)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.>= 0 nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.>= 0 true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.>= 0 false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.>= 0 #\"[0]\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.>= 0 '(0))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.>= 0 [0])", shouldFailAs: .InvalidArgumentError)
  }

  /// .>= should take exactly two arguments.
  func testArity() {
    expectArityErrorFrom("(.>=)")
    expectArityErrorFrom("(.>= 1)")
    expectArityErrorFrom("(.>= 1 1 1)")
  }
}

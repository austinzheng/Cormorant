//
//  TestEquals.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/8/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the '.=' built-in function.
class TestEqualsBuiltin : InterpreterTest {

  /// .= should properly compare nil to nil.
  func testWithNil() {
    expectThat("(.= nil nil)", shouldEvalTo: true)
  }

  /// .= should not return true if nil is compared to a 'falsy' value (e.g. 0, false, "")
  func testWithNilAndFalsy() {
    expectThat("(.= nil false)", shouldEvalTo: false)
    expectThat("(.= nil 0)", shouldEvalTo: false)
    expectThat("(.= nil \"\")", shouldEvalTo: false)
    expectThat("(.= nil ())", shouldEvalTo: false)
    expectThat("(.= nil [])", shouldEvalTo: false)
    expectThat("(.= nil {})", shouldEvalTo: false)
  }

  /// .= should properly compare booleans.
  func testWithBooleans() {
    expectThat("(.= false false)", shouldEvalTo: true)
    expectThat("(.= true true)", shouldEvalTo: true)
    expectThat("(.= true false)", shouldEvalTo: false)
    expectThat("(.= false true)", shouldEvalTo: false)
  }

  /// .= should properly compare integers.
  func testWithIntegers() {
    expectThat("(.= 0 0)", shouldEvalTo: true)
    expectThat("(.= 1523 1523)", shouldEvalTo: true)
    expectThat("(.= -28 28)", shouldEvalTo: false)
  }

  /// .= should properly compare floating-point numbers.
  func testWithFloats() {
    expectThat("(.= 0.0 0.0)", shouldEvalTo: true)
    expectThat("(.= -0.00000001928 -0.00000001928)", shouldEvalTo: true)
    expectThat("(.= 18872.0096991 18872.0096992)", shouldEvalTo: false)
  }

  /// .= should return false if numbers of different types are compared against each other.
  func testDifferentNumberTypes() {
    expectThat("(.= 0 0.000000)", shouldEvalTo: false)
    expectThat("(.= 1.0000 1)", shouldEvalTo: false)
    expectThat("(.= -52316 -52316.0)", shouldEvalTo: false)
  }

  /// .= should properly compare characters.
  func testWithChararcters() {
    expectThat("(.= \\a \\a)", shouldEvalTo: true)
    expectThat("(.= \\backspace \\backspace)", shouldEvalTo: true)
    expectThat("(.= \\newline \\newline)", shouldEvalTo: true)
    expectThat("(.= \\return \\return)", shouldEvalTo: true)
    expectThat("(.= \\tab \\tab)", shouldEvalTo: true)
    expectThat("(.= \\space \\space)", shouldEvalTo: true)
    expectThat("(.= \\a \\z)", shouldEvalTo: false)
    expectThat("(.= \\newline \\n)", shouldEvalTo: false)
  }

  /// .= should properly compare symbols.
  func testWithSymbols() {
    expectThat("(.= 'foo 'foo)", shouldEvalTo: true)
    expectThat("(.= 'bar 'baz)", shouldEvalTo: false)
  }

  /// .= should properly compare keywords.
  func testWithKeywords() {
    expectThat("(.= :and :and)", shouldEvalTo: true)
    expectThat("(.= :then :else)", shouldEvalTo: false)
  }

  /// .= should properly compare strings.
  func testWithStrings() {
    expectThat("(.= \"\" \"\")", shouldEvalTo: true)
    expectThat("(.= \"hello world\" \"hello world\")", shouldEvalTo: true)
    expectThat("(.= \"hello world\" \"hello worl\")", shouldEvalTo: false)
    expectThat("(.= \"quick brown fox\" \"lazy dog\")", shouldEvalTo: false)
  }

  /// .= should return false if strings are compared against numbers or character lists or arrays.
  func testBadStringComparisons() {
    expectThat("(.= \"abcd\" '(\\a \\b \\c \\d))", shouldEvalTo: false)
    expectThat("(.= \"abcd\" [\\a \\b \\c \\d])", shouldEvalTo: false)
    expectThat("(.= \"1523\" 1523)", shouldEvalTo: false)
  }

  /// .= should return false if characters, numbers, symbols, or keywords are compared against each other.
  func testMismatchedAtomTypes() {
    expectThat("(.= \\a 97)", shouldEvalTo: false)
    expectThat("(.= \\b :b)", shouldEvalTo: false)
    expectThat("(.= 'foo :foo)", shouldEvalTo: false)
    expectThat("(.= :bar 'bar)", shouldEvalTo: false)
    expectThat("(.= \\z 'z)", shouldEvalTo: false)
    expectThat("(.= :456 456)", shouldEvalTo: false)
    expectThat("(.= 456 :456)", shouldEvalTo: false)
  }

  /// .= should properly compare lists.
  func testWithLists() {
    expectThat("(.= () ())", shouldEvalTo: true)
    expectThat("(.= '(1 2 \"three\" :four \\5 six) '(1 2 \"three\" :four \\5 six))", shouldEvalTo: true)
    expectThat("(.= '(1 2 (3 (4 4 4) 4) [5 6] {7 8 9 10} 11 12) '(1 2 (3 (4 4 4) 4) [5 6] {7 8 9 10} 11 12))",
      shouldEvalTo: true)
    expectThat("(.= '(1 1 (3 4) [5 6] {7 8 9 10} 11 12) '(1 2 (3 4) [5 6] {7 8 9 10} 11 12))",
      shouldEvalTo: false)
    expectThat("(.= '(true true true) '(true true))", shouldEvalTo: false)
    expectThat("(.= '(12 \"foobar\") '(99 98 97))", shouldEvalTo: false)
  }

  /// .= should properly compare vectors.
  func testWithVectors() {
    expectThat("(.= [] [])", shouldEvalTo: true)
    expectThat("(.= [1 2 \"three\" :four \\5 'six] [1 2 \"three\" :four \\5 'six])", shouldEvalTo: true)
    expectThat("(.= [1 2 [3 [4 4 4] 4] '(5 6) {7 8 9 10} 11 12] [1 2 [3 [4 4 4] 4] '(5 6) {7 8 9 10} 11 12])",
      shouldEvalTo: true)
    expectThat("(.= [1 1 '(3 4) [5 6] {7 8 9 10} 11 12] [1 2 '(3 4) [5 6] {7 8 9 10} 11 12])", shouldEvalTo: false)
    expectThat("(.= [true true true] [true true])", shouldEvalTo: false)
    expectThat("(.= [12 \"foobar\"] [99 98 97])", shouldEvalTo: false)
  }

  /// .= should properly compare maps.
  func testWithMaps() {
    expectThat("(.= {} {})", shouldEvalTo: true)
    expectThat("(.= {:a 1 :b 2} {:b 2 :a 1})", shouldEvalTo: true)
    expectThat("(.= {1 \"2\" {3 {4 true}} :value '(5 6) 7} {1 \"2\" {3 {4 true}} :value '(5 6) 7})",
      shouldEvalTo: true)
    expectThat("(.= {\"foo\" \"bar\" {:a :b} 'c} {\"foo\" nil {:a :b} 'c})", shouldEvalTo: false)
    expectThat("(.= {\"foo\" \"bar\" {:a :b} 'c} {\"fooo\" \"bar\" {:a :b} 'c})", shouldEvalTo: false)
    expectThat("(.= {:a 1 :b 2} {:a 1})", shouldEvalTo: false)
  }

  /// .= should properly compare built-in functions.
  func testWithBuiltInFns() {
    expectThat("(.= .= .=)", shouldEvalTo: true)
    expectThat("(.= .= .+)", shouldEvalTo: false)
    expectThat("(.= .- ./)", shouldEvalTo: false)
  }

  /// .= should take exactly two arguments.
  func testArity() {
    expectArityErrorFrom("(.= nil)")
    expectArityErrorFrom("(.= nil nil nil)")
  }
}

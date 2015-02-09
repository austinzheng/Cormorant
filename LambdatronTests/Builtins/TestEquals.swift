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
    expectThat("(.= nil nil)", shouldEvalTo: .BoolAtom(true))
  }

  /// .= should not return true if nil is compared to a 'falsy' value (e.g. 0, false, "")
  func testWithNilAndFalsy() {
    expectThat("(.= nil false)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= nil 0)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= nil \"\")", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= nil ())", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= nil [])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= nil {})", shouldEvalTo: .BoolAtom(false))
  }

  /// .= should properly compare booleans.
  func testWithBooleans() {
    expectThat("(.= false false)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= true true)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= true false)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= false true)", shouldEvalTo: .BoolAtom(false))
  }

  /// .= should properly compare integers.
  func testWithIntegers() {
    expectThat("(.= 0 0)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= 1523 1523)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= -28 28)", shouldEvalTo: .BoolAtom(false))
  }

  /// .= should properly compare floating-point numbers.
  func testWithFloats() {
    expectThat("(.= 0.0 0.0)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= -0.00000001928 -0.00000001928)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= 18872.0096991 18872.0096992)", shouldEvalTo: .BoolAtom(false))
  }

  /// .= should return false if numbers of different types are compared against each other.
  func testDifferentNumberTypes() {
    expectThat("(.= 0 0.000000)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= 1.0000 1)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= -52316 -52316.0)", shouldEvalTo: .BoolAtom(false))
  }

  /// .= should properly compare characters.
  func testWithChararcters() {
    expectThat("(.= \\a \\a)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= \\backspace \\backspace)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= \\newline \\newline)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= \\return \\return)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= \\tab \\tab)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= \\space \\space)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= \\a \\z)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= \\newline \\n)", shouldEvalTo: .BoolAtom(false))
  }

  /// .= should properly compare symbols.
  func testWithSymbols() {
    expectThat("(.= 'foo 'foo)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= 'bar 'baz)", shouldEvalTo: .BoolAtom(false))
  }

  /// .= should properly compare keywords.
  func testWithKeywords() {
    expectThat("(.= :and :and)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= :then :else)", shouldEvalTo: .BoolAtom(false))
  }

  /// .= should properly compare strings.
  func testWithStrings() {
    expectThat("(.= \"\" \"\")", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= \"hello world\" \"hello world\")", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= \"hello world\" \"hello worl\")", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= \"quick brown fox\" \"lazy dog\")", shouldEvalTo: .BoolAtom(false))
  }

  /// .= should return false if strings are compared against numbers or character lists or arrays.
  func testBadStringComparisons() {
    expectThat("(.= \"abcd\" '(\\a \\b \\c \\d))", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= \"abcd\" [\\a \\b \\c \\d])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= \"1523\" 1523)", shouldEvalTo: .BoolAtom(false))
  }

  /// .= should return false if characters, numbers, symbols, or keywords are compared against each other.
  func testMismatchedAtomTypes() {
    expectThat("(.= \\a 97)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= \\b :b)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= 'foo :foo)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= :bar 'bar)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= \\z 'z)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= :456 456)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= 456 :456)", shouldEvalTo: .BoolAtom(false))
  }

  /// .= should properly compare lists.
  func testWithLists() {
    expectThat("(.= () ())", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= '(1 2 \"three\" :four \\5 six) '(1 2 \"three\" :four \\5 six))", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= '(1 2 (3 (4 4 4) 4) [5 6] {7 8 9 10} 11 12) '(1 2 (3 (4 4 4) 4) [5 6] {7 8 9 10} 11 12))",
      shouldEvalTo: .BoolAtom(true))
    expectThat("(.= '(1 1 (3 4) [5 6] {7 8 9 10} 11 12) '(1 2 (3 4) [5 6] {7 8 9 10} 11 12))",
      shouldEvalTo: .BoolAtom(false))
    expectThat("(.= '(true true true) '(true true))", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= '(12 \"foobar\") '(99 98 97))", shouldEvalTo: .BoolAtom(false))
  }

  /// .= should properly compare vectors.
  func testWithVectors() {
    expectThat("(.= [] [])", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= [1 2 \"three\" :four \\5 'six] [1 2 \"three\" :four \\5 'six])", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= [1 2 [3 [4 4 4] 4] '(5 6) {7 8 9 10} 11 12] [1 2 [3 [4 4 4] 4] '(5 6) {7 8 9 10} 11 12])",
      shouldEvalTo: .BoolAtom(true))
    expectThat("(.= [1 1 '(3 4) [5 6] {7 8 9 10} 11 12] [1 2 '(3 4) [5 6] {7 8 9 10} 11 12])",
      shouldEvalTo: .BoolAtom(false))
    expectThat("(.= [true true true] [true true])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= [12 \"foobar\"] [99 98 97])", shouldEvalTo: .BoolAtom(false))
  }

  /// .= should properly compare maps.
  func testWithMaps() {
    expectThat("(.= {} {})", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= {:a 1 :b 2} {:b 2 :a 1})", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= {1 \"2\" {3 {4 true}} :value '(5 6) 7} {1 \"2\" {3 {4 true}} :value '(5 6) 7})",
      shouldEvalTo: .BoolAtom(true))
    expectThat("(.= {\"foo\" \"bar\" {:a :b} 'c} {\"foo\" nil {:a :b} 'c})", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= {\"foo\" \"bar\" {:a :b} 'c} {\"fooo\" \"bar\" {:a :b} 'c})", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= {:a 1 :b 2} {:a 1})", shouldEvalTo: .BoolAtom(false))
  }

  /// .= should properly compare built-in functions.
  func testWithBuiltInFns() {
    expectThat("(.= .= .=)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.= .= .+)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.= .- ./)", shouldEvalTo: .BoolAtom(false))
  }

  /// .= should take exactly two arguments.
  func testArity() {
    expectArityErrorFrom("(.= nil)")
    expectArityErrorFrom("(.= nil nil nil)")
  }
}

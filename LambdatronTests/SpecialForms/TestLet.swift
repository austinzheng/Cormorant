//
//  TestLet.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/27/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the 'let' special form.
class TestLet : InterpreterTest {

  /// let should accept an empty binding vector.
  func testEmptyBindingVector() {
    expectThat("(let [] 155)", shouldEvalTo: 155)
  }

  /// let should return nil if it has no constituent forms.
  func testNoForms() {
    expectThat("(let [a 10])", shouldEvalTo: .Nil)
  }

  /// let should not accept a binding vector with an odd number of arguments.
  func testOddArgumentsBindingVector() {
    expectThat("(let [a] 10)", shouldFailAs: .BindingMismatchError)
    expectThat("(let [a 10 b] 10)", shouldFailAs: .BindingMismatchError)
  }

  /// let should not accept a binding vector with a non-symbol in an even-indexed slot.
  func testNonSymbolBinding() {
    expectInvalidArgumentErrorFrom("(let [1234 10] nil)")
    expectInvalidArgumentErrorFrom("(let [\\c 10] nil)")
    expectInvalidArgumentErrorFrom("(let [:foobar 10] nil)")
    expectInvalidArgumentErrorFrom("(let [\"hello\" 10] nil)")
    expectInvalidArgumentErrorFrom("(let [true 10] nil)")
    expectInvalidArgumentErrorFrom("(let [false 10] nil)")
    expectInvalidArgumentErrorFrom("(let [nil 10] nil)")
    expectInvalidArgumentErrorFrom("(let [[a] 10] nil)")
    expectInvalidArgumentErrorFrom("(let ['(a) 10] nil)")
  }

  /// let should not accept qualified symbols in the binding vector.
  func testWithQualifiedSymbols() {
    expectThat("(let [foo/a 10] nil)", shouldFailAs: .QualifiedSymbolMisuseError)
    expectThat("(let [a 10 foo/b 20] nil)", shouldFailAs: .QualifiedSymbolMisuseError)
    expectThat("(let [ns1/a 10 ns2/b 20] nil)", shouldFailAs: .QualifiedSymbolMisuseError)
  }

  /// let should require the second argument to be a binding vector.
  func testSecondArgument() {
    expectInvalidArgumentErrorFrom("(let '(a 10) 15)")
    expectInvalidArgumentErrorFrom("(let 15)")
    expectInvalidArgumentErrorFrom("(let a)")
    expectInvalidArgumentErrorFrom("(let :a)")
    expectInvalidArgumentErrorFrom("(let \\a)")
    expectInvalidArgumentErrorFrom("(let \"a\")")
    expectInvalidArgumentErrorFrom("(let {a 10} 15)")
    expectInvalidArgumentErrorFrom("(let true)")
    expectInvalidArgumentErrorFrom("(let false)")
    expectInvalidArgumentErrorFrom("(let nil)")
  }

  /// let should return the evaluated result of its last form.
  func testLetBody() {
    expectThat("(let [a 10] (.print a) (.+ 1 2) nil \"foobar\")", shouldEvalTo: .StringAtom("foobar"))
    expectOutputBuffer(toBe: "10")
  }

  /// let should fail without any arguments.
  func testZeroArity() {
    expectArityErrorFrom("(let)")
  }
}

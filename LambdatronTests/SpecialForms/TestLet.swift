//
//  TestLet.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/27/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test scoping rules related to the 'let' special form.
class TestScoping : InterpreterTest {

  override func setUp() {
    super.setUp()
    clearOutputBuffer()
    interpreter.writeOutput = writeToBuffer
  }

  override func tearDown() {
    // Reset the interpreter
    clearOutputBuffer()
    interpreter.writeOutput = print
  }

  /// let-scoping should define a new locally usable binding.
  func testLetBinding() {
    expectThat("(let [a 500] a)", shouldEvalTo: .IntAtom(500))
    expectThat("(let [a 1 b 200] (.+ a b))", shouldEvalTo: .IntAtom(201))
  }

  /// Non-shadowed vars should be visible within a let binding.
  func testNonShadowedVarsInLet() {
    runCode("(def a 500)")
    runCode("(def b 21)")
    expectThat("(let [c 20 d 18] (.println a) (.println b) (.println c) (.println d))", shouldEvalTo: .Nil)
    expectOutputBuffer(toBe: "500\n21\n20\n18\n")
  }

  /// Non-shadowed bindings should be visible within a let binding.
  func testNonShadowedBindings() {
    // Three-level binding nesting: a = 10 (level 1), b = 21 (level 2), c = 17 (level 3). All 3 levels used in the final
    //  expression.
    expectThat("(let [a 10] (let [b 21] (let [c 17] (.+ a (.+ b c)))))", shouldEvalTo: .IntAtom(48))
  }

  /// Bindings should properly shadow vars and bindings.
  func testShadowing1() {
    // 'a' is a var that is shadowed twice. 'b' is bound in the outer let, and shadowed once. 'c' and 'd' are unshadowed
    //  but declared within the inner let expressions.
    runCode("(def a 71)")
    expectThat("(let [b 15] (.println a) (.println b) (let [a 99 c 1234] (.println a) (.println b) (.println c) (let [a 53 b 1 d 9990] (.println a) (.println b) (.println d))))",
      shouldEvalTo: .Nil)
    expectOutputBuffer(toBe: "71\n15\n99\n15\n1234\n53\n1\n9990\n")
  }

  /// Bindings should properly shadow vars and bindings.
  func testShadowing2() {
    // 'a' is not shadowed at all. 'b' is shadowed once. 'c' is shadowed twice.
    expectThat("(let [a 10 b 11 c 12] (.println a) (.println b) (.println c) (let [b 21 c 22] (.println a) (.println b) (.println c) (let [c 32] (.println a) (.println b) (.println c))))",
      shouldEvalTo: .Nil)
    expectOutputBuffer(toBe: "10\n11\n12\n10\n21\n22\n10\n21\n32\n")
  }

  /// Binding expressions should have visibility into previously declared vars and bindings.
  func testBindingVisibility() {
    runCode("(def a 99)")
    // Binding expression for 'c' has access to both the def 'a' and the previously bound variable 'b'.
    expectThat("(let [b 50] (let [c (.+ a b)] c))", shouldEvalTo: .IntAtom(149))
  }

  /// Binding expressions should have visibility into previously created bindings.
  func testSequentialBinding() {
     expectThat("(let [a 4 b (.+ a 10) c (.+ b a)] (.println a) (.println b) (.println c))", shouldEvalTo: .Nil)
     expectOutputBuffer(toBe: "4\n14\n18\n")
  }
}

/// Test proper usage and behavior of the 'let' special form.
class TestLet : InterpreterTest {

  override func setUp() {
    super.setUp()
    clearOutputBuffer()
    interpreter.writeOutput = writeToBuffer
  }

  override func tearDown() {
    // Reset the interpreter
    clearOutputBuffer()
    interpreter.writeOutput = print
  }

  /// let should accept an empty binding vector.
  func testEmptyBindingVector() {
    expectThat("(let [] 155)", shouldEvalTo: .IntAtom(155))
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
    expectThat("(let [1234 10] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let [\\c 10] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let [:foobar 10] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let [\"hello\" 10] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let [true 10] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let [false 10] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let [nil 10] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let [[a] 10] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let ['(a) 10] nil)", shouldFailAs: .InvalidArgumentError)
  }

  /// let should require the second argument to be a binding vector.
  func testSecondArgument() {
    expectThat("(let '(a 10) 15)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let 15)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let :a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let \\a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let \"a\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(let {a 10} 15)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(let nil)", shouldFailAs: .InvalidArgumentError)
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

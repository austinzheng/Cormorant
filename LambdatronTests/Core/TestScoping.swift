//
//  TestScoping.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/7/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test lexical scoping.
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

  /// A binding in a 'let' form should be visible to a function defined internally, unless shadowed.
  func testFunctionInLet() {
    runCode("(let [a 19 b 20] (.print \"a1\" a) (.print \"b1\" b) ((fn [b c] (.print \"a2\" a) (.print \"b2\" b) (.print \"c2\" c)) 21 22))")
    // 'a' comes from the let. 'b' is shadowed, while 'c' comes from the function parameters.
    expectOutputBuffer(toBe: "a1 19b1 20a2 19b2 21c2 22")
  }

  /// Bindings in functions should be visible in a 'let' form defined internally, unless shadowed.
  func testLetInFunction() {
    runCode("((fn [a b] (.print \"a1\" a) (.print \"b1\" b) (let [b 29 c 88] (.print \"a2\" a) (.print \"b2\" b) (.print \"c2\" c))) -7 153)")
    // 'a comes from the fn. 'b' is shadowed, while 'c' comes from the let.
    expectOutputBuffer(toBe: "a1 -7b1 153a2 -7b2 29c2 88")
  }

  /// Function parameters should properly shadow vars.
  func testFunctionShadowingVar() {
    runCode("(def a 10)")
    runCode("(def b 23)")
    runCode("(do (.print \"a1\" a) (.print \"b1\" b))")
    runCode("((fn [b c] (.print \"a2\" a) (.print \"b2\" b) (.print \"c2\" c)) 45 76)")
    expectOutputBuffer(toBe: "a1 10b1 23a2 10b2 45c2 76")
  }
}

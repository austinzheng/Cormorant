//
//  TestLet.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/27/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

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
    expectThat("(let [a 500] a)", shouldEvalTo: .IntegerLiteral(500))
    expectThat("(let [a 1 b 200] (.+ a b))", shouldEvalTo: .IntegerLiteral(201))
  }

  /// Non-shadowed vars should be visible within a let binding.
  func testNonShadowedVarsInLet() {
    runCode("(def a 500)")
    runCode("(def b 21)")
    expectThat("(let [c 20 d 18] (.println a) (.println b) (.println c) (.println d))", shouldEvalTo: .NilLiteral)
    expectOutputBuffer(toBe: "500\n21\n20\n18\n")
  }

  /// Non-shadowed bindings should be visible within a let binding.
  func testNonShadowedBindings() {
    // Three-level binding nesting: a = 10 (level 1), b = 21 (level 2), c = 17 (level 3). All 3 levels used in the final
    //  expression.
    expectThat("(let [a 10] (let [b 21] (let [c 17] (.+ a (.+ b c)))))", shouldEvalTo: .IntegerLiteral(48))
  }

  /// Bindings should properly shadow vars and bindings.
  func testShadowing1() {
    runCode("(def a 71)")
    expectThat("(let [b 15] (.println a) (.println b) (let [a 99] (.println a) (.println b) (let [a 53 b 1] (.println a) (.println b))))",
      shouldEvalTo: .NilLiteral)
    expectOutputBuffer(toBe: "71\n15\n99\n15\n53\n1\n")
  }

  /// Bindings should properly shadow vars and bindings.
  func testShadowing2() {
    expectThat("(let [a 10 b 11 c 12] (.println a) (.println b) (.println c) (let [b 21 c 22] (.println a) (.println b) (.println c) (let [c 32] (.println a) (.println b) (.println c))))",
      shouldEvalTo: .NilLiteral)
    expectOutputBuffer(toBe: "10\n11\n12\n10\n21\n22\n10\n21\n32\n")
  }

  /// Binding expressions should have visibility into previously declared vars and bindings.
  func testBindingVisibility() {
    runCode("(def a 99)")
    expectThat("(let [b 50] (let [c (.+ a b)] c))", shouldEvalTo: .IntegerLiteral(149))
  }

  /// Binding expressions should have visibility into previously created bindings.
  func testSequentialBinding() {
     expectThat("(let [a 4 b (.+ a 10) c (.+ b a)] (.println a) (.println b) (.println c))", shouldEvalTo: .NilLiteral)
     expectOutputBuffer(toBe: "4\n14\n18\n")
  }
}

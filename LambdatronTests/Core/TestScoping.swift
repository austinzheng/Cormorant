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
  func testShadowing() {
    // 'a' is a var that is shadowed twice. 'b' is bound in the outer let, and shadowed once. 'c' and 'd' are unshadowed
    //  but declared within the inner let expressions.
    runCode("(def a 71)")
    expectThat("(let [b 15] (.println a) (.println b) (let [a 99 c 1234] (.println a) (.println b) (.println c) (let [a 53 b 1 d 9990] (.println a) (.println b) (.println d))))",
      shouldEvalTo: .Nil)
    expectOutputBuffer(toBe: "71\n15\n99\n15\n1234\n53\n1\n9990\n")
    clearOutputBuffer()
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

  /// A binding in a 'let' form should be visible to a loop defined internally, unless shadowed.
  func testLetInLoop() {
    // Define 'a' and 'b' in the let. Define 'b' and 'c' in the loop. The loop runs 4 times.
    expectThat("(let [a 10 b 11] (.print \"ainit:\" a) (.print \"binit:\" b) (loop [b 3 c 100] (.print \"a:\" a) (.print \"b:\" b) (.print \"c:\" c) (if (.= b 0) \"done\" (recur (.- b 1) c))))",
      shouldEvalTo: .StringAtom("done"))
    expectOutputBuffer(toBe: "ainit: 10binit: 11a: 10b: 3c: 100a: 10b: 2c: 100a: 10b: 1c: 100a: 10b: 0c: 100")
  }

  /// Bindings in loops should be visible in a 'let' form defined internally, unless shadowed.
  func testLoopInLet() {
    expectThat("(loop [a 3 b 10] (.print \"ao:\" a) (.print \"bo:\" b) (let [b 99 c (.+ a b)] (.print \"a:\" a) (.print \"b:\" b) (.print \"c:\" c)) (if (.= a 0) \"done\" (recur (.- a 1) (.+ b 1))))",
      shouldEvalTo: .StringAtom("done"))
    expectOutputBuffer(toBe: "ao: 3bo: 10a: 3b: 99c: 102ao: 2bo: 11a: 2b: 99c: 101ao: 1bo: 12a: 1b: 99c: 100ao: 0bo: 13a: 0b: 99c: 99")
  }
}

//
//  TestEvaluating.swift
//  Cormorant
//
//  Created by Austin Zheng on 1/19/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the way functions are evaluated.
class TestFunctionEvaluation : InterpreterTest {

  /// A function should properly return the value of the last form in its body.
  func testFunctionReturnValue() {
    run(input: "(def testFunc (fn [] (.+ 1 2)))")
    expectThat("(testFunc)", shouldEvalTo: 3)
  }

  /// A function should run its body forms in order and return the value of the last one.
  func testFunctionBodyEvaluation() {
    run(input: "(def testFunc (fn [] (.print \"first\") (.print \"second\") (.print \"third\") 1.2345))")
    expectThat("(testFunc)", shouldEvalTo: 1.2345)
    expectOutputBuffer(toBe: "firstsecondthird")
  }

  /// A function should properly run recursively when referred to by the name within the 'fn' definition.
  func testFunctionRecursion() {
    // This lambda just counts down from a starting value and returns 'true' when done.
    expectThat("((fn rec [a] (if (.= a 0) (do (.print \"done\") true) (do (.print a) (rec (.- a 1))))) 15)",
      shouldEvalTo: true)
    expectOutputBuffer(toBe: "151413121110987654321done")
  }

  /// Mutually recursive functions should call each other properly.
  func testMutualRecursion() {
    run(input: "(def f1 (fn [a] (if (.= a 0) (.print \"f1-done\") (do (.print \"f1\" a \" \") (f2 (.- a 1))))))")
    run(input: "(def f2 (fn [a] (if (.= a 0) (.print \"f2-done\") (do (.print \"f2\" a \" \") (f3 (.- a 1))))))")
    run(input: "(def f3 (fn [a] (if (.= a 0) (.print \"f3-done\") (do (.print \"f3\" a \" \") (f1 (.- a 1))))))")
    run(input: "(f1 10)")
    expectOutputBuffer(toBe: "f1 10  f2 9  f3 8  f1 7  f2 6  f3 5  f1 4  f2 3  f3 2  f1 1  f2-done")
  }

  /// A function should properly recurse when used with the 'recur' form.
  func testFunctionWithRecur() {
    expectThat("((fn [ctr acc] (.print \"ctr:\" ctr) (.print \"acc:\" acc) (if (.= ctr 0) acc (recur (.- ctr 1) (.+ ctr acc)))) 10 0)",
      shouldEvalTo: 55)
    expectOutputBuffer(toBe: "ctr: 10acc: 0ctr: 9acc: 10ctr: 8acc: 19ctr: 7acc: 27ctr: 6acc: 34ctr: 5acc: 40ctr: 4acc: 45ctr: 3acc: 49ctr: 2acc: 52ctr: 1acc: 54ctr: 0acc: 55")
  }

  /// A function with variadic arguments should properly recurse when used with the 'recur' form.
  func testVariadicFuncWithRecur() {
    expectThat("((fn [ctr & a] (if (.= 0 ctr) a (recur (.- ctr 1) (.rest a)))) 3 10 20 30 40 50 60)",
      shouldEvalTo: list(containing: 40, 50, 60))
  }

  /// A function with only a vararg should properly recurse when used with the 'recur' form.
  func testVarargOnlyFuncWithRecur() {
    expectThat("((fn [& a] (.print \"a:\" a) (if (.= nil (.next a)) \"done\" (recur (.rest a)))) 1 2 3 4 5)",
      shouldEvalTo: .string("done"))
    expectOutputBuffer(toBe: "a: (1 2 3 4 5)a: (2 3 4 5)a: (3 4 5)a: (4 5)a: (5)")
  }

  /// A function with a vararg that recurses should allow a non-list form to be passed as the new value of the vararg.
  func testFuncAnyVarargRecur() {
    // Note how the vararg 'b' is bound to "foobar" when the function recurses.
    expectThat("((fn [a & b] (if (.= a 0) b (recur (.- a 1) \"foobar\"))) 5 1 2 3 4)",
      shouldEvalTo: .string("foobar"))
    expectThat("((fn [a & b] (if (.= a 0) b (recur (.- a 1) 3.141592))) 5 1 2 3 4)",
      shouldEvalTo: 3.141592)
    expectThat("((fn [a & b] (if (.= a 0) b (recur (.- a 1) nil))) 2 8)", shouldEvalTo: .nilValue)
  }

  /// A function with multiple arities should pick the appropriate fixed arity, if appropriate.
  func testFixedArityMultiFunction() {
    run(input: "(def testFunc (fn ([a b c] (.print \"3 args:\" a b c)) ([a b] (.print \"2 args:\" a b)) ([a] (.print \"1 arg:\" a))))")
    run(input: "(testFunc 1 2 3)")
    expectOutputBuffer(toBe: "3 args: 1 2 3")
    // Try 2
    clearOutputBuffer()
    run(input: "(testFunc 12345)")
    expectOutputBuffer(toBe: "1 arg: 12345")
    // Try 3
    clearOutputBuffer()
    run(input: "(testFunc 9 7)")
    expectOutputBuffer(toBe: "2 args: 9 7")
  }

  /// A function with multiple arities should pick the appropriate variadic body, if appropriate.
  func testVariadicMultiFunction() {
    run(input: "(def testFunc (fn ([a b] (.print \"2 args:\" a b)) ([a b & c] (.print \"varargs:\" a b c))))")
    run(input: "(testFunc 10 20)")
    expectOutputBuffer(toBe: "2 args: 10 20")
    // Try 2
    clearOutputBuffer()
    run(input: "(testFunc 9 97 998)")
    expectOutputBuffer(toBe: "varargs: 9 97 (998)")
    // Try 3
    clearOutputBuffer()
    run(input: "(testFunc -1 0 14 15)")
    expectOutputBuffer(toBe: "varargs: -1 0 (14 15)")
  }

  /// A function's output should not be further evaluated.
  func testFunctionOutputEvaluation() {
    run(input: "(def testFunc (fn [] (.list .+ 500 200)))")
    expectThat("(testFunc)", shouldEvalTo: list(containing: .builtInFunction(.Plus), 500, 200))
  }

  /// A function's arguments should be evaluated by the time the function sees them.
  func testParamEvaluation() {
    // Define a function
    run(input: "(def testFunc (fn [a b] (.print a) (.print \", \") (.print b) true))")
    expectThat("(testFunc (.+ 1 2) (.+ 3 4))", shouldEvalTo: true)
    expectOutputBuffer(toBe: "3, 7")
  }

  /// A function's arguments should be evaluated in order, from left to right.
  func testParamEvaluationOrder() {
    // Define a function that takes 4 args and does nothing
    run(input: "(def testFunc (fn [a b c d] nil))")
    expectThat("(testFunc (.print \"arg1\") (.print \"arg2\") (.print \"arg3\") (.print \"arg4\"))",
               shouldEvalTo: .nilValue)
    expectOutputBuffer(toBe: "arg1arg2arg3arg4")
  }

  /// Vars and unshadowed let bindings should be available within a function body.
  func testBindingHierarchy() {
    run(input: "(def a 187)")
    run(input: "(let [b 51] (def testFunc (fn [c] (.+ (.+ a b) c))))")
    expectThat("(testFunc 91200)", shouldEvalTo: 91438)
  }

  /// A function's arguments should shadow any vars or let bindings.
  func testBindingShadowing() {
    run(input: "(def a 187)")
    run(input: "(let [b 51] (def testFunc (fn [a b c] (.+ (.+ a b) c))))")
    expectThat("(testFunc 100 201 512)", shouldEvalTo: 813)
  }

  /// A function should not capture a var's value at creation time.
  func testFunctionVarCapture() {
    // Define a function that returns a var
    run(input: "(def testFunc (fn [] a))")
    run(input: "(def a 500)")
    expectThat("(testFunc)", shouldEvalTo: 500)
    run(input: "(def a false)")
    expectThat("(testFunc)", shouldEvalTo: false)
  }

  /// A function with more than 16 arguments should capture their values correctly.
  func testManyArgFunction() {
    run(input: "(def testFunc (fn [a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a18 a19] (.print a0) (.print a1) (.print a2) (.print a3) (.print a4) (.print a5) (.print a6) (.print a7) (.print a8) (.print a9) (.print a10) (.print a11) (.print a12) (.print a13) (.print a14) (.print a15) (.print a16) (.print a17) (.print a18) (.print a19) (.print a0)))")
    run(input: "(testFunc \\a \\b \\c \\d \\e \\f \\g \\h \\i \\j \\k \\l \\m \\n \\o \\p \\q \\r \\s \\t)")
    expectOutputBuffer(toBe: "\\a\\b\\c\\d\\e\\f\\g\\h\\i\\j\\k\\l\\m\\n\\o\\p\\q\\r\\s\\t\\a")
  }
}

/// Test the way macros are evaluated.
class TestMacroEvaluation : InterpreterTest {

  /// A macro should properly return the value of the last form in its body for evaluation.
  func testMacroReturnValue() {
    run(input: "(defmacro testMacro [] 3)")
    expectThat("(testMacro)", shouldEvalTo: 3)
  }

  /// A macro should run its body forms in order and return the value of the last one.
  func testMacroBodyEvaluation() {
    run(input: "(defmacro testMacro [] (.print \"first\") (.print \"second\") (.print \"third\") 1.2345)")
    expectThat("(testMacro)", shouldEvalTo: 1.2345)
    expectOutputBuffer(toBe: "firstsecondthird")
  }

  /// A macro should properly recurse when used with the 'recur' form.
  func testMacroWithRecur() {
    run(input: "(defmacro testMacro [ctr acc] (.print \"ctr:\" ctr) (.print \"acc:\" acc) (if (.= ctr 0) acc (recur (.- ctr 1) (.+ ctr acc))))")
    expectThat("(testMacro 10 0)", shouldEvalTo: 55)
    expectOutputBuffer(toBe: "ctr: 10acc: 0ctr: 9acc: 10ctr: 8acc: 19ctr: 7acc: 27ctr: 6acc: 34ctr: 5acc: 40ctr: 4acc: 45ctr: 3acc: 49ctr: 2acc: 52ctr: 1acc: 54ctr: 0acc: 55")
  }

  /// A macro's output form should be automatically evaluated to produce a value.
  func testMacroOutputEvaluation() {
    run(input: "(defmacro testMacro [] (.list .+ 500 200))")
    expectThat("(testMacro)", shouldEvalTo: 700)
  }

  /// A macro's output form should be evaluated with regards to both argument and external bindings.
  func testMacroOutputWithArgs() {
    run(input: "(def a 11)")
    run(input: "(defmacro testMacro [b] (.list .+ a b))")
    expectThat("(testMacro 12)", shouldEvalTo: 23)
  }

  /// A macro's parameters should be passed to the macro without being evaluated or otherwise touched.
  func testMacroParameters() {
    // Define a macro that takes 2 parameters
    run(input: "(defmacro testMacro [a b] (.print a) (.print b) nil)")
    expectThat("(testMacro (+ 1 2) [(+ 3 4) 5])", shouldEvalTo: .nilValue)
    expectOutputBuffer(toBe: "(+ 1 2)[(+ 3 4) 5]")
  }

  /// A macro should not evaluate its parameters if not explicitly asked to do so.
  func testMacroUntouchedParam() {
    // Note that only either 'then' or 'else' can ever be evaluated.
    run(input: "(defmacro testMacro [pred then else] (if pred then else))")
    expectThat("(testMacro true (do (.print \"good\") 123) (.print \"bad\"))", shouldEvalTo: 123)
    expectOutputBuffer(toBe: "good")
  }

  /// Vars and unshadowed let bindings should be available within a macro body.
  func testBindingHierarchy() {
    run(input: "(def a 187)")
    run(input: "(let [b 51] (defmacro testMacro [c] (.+ (.+ a b) c)))")
    expectThat("(testMacro 91200)", shouldEvalTo: 91438)
  }

  /// A macro's arguments should shadow any vars or let bindings.
  func testBindingShadowing() {
    run(input: "(def a 187)")
    run(input: "(let [b 51] (defmacro testMacro [a b c] (.+ (.+ a b) c)))")
    expectThat("(testMacro 100 201 512)", shouldEvalTo: 813)
  }

  /// A macro should not capture a var's value at creation time.
  func testMacroVarCapture() {
    // Define a function that returns a var
    run(input: "(defmacro testMacro [] a)")
    run(input: "(def a 500)")
    expectThat("(testMacro)", shouldEvalTo: 500)
    run(input: "(def a false)")
    expectThat("(testMacro)", shouldEvalTo: false)
  }

  /// If a symbol in a macro is not part of the lexical context, lookup at expansion time should evaluate to a var.
  func testMacroSymbolCapture() {
    run(input: "(def b \"hello\")")
    // note the lexical context: no definition for 'b'
    run(input: "(defmacro testMacro [a] (.list .+ a b))")
    run(input: "(def b 125)")
    // testMacro, when run, must resort to getting the var named 'b'
    expectThat("(testMacro 6)", shouldEvalTo: 131)
    run(input: "(def b 918)")
    expectThat("(testMacro 6)", shouldEvalTo: 924)
  }

  /// A macro should capture its lexical context and bind valid symbols to items in that context as necessary.
  func testMacroBindingCapture() {
    // This unit test is actually similar to 'testBindingShadowing' above, but more explicit.
    // note the lexical context: definition for 'b'
    run(input: "(let [b 51] (defmacro testMacro [a] (.list .+ a b)))")
    run(input: "(def b 125)")
    // testMacro, when run, always resolves 'b' to its binding when the macro was defined
    expectThat("(testMacro 6)", shouldEvalTo: 57)
    run(input: "(def b 918)")
    expectThat("(testMacro 6)", shouldEvalTo: 57)
  }
}

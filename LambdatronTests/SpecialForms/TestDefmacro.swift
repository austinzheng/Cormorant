//
//  TestDefmacro.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/7/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the 'defmacro' special form.
class TestDefmacro : InterpreterTest {

  /// defmacro should allow the user to define a macro with no explicit body.
  func testEmptyMacro() {
    runCode("(defmacro testMacro [])")
    expectThat("(testMacro)", shouldEvalTo: .Nil)
    runCode("(defmacro testMacro2 ([]))")
    expectThat("(testMacro2)", shouldEvalTo: .Nil)
  }

  /// defmacro should allow the user to define a single-arity macro.
  func testSingleArityMacro() {
    runCode("(defmacro testMacro [left infix right] (.list infix left right))")
    expectThat("(testMacro 5 .+ 3)", shouldEvalTo: 8)
  }

  /// defmacro should allow the user to define a macro with multiple arity definitions.
  func testMultiArityMacro() {
    runCode("(defmacro testMacro ([left infix right] (.list infix left right)) ([a postfix] (.list postfix a)))")
    expectThat("(testMacro 2 .* 10)", shouldEvalTo: 20)
    expectThat("(testMacro 102 .int?)", shouldEvalTo: true)
  }

  // defmacro should allow the user to define a multiple-arity macro.
  func testVariadicMacro() {
    runCode("(defmacro testMacro [a b & c] (.concat [.list a b] c))")
    expectThat("(testMacro 1 2 3 4 5)", shouldEvalTo: "'(1 2 3 4 5)")
  }

  // defmacro should reject an attempt to define a macro with multiple bodies with the same arity.
  func testDuplicateArities() {
    expectThat("(defmacro myMacro ([a b] 1) ([c d] 2) ([a] 100))", shouldFailAs: .MultipleDefinitionsPerArityError)
  }

  // defmacro should reject an attempt to define a macro with more than one variadic body.
  func testDuplicateVaridicArities() {
    expectThat("(defmacro myMacro ([a & b] 1) ([a] 12) ([a b c & d] 15))", shouldFailAs: .MultipleVariadicAritiesError)
  }

  /// defmacro should reject defining a macro with a variadic arity definition whose arity is not more than that of any
  /// fixed arity definition.
  func testTooFewVariadicArity() {
    expectThat("(defmacro myMacro ([a & b] true) ([c d] false))", shouldFailAs: .FixedArityExceedsVariableArityError)
  }

  /// defmacro should reject being invoked with no arguments, or with only a name.
  func testArity() {
    expectArityErrorFrom("(defmacro)")
    expectArityErrorFrom("(defmacro myMacroName)")
  }

  /// defmacro should use the rightmost binding of a duplicate symbol.
  func testArgVectorDuplicateSymbols() {
    // If it were up to me, we would reject these outright. However, Clojure accepts macros defined with duplicate
    //  arguments.
    runCode("(defmacro testMacro [a a a] a)")
    expectThat("(testMacro true \"foobar\" 1523)", shouldEvalTo: 1523)
  }

  /// defmacro should reject being invoked with an argument vector that doesn't contain symbols.
  func testArgVectorInvalidTypes() {
    expectThat("(defmacro myMacro [a nil c])", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro [a true c])", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro [a false c])", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro [a 1523 c])", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro [a 2.0091 c])", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro [a \"b\" c])", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro [a :b c])", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro [a 'b c])", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro [a \\b c])", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro [a (a b) c])", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro [a [a b] c])", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro [a {a b} c])", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro [a .+ c])", shouldFailAs: .InvalidArgumentError)
  }

  /// defmacro should only take a symbol (for a name) for its first argument.
  func testInvalidFirstArguments() {
    expectThat("(defmacro \"myFunc\" [] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro :myFunc [] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro 'myFunc [] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro nil [] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro true [] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro false [] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro 152 [] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro 928.1 [] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro '(a b) [] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro {'a 'b} [] nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro [a b] nil)", shouldFailAs: .InvalidArgumentError)
    expectArityErrorFrom("(defmacro ([a b] nil))")
  }

  /// defmacro should either take a vector as the next argument after the name, or macro bodies.
  func testInvalidRestArguments() {
    expectThat("(defmacro myMacro nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro (.+ 1 2))", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro ([a b] (.+ a b)) [c d] (.+ c d))", shouldFailAs: .InvalidArgumentError)
  }

  /// defmacro should reject definitions with lists that don't start with an argument vector.
  func testInvalidArgVectorsInBodies() {
    expectThat("(defmacro myMacro ([a] 1) ([\"b\"] 2))", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro ([a] 1) ([:b] 2))", shouldFailAs: .InvalidArgumentError)
    expectThat("(defmacro myMacro ([a] 1) (['b] 2))", shouldFailAs: .InvalidArgumentError)
  }
}

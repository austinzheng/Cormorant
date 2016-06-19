//
//  TestDefmacro.swift
//  Cormorant
//
//  Created by Austin Zheng on 2/7/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the 'defmacro' special form.
class TestDefmacro : InterpreterTest {

  /// defmacro should allow the user to define a macro with no explicit body.
  func testEmptyMacro() {
    run(input: "(defmacro testMacro [])")
    expectThat("(testMacro)", shouldEvalTo: .nilValue)
    run(input: "(defmacro testMacro2 ([]))")
    expectThat("(testMacro2)", shouldEvalTo: .nilValue)
  }

  /// defmacro should allow the user to define a single-arity macro.
  func testSingleArityMacro() {
    run(input: "(defmacro testMacro [left infix right] (.list infix left right))")
    expectThat("(testMacro 5 .+ 3)", shouldEvalTo: 8)
  }

  /// defmacro should allow the user to define a macro with multiple arity definitions.
  func testMultiArityMacro() {
    run(input: "(defmacro testMacro ([left infix right] (.list infix left right)) ([a postfix] (.list postfix a)))")
    expectThat("(testMacro 2 .* 10)", shouldEvalTo: 20)
    expectThat("(testMacro 102 .int?)", shouldEvalTo: true)
  }

  // defmacro should allow the user to define a multiple-arity macro.
  func testVariadicMacro() {
    run(input: "(defmacro testMacro [a b & c] (.concat [.list a b] c))")
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

  /// defmacro should allow qualified symbols only if they are in the current namespace.
  func testQualifiedSymbols() {
    run(input: "(.ns-set 'foo)")
    expectThat("(defmacro bar/a [] nil)", shouldFailAs: .QualifiedSymbolMisuseError)
    run(input: "(defmacro foo/a [] nil)")
    run(input: "(defmacro foo/b [] nil)")
    expectThat("(defmacro bar/z [] nil)", shouldFailAs: .QualifiedSymbolMisuseError)
    // Move namespaces
    run(input: "(.ns-set 'bar)")
    expectThat("(defmacro foo/a [] nil)", shouldFailAs: .QualifiedSymbolMisuseError)
    run(input: "(defmacro bar/a [] nil)")
    run(input: "(defmacro bar/b [] nil)")
    expectThat("(defmacro foo/z [] nil)", shouldFailAs: .QualifiedSymbolMisuseError)
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
    run(input: "(defmacro testMacro [a a a] a)")
    expectThat("(testMacro true \"foobar\" 1523)", shouldEvalTo: 1523)
  }

  /// defmacro should reject being invoked with an argument vector that doesn't contain symbols.
  func testArgVectorInvalidTypes() {
    expectInvalidArgumentErrorFrom("(defmacro myMacro [a nil c])")
    expectInvalidArgumentErrorFrom("(defmacro myMacro [a true c])")
    expectInvalidArgumentErrorFrom("(defmacro myMacro [a false c])")
    expectInvalidArgumentErrorFrom("(defmacro myMacro [a 1523 c])")
    expectInvalidArgumentErrorFrom("(defmacro myMacro [a 2.0091 c])")
    expectInvalidArgumentErrorFrom("(defmacro myMacro [a \"b\" c])")
    expectInvalidArgumentErrorFrom("(defmacro myMacro [a :b c])")
    expectInvalidArgumentErrorFrom("(defmacro myMacro [a 'b c])")
    expectInvalidArgumentErrorFrom("(defmacro myMacro [a \\b c])")
    expectInvalidArgumentErrorFrom("(defmacro myMacro [a (a b) c])")
    expectInvalidArgumentErrorFrom("(defmacro myMacro [a [a b] c])")
    expectInvalidArgumentErrorFrom("(defmacro myMacro [a {a b} c])")
    expectInvalidArgumentErrorFrom("(defmacro myMacro [a .+ c])")
  }

  /// defmacro should only take a symbol (for a name) for its first argument.
  func testInvalidFirstArguments() {
    expectInvalidArgumentErrorFrom("(defmacro \"myFunc\" [] nil)")
    expectInvalidArgumentErrorFrom("(defmacro :myFunc [] nil)")
    expectInvalidArgumentErrorFrom("(defmacro 'myFunc [] nil)")
    expectInvalidArgumentErrorFrom("(defmacro nil [] nil)")
    expectInvalidArgumentErrorFrom("(defmacro true [] nil)")
    expectInvalidArgumentErrorFrom("(defmacro false [] nil)")
    expectInvalidArgumentErrorFrom("(defmacro 152 [] nil)")
    expectInvalidArgumentErrorFrom("(defmacro 928.1 [] nil)")
    expectInvalidArgumentErrorFrom("(defmacro '(a b) [] nil)")
    expectInvalidArgumentErrorFrom("(defmacro {'a 'b} [] nil)")
    expectInvalidArgumentErrorFrom("(defmacro [a b] nil)")
    expectArityErrorFrom("(defmacro ([a b] nil))")
  }

  /// defmacro should either take a vector as the next argument after the name, or macro bodies.
  func testInvalidRestArguments() {
    expectInvalidArgumentErrorFrom("(defmacro myMacro nil)")
    expectInvalidArgumentErrorFrom("(defmacro myMacro (.+ 1 2))")
    expectInvalidArgumentErrorFrom("(defmacro myMacro ([a b] (.+ a b)) [c d] (.+ c d))")
  }

  /// defmacro should reject definitions with lists that don't start with an argument vector.
  func testInvalidArgVectorsInBodies() {
    expectInvalidArgumentErrorFrom("(defmacro myMacro ([a] 1) ([\"b\"] 2))")
    expectInvalidArgumentErrorFrom("(defmacro myMacro ([a] 1) ([:b] 2))")
    expectInvalidArgumentErrorFrom("(defmacro myMacro ([a] 1) (['b] 2))")
  }
}

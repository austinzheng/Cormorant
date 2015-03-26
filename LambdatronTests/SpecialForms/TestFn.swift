//
//  TestFn.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/6/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the 'fn' special form.
class TestFn : InterpreterTest {
  // Note that tests for the actual evaluation machinery are located in 'TestEvaluating.swift'.

  /// fn should allow the user to define a function with no explicit body.
  func testEmptyFn() {
    expectThat("((fn []))", shouldEvalTo: .Nil)
    expectThat("((fn ([])))", shouldEvalTo: .Nil)
  }

  /// fn should allow the user to define a single-arity function.
  func testSingleArityFn() {
    expectThat("((fn [a b c] (.+ (.+ a b) c)) 10 11 -8)", shouldEvalTo: 13)
  }

  /// fn should allow the user to define a function with multiple arity definitions.
  func testMultiArityFn() {
    expectThat("((fn ([a] (.+ a 100)) ([a b] (.- a b)) ([a b c] (.* (.+ a b) c))) 14 23 3)", shouldEvalTo: 111)
  }

  // fn should allow the user to define a multiple-arity function.
  func testVariadicFn() {
    expectThat("((fn [a b & c] (.concat (.list a b) c)) 5 16 3 2 9)", shouldEvalTo: listWithItems(5, 16, 3, 2, 9))
  }

  // fn should allow the user to define a function with only a variadic argument.
  func testVarargOnlyFn() {
    expectThat("((fn [& a] a) 1 2 3 4 5)", shouldEvalTo: listWithItems(1, 2, 3, 4, 5))
  }

  // fn should reject an attempt to define a function with multiple bodies with the same arity.
  func testDuplicateArities() {
    expectThat("(fn ([a b] 1) ([c d] 2) ([a] 100))", shouldFailAs: .MultipleDefinitionsPerArityError)
  }

  // fn should reject an attempt to define a function with more than one variadic body.
  func testDuplicateVaridicArities() {
    expectThat("(fn ([a & b] 1) ([a] 12) ([a b c & d] 15))", shouldFailAs: .MultipleVariadicAritiesError)
  }

  /// fn should reject defining a function with a variadic arity definition whose arity is not more than that of any
  /// fixed arity definition.
  func testTooFewVariadicArity() {
    expectThat("(fn ([a & b] true) ([c d] false))", shouldFailAs: .FixedArityExceedsVariableArityError)
  }

  /// fn should reject being invoked with no arguments, or with only a name.
  func testArity() {
    expectArityErrorFrom("(fn)")
    expectArityErrorFrom("(fn myFuncName)")
  }

  /// fn should use the rightmost binding of a duplicate symbol.
  func testArgVectorDuplicateSymbols() {
    // If it were up to me, we would reject these outright. However, Clojure accepts functions defined with duplicate
    //  arguments.
    expectThat("((fn [a a a] a) true \"foobar\" 1523)", shouldEvalTo: 1523)
  }

  /// fn should reject being invoked with an argument vector that doesn't contain symbols.
  func testArgVectorInvalidTypes() {
    expectInvalidArgumentErrorFrom("(fn [a nil c])")
    expectInvalidArgumentErrorFrom("(fn [a true c])")
    expectInvalidArgumentErrorFrom("(fn [a false c])")
    expectInvalidArgumentErrorFrom("(fn [a 1523 c])")
    expectInvalidArgumentErrorFrom("(fn [a 2.0091 c])")
    expectInvalidArgumentErrorFrom("(fn [a \"b\" c])")
    expectInvalidArgumentErrorFrom("(fn [a :b c])")
    expectInvalidArgumentErrorFrom("(fn [a 'b c])")
    expectInvalidArgumentErrorFrom("(fn [a \\b c])")
    expectInvalidArgumentErrorFrom("(fn [a (a b) c])")
    expectInvalidArgumentErrorFrom("(fn [a [a b] c])")
    expectInvalidArgumentErrorFrom("(fn [a {a b} c])")
    expectInvalidArgumentErrorFrom("(fn [a .+ c])")
  }

  // fn should reject qualified symbols in the argument vector.
  func testWithQualifiedSymbols() {
    expectInvalidArgumentErrorFrom("(fn [foo/a])")
    expectInvalidArgumentErrorFrom("(fn [a foo/b c])")
    expectInvalidArgumentErrorFrom("(fn [ns1/a ns2/a ns3/a])")
  }

  /// fn should only take a list, vector, or symbol (for a name) for its first argument.
  func testInvalidFirstArguments() {
    expectInvalidArgumentErrorFrom("(fn \"myFunc\" [] nil)")
    expectInvalidArgumentErrorFrom("(fn :myFunc [] nil)")
    expectInvalidArgumentErrorFrom("(fn 'myFunc [] nil)")
    expectInvalidArgumentErrorFrom("(fn nil [] nil)")
    expectInvalidArgumentErrorFrom("(fn true [] nil)")
    expectInvalidArgumentErrorFrom("(fn false [] nil)")
    expectInvalidArgumentErrorFrom("(fn 152 [] nil)")
    expectInvalidArgumentErrorFrom("(fn 928.1 [] nil)")
    expectInvalidArgumentErrorFrom("(fn '(a b) [] nil)")
    expectInvalidArgumentErrorFrom("(fn {'a 'b} [] nil)")
  }

  /// fn should either take a vector as the next argument after the name, or function bodies.
  func testInvalidRestArguments() {
    expectInvalidArgumentErrorFrom("(fn myFunc nil)")
    expectInvalidArgumentErrorFrom("(fn myFunc (.+ 1 2))")
    expectInvalidArgumentErrorFrom("(fn myFunc ([a b] (.+ a b)) [c d] (.+ c d))")
  }

  /// fn should reject definitions with lists that don't start with an argument vector.
  func testInvalidArgVectorsInBodies() {
    expectInvalidArgumentErrorFrom("(fn ([a] 1) ([\"b\"] 2))")
    expectInvalidArgumentErrorFrom("(fn ([a] 1) ([:b] 2))")
    expectInvalidArgumentErrorFrom("(fn ([a] 1) (['b] 2))")
  }
}

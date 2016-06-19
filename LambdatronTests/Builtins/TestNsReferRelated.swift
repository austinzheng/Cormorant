//
//  TestNsReferRelated.swift
//  Lambdatron
//
//  Created by Austin Zheng on 3/31/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
@testable import Lambdatron

/// Test the '.ns-refer' built-in function.
class TestNsReferBuiltin : InterpreterTest {

  /// .ns-refer should refer a namespace given a valid symbol naming that namespace.
  func testReferring() {
    // Create a namespace and refer it
    run(input: "(.ns-set 'toRefer)")
    run(input: "(def a \"foobar\")")
    run(input: "(.ns-set 'user)")
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    expectThat("(.ns-refer 'toRefer)", shouldEvalTo: .nilValue)
    // The symbol should resolve properly now
    expectThat("a", shouldEvalTo: .string("foobar"))
  }

  /// .ns-refer should reject a symbol not naming a namespace.
  func testInvalidNamespaceName() {
    expectThat("(.ns-refer 'asdkajsdl)", shouldFailAs: EvalError.EvalErrorType.InvalidNamespaceError)
  }

  /// .ns-refer should reject non-symbol arguments.
  func testArgumentType() {
    expectInvalidArgumentErrorFrom("(.ns-refer nil)")
    expectInvalidArgumentErrorFrom("(.ns-refer true)")
    expectInvalidArgumentErrorFrom("(.ns-refer false)")
    expectInvalidArgumentErrorFrom("(.ns-refer 591)")
    expectInvalidArgumentErrorFrom("(.ns-refer 1.2071)")
    expectInvalidArgumentErrorFrom("(.ns-refer \"hello\")")
    expectInvalidArgumentErrorFrom("(.ns-refer *ns*)")
    expectInvalidArgumentErrorFrom("(.ns-refer :foobar)")
    expectInvalidArgumentErrorFrom("(.ns-refer \\w)")
    expectInvalidArgumentErrorFrom("(.ns-refer #\"[0-9]+\")")
    expectInvalidArgumentErrorFrom("(.ns-refer ())")
    expectInvalidArgumentErrorFrom("(.ns-refer [])")
    expectInvalidArgumentErrorFrom("(.ns-refer {})")
    expectInvalidArgumentErrorFrom("(.ns-refer .ns-refer)")
  }

  /// .ns-refer should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.ns-refer)")
    expectArityErrorFrom("(.ns-refer 'user 'user)")
  }
}

/// Test the '.ns-refers' built-in function.
class TestNsRefersBuiltin : InterpreterTest {

  /// .ns-refers should list all refers when given a symbol naming a namespace.
  func testWithNameSymbol() {
    run(input: "(.ns-set 'foo)")
    run(input: "(.ns-set 'refer1)")
    run(input: "(def a 10)")
    run(input: "(def b 20)")
    run(input: "(.ns-set 'refer2)")
    run(input: "(def c 30)")
    run(input: "(def d 40)")
    run(input: "(.ns-set 'foo)")
    run(input: "(def e 50)")
    run(input: "(def f 60)")
    run(input: "(.ns-refer 'refer1)")
    run(input: "(.ns-refer 'refer2)")
    run(input: "(.ns-set 'user)")
    expectThat("(.ns-refers 'foo)", shouldEvalTo: .map([
      .symbol(symbol("a")) : .`var`(VarType(symbol("a", namespace: "refer1"), value: 10)),
      .symbol(symbol("b")) : .`var`(VarType(symbol("b", namespace: "refer1"), value: 20)),
      .symbol(symbol("c")) : .`var`(VarType(symbol("c", namespace: "refer2"), value: 30)),
      .symbol(symbol("d")) : .`var`(VarType(symbol("d", namespace: "refer2"), value: 40)),]))
  }

  /// .ns-refers should list all refers when given a namespace object.
  func testWithNamespace() {
    // Create two namespaces and intern some Vars in each
    run(input: "(.ns-set 'refer1)")
    run(input: "(def a true)")
    run(input: "(def b nil)")
    run(input: "(.ns-set 'refer2)")
    run(input: "(def c false)")
    run(input: "(def d \\c)")
    // Go back to 'user' and make a 'foo' namespace, capturing a reference to the object
    run(input: "(.ns-set 'user)")
    run(input: "(def testNs (.ns-create 'foo))")
    // Go to 'foo', intern some Vars, and refer both 'refer1' and 'refer2'
    run(input: "(.ns-set 'foo)")
    run(input: "(def e 50)")
    run(input: "(def f 60)")
    run(input: "(.ns-refer 'refer1)")
    run(input: "(.ns-refer 'refer2)")
    // Go back to 'user' and call .ns-refers on 'foo'
    run(input: "(.ns-set 'user)")
    expectThat("(.ns-refers 'foo)", shouldEvalTo: .map([
      .symbol(symbol("a")) : .`var`(VarType(symbol("a", namespace: "refer1"), value: true)),
      .symbol(symbol("b")) : .`var`(VarType(symbol("b", namespace: "refer1"), value: .nilValue)),
      .symbol(symbol("c")) : .`var`(VarType(symbol("c", namespace: "refer2"), value: false)),
      .symbol(symbol("d")) : .`var`(VarType(symbol("d", namespace: "refer2"), value: .char("c")))]))
  }

  /// .ns-refers should reject a symbol not naming a namespace.
  func testInvalidNamespaceName() {
    expectThat("(.ns-refers 'asdkajsdl)", shouldFailAs: EvalError.EvalErrorType.InvalidNamespaceError)
  }

  /// .ns-refers should reject non-symbol and non-namespace arguments.
  func testArgumentType() {
    expectInvalidArgumentErrorFrom("(.ns-refers nil)")
    expectInvalidArgumentErrorFrom("(.ns-refers true)")
    expectInvalidArgumentErrorFrom("(.ns-refers false)")
    expectInvalidArgumentErrorFrom("(.ns-refers 591)")
    expectInvalidArgumentErrorFrom("(.ns-refers 1.2071)")
    expectInvalidArgumentErrorFrom("(.ns-refers \"hello\")")
    expectInvalidArgumentErrorFrom("(.ns-refers :foobar)")
    expectInvalidArgumentErrorFrom("(.ns-refers \\w)")
    expectInvalidArgumentErrorFrom("(.ns-refers #\"[0-9]+\")")
    expectInvalidArgumentErrorFrom("(.ns-refers ())")
    expectInvalidArgumentErrorFrom("(.ns-refers [])")
    expectInvalidArgumentErrorFrom("(.ns-refers {})")
    expectInvalidArgumentErrorFrom("(.ns-refers .ns-refer)")
  }

  /// .ns-refers should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.ns-refers)")
    expectArityErrorFrom("(.ns-refers *ns* *ns*)")
  }
}

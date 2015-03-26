//
//  TestNsReferRelated.swift
//  Lambdatron
//
//  Created by Austin Zheng on 3/31/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the '.ns-refer' built-in function.
class TestNsReferBuiltin : InterpreterTest {

  /// .ns-refer should refer a namespace given a valid symbol naming that namespace.
  func testReferring() {
    // Create a namespace and refer it
    runCode("(.ns-set 'toRefer)")
    runCode("(def a \"foobar\")")
    runCode("(.ns-set 'user)")
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    expectThat("(.ns-refer 'toRefer)", shouldEvalTo: .Nil)
    // The symbol should resolve properly now
    expectThat("a", shouldEvalTo: .StringAtom("foobar"))
  }

  /// .ns-refer should reject a symbol not naming a namespace.
  func testInvalidNamespaceName() {
    expectThat("(.ns-refer 'asdkajsdl)", shouldFailAs: EvalError.ErrorType.InvalidNamespaceError)
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
    runCode("(.ns-set 'foo)")
    runCode("(.ns-set 'refer1)")
    runCode("(def a 10)")
    runCode("(def b 20)")
    runCode("(.ns-set 'refer2)")
    runCode("(def c 30)")
    runCode("(def d 40)")
    runCode("(.ns-set 'foo)")
    runCode("(def e 50)")
    runCode("(def f 60)")
    runCode("(.ns-refer 'refer1)")
    runCode("(.ns-refer 'refer2)")
    runCode("(.ns-set 'user)")
    expectThat("(.ns-refers 'foo)", shouldEvalTo: .Map([
      .Symbol(symbol("a")) : .Var(VarType(.Literal(10), name: symbol("a", namespace: "refer1"))),
      .Symbol(symbol("b")) : .Var(VarType(.Literal(20), name: symbol("b", namespace: "refer1"))),
      .Symbol(symbol("c")) : .Var(VarType(.Literal(30), name: symbol("c", namespace: "refer2"))),
      .Symbol(symbol("d")) : .Var(VarType(.Literal(40), name: symbol("d", namespace: "refer2")))]))
  }

  /// .ns-refers should list all refers when given a namespace object.
  func testWithNamespace() {
    // Create two namespaces and intern some Vars in each
    runCode("(.ns-set 'refer1)")
    runCode("(def a true)")
    runCode("(def b nil)")
    runCode("(.ns-set 'refer2)")
    runCode("(def c false)")
    runCode("(def d \\c)")
    // Go back to 'user' and make a 'foo' namespace, capturing a reference to the object
    runCode("(.ns-set 'user)")
    runCode("(def testNs (.ns-create 'foo))")
    // Go to 'foo', intern some Vars, and refer both 'refer1' and 'refer2'
    runCode("(.ns-set 'foo)")
    runCode("(def e 50)")
    runCode("(def f 60)")
    runCode("(.ns-refer 'refer1)")
    runCode("(.ns-refer 'refer2)")
    // Go back to 'user' and call .ns-refers on 'foo'
    runCode("(.ns-set 'user)")
    expectThat("(.ns-refers 'foo)", shouldEvalTo: .Map([
      .Symbol(symbol("a")) : .Var(VarType(.Literal(true), name: symbol("a", namespace: "refer1"))),
      .Symbol(symbol("b")) : .Var(VarType(.Literal(.Nil), name: symbol("b", namespace: "refer1"))),
      .Symbol(symbol("c")) : .Var(VarType(.Literal(false), name: symbol("c", namespace: "refer2"))),
      .Symbol(symbol("d")) : .Var(VarType(.Literal(.CharAtom("c")), name: symbol("d", namespace: "refer2")))]))
  }

  /// .ns-refers should reject a symbol not naming a namespace.
  func testInvalidNamespaceName() {
    expectThat("(.ns-refers 'asdkajsdl)", shouldFailAs: EvalError.ErrorType.InvalidNamespaceError)
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

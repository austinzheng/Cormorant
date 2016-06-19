//
//  TestNsAliasRelated.swift
//  Lambdatron
//
//  Created by Austin Zheng on 3/30/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
@testable import Lambdatron

/// Test the '.ns-alias' built-in function.
class TestNsAliasBuiltin : InterpreterTest {

  /// .ns-alias should properly create an alias for a different namespace.
  func testAliasingOtherNamespace() {
    // Make another namespace and define a few vars in it
    run(input: "(.ns-set 'other)")
    run(input: "(def a 1.111)")
    run(input: "(def b false)")
    // Switch to yet another namespace
    run(input: "(.ns-set 'foo)")
    // Make an alias, 'bar'
    expectThat("(.ns-alias 'bar 'other)", shouldEvalTo: .nilValue)
    expectThat("bar/a", shouldEvalTo: 1.111)
    expectThat("bar/b", shouldEvalTo: false)
    // Make an alias, 'baz'
    expectThat("(.ns-alias 'baz 'other)", shouldEvalTo: .nilValue)
    expectThat("baz/a", shouldEvalTo: 1.111)
    expectThat("baz/b", shouldEvalTo: false)
  }

  /// .ns-alias should properly create an alias for the current namespace.
  func testAliasingThisNamespace() {
    // Define two variables in the default (user) namespace
    run(input: "(def a 10)")
    run(input: "(def b \"hello\")")
    // Make an alias, 'foo'
    expectThat("(.ns-alias 'foo *ns*)", shouldEvalTo: .nilValue)
    expectThat("foo/a", shouldEvalTo: 10)
    expectThat("foo/b", shouldEvalTo: .string("hello"))
    // Make another alias, 'bar'
    expectThat("(.ns-alias 'bar *ns*)", shouldEvalTo: .nilValue)
    expectThat("bar/a", shouldEvalTo: 10)
    expectThat("bar/b", shouldEvalTo: .string("hello"))
  }

  /// .ns-alias should not allow aliasing to another alias.
  func testAliasingAliases() {
    run(input: "(.ns-alias 'foo *ns*)")
    expectThat("(.ns-alias 'bar 'foo)", shouldFailAs: EvalError.EvalErrorType.InvalidNamespaceError)
  }

  /// .ns-alias should not allow resolving aliases from outside the namespace within which the alias was defined.
  func testAliasResolutionFromOutsideNamespace() {
    // Set up an alias within originNamespace to targetNamespace
    run(input: "(.ns-set 'targetNamespace)")
    run(input: "(def a 10)")
    run(input: "(def b \"foobar\")")
    run(input: "(.ns-set 'originNamespace)")
    run(input: "(.ns-alias 'myAlias 'targetNamespace)")
    expectThat("myAlias/a", shouldEvalTo: 10)
    expectThat("myAlias/b", shouldEvalTo: .string("foobar"))
    // Leave the alias and try to resolve
    run(input: "(.ns-set 'outsideNamespace)")
    expectThat("originNamespace/a", shouldFailAs: .InvalidSymbolError)
    expectThat("originNamespace/b", shouldFailAs: .InvalidSymbolError)
    expectThat("myAlias/a", shouldFailAs: .InvalidSymbolError)
    expectThat("myAlias/b", shouldFailAs: .InvalidSymbolError)
  }

  /// .ns-alias should reject namespaces names that are invalid.
  func testInvalidNamespaceName() {
    run(input: "(.ns-create 'other)")
    expectThat("(.ns-alias 'first 'other)", shouldEvalTo: .nilValue)
    expectThat("(.ns-alias 'second 'another)", shouldFailAs: EvalError.EvalErrorType.InvalidNamespaceError)
  }

  /// .ns-alias should reject reassigning the same alias (originally aliased to another namespace).
  func testReassigningOtherAlias() {
    run(input: "(.ns-create 'other)")
    run(input: "(.ns-create 'another)")
    expectThat("(.ns-alias 'foo 'other)", shouldEvalTo: .nilValue)
    expectThat("(.ns-alias 'foo 'another)", shouldFailAs: .AliasRebindingError)
    expectThat("(.ns-alias 'foo 'other)", shouldEvalTo: .nilValue)
  }

  /// .ns-alias should reject reassigning the same alias (originally aliased to the current namespace).
  func testReassigningSelfAlias() {
    run(input: "(.ns-create 'other)")
    expectThat("(.ns-alias 'foo *ns*)", shouldEvalTo: .nilValue)
    expectThat("(.ns-alias 'foo 'other)", shouldFailAs: .AliasRebindingError)
    expectThat("(.ns-alias 'foo *ns*)", shouldEvalTo: .nilValue)
  }

  /// .ns-alias should reject first arguments that aren't symbols.
  func testAliasArgumentType() {
    expectInvalidArgumentErrorFrom("(.ns-alias nil 'user)")
    expectInvalidArgumentErrorFrom("(.ns-alias true 'user)")
    expectInvalidArgumentErrorFrom("(.ns-alias false 'user)")
    expectInvalidArgumentErrorFrom("(.ns-alias -59812 'user)")
    expectInvalidArgumentErrorFrom("(.ns-alias 1.2345 'user)")
    expectInvalidArgumentErrorFrom("(.ns-alias \"hello\" 'user)")
    expectInvalidArgumentErrorFrom("(.ns-alias #\"[0-9]+\" 'user)")
    expectInvalidArgumentErrorFrom("(.ns-alias \\c 'user)")
    expectInvalidArgumentErrorFrom("(.ns-alias :foobar 'user)")
    expectInvalidArgumentErrorFrom("(.ns-alias *ns* 'user)")
    expectInvalidArgumentErrorFrom("(.ns-alias () 'user)")
    expectInvalidArgumentErrorFrom("(.ns-alias [] 'user)")
    expectInvalidArgumentErrorFrom("(.ns-alias {} 'user)")
    expectInvalidArgumentErrorFrom("(.ns-alias .ns-alias 'user)")
  }

  /// .ns-alias should reject second arguments that aren't symbols or namespaces.
  func testNamespaceArgumentType() {
    expectInvalidArgumentErrorFrom("(.ns-alias 'foo nil)")
    expectInvalidArgumentErrorFrom("(.ns-alias 'foo true)")
    expectInvalidArgumentErrorFrom("(.ns-alias 'foo false)")
    expectInvalidArgumentErrorFrom("(.ns-alias 'foo 1)")
    expectInvalidArgumentErrorFrom("(.ns-alias 'foo 5991.2991)")
    expectInvalidArgumentErrorFrom("(.ns-alias 'foo \"user\")")
    expectInvalidArgumentErrorFrom("(.ns-alias 'foo #\"[0-9]+\")")
    expectInvalidArgumentErrorFrom("(.ns-alias 'foo \\y)")
    expectInvalidArgumentErrorFrom("(.ns-alias 'foo :user)")
    expectInvalidArgumentErrorFrom("(.ns-alias 'foo ())")
    expectInvalidArgumentErrorFrom("(.ns-alias 'foo [])")
    expectInvalidArgumentErrorFrom("(.ns-alias 'foo {})")
    expectInvalidArgumentErrorFrom("(.ns-alias 'foo .ns-alias)")
  }

  /// .ns-alias should take exactly two arguments.
  func testArity() {
    expectArityErrorFrom("(.ns-alias 'foo)")
    expectArityErrorFrom("(.ns-alias 'foo *ns* 'bar)")
  }
}

/// Test the '.ns-unalias' built-in function.
class TestNsUnaliasBuiltin : InterpreterTest {

  /// .ns-unalias should silently ignore nonsense aliases.
  func testRemoveInvalidAlias() {
    expectThat("(.ns-unalias 'user 'asdkaljdasd)", shouldEvalTo: .nilValue)
  }

  /// .ns-unalias should properly remove an alias for another namespace from the current namespace.
  func testRemoveOtherAlias() {
    // Set up and verify
    run(input: "(.ns-set 'foo)")
    run(input: "(def a 10)")
    run(input: "(def b \"foobar\")")
    run(input: "(.ns-set 'bar)")
    expectThat("(.ns-alias 'testAlias 'foo)", shouldEvalTo: .nilValue)
    expectThat("testAlias/a", shouldEvalTo: 10)
    expectThat("testAlias/b", shouldEvalTo: .string("foobar"))
    // Remove the alias
    expectThat("(.ns-unalias core/*ns* 'testAlias)", shouldEvalTo: .nilValue)
    expectThat("testAlias/a", shouldFailAs: .InvalidSymbolError)
    expectThat("testAlias/b", shouldFailAs: .InvalidSymbolError)
  }

  /// .ns-unalias should properly remove a self-alias from the current namespace.
  func testRemoveSelfAlias() {
    // Set up and verify
    run(input: "(def a 10)")
    run(input: "(def b \"foobar\")")
    expectThat("(.ns-alias 'testAlias 'user)", shouldEvalTo: .nilValue)
    expectThat("testAlias/a", shouldEvalTo: 10)
    expectThat("testAlias/b", shouldEvalTo: .string("foobar"))
    // Remove the alias
    expectThat("(.ns-unalias 'user 'testAlias)", shouldEvalTo: .nilValue)
    expectThat("testAlias/a", shouldFailAs: .InvalidSymbolError)
    expectThat("testAlias/b", shouldFailAs: .InvalidSymbolError)
    expectThat("a", shouldEvalTo: 10)
    expectThat("b", shouldEvalTo: .string("foobar"))
  }

  /// .ns-unalias should properly remove an alias for another namespace from a non-current namespace.
  func testRemoveOtherAliasFromNonCurrentNamespace() {
    // Set up and verify
    run(input: "(.ns-set 'otherNamespace)")
    run(input: "(def a 10)")
    run(input: "(def b \"foobar\")")
    run(input: "(.ns-set 'targetNamespace)")
    expectThat("(.ns-alias 'testAlias 'otherNamespace)", shouldEvalTo: .nilValue)
    expectThat("testAlias/a", shouldEvalTo: 10)
    expectThat("testAlias/b", shouldEvalTo: .string("foobar"))
    // Switch to another namespace and remove the alias from 'targetNamespace'
    run(input: "(.ns-set 'user)")
    expectThat("(.ns-unalias 'targetNamespace 'testAlias)", shouldEvalTo: .nilValue)
    // Verify that the alias 'testAlias' no longer exists in 'targetNamespace'
    run(input: "(.ns-set 'targetNamespace)")
    expectThat("testAlias/a", shouldFailAs: .InvalidSymbolError)
    expectThat("testAlias/b", shouldFailAs: .InvalidSymbolError)
  }

  /// .ns-unalias should properly remove an self-alias from a non-current namespace.
  func testRemoveSelfAliasFromNonCurrentNamespace() {
    // Set up and verify
    run(input: "(.ns-set 'targetNamespace)")
    run(input: "(def a 10)")
    run(input: "(def b \"foobar\")")
    expectThat("(.ns-alias 'testAlias core/*ns*)", shouldEvalTo: .nilValue)
    // Switch to another namespace and remove the alias from 'targetNamespace'
    run(input: "(.ns-set 'user)")
    expectThat("(.ns-unalias 'targetNamespace 'testAlias)", shouldEvalTo: .nilValue)
    // Verify that the alias 'testAlias' no longer exists in 'targetNamespace'
    run(input: "(.ns-set 'targetNamespace)")
    expectThat("testAlias/a", shouldFailAs: .InvalidSymbolError)
    expectThat("testAlias/b", shouldFailAs: .InvalidSymbolError)
    expectThat("a", shouldEvalTo: 10)
    expectThat("b", shouldEvalTo: .string("foobar"))
  }

  /// .ns-unalias should reject name symbols that don't actually name a namespace.
  func testInvalidNamespaceName() {
    expectThat("(.ns-unalias 'asdasdasd 'adadasdasd)", shouldFailAs: EvalError.EvalErrorType.InvalidNamespaceError)
  }

  /// .ns-unalias should reject first arguments that aren't symbols or namespaces.
  func testNamespaceArgumentType() {
    expectInvalidArgumentErrorFrom("(.ns-unalias nil 'myAlias)")
    expectInvalidArgumentErrorFrom("(.ns-unalias true 'myAlias)")
    expectInvalidArgumentErrorFrom("(.ns-unalias false 'myAlias)")
    expectInvalidArgumentErrorFrom("(.ns-unalias 99 'myAlias)")
    expectInvalidArgumentErrorFrom("(.ns-unalias 99.0 'myAlias)")
    expectInvalidArgumentErrorFrom("(.ns-unalias \\newline 'myAlias)")
    expectInvalidArgumentErrorFrom("(.ns-unalias :user 'myAlias)")
    expectInvalidArgumentErrorFrom("(.ns-unalias \"user\" 'myAlias)")
    expectInvalidArgumentErrorFrom("(.ns-unalias #\"[0-9]+\" 'myAlias)")
    expectInvalidArgumentErrorFrom("(.ns-unalias () 'myAlias)")
    expectInvalidArgumentErrorFrom("(.ns-unalias [] 'myAlias)")
    expectInvalidArgumentErrorFrom("(.ns-unalias {} 'myAlias)")
    expectInvalidArgumentErrorFrom("(.ns-unalias .ns-unalias 'myAlias)")
  }

  /// .ns-unalias should reject second arguments that aren't symbols.
  func testAliasArgumentType() {
    expectInvalidArgumentErrorFrom("(.ns-unalias *ns* nil)")
    expectInvalidArgumentErrorFrom("(.ns-unalias *ns* true)")
    expectInvalidArgumentErrorFrom("(.ns-unalias *ns* false)")
    expectInvalidArgumentErrorFrom("(.ns-unalias *ns* 157)")
    expectInvalidArgumentErrorFrom("(.ns-unalias *ns* -0.291923)")
    expectInvalidArgumentErrorFrom("(.ns-unalias *ns* \\n)")
    expectInvalidArgumentErrorFrom("(.ns-unalias *ns* :myAlias)")
    expectInvalidArgumentErrorFrom("(.ns-unalias *ns* \"myAlias\")")
    expectInvalidArgumentErrorFrom("(.ns-unalias *ns* #\"[0-9]+\")")
    expectInvalidArgumentErrorFrom("(.ns-unalias *ns* *ns*)")
    expectInvalidArgumentErrorFrom("(.ns-unalias *ns* ())")
    expectInvalidArgumentErrorFrom("(.ns-unalias *ns* [])")
    expectInvalidArgumentErrorFrom("(.ns-unalias *ns* {})")
    expectInvalidArgumentErrorFrom("(.ns-unalias *ns* .ns-unalias)")
  }

  /// .ns-unalias should take exactly two arguments.
  func testArity() {
    expectArityErrorFrom("(.ns-unalias *ns*)")
    expectArityErrorFrom("(.ns-unalias *ns* 'foo 'bar)")
  }
}

/// Test the '.ns-aliases' built-in function.
class TestNsAliasesBuiltin : InterpreterTest {

  /// .ns-aliases should return an empty map if there are no aliases in the namespace.
  func testWithoutAliases() {
    expectThat("(.ns-aliases *ns*)", shouldEvalTo: .map([:]))
  }

  /// .ns-aliases should return a map of aliases if there are aliases in the namespace.
  func testWithAliases() {
    // Set up
    let alias1 = symbol("alias1")
    let alias2 = symbol("alias2")
    let alias3 = symbol("alias3")
    let alias5 = symbol("alias5")
    let alias6 = symbol("alias6")
    let foo = run(input: "(.ns-set 'foo)")!
    let bar = run(input: "(.ns-set 'bar)")!
    let target = run(input: "(.ns-set 'targetNamespace)")!
    expectThat("(.ns-alias 'alias1 'foo)", shouldEvalTo: .nilValue)
    expectThat("(.ns-alias 'alias2 'bar)", shouldEvalTo: .nilValue)
    expectThat("(.ns-alias 'alias3 'foo)", shouldEvalTo: .nilValue)
    expectThat("(.ns-alias 'alias4 'foo)", shouldEvalTo: .nilValue)
    expectThat("(.ns-alias 'alias5 core/*ns*)", shouldEvalTo: .nilValue)
    expectThat("(.ns-alias 'alias6 'targetNamespace)", shouldEvalTo: .nilValue)
    expectThat("(.ns-unalias 'targetNamespace 'alias4)", shouldEvalTo: .nilValue)
    // Verify
    run(input: "(.ns-set 'user)")
    expectThat("(.ns-aliases 'targetNamespace)", shouldEvalTo: .map([
      .symbol(alias1): foo,
      .symbol(alias2): bar,
      .symbol(alias3): foo,
      .symbol(alias5): target,
      .symbol(alias6): target]))
  }

  /// .ns-aliases should reject namespaces names that are invalid.
  func testInvalidNamespaceName() {
    expectThat("(.ns-aliases 'askdjasldj)", shouldFailAs: EvalError.EvalErrorType.InvalidNamespaceError)
  }

  /// .ns-aliases should reject arguments that aren't symbols or namespaces.
  func testNamespaceArgumentType() {
    expectInvalidArgumentErrorFrom("(.ns-aliases nil)")
    expectInvalidArgumentErrorFrom("(.ns-aliases true)")
    expectInvalidArgumentErrorFrom("(.ns-aliases false)")
    expectInvalidArgumentErrorFrom("(.ns-aliases 99)")
    expectInvalidArgumentErrorFrom("(.ns-aliases 99.0)")
    expectInvalidArgumentErrorFrom("(.ns-aliases \\newline)")
    expectInvalidArgumentErrorFrom("(.ns-aliases :user)")
    expectInvalidArgumentErrorFrom("(.ns-aliases \"user\")")
    expectInvalidArgumentErrorFrom("(.ns-aliases #\"[0-9]+\")")
    expectInvalidArgumentErrorFrom("(.ns-aliases ())")
    expectInvalidArgumentErrorFrom("(.ns-aliases [])")
    expectInvalidArgumentErrorFrom("(.ns-aliases {})")
    expectInvalidArgumentErrorFrom("(.ns-aliases .ns-unalias)")
  }

  /// .ns-aliases should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.ns-aliases)")
    expectArityErrorFrom("(.ns-aliases *ns* *ns*)")
  }
}

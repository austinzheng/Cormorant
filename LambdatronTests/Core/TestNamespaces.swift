//
//  TestNamespaces.swift
//  Lambdatron
//
//  Created by Austin Zheng on 3/27/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest
@testable import Lambdatron

/// Test overall and miscellaneous behavior of the 'refer' functionality for namespaces.
class TestNamespaceRefer : InterpreterTest {

  /// A mapping of a symbol to a Var should be shadowed if a namespace with that same symbol name is referred.
  func testReferShadowingLocalBinding() {
    // Intern a Var locally
    runCode("(def a 1000)")
    expectThat("a", shouldEvalTo: 1000)
    // Create another namespace and refer it
    runCode("(.ns-set 'toRefer)")
    runCode("(def a \"foobar\")")
    runCode("(.ns-set 'user)")
    runCode("(.ns-refer 'toRefer)")
    // Test the value of 'a'
    expectThat("a", shouldEvalTo: .StringAtom("foobar"))
    expectThat("user/a", shouldFailAs: .InvalidSymbolError)
  }

  /// Referring a namespace to itself should not do anything.
  func testReferringSelf() {
    runCode("(def a 1000)")
    expectThat("a", shouldEvalTo: 1000)
    expectThat("user/a", shouldEvalTo: 1000)
    // Refer the 'user' namespace
    runCode("(.ns-refer 'user)")
    expectThat("a", shouldEvalTo: 1000)
    // If refer ran erroneously, the following should fail
    expectThat("user/a", shouldEvalTo: 1000)
  }

  /// Referring the same namespace multiple times should update the bindings.
  func testDuplicateReferring() {
    runCode("(.ns-set 'foo)")
    runCode("(def a 1000)")
    runCode("(.ns-set 'user)")
    // Refer
    runCode("(.ns-refer 'foo)")
    expectThat("a", shouldEvalTo: 1000)
    expectThat("b", shouldFailAs: .InvalidSymbolError)
    // Add another Var to 'foo'
    runCode("(.ns-set 'foo)")
    runCode("(def b 2000)")
    runCode("(.ns-set 'user)")
    runCode("(.ns-refer 'foo)")
    expectThat("a", shouldEvalTo: 1000)
    expectThat("b", shouldEvalTo: 2000)
  }

  /// An error should occur when attempting to intern a Var using a symbol that was already used by refer, and the
  /// referred namespace is not a system namespace.
  func testInternAfterReferNormalNamespace() {
    // Create another namespace and refer it
    runCode("(.ns-set 'toRefer)")
    runCode("(def a 9999)")
    runCode("(.ns-set 'user)")
    runCode("(.ns-refer 'toRefer)")
    expectThat("a", shouldEvalTo: 9999)
    // Try interning a local Var
    expectThat("(def a \"foobar\")", shouldFailAs: .VarRebindingError)
  }

  /// Interning a Var using a symbol that was already used by refer should succeed and take priority if the referred
  /// namespace is a system namespace.
  func testInternAfterReferSystemNamespace() {
    // Manually build and load a system namespace
    let sys = NamespaceName(symbol("sys"))
    let systemNamespace = NamespaceContext(interpreter: interpreter, ns: sys, asSystemNamespace: true)
    systemNamespace.setVar(symbol("a"), newValue: 1000)
    interpreter.testOnly_addNamespace(systemNamespace, named: sys)
    // Refer the namespace
    runCode("(.ns-refer 'sys)")
    expectThat("a", shouldEvalTo: 1000)
    // Try interning a local Var
    runCode("(def a \"foobar\")")
    expectThat("a", shouldEvalTo: .StringAtom("foobar"))
  }

  /// Referring a namespace with a symbol that was present in a previously referred namespace should cause an error.
  func testReferNameConflict() {
    // Build a namespace
    runCode("(.ns-set 'ns1)")
    runCode("(def a 10)")
    runCode("(.ns-set 'ns2)")
    runCode("(def a 20)")
    runCode("(.ns-set 'user)")
    // Refer ns1
    runCode("(.ns-refer 'ns1)")
    expectThat("a", shouldEvalTo: 10)
    // Try to refer ns2 now
    expectThat("(.ns-refer 'ns2)", shouldFailAs: .VarRebindingError)
  }

  /// Referring a namespace and then deleting that namespace should not affect the accessibility of refer'ed Vars.
  func testReferAfterReferredNamespaceDeleted() {
    // Create another namespace and refer it
    runCode("(.ns-set 'toRefer)")
    runCode("(def a 9999)")
    runCode("(.ns-set 'user)")
    runCode("(.ns-refer 'toRefer)")
    expectThat("a", shouldEvalTo: 9999)
    // Delete the referred namespace
    runCode("(.ns-remove 'toRefer)")
    // The original binding to the Var should be gone, but the refer binding should still be valid
    expectThat("toRefer/a", shouldFailAs: .InvalidSymbolError)
    expectThat("a", shouldEvalTo: 9999)
  }

  /// A Var that is referred in a namespace should not be accessible through a symbol qualified to that namespace.
  func testQualifiedSymbolForReferredVar() {
    // Create a namespace to refer, and define a variable in that namespace
    runCode("(.ns-set 'toRefer)")
    runCode("(def a 10)")
    // Refer the target namespace
    runCode("(.ns-set 'default)")
    runCode("(.ns-refer 'toRefer)")

    // Unqualified symbol should work, as should qualified symbol referring to original Var
    expectThat("a", shouldEvalTo: 10)
    expectThat("toRefer/a", shouldEvalTo: 10)
    // Qualified symbol referring to the namespace within which the refer was defined should *not* work
    expectThat("default/a", shouldFailAs: .InvalidSymbolError)
  }

  /// A Var that is referred, and then later updated, should show its updated value through the refer'ed alias.
  func testReferredVarRebinding() {
    // Create a namespace to refer, and define a variable in that namespace
    runCode("(.ns-set 'toRefer)")
    runCode("(def a 10)")

    // Refer the target namespace, and make sure the symbol appears
    runCode("(.ns-set 'firstNamespace)")
    runCode("(.ns-refer 'toRefer)")
    expectThat("a", shouldEvalTo: 10)
    // Try it in another namespace
    runCode("(.ns-set 'secondNamespace)")
    runCode("(.ns-refer 'toRefer)")
    expectThat("a", shouldEvalTo: 10)

    // Update the var
    runCode("(.ns-set 'toRefer)")
    runCode("(def a \"foobar\")")
    // Check that refer'ed aliases show the updated value
    runCode("(.ns-set 'firstNamespace)")
    expectThat("a", shouldEvalTo: .StringAtom("foobar"))
    runCode("(.ns-set 'secondNamespace)")
    expectThat("a", shouldEvalTo: .StringAtom("foobar"))
  }

  /// If a namespace is referred, any Vars added later to that namespace should not be visible through refer.
  func testReferredNamespaceAddingVars() {
    // Create a namespace to refer, and define a variable in that namespace
    runCode("(.ns-set 'toRefer)")
    runCode("(def a 10)")
    // Refer the target namespace, and make sure the symbol appears
    runCode("(.ns-set 'default)")
    runCode("(.ns-refer 'toRefer)")
    expectThat("a", shouldEvalTo: 10)

    // Add another symbol to 'toRefer'
    runCode("(.ns-set 'toRefer)")
    runCode("(def b 555)")

    // In 'default', the new symbol 'b' should not be visible
    runCode("(.ns-set 'default)")
    expectThat("a", shouldEvalTo: 10)
    expectThat("toRefer/b", shouldEvalTo: 555)
    expectThat("b", shouldFailAs: .InvalidSymbolError)
  }

  /// If a namespace is referred, any Vars removed later from that namespace should not be unmapped through refer.
  func testReferredNamespaceUnmappingVars() {
    // Create a namespace to refer, and define a variable in that namespace
    runCode("(.ns-set 'toRefer)")
    runCode("(def a 10)")
    runCode("(def b 11)")
    // Refer the target namespace, and make sure the symbol appears
    runCode("(.ns-set 'default)")
    runCode("(.ns-refer 'toRefer)")
    expectThat("a", shouldEvalTo: 10)
    expectThat("b", shouldEvalTo: 11)

    // Remove 'a' from 'toRefer'
    runCode("(.ns-set 'toRefer)")
    runCode("(.ns-unmap core/*ns* 'a)")

    // In 'default', 'a' should not have been deleted
    runCode("(.ns-set 'default)")

    expectThat("toRefer/a", shouldFailAs: .InvalidSymbolError)
    expectThat("toRefer/b", shouldEvalTo: 11)
    expectThat("a", shouldEvalTo: 10)
    expectThat("b", shouldEvalTo: 11)
  }
}

/// Test that symbols or keywords with the same names and namespaces are properly constructed and equatable.
class TestSymbolKeywordConstruction : InterpreterTest {

  /// Unqualified symbols constructed through different means should equate to each other.
  func testUnqualifiedSymbolConstruction() {
    let expected = symbol("meela", namespace: nil)
    expectThat("'meela", shouldEvalTo: .Symbol(expected))
    expectThat("(.symbol \"meela\")", shouldEvalTo: .Symbol(expected))
    expectThat("(.symbol 'meela)", shouldEvalTo: .Symbol(expected))
  }

  /// Qualified symbols constructed through different means should equate to each other.
  func testQualifiedSymbolConstruction() {
    let expected = symbol("meela", namespace: "foo")
    expectThat("'foo/meela", shouldEvalTo: .Symbol(expected))
    expectThat("(.symbol \"foo\" \"meela\")", shouldEvalTo: .Symbol(expected))
    expectThat("(.symbol 'foo/meela)", shouldEvalTo: .Symbol(expected))
  }

  /// Unqualified keywords constructed through different means should equate to each other.
  func testUnqualifiedKeywordConstruction() {
    let expected = keyword("meela", namespace: nil)
    expectThat(":meela", shouldEvalTo: .Keyword(expected))
    expectThat("(.keyword \"meela\")", shouldEvalTo: .Keyword(expected))
    expectThat("(.keyword 'meela)", shouldEvalTo: .Keyword(expected))
    expectThat("(.keyword :meela)", shouldEvalTo: .Keyword(expected))
  }

  /// Qualified keywords constructed through different means should equate to each other.
  func testQualifiedKeywordConstruction() {
    let expected = keyword("meela", namespace: "foo")
    runCode("(.ns-set 'foo)")
    expectThat(":foo/meela", shouldEvalTo: .Keyword(expected))
    expectThat("::meela", shouldEvalTo: .Keyword(expected))
    expectThat("(.keyword \"foo\" \"meela\")", shouldEvalTo: .Keyword(expected))
    expectThat("(.keyword 'foo/meela)", shouldEvalTo: .Keyword(expected))
    expectThat("(.keyword (.symbol \"foo\" \"meela\"))", shouldEvalTo: .Keyword(expected))
  }
}

/// Test behavior of the special *ns* symbol.
class TestNsSymbol : InterpreterTest {

  /// The *ns* symbol should resolve to the current namespace.
  func testCorrectNamespace() {
    XCTAssert(interpreter.currentNamespace.name == "user",
      "Current namespace expected to be 'user', but was '\(interpreter.currentNamespace.name)'")
    expectThat("*ns*", shouldEvalTo: .Namespace(interpreter.currentNamespace))
    runCode("(.ns-set 'foo)")
    XCTAssert(interpreter.currentNamespace.name == "foo",
      "Current namespace expected to be 'foo', but was '\(interpreter.currentNamespace.name)'")
    expectThat("core/*ns*", shouldEvalTo: .Namespace(interpreter.currentNamespace))
    runCode("(.ns-set 'bar)")
    XCTAssert(interpreter.currentNamespace.name == "bar",
      "Current namespace expected to be 'bar', but was '\(interpreter.currentNamespace.name)'")
    expectThat("core/*ns*", shouldEvalTo: .Namespace(interpreter.currentNamespace))
    runCode("(.ns-set 'user)")
    XCTAssert(interpreter.currentNamespace.name == "user",
      "Current namespace expected to be 'user', but was '\(interpreter.currentNamespace.name)'")
    expectThat("*ns*", shouldEvalTo: .Namespace(interpreter.currentNamespace))
  }

  /// The *ns* symbol should be unresolvable if the current namespace is deleted.
  func testDeletingCurrentNamespace() {
    runCode("(.ns-set 'foo)")
    XCTAssert(interpreter.currentNamespace.name == "foo",
      "Current namespace expected to be 'foo', but was '\(interpreter.currentNamespace.name)'")
    expectThat("core/*ns*", shouldEvalTo: .Namespace(interpreter.currentNamespace))
    // Delete namespace
    runCode("(.ns-remove 'foo)")
    expectThat("core/*ns*", shouldFailAs: .InvalidSymbolError)
  }
}

/// Test symbol resolution in the context of namespace support, including resolution of both qualified and unqualified
/// symbols.
class TestSymbolNamespacing : InterpreterTest {

  /// A var bound to an unqualified symbol should resolve locally using either the unqualified or qualified symbols.
  func testVarBoundToUnqualifiedSymbol() {
    expectThat("myVar", shouldFailAs: .InvalidSymbolError)
    runCode("(def myVar 12345)")
    expectThat("myVar", shouldEvalTo: 12345)
    expectThat("user/myVar", shouldEvalTo: 12345)
  }

  /// A var bound to a qualified symbol should resolve locally using either the unqualified or qualified symbols.
  func testVarBoundToQualifiedSymbol() {
    expectThat("myVar", shouldFailAs: .InvalidSymbolError)
    runCode("(def user/myVar 12345)")
    expectThat("myVar", shouldEvalTo: 12345)
    expectThat("user/myVar", shouldEvalTo: 12345)
  }

  /// A constructed qualified symbol should be able to refer to a var in a different namespace.
  func testConstructedQualifiedSymbol() {
    runCode("(.ns-set 'foo)")
    runCode("(def a 12345)")
    runCode("(.ns-set 'bar)")
    expectThat("foo/a", shouldEvalTo: 12345)
    expectThat("(.eval (.symbol \"foo\" \"a\"))", shouldEvalTo: 12345)
  }

  /// Symbols with the same name defined in different namespaces should be accessed properly from each namespace.
  func testSameNamedSymbols() {
    // Define in 'foo'
    runCode("(.ns-set 'foo)")
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    runCode("(def a 999)")
    expectThat("a", shouldEvalTo: 999)
    expectThat("foo/a", shouldEvalTo: 999)
    expectThat("bar/a", shouldFailAs: .InvalidSymbolError)
    expectThat("baz/a", shouldFailAs: .InvalidSymbolError)

    // Define in 'bar'
    runCode("(.ns-set 'bar)")
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    runCode("(def a 715)")
    expectThat("a", shouldEvalTo: 715)
    expectThat("foo/a", shouldEvalTo: 999)
    expectThat("bar/a", shouldEvalTo: 715)
    expectThat("baz/a", shouldFailAs: .InvalidSymbolError)

    // Define in 'baz'
    runCode("(.ns-set 'baz)")
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    runCode("(def a -1200)")
    expectThat("a", shouldEvalTo: -1200)
    expectThat("foo/a", shouldEvalTo: 999)
    expectThat("bar/a", shouldEvalTo: 715)
    expectThat("baz/a", shouldEvalTo: -1200)

    // Return to 'foo'
    runCode("(.ns-set 'foo)")
    expectThat("a", shouldEvalTo: 999)

    // Return to 'bar'
    runCode("(.ns-set 'bar)")
    expectThat("a", shouldEvalTo: 715)

    // Return to 'baz
    runCode("(.ns-set 'baz)")
    expectThat("a", shouldEvalTo: -1200)
  }
}

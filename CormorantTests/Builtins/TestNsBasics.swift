//
//  TestNsBasics.swift
//  Cormorant
//
//  Created by Austin Zheng on 3/31/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest
@testable import Cormorant

private extension Value {
  var asNamespace : NamespaceContext? {
    if case let .namespace(value) = self {
      return value
    }
    return nil
  }
}

/// Test the '.ns-create' built-in function.
class TestNsCreateBuiltin : InterpreterTest {

  /// .ns-create should return a new namespace if one doesn't exist.
  func testCreateNewNamespace() {
    let fooNamespace = run(input: "(.ns-create 'foo)")
    if let namespace = fooNamespace?.asNamespace {
      XCTAssert(namespace.name == "foo", ".ns-create did not create a namespace with the correct name")
    }
    else {
      XCTFail(".ns-create did not return a namespace object; instead, it returned: \(fooNamespace)")
    }
  }

  /// .ns-create should return an existing namespace if one does exist.
  func testReturnExistingNamespace() {
    let initial = run(input: "(.ns-set 'foo)")
    let another = run(input: "(.ns-create 'foo)")
    if let initial = initial?.asNamespace, another = another?.asNamespace {
      XCTAssert(initial === another, ".ns-create did not return an existing namespace when one existed")
    }
    else {
      XCTFail(".ns-set or .ns-create did not return the correct objects: ns-set: \(initial); ns-create: \(another)")
    }
  }

  /// .ns-create should not change the current namespace.
  func testCurrentNamespaceStatus() {
    if let initial = run(input: "*ns*")?.asNamespace {
      run(input: "(.ns-create 'foo)")
      let a1 = run(input: "core/*ns*")
      if let a1 = a1?.asNamespace {
        XCTAssert(initial === a1, "Namespace was changed after .ns-create was run to create foo")
      }
      else {
        XCTFail("*ns* failed to return namespace object: \(a1)")
      }
      run(input: "(.ns-create 'bar)")
      let b1 = run(input: "core/*ns*")
      if let b1 = b1?.asNamespace {
        XCTAssert(initial === b1, "Namespace was changed after .ns-create was run to create bar")
      }
      else {
        XCTFail("*ns* failed to return namespace object: \(b1)")
      }
    }
    else {
      XCTFail("Initial setup failed: *ns* failed to return a namespace object")
    }
  }

  /// .ns-create should only take symbol arguments.
  func testArgumentType() {
    expectInvalidArgumentErrorFrom("(.ns-create nil)")
    expectInvalidArgumentErrorFrom("(.ns-create true)")
    expectInvalidArgumentErrorFrom("(.ns-create false)")
    expectInvalidArgumentErrorFrom("(.ns-create 501)")
    expectInvalidArgumentErrorFrom("(.ns-create -6.9123)")
    expectInvalidArgumentErrorFrom("(.ns-create \"apple\")")
    expectInvalidArgumentErrorFrom("(.ns-create #\"[0-9]+\")")
    expectInvalidArgumentErrorFrom("(.ns-create :apple)")
    expectInvalidArgumentErrorFrom("(.ns-create \\x)")
    expectInvalidArgumentErrorFrom("(.ns-create core/*ns*)")
    expectInvalidArgumentErrorFrom("(.ns-create ())")
    expectInvalidArgumentErrorFrom("(.ns-create [])")
    expectInvalidArgumentErrorFrom("(.ns-create {})")
    expectInvalidArgumentErrorFrom("(.ns-create .ns-set)")
  }

  /// .ns-create should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.ns-create)")
    expectArityErrorFrom("(.ns-create 'foo 'bar)")
  }
}

/// Test the '.ns-set' built-in function.
class TestNsSetBuiltin : InterpreterTest {

  /// .ns-set should return a new namespace if one doesn't exist.
  func testCreateNewNamespace() {
    let fooNamespace = run(input: "(.ns-set 'foo)")
    if let namespace = fooNamespace?.asNamespace {
      XCTAssert(namespace.name == "foo", ".ns-set did not create a namespace with the correct name")
    }
    else {
      XCTFail(".ns-set did not return a namespace object; instead, it returned: \(fooNamespace)")
    }
  }

  /// .ns-set should return an existing namespace if one does exist.
  func testReturnExistingNamespace() {
    let initial = run(input: "(.ns-create 'foo)")
    let another = run(input: "(.ns-set 'foo)")
    if let initial = initial?.asNamespace, another = another?.asNamespace {
      XCTAssert(initial === another, ".ns-set did not return an existing namespace when one existed")
    }
    else {
      XCTFail(".ns-set or .ns-create did not return the correct objects: ns-create: \(initial); ns-set: \(another)")
    }
  }

  /// .ns-set should change the current namespace.
  func testCurrentNamespaceStatus() {
    if run(input: "*ns*")?.asNamespace != nil {
      let a = run(input: "(.ns-set 'foo)")
      let a1 = run(input: "core/*ns*")
      if let a = a?.asNamespace, a1 = a1?.asNamespace {
        XCTAssert(a === a1, "Namespace created by .ns-set (foo) should now be set as current namespace")
      }
      else {
        XCTFail(".ns-set or *ns* failed to return namespace objects: .ns-set: \(a); *ns*: \(a1)")
      }
      let b = run(input: "(.ns-set 'bar)")
      let b1 = run(input: "core/*ns*")
      if let b = b?.asNamespace, b1 = b1?.asNamespace {
        XCTAssert(b === b1, "Namespace created by .ns-set (bar) should now be set as current namespace")
      }
      else {
        XCTFail(".ns-set or *ns* failed to return namespace objects: .ns-set: \(a); *ns*: \(a1)")
      }
    }
    else {
      XCTFail("Initial setup failed: *ns* failed to return a namespace object")
    }
  }

  /// .ns-set should disallow changing to a system namespace.
  func testChangingToSystemNamespace() {
    expectThat("(.ns-set 'core)", shouldFailAs: .ReservedNamespaceError)
  }

  /// .ns-set should only take symbol arguments.
  func testArgumentType() {
    expectInvalidArgumentErrorFrom("(.ns-set nil)")
    expectInvalidArgumentErrorFrom("(.ns-set true)")
    expectInvalidArgumentErrorFrom("(.ns-set false)")
    expectInvalidArgumentErrorFrom("(.ns-set 501)")
    expectInvalidArgumentErrorFrom("(.ns-set -6.9123)")
    expectInvalidArgumentErrorFrom("(.ns-set \"apple\")")
    expectInvalidArgumentErrorFrom("(.ns-set #\"[0-9]+\")")
    expectInvalidArgumentErrorFrom("(.ns-set :apple)")
    expectInvalidArgumentErrorFrom("(.ns-set \\x)")
    expectInvalidArgumentErrorFrom("(.ns-set core/*ns*)")
    expectInvalidArgumentErrorFrom("(.ns-set ())")
    expectInvalidArgumentErrorFrom("(.ns-set [])")
    expectInvalidArgumentErrorFrom("(.ns-set {})")
    expectInvalidArgumentErrorFrom("(.ns-set .ns-set)")
  }

  /// .ns-set should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.ns-set)")
    expectArityErrorFrom("(.ns-set 'foo 'bar)")
  }
}

/// Test the '.ns-get' built-in function.
class TestNsGetBuiltin : InterpreterTest {

  /// .ns-get should return a namespace given a symbol naming it.
  func testNamespaceForSymbol() {
    run(input: "(.ns-create 'foo)")
    if let namespace = run(input: "(.ns-get 'foo)")?.asNamespace {
      XCTAssert(namespace.name == "foo", ".ns-get failed to return the proper namespace given a symbol: \(namespace)")
    }
    else {
      XCTFail(".ns-get failed to get a namespace")
    }
  }

  /// .ns-get should return a namespace verbatim.
  func testNamespaceForNamespace() {
    if let namespace = run(input: "(.ns-get (.ns-create 'foo))")?.asNamespace {
      XCTAssert(namespace.name == "foo", ".ns-get failed to return the same namespace given a namespace")
    }
    else {
      XCTFail(".ns-get or .ns-create failed")
    }
  }

  /// .ns-get should reject name symbols that don't correspond to namespaces.
  func testInvalidNamespaceName() {
    expectThat("(.ns-get 'asdakdjlakd)", shouldFailAs: EvalError.EvalErrorType.InvalidNamespaceError)
  }

  /// .ns-get should return the namespace given a namespace, even if the namespace has been removed, but should not get
  /// the namespace given a symbol.
  func testGettingNamespaceAfterRemoval() {
    run(input: "(def a (.ns-create 'foo))")
    if let initial = run(input: "a")?.asNamespace {
      // Remove the 'foo namespace
      run(input: "(.ns-remove 'foo)")
      // Name symbol should not resolve.
      expectThat("(.ns-get 'foo)", shouldFailAs: EvalError.EvalErrorType.InvalidNamespaceError)
      // The namespace itself should resolve.
      if let namespace = run(input: "(.ns-get a)")?.asNamespace {
        XCTAssert(initial === namespace, ".ns-get didn't return the proper namespace given a namespace")
      }
      else {
        XCTFail(".ns-get wasn't able to return a namespace given that namespace, even after the namespace was removed")
      }
    }
    else {
      XCTFail("Initial setup failed: .ns-create failed to return a namespace")
    }
  }

  /// .ns-set should only take symbol or namespace arguments.
  func testArgumentType() {
    expectInvalidArgumentErrorFrom("(.ns-get nil)")
    expectInvalidArgumentErrorFrom("(.ns-get true)")
    expectInvalidArgumentErrorFrom("(.ns-get false)")
    expectInvalidArgumentErrorFrom("(.ns-get 501)")
    expectInvalidArgumentErrorFrom("(.ns-get -6.9123)")
    expectInvalidArgumentErrorFrom("(.ns-get \"apple\")")
    expectInvalidArgumentErrorFrom("(.ns-get #\"[0-9]+\")")
    expectInvalidArgumentErrorFrom("(.ns-get :apple)")
    expectInvalidArgumentErrorFrom("(.ns-get \\x)")
    expectInvalidArgumentErrorFrom("(.ns-get ())")
    expectInvalidArgumentErrorFrom("(.ns-get [])")
    expectInvalidArgumentErrorFrom("(.ns-get {})")
    expectInvalidArgumentErrorFrom("(.ns-get .ns-get)")
  }

  /// .ns-get should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.ns-get)")
    expectArityErrorFrom("(.ns-get 'user 'user)")
  }
}

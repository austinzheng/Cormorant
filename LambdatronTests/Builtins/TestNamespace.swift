//
//  TestNamespace.swift
//  Lambdatron
//
//  Created by Austin Zheng on 3/30/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the '.namespace' built-in function.
class TestNamespaceBuiltin : InterpreterTest {

  /// .namespace should return nil for unqualified symbols.
  func testUnqualifiedSymbols() {
    expectThat("(.namespace 'a)", shouldEvalTo: .nilValue)
    expectThat("(.namespace 'fooooooooooo)", shouldEvalTo: .nilValue)
  }

  /// .namespace should return the namespace as a string for qualified symbols.
  func testQualifiedSymbols() {
    expectThat("(.namespace 'user/a)", shouldEvalTo: .string("user"))
    expectThat("(.namespace 'foo/bar/baz)", shouldEvalTo: .string("foo"))
  }

  /// .namespace should return nil for unqualified keywords.
  func testUnqualifiedKeywords() {
    expectThat("(.namespace :a)", shouldEvalTo: .nilValue)
    expectThat("(.namespace :fooooooooooo)", shouldEvalTo: .nilValue)
  }

  /// .namespace should return the namespace as a string for qualified keywords.
  func testQualifiedKeywords() {
    expectThat("(.namespace :user/a)", shouldEvalTo: .string("user"))
    expectThat("(.namespace :foo/bar/baz)", shouldEvalTo: .string("foo"))
  }

  /// .namespace should reject 
  func testInvalidArguments() {
    expectInvalidArgumentErrorFrom("(.namespace nil)")
    expectInvalidArgumentErrorFrom("(.namespace true)")
    expectInvalidArgumentErrorFrom("(.namespace false)")
    expectInvalidArgumentErrorFrom("(.namespace 152)")
    expectInvalidArgumentErrorFrom("(.namespace -0.3123)")
    expectInvalidArgumentErrorFrom("(.namespace \"hello\")")
    expectInvalidArgumentErrorFrom("(.namespace #\"[0-9]+\")")
    expectInvalidArgumentErrorFrom("(.namespace \\c)")
    expectInvalidArgumentErrorFrom("(.namespace ())")
    expectInvalidArgumentErrorFrom("(.namespace [])")
    expectInvalidArgumentErrorFrom("(.namespace {})")
    expectInvalidArgumentErrorFrom("(.namespace .namespace)")
  }

  /// .namespace should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.namespace)")
    expectArityErrorFrom("(.namespace 'foo 'bar)")
  }
}

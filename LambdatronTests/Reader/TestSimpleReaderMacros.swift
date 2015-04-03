//
//  TestSimpleReaderMacros.swift
//  Lambdatron
//
//  Created by Austin Zheng on 4/2/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the var (#') reader macro.
class TestVarReaderMacro : InterpreterTest {

  /// The var reader macro should properly expand against a simple symbol.
  func testWithSymbol() {
    expect("#'a", shouldExpandTo: "(var a)")
  }

  /// The var reader macro should properly expand against a list.
  func testWithList() {
    expect("#'(a b c d)", shouldExpandTo: "(var (a b c d))")
  }

  /// The var reader macro should properly expand against the var macro.
  func testWithVarMacro() {
    expect("#'#'a", shouldExpandTo: "(var (var a))")
  }

  /// The var reader macro should properly expand against the deref macro.
  func testWithDerefMacro() {
    expect("#'@a", shouldExpandTo: "(var (.deref a))")
  }
}

/// Test the deref (@) reader macro.
class TestDerefReaderMacro : InterpreterTest {

  /// The deref reader macro should properly expand against a simple symbol.
  func testWithSymbol() {
    expect("@a", shouldExpandTo: "(.deref a)")
  }

  /// The deref reader macro should properly expand against a list.
  func testWithList() {
    expect("@(a b c d)", shouldExpandTo: "(.deref (a b c d))")
  }

  /// The deref reader macro should properly expand against the var macro.
  func testWithVarMacro() {
    expect("@#'a", shouldExpandTo: "(.deref (var a))")
  }

  /// The deref reader macro should properly expand against the deref macro.
  func testWithDerefMacro() {
    expect("@@a", shouldExpandTo: "(.deref (.deref a))")
  }
}

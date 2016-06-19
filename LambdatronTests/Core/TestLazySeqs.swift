//
//  TestLazySeqs.swift
//  Lambdatron
//
//  Created by Austin Zheng on 3/21/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest
@testable import Lambdatron

class TestLazySeqs : InterpreterTest {
  let evalFailMessage = "Code execution failed with an evaluation error"

  /// A lazy sequence should not be evaluated when assigned to a let binding.
  func testAssignmentToBinding() {
    run(input: "(let [a (.lazy-seq (fn [] (.print \"bad\") [0]))] a)")
    expectOutputBuffer(toBe: "")
  }

  /// A lazy sequence should not be evaluated when assigned to a function param.
  func testAssignmentAsParam() {
    run(input: "(def myfn (fn [arg1] arg1))")
    run(input: "(myfn (.lazy-seq (fn [] (.print \"bad\") [0])))")
    expectEmptyOutputBuffer()
  }

  /// A lazy sequence should not be evaluated when assigned to a var.
  func testAssignmentToVar() {
    run(input: "(def a (.lazy-seq (fn [] (.print \"bad\") [0])))")
    expectEmptyOutputBuffer()
  }

  /// A lazy sequence should not be evaluated when returned from a function.
  func testReturningLazySeq() {
    run(input: "(def myfn (fn [arg1] arg1))")
    run(input: "(def z (.lazy-seq (fn [] (.print \"bad\") [0])))")
    expectEmptyOutputBuffer()
  }

  /// A lazy sequence should be evaluated when it is described.
  func testDescribingLazySeq() {
    run(input: "(def a (.lazy-seq (fn [] (.print \"evaluated thunk \") [0 1 2])))")
    expectEmptyOutputBuffer()
    run(input: "(.print a)")
    expectOutputBuffer(toBe: "evaluated thunk (0 1 2)")
  }

  /// A lazy sequence that forms the 'rest' of a list should not be evaluated when '.rest' is called.
  func testLazySeqAsRest() {
    if let value = run(input: "(.rest (.cons 1 (.lazy-seq (fn [] (.print \"evaluated thunk\") '(2 3 4 5)))))")?.asSeq {
      expectEmptyOutputBuffer()
      expect(list: value, toMatch: [2, 3, 4, 5])
      expectOutputBuffer(toBe: "evaluated thunk")
    }
  }

  /// A lazy sequence that forms the 'rest' of a list should be evaluated when '.next' is called.
  func testLazySeqAsNext() {
    if let value = run(input: "(.next (.cons 1 (.lazy-seq (fn [] (.print \"evaluated thunk\") '(2 3 4 5)))))")?.asSeq {
      expectOutputBuffer(toBe: "evaluated thunk")
      clearOutputBuffer()
      expect(list: value, toMatch: [2, 3, 4, 5])
      expectEmptyOutputBuffer()
    }
  }

  /// A lazy sequence passed into '.seq' should be forced.
  func testForcingThroughSeq() {
    run(input: "(def a (.lazy-seq (fn [] (.print \"evaluated thunk\") [0 1 2])))")
    expectEmptyOutputBuffer()
    // Now run through seq
    if let value = run(input: "(.seq a)") {
      expectOutputBuffer(toBe: "evaluated thunk")
      expect(list: value.asSeq!, toMatch: [0, 1, 2])
    }
  }
}

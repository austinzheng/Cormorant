//
//  InterpreterTest.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/16/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest
// Importing this to more easily see the public interface.
import Lambdatron

extension ObjectResult {
  func force() -> ConsValue {
    switch self {
    case let .Success(v): return v
    case .Error: fatalError("ObjectResult's 'force' method used improperly")
    }
  }
}

let EmptyNode = Empty()

/// Convenience function: given a bunch of ConsValues, return a list.
func listWithItems(items: ConsValue...) -> ConsValue {
  return .Seq(items.count == 0 ? Empty() : ContiguousList(items))
}

/// Convenience functions: given a bunch of ConsValues, return a vector.
func vectorWithItems(items: ConsValue...) -> ConsValue {
  return .Vector(items)
}

/// Convenience function: given a bunch of ConsValue key-value pairs, return a map.
func mapWithItems(items: (ConsValue, ConsValue)...) -> ConsValue {
  if items.count == 0 {
    return .Map([:])
  }
  var buffer : MapType = [:]
  for (key, value) in items {
    buffer[key] = value
  }
  return .Map(buffer)
}

/// An abstract superclass intended for various interpreter tests.
class InterpreterTest : XCTestCase {
  var interpreter = Interpreter()

  func keyword(name: String, namespace: String? = nil) -> InternedKeyword {
    return InternedKeyword(name, namespace: namespace, ivs: interpreter.internStore)
  }

  func symbol(name: String, namespace: String? = nil) -> InternedSymbol {
    return InternedSymbol(name, namespace: namespace, ivs: interpreter.internStore)
  }

  override func setUp() {
    super.setUp()
    interpreter.reset()
    clearOutputBuffer()
    interpreter.writeOutput = writeToBuffer
  }

  override func tearDown() {
    super.tearDown()
    // Reset the interpreter
    clearOutputBuffer()
    interpreter.writeOutput = print
  }

  // Run some input, expecting no errors.
  func runCode(input: String) -> ConsValue? {
    let result = interpreter.evaluate(input)
    switch result {
    case let .Success(s):
      return s
    case let .ReadFailure(err):
      XCTFail("runCode did not successfully evaluate the input \"\(input)\"; read error: \(err.description)")
    case let .EvalFailure(err):
      XCTFail("runCode did not successfully evaluate the input \"\(input)\"; eval error: \(err.description)")
    }
    return nil
  }

  /// Given an input string, evaluate it and compare the output to an expected ConsValue output.
  func expectThat(input: String, shouldEvalTo expected: ConsValue) {
    let result = interpreter.evaluate(input)
    switch result {
    case let .Success(actual):
      XCTAssert(expected == actual, "expected: \(expected), got: \(actual)")
    case let .ReadFailure(f):
      XCTFail("read error: \(f.description)")
    case let .EvalFailure(f):
      XCTFail("evaluation error: \(f.description)")
    }
  }

  /// Given an input string, evaluate it and expect a seq. Then compare the items in the seq to a given set of items.
  /// This test does not check the order of items, only that they all appear exactly once.
  func expectThat(input: String, shouldEvalToContain item: ConsValue, _ expected: ConsValue...) {
    // Put the items in a set
    let expectedItems : Set<ConsValue> = Set(expected + [item])

    let result = interpreter.evaluate(input)
    switch result {
    case let .Success(actual):
      if let actual = actual.asSeq {
        var actualItems = Set<ConsValue>()
        for item in SeqIterator(actual) {
          actualItems.insert(item.force())
        }
        XCTAssert(expectedItems == actualItems, "actual and expected items didn't match:\nexpected \(expectedItems)\ngot \(actualItems)")
      }
      else {
        XCTFail("expected a sequence from expectThat:shouldEvalToContain:, got \(actual)")
      }
    case let .ReadFailure(f):
      XCTFail("read error: \(f.description)")
    case let .EvalFailure(f):
      XCTFail("evaluation error: \(f.description)")
    }
  }

  /// Given an input string and a string describing an expected form, evaluate both and compare for equality.
  func expectThat(input: String, shouldEvalTo form: String) {
    // Evaluate the test form first
    let actual = interpreter.evaluate(input)
    switch actual {
    case let .Success(actual):
      // Then evaluate the reference form
      let expected = interpreter.evaluate(form)
      switch expected {
      case let .Success(expected):
        XCTAssert(expected == actual, "expected: \(expected), got: \(actual)")
      default:
        XCTFail("reference form failed to evaluate successfully; this is a problem with the unit test")
      }
    case let .ReadFailure(f):
      XCTFail("read error: \(f.description)")
    case let .EvalFailure(f):
      XCTFail("evaluation error: \(f.description)")
    }
  }

  /// Given an input string, evaluate it and expect a particular read failure.
  func expectThat(input: String, shouldFailAs expected: ReadError.ErrorType) {
    let result = interpreter.evaluate(input)
    switch result {
    case let .Success(s):
      XCTFail("evaluation unexpectedly succeeded; result: \(s.description)")
    case let .ReadFailure(actual):
      let expectedName = expected.rawValue
      let actualName = actual.error.rawValue
      XCTAssert(expected == actual.error, "expected: \(expectedName), got: \(actualName)")
    case let .EvalFailure(err):
      XCTFail("unexpected evaluation error: \(err.description)")
    }
  }

  /// Given an input string, evaluate it and expect a particular evaluation failure.
  func expectThat(input: String, shouldFailAs expected: EvalError.ErrorType) {
    let result = interpreter.evaluate(input)
    switch result {
    case let .Success(s):
      XCTFail("evaluation unexpectedly succeeded; result: \(s.description)")
    case let .ReadFailure(err):
      XCTFail("unexpected read error: \(err.description)")
    case let .EvalFailure(actual):
      let expectedName = expected.rawValue
      let actualName = actual.error.rawValue
      XCTAssert(expected == actual.error, "expected: \(expectedName), got: \(actualName)")
    }
  }

  /// Given an input string, evaluate it and expect an invalid argument error.
  func expectInvalidArgumentErrorFrom(input: String) {
    expectThat(input, shouldFailAs: .InvalidArgumentError)
  }

  /// Given an input string, evaluate it and expect an arity error.
  func expectArityErrorFrom(input: String) {
    expectThat(input, shouldFailAs: .ArityError)
  }

  // Buffer functionality
  /// A buffer capturing output from the interpreter.
  var outputBuffer : String = ""

  /// Clear the output buffer.
  func clearOutputBuffer() {
    outputBuffer = ""
  }

  /// Write to the output buffer. Intended to be passed to the interpreter for use in testing println and side effects.
  func writeToBuffer(item: String) {
    outputBuffer += item
  }

  /// Compare an input string to the contents of the output buffer.
  func expectOutputBuffer(toBe expected: String) {
    XCTAssert(outputBuffer == expected, "expected: \(expected), got: \(outputBuffer)")
  }

  /// Test whether the output buffer is empty or not.
  func expectEmptyOutputBuffer() {
    XCTAssert(outputBuffer.isEmpty, "Output buffer was not empty; got: \(outputBuffer)")
  }

  /// Test whether or not a ListType matches the items in a collection.
  func expectList<T : SequenceType where T.Generator.Element == ConsValue>(list: SeqType, toMatch match: T) {
    var listGenerator = SeqIterator(list).generate()
    var matchGenerator = match.generate()

    while true {
      let thisListItem = listGenerator.next()
      let thisMatchItem = matchGenerator.next()
      if thisMatchItem == nil && thisListItem == nil {
        // Reached the end of the lists, and both match
        return
      }
      else if thisMatchItem == nil || thisListItem == nil {
        // Reached the end of only one of the lists; length mismatch
        XCTFail("List did not match expected collection \(match); length mismatch")
        return
      }
      switch thisListItem! {
      case let .Success(value):
        if value != thisMatchItem! {
          XCTFail("Item mismatch: expected: \(thisMatchItem!), got: \(value)")
          return
        }
        continue
      case let .Error(err):
        XCTFail("Evaluation error while iterating through list: \(err.description)")
        return
      }
    }
  }
}

//
//  TestDescribing.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/23/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest
@testable import Lambdatron

class TestDescribing : InterpreterTest {

  /// Build and return an array of raw strings from the 'rawstrings.txt' file.
  lazy var rawStrings : [String] = {
    let filename = "/rawstrings.txt"
    let resourcePath = Bundle(for: self.dynamicType).resourcePath
    if let resourcePath = resourcePath {
      let finalName = resourcePath + filename
      let strs = try? NSString(contentsOfFile: finalName, encoding: String.Encoding.utf8.rawValue)
      if let strs = strs as? String {
        return strs.characters.split(maxSplits: Int.max, omittingEmptySubsequences: true) { $0 == "\n" }.map { String($0) }
      }
    }
    fatalError("ERROR! Could not load strings from test support file \(filename)")
  }()

  /// Return the raw string corresponding to the (1-based) line number of the 'rawstrings.txt' file.
  func rawString(for line: Int) -> String {
    return rawStrings[line-1]
  }

  /// Given an input string, evaluate it and compare the description of the output to an expected string.
  func expectThat(_ input: String, shouldBeDescribedAs expected: String) {
    let result = interpreter.evaluate(form: input)
    switch result {
    case let .Success(raw):
      let actual = interpreter.describe(form: raw).rawStringValue
      XCTAssert(expected == actual, "expected: \(expected), got: \(actual)")
    case let .ReadFailure(f):
      XCTFail("read error: \(f.description)")
    case let .EvalFailure(f):
      XCTFail("evaluation error: \(f.description)")
    }
  }

  func testDescribingNil() {
    expectThat("nil", shouldBeDescribedAs: "nil")
  }

  func testDescribingInts() {
    expectThat("152312421", shouldBeDescribedAs: "152312421")
  }

  func testDescribingFloats() {
    expectThat("-3821.569991", shouldBeDescribedAs: "-3821.569991")
  }

  func testDescribingBools() {
    expectThat("true", shouldBeDescribedAs: "true")
    expectThat("false", shouldBeDescribedAs: "false")
  }

  /// All characters should be described using the backslash literal notation, except for the named characters.
  func testDescribingChars() {
    expectThat("\\a", shouldBeDescribedAs: "\\a")
    expectThat("\\n", shouldBeDescribedAs: "\\n")
    expectThat("\\\\", shouldBeDescribedAs: "\\\\")
    expectThat("\\tab", shouldBeDescribedAs: "\\tab")
    expectThat("\\space", shouldBeDescribedAs: "\\space")
    expectThat("\\newline", shouldBeDescribedAs: "\\newline")
    expectThat("\\return", shouldBeDescribedAs: "\\return")
    expectThat("\\backspace", shouldBeDescribedAs: "\\backspace")
    expectThat("\\formfeed", shouldBeDescribedAs: "\\formfeed")
  }

  func testDescribingSymbols() {
    expectThat("'a", shouldBeDescribedAs: "a")
    expectThat("'theQuickBrownFox", shouldBeDescribedAs: "theQuickBrownFox")
  }

  func testDescribingKeywords() {
    expectThat(":b", shouldBeDescribedAs: ":b")
    expectThat(":thisIsALongKeyword", shouldBeDescribedAs: ":thisIsALongKeyword")
  }

  func testDescribingEmptyStr() {
    let empty = rawString(for: 1)
    expectThat(empty, shouldBeDescribedAs: empty)
  }

  func testDescribingBasicStr() {
    let oneSpace = rawString(for: 2)
    expectThat(oneSpace, shouldBeDescribedAs: oneSpace)
    let helloWorld = rawString(for: 3)
    expectThat(helloWorld, shouldBeDescribedAs: helloWorld)
  }

  func testDescribingStrWithEscapes() {
    let escapedHelloWorld = rawString(for: 4)
    expectThat(escapedHelloWorld, shouldBeDescribedAs: escapedHelloWorld)
    let escapedGoodbye = rawString(for: 5)
    expectThat(escapedGoodbye, shouldBeDescribedAs: escapedGoodbye)
  }

  func testDescribingBasicList() {
    expectThat("()", shouldBeDescribedAs: "()")
    let basicInput = rawString(for: 6)
    let basicOutput = rawString(for: 7)
    expectThat(basicInput, shouldBeDescribedAs: basicOutput)
  }

  func testDescribingListWithEscapes() {
    let escapedInput = rawString(for: 8)
    let escapedOutput = rawString(for: 9)
    expectThat(escapedInput, shouldBeDescribedAs: escapedOutput)
  }

  func testDescribingVector() {
    expectThat("[]", shouldBeDescribedAs: "[]")
    let vectorInput = rawString(for: 10)
    let vectorOutput = rawString(for: 11)
    expectThat(vectorInput, shouldBeDescribedAs: vectorOutput)
  }

  func testDescribingRegex() {
    let regex = rawString(for: 12)
    expectThat(regex, shouldBeDescribedAs: regex)
  }

  // TODO: (az) re-enable when this test can be rewritten in a less fragile form
//  func testDescribingMap() {
//    expectThat("{}", shouldBeDescribedAs: "{}")
//    let mapInput = rawStringForLine(13)
//    let mapOutput = rawStringForLine(14)
//    expectThat(mapInput, shouldBeDescribedAs: mapOutput)
//  }
}

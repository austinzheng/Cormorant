//
//  TestDescribing.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/23/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest

class TestDescribing : InterpreterTest {

  /// Build and return an array of raw strings from the 'rawstrings.txt' file.
  lazy var rawStrings : [String] = {
    let filename = "/rawstrings.txt"
    let resourcePath = NSBundle(forClass: self.dynamicType).resourcePath
    if let resourcePath = resourcePath {
      let finalName = resourcePath + filename
      let strs = NSString(contentsOfFile: finalName, encoding: NSUTF8StringEncoding, error: nil)
      if let strs = strs as? String {
        return split(strs, { $0 == "\n" }, maxSplit: Int.max, allowEmptySlices: false)
      }
    }
    fatalError("ERROR! Could not load strings from test support file \(filename)")
  }()

  /// Return the raw string corresponding to the (1-based) line number of the 'rawstrings.txt' file.
  func rawStringForLine(line: Int) -> String {
    return rawStrings[line-1]
  }

  /// Given an input string, evaluate it and compare the description of the output to an expected string.
  func expectThat(input: String, shouldBeDescribedAs expected: String) {
    let result = interpreter.evaluate(input)
    switch result {
    case let .Success(raw):
      let actual = interpreter.describe(raw).asString
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
    let empty = rawStringForLine(1)
    expectThat(empty, shouldBeDescribedAs: empty)
  }

  func testDescribingBasicStr() {
    let oneSpace = rawStringForLine(2)
    expectThat(oneSpace, shouldBeDescribedAs: oneSpace)
    let helloWorld = rawStringForLine(3)
    expectThat(helloWorld, shouldBeDescribedAs: helloWorld)
  }

  func testDescribingStrWithEscapes() {
    let escapedHelloWorld = rawStringForLine(4)
    expectThat(escapedHelloWorld, shouldBeDescribedAs: escapedHelloWorld)
    let escapedGoodbye = rawStringForLine(5)
    expectThat(escapedGoodbye, shouldBeDescribedAs: escapedGoodbye)
  }

  func testDescribingBasicList() {
    expectThat("()", shouldBeDescribedAs: "()")
    let basicInput = rawStringForLine(6)
    let basicOutput = rawStringForLine(7)
    expectThat(basicInput, shouldBeDescribedAs: basicOutput)
  }

  func testDescribingListWithEscapes() {
    let escapedInput = rawStringForLine(8)
    let escapedOutput = rawStringForLine(9)
    expectThat(escapedInput, shouldBeDescribedAs: escapedOutput)
  }

  func testDescribingVector() {
    expectThat("[]", shouldBeDescribedAs: "[]")
    let vectorInput = rawStringForLine(10)
    let vectorOutput = rawStringForLine(11)
    expectThat(vectorInput, shouldBeDescribedAs: vectorOutput)
  }

  func testDescribingRegex() {
    let regex = rawStringForLine(12)
    expectThat(regex, shouldBeDescribedAs: regex)
  }

  func testDescribingMap() {
    expectThat("{}", shouldBeDescribedAs: "{}")
    let mapInput = rawStringForLine(13)
    let mapOutput = rawStringForLine(14)
    expectThat(mapInput, shouldBeDescribedAs: mapOutput)
  }
}

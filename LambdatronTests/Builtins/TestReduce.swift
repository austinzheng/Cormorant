//
//  TestReduce.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/12/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the '.reduce' built-in function.
class TestReduceBuiltin : InterpreterTest {

  /// .reduce called on nil with no initial value should call the provided function with no arguments.
  func testNoValNil() {
    runCode("(def tf (fn [] (.print \"done!\") 12345))")
    expectThat("(.reduce tf nil)", shouldEvalTo: .IntAtom(12345))
    expectOutputBuffer(toBe: "done!")
  }

  /// .reduce called on an empty string with no initial value should call the provided function with no arguments.
  func testNoValEmptyString() {
    runCode("(def tf (fn [] (.print \"done!\") 12345))")
    expectThat("(.reduce tf \"\")", shouldEvalTo: .IntAtom(12345))
    expectOutputBuffer(toBe: "done!")
  }

  /// .reduce called on an empty list with no initial value should call the provided function with no arguments.
  func testNoValEmptyList() {
    runCode("(def tf (fn [] (.print \"done!\") 12345))")
    expectThat("(.reduce tf ())", shouldEvalTo: .IntAtom(12345))
    expectOutputBuffer(toBe: "done!")
  }

  /// .reduce called on an empty vector with no initial value should call the provided function with no arguments.
  func testNoValEmptyVector() {
    runCode("(def tf (fn [] (.print \"done!\") 12345))")
    expectThat("(.reduce tf [])", shouldEvalTo: .IntAtom(12345))
    expectOutputBuffer(toBe: "done!")
  }

  /// .reduce called on an empty map with no initial value should call the provided function with no arguments.
  func testNoValEmptyMap() {
    runCode("(def tf (fn [] (.print \"done!\") 12345))")
    expectThat("(.reduce tf {})", shouldEvalTo: .IntAtom(12345))
    expectOutputBuffer(toBe: "done!")
  }

  /// .reduce called on a one-character string with no initial value should return the item without calling the fn.
  func testNoValOneItemString() {
    runCode("(def tf (fn [] (.print \"done!\") nil))")
    expectThat("(.reduce tf \"b\")", shouldEvalTo: .CharAtom("b"))
    expectOutputBuffer(toBe: "")
  }

  /// .reduce called on a one-item list with no initial value should return the item without calling the fn.
  func testNoValOneItemList() {
    runCode("(def tf (fn [] (.print \"done!\") nil))")
    expectThat("(.reduce tf '(\"foobar\"))", shouldEvalTo: .StringAtom("foobar"))
    expectOutputBuffer(toBe: "")
  }

  /// .reduce called on a one-item vector with no initial value should return the item without calling the fn.
  func testNoValOneItemVector() {
    runCode("(def tf (fn [] (.print \"done!\") nil))")
    expectThat("(.reduce tf [\"foobar\"])", shouldEvalTo: .StringAtom("foobar"))
    expectOutputBuffer(toBe: "")
  }

  /// .reduce called on a one-item map with no initial value should return the item without calling the fn.
  func testNoValOneItemMap() {
    runCode("(def tf (fn [] (.print \"done!\") nil))")
    expectThat("(.reduce tf {\"foo\" \"bar\"})", shouldEvalTo: vectorWithItems(.StringAtom("foo"), .StringAtom("bar")))
    expectOutputBuffer(toBe: "")
  }

  /// .reduce called on a string with no initial values should properly reduce.
  func testNoValMultiItemString() {
    runCode("(def tf (fn [a b] (.print \"a:\" a \"b:\" b) (.+ (.int a) (.int b))))")
    expectThat("(.reduce tf \"foobar\")", shouldEvalTo: .IntAtom(633))
    expectOutputBuffer(toBe: "a: \\f b: \\oa: 213 b: \\oa: 324 b: \\ba: 422 b: \\aa: 519 b: \\r")
  }

  /// .reduce called on a list with no initial values should properly reduce.
  func testNoValMultiItemList() {
    runCode("(def tf (fn [a b] (.print \"a:\" a \"b:\" b) (.+ a b)))")
    expectThat("(.reduce tf '(1 3 8 10 14))", shouldEvalTo: .IntAtom(36))
    expectOutputBuffer(toBe: "a: 1 b: 3a: 4 b: 8a: 12 b: 10a: 22 b: 14")
  }

  /// .reduce called on a list with no initial values should properly reduce.
  func testNoValMultiItemVector() {
    runCode("(def tf (fn [a b] (.print \"a:\" a \"b:\" b) (.+ a b)))")
    expectThat("(.reduce tf [1 3 8 10 14])", shouldEvalTo: .IntAtom(36))
    expectOutputBuffer(toBe: "a: 1 b: 3a: 4 b: 8a: 12 b: 10a: 22 b: 14")
  }

  /// .reduce called on a list with no initial values should properly reduce.
  func testNoValMultiItemMap() {
    let a = interpreter.context.keywordForName("a")
    let b = interpreter.context.keywordForName("b")
    let c = interpreter.context.keywordForName("c")
    let d = interpreter.context.keywordForName("d")
    runCode("(def tf (fn [a b] (.print \"a:\" a \"b:\" b) (.concat a b)))")
    expectThat("(.reduce tf {:a 1 :b 2 :c 3 :d 4})", shouldEvalTo: listWithItems(
      .Keyword(b), .IntAtom(2), .Keyword(c), .IntAtom(3), .Keyword(a), .IntAtom(1), .Keyword(d), .IntAtom(4)))
    expectOutputBuffer(toBe: "a: [:b 2] b: [:c 3]a: (:b 2 :c 3) b: [:a 1]a: (:b 2 :c 3 :a 1) b: [:d 4]")
  }

  /// .reduce called on nil with an initial value should return the value without calling the fn.
  func testWithValOnNil() {
    runCode("(def tf (fn [] (.print \"done!\") nil))")
    expectThat("(.reduce tf 98765 nil)", shouldEvalTo: .IntAtom(98765))
    expectOutputBuffer(toBe: "")
  }

  /// .reduce called on an empty string with an initial value should return the value without calling the fn.
  func testWithValOnEmptyString() {
    runCode("(def tf (fn [] (.print \"done!\") nil))")
    expectThat("(.reduce tf 98765 \"\")", shouldEvalTo: .IntAtom(98765))
    expectOutputBuffer(toBe: "")
  }

  /// .reduce called on an empty list with an initial value should return the value without calling the fn.
  func testWithValOnEmptyList() {
    runCode("(def tf (fn [] (.print \"done!\") nil))")
    expectThat("(.reduce tf 98765 ())", shouldEvalTo: .IntAtom(98765))
    expectOutputBuffer(toBe: "")
  }

  /// .reduce called on an empty vector with an initial value should return the value without calling the fn.
  func testWithValOnEmptyVector() {
    runCode("(def tf (fn [] (.print \"done!\") nil))")
    expectThat("(.reduce tf 98765 [])", shouldEvalTo: .IntAtom(98765))
    expectOutputBuffer(toBe: "")
  }

  /// .reduce called on an empty map with an initial value should return the value without calling the fn.
  func testWithValOnEmptyMap() {
    runCode("(def tf (fn [] (.print \"done!\") nil))")
    expectThat("(.reduce tf 98765 {})", shouldEvalTo: .IntAtom(98765))
    expectOutputBuffer(toBe: "")
  }

  /// .reduce called on a nonempty list with an initial value should properly reduce.
  func testWithValOnString() {
    runCode("(def tf (fn [a b] (.print \"a:\" a \"b:\" b) (.+ (.int a) (.int b))))")
    expectThat("(.reduce tf -91 \"qwerty\")", shouldEvalTo: .IntAtom(593))
    expectOutputBuffer(toBe: "a: -91 b: \\qa: 22 b: \\wa: 141 b: \\ea: 242 b: \\ra: 356 b: \\ta: 472 b: \\y")
  }

  /// .reduce called on a nonempty list with an initial value should properly reduce.
  func testWithValOnList() {
    runCode("(def tf (fn [a b] (.print \"a:\" a \"b:\" b) (.+ a b)))")
    expectThat("(.reduce tf 152 '(1 8 77 6 1001))", shouldEvalTo: .IntAtom(1245))
    expectOutputBuffer(toBe: "a: 152 b: 1a: 153 b: 8a: 161 b: 77a: 238 b: 6a: 244 b: 1001")
  }

  /// .reduce called on a nonempty list with an initial value should properly reduce.
  func testWithValOnVector() {
    runCode("(def tf (fn [a b] (.print \"a:\" a \"b:\" b) (.+ a b)))")
    expectThat("(.reduce tf 152 [1 8 77 6 1001])", shouldEvalTo: .IntAtom(1245))
    expectOutputBuffer(toBe: "a: 152 b: 1a: 153 b: 8a: 161 b: 77a: 238 b: 6a: 244 b: 1001")
  }

  /// .reduce called on a nonempty list with an initial value should properly reduce.
  func testWithValOnMap() {
    let a = interpreter.context.keywordForName("a")
    let b = interpreter.context.keywordForName("b")
    runCode("(def tf (fn [a b] (.print \"a:\" a \"b:\" b) (.concat a b)))")
    expectThat("(.reduce tf [6 7 8 9] {:a 1 :b 2})", shouldEvalTo: listWithItems(
      .IntAtom(6), .IntAtom(7), .IntAtom(8), .IntAtom(9), .Keyword(b), .IntAtom(2), .Keyword(a), .IntAtom(1)))
    expectOutputBuffer(toBe: "a: [6 7 8 9] b: [:b 2]a: (6 7 8 9 :b 2) b: [:a 1]")
  }

  /// .reduce called with a map in function position should work correctly when there are two items to reduce on.
  func testWithMapInFnPos() {
    expectThat("(.reduce {:a 1 :b 2} '(:a false))", shouldEvalTo: .IntAtom(1))
    expectThat("(.reduce {:a 1 :b 2} :c [1000])", shouldEvalTo: .IntAtom(1000))
  }

  /// .reduce called with a keyword in function position should work correctly when there are two items to reduce on.
  func testWithKeywordInFnPos() {
    expectThat("(.reduce :a [{:a 1 :b 2} false])", shouldEvalTo: .IntAtom(1))
    expectThat("(.reduce :c {:a 1 :b 2} '(1000))", shouldEvalTo: .IntAtom(1000))
  }

  /// .reduce called with a symbol in function position should work correctly when there are two items to reduce on.
  func testWithSymbolInFnPos() {
    expectThat("(.reduce 'a '({a 1 b 2} false))", shouldEvalTo: .IntAtom(1))
    expectThat("(.reduce 'c {'a 1 'b 2} [1000])", shouldEvalTo: .IntAtom(1000))
  }

  /// .reduce should take either two or three arguments.
  func testArity() {
    expectArityErrorFrom("(.reduce)")
    expectArityErrorFrom("(.reduce .+)")
    expectArityErrorFrom("(.reduce .+ 0 '(1 2 3 4 5) '(6 7 8 9 10))")
  }

  /// .reduce must take a evaluatable object as its first argument.
  func testFunctionArg() {
    expectThat("(.reduce nil [1 2 3 4])", shouldFailAs: .NotEvalableError)
    expectThat("(.reduce true [1 2 3 4])", shouldFailAs: .NotEvalableError)
    expectThat("(.reduce false [1 2 3 4])", shouldFailAs: .NotEvalableError)
    expectThat("(.reduce 1023 [1 2 3 4])", shouldFailAs: .NotEvalableError)
    expectThat("(.reduce -9.2156 [1 2 3 4])", shouldFailAs: .NotEvalableError)
    expectThat("(.reduce \\c [1 2 3 4])", shouldFailAs: .NotEvalableError)
    expectThat("(.reduce \"foobar\" [1 2 3 4])", shouldFailAs: .NotEvalableError)
  }

  /// .reduce should throw an arity error if the function it has been given is not a 2-arity function.
  func testInputFunctionArity() {
    runCode("(def tf (fn [a b c] (.+ a (.* b c))))")
    expectArityErrorFrom("(.reduce tf '(1 2 3 4 5 6 7))")
  }

  /// .reduce should fail when given a vector as its first argument, since vectors must take one argument.
  func testWithVectorInFnPos() {
    expectArityErrorFrom("(.reduce [1 2 3 4] '(1 2))")
  }

  /// .reduce must take a collection as its last argument.
  func testCollectionArg() {
    expectThat("(.reduce .+ 1 true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.reduce .+ 1 false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.reduce .+ 1 152)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.reduce .+ 1 3.2985)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.reduce .+ 1 \\c)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.reduce .+ 1 'c)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.reduce .+ 1 :c)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.reduce .+ 1 .+)", shouldFailAs: .InvalidArgumentError)
  }
}

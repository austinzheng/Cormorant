//
//  TestApply.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/4/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the 'apply' special form.
class TestApply : InterpreterTest {

  override func setUp() {
    super.setUp()
    clearOutputBuffer()
    interpreter.writeOutput = writeToBuffer
  }

  override func tearDown() {
    // Reset the interpreter
    clearOutputBuffer()
    interpreter.writeOutput = print
  }

  /// apply must take at least two arguments.
  func testApplyArity() {
    expectArityErrorFrom("(apply)")
    expectArityErrorFrom("(apply .+)")
  }

  /// apply should work when invoked upon zero-arity functions using an empty sequence.
  func testApplyWithNoArgs() {
    expectThat("(apply (fn [] true) nil)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(apply (fn [] 152) ())", shouldEvalTo: .IntegerLiteral(152))
    expectThat("(apply (fn [] \"foobar\") [])", shouldEvalTo: .StringLiteral("foobar"))
    expectThat("(apply (fn [] \\a) {})", shouldEvalTo: .CharacterLiteral("a"))
  }

  /// apply should work when invoked upon a function with a list as the final sequence.
  func testApplyWithArgList() {
    expectThat("(apply .+ '(15 21))", shouldEvalTo: .IntegerLiteral(36))
    expectThat("(apply .concat '((1 2) [3 4 5]))", shouldEvalTo: "'(1 2 3 4 5)")
  }

  /// apply should work when invoked upon a function with a vector as the final sequence.
  func testApplyWithArgVector() {
    expectThat("(apply .+ [15 21])", shouldEvalTo: .IntegerLiteral(36))
    expectThat("(apply .concat ['(1 2 3) [4 5]])", shouldEvalTo: "'(1 2 3 4 5)")
  }

  /// apply should work when invoked upon a function with a map as the final sequence.
  func testApplyWithArgMap() {
    expectThat("(apply .concat {:a 1 :b 2})", shouldEvalTo: "'(:b 2 :a 1)")
    expectThat("(apply .concat {:a 1 :b 2 :c 3})", shouldEvalTo: "'(:b 2 :c 3 :a 1)")
  }

  /// apply should work properly when invoked with a symbol that maps to a function.
  func testSymbolResolution() {
    runCode("(def myfn (fn [a b c] (.+ a (.+ b c))))")
    expectThat("(apply myfn [1 3 7])", shouldEvalTo: .IntegerLiteral(11))
    runCode("(def myfn 1000)")
    expectThat("(apply myfn [1 3 7])", shouldFailAs: .NotEvalableError)
  }

  /// apply should work when invoked with 'nil' as the sequence (last argument).
  func testFinalNil() {
    expectThat("(apply .+ 15 28 nil)", shouldEvalTo: .IntegerLiteral(43))
    expectThat("(apply .concat [1 2] [3 4] [5 6] nil)", shouldEvalTo: "'(1 2 3 4 5 6)")
  }

  /// apply should work when invoked with leading arguments before a non-nil final list.
  func testLeadingArgsThenList() {
    expectThat("(apply .+ 15 '(28))", shouldEvalTo: .IntegerLiteral(43))
    expectThat("(apply .+ 15 28 ())", shouldEvalTo: .IntegerLiteral(43))
    expectThat("(apply .concat [1] [2] [3] '([4 5] [6 7]))", shouldEvalTo: "'(1 2 3 4 5 6 7)")
    expectThat("(apply .concat [1] [2] [3] [4 5] [6 7] ())", shouldEvalTo: "'(1 2 3 4 5 6 7)")
  }

  /// apply should work when invoked with leading arguments before a non-nil final vector.
  func testLeadingArgsThenVector() {
    expectThat("(apply .+ 15 [28])", shouldEvalTo: .IntegerLiteral(43))
    expectThat("(apply .+ 15 28 [])", shouldEvalTo: .IntegerLiteral(43))
    expectThat("(apply .concat '(1) '(2) '(3) ['(4 5) '(6 7)])", shouldEvalTo: "'(1 2 3 4 5 6 7)")
    expectThat("(apply .concat '(1) '(2) '(3) '(4 5) '(6 7) [])", shouldEvalTo: "'(1 2 3 4 5 6 7)")
  }

  /// apply should work when invoked with leading arguments before a non-nil final map.
  func testLeadingArgsThenMap() {
    expectThat("(apply .concat [1 2] [3 4] {:a 15 :b 16})", shouldEvalTo: "'(1 2 3 4 :b 16 :a 15)")
    expectThat("(apply .concat [1 2] [3 4] [:a 15 :b 16] {})", shouldEvalTo: "'(1 2 3 4 :a 15 :b 16)")
  }

  /// apply should work properly when a vector is used as the function.
  func testApplyOnVector() {
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] 0 nil)", shouldEvalTo: .StringLiteral("foo"))
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] '(1))", shouldEvalTo: .StringLiteral("bar"))
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] [2])", shouldEvalTo: .StringLiteral("baz"))
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] 15 nil)", shouldFailAs: .OutOfBoundsError)
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] -1 ())", shouldFailAs: .OutOfBoundsError)
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] ())", shouldFailAs: .ArityError)
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] 0 '(1))", shouldFailAs: .ArityError)
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] 0 558 nil)", shouldFailAs: .ArityError)
  }

  /// apply should work properly when a map is used as the function.
  func testApplyOnMap() {
    expectThat("(apply {:a 1 'b 2 \\c 3} :a nil)", shouldEvalTo: .IntegerLiteral(1))
    expectThat("(apply {:a 1 'b 2 \\c 3} '(b))", shouldEvalTo: .IntegerLiteral(2))
    expectThat("(apply {:a 1 'b 2 \\c 3} [\\c])", shouldEvalTo: .IntegerLiteral(3))
    expectThat("(apply {:a 1 'b 2 \\c 3} :d nil)", shouldEvalTo: .NilLiteral)
    expectThat("(apply {:a 1 'b 2 \\c 3} '(:d))", shouldEvalTo: .NilLiteral)
    expectThat("(apply {:a 1 'b 2 \\c 3} :d \"foo\" nil)", shouldEvalTo: .StringLiteral("foo"))
    expectThat("(apply {:a 1 'b 2 \\c 3} '(:d \"foo\"))", shouldEvalTo: .StringLiteral("foo"))
    expectThat("(apply {:a 1 'b 2 \\c 3} :a :b nil)", shouldEvalTo: .IntegerLiteral(1))
    expectThat("(apply {:a 1 'b 2 \\c 3} :a :b :c nil)", shouldFailAs: .ArityError)
    expectThat("(apply {:a 1 'b 2 \\c 3} '(:a :b :c))", shouldFailAs: .ArityError)
    expectThat("(apply {:a 1 'b 2 \\c 3} nil)", shouldFailAs: .ArityError)
  }

  /// apply should work properly when a symbol is used as the function.
  func testApplyOnSymbol() {
    expectThat("(apply 'a {'a 1 'b 2 'c 3} nil)", shouldEvalTo: .IntegerLiteral(1))
    expectThat("(apply 'b '({a 1 b 2 c 3}))", shouldEvalTo: .IntegerLiteral(2))
    expectThat("(apply 'c [{'a 1 'b 2 'c 3}])", shouldEvalTo: .IntegerLiteral(3))
    expectThat("(apply 'd {'a 1 'b 2 'c 3} nil)", shouldEvalTo: .NilLiteral)
    expectThat("(apply 'd \"foobar\" nil)", shouldEvalTo: .NilLiteral)
    expectThat("(apply 'd {'a 1 'b 2 'c 3} \"bar\" nil)", shouldEvalTo: .StringLiteral("bar"))
    expectThat("(apply 'd '({a 1 b 2 c 3} \"bar\"))", shouldEvalTo: .StringLiteral("bar"))
    expectThat("(apply 'a {'a 1 'b 2 'c 3} \"bar\" nil)", shouldEvalTo: .IntegerLiteral(1))
    expectThat("(apply 'a {'a 1 'b 2 'c 3} true false nil)", shouldFailAs: .ArityError)
    expectThat("(apply 'a '({a 1 b 2 c 3} true false))", shouldFailAs: .ArityError)
    expectThat("(apply 'a nil)", shouldFailAs: .ArityError)
  }

  /// apply should work properly when a keyword is used as the function.
  func testApplyOnKeyword() {
    expectThat("(apply :a {:a 1 :b 2 :c 3} nil)", shouldEvalTo: .IntegerLiteral(1))
    expectThat("(apply :b '({:a 1 :b 2 :c 3}))", shouldEvalTo: .IntegerLiteral(2))
    expectThat("(apply :c [{:a 1 :b 2 :c 3}])", shouldEvalTo: .IntegerLiteral(3))
    expectThat("(apply :d {:a 1 :b 2 :c 3} nil)", shouldEvalTo: .NilLiteral)
    expectThat("(apply :d \"foobar\" nil)", shouldEvalTo: .NilLiteral)
    expectThat("(apply :d {:a 1 :b 2 :c 3} \"bar\" nil)", shouldEvalTo: .StringLiteral("bar"))
    expectThat("(apply :d '({:a 1 :b 2 :c 3} \"bar\"))", shouldEvalTo: .StringLiteral("bar"))
    expectThat("(apply :a {:a 1 :b 2 :c 3} \"bar\" nil)", shouldEvalTo: .IntegerLiteral(1))
    expectThat("(apply :a {:a 1 :b 2 :c 3} true false nil)", shouldFailAs: .ArityError)
    expectThat("(apply :a '({:a 1 :b 2 :c 3} true false))", shouldFailAs: .ArityError)
    expectThat("(apply :a nil)", shouldFailAs: .ArityError)
  }

  /// apply should reject a first argument that isn't a function.
  func testNonFunctionFirstArg() {
    expectThat("(apply nil ())", shouldFailAs: .NotEvalableError)
    expectThat("(apply true ())", shouldFailAs: .NotEvalableError)
    expectThat("(apply false ())", shouldFailAs: .NotEvalableError)
    expectThat("(apply -91882 ())", shouldFailAs: .NotEvalableError)
    expectThat("(apply 0.0000015 ())", shouldFailAs: .NotEvalableError)
    expectThat("(apply \\c ())", shouldFailAs: .NotEvalableError)
    expectThat("(apply \"foobar\" ())", shouldFailAs: .NotEvalableError)
  }

  /// apply should reject an only argument that isn't nil or a valid sequence.
  func testNonSeqOnlyArg() {
    expectThat("(apply .print true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print 152)", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print -299.123)", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print \"hello\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print \\c)", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print 'c)", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print :c)", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print .print)", shouldFailAs: .InvalidArgumentError)
  }

  /// apply should reject a last argument that isn't nil or a valid sequence.
  func testNonSeqLastArg() {
    expectThat("(apply .print \"foo\" \"bar\" true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print \"foo\" \"bar\" false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print \"foo\" \"bar\" 152)", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print \"foo\" \"bar\" -299.123)", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print \"foo\" \"bar\" \"hello\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print \"foo\" \"bar\" \\c)", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print \"foo\" \"bar\" 'c)", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print \"foo\" \"bar\" :c)", shouldFailAs: .InvalidArgumentError)
    expectThat("(apply .print \"foo\" \"bar\" .print)", shouldFailAs: .InvalidArgumentError)
  }

  /// apply should fully evaluate all of its parameters when invoked, but not multiple times.
  func testSideEffects() {
    expectThat("(apply (do (.print \"az\") .+) (do (.print \"by\") 1) (do (.print \"cx\") [2]))",
      shouldEvalTo: .IntegerLiteral(3))
    expectOutputBuffer(toBe: "azbycx")
  }

  /// apply should throw an error if called with too many or not enough arguments.
  func testImproperArity() {
    // .+ cannot take 3 arguments
    expectThat("(apply .+ 1 2 3 ())", shouldFailAs: .ArityError)
    expectThat("(apply .+ 1 2 '(3))", shouldFailAs: .ArityError)
    expectThat("(apply .+ 1 '(2 3))", shouldFailAs: .ArityError)
    expectThat("(apply .+ '(1 2 3))", shouldFailAs: .ArityError)
  }

  /// apply should work properly with functions that take varargs
  func testVarargs() {
    // This should evaluate to nil
    expectThat("(apply (fn [a b & c] c) 1 2 nil)", shouldEvalTo: .NilLiteral)
    // This should evaluate to "(3)"
    expectThat("(apply (fn [a b & c] c) 1 2 3 nil)", shouldEvalTo: "'(3)")
    // This should evaluate to "(3 4 5)"
    expectThat("(apply (fn [a b & c] c) 1 2 3 4 5 nil)", shouldEvalTo: "'(3 4 5)")
    // This should evaluate to "(3 4 5 6 7)"
    expectThat("(apply (fn [a b & c] c) 1 2 3 4 '(5 6 7))", shouldEvalTo: "'(3 4 5 6 7)")
  }
}

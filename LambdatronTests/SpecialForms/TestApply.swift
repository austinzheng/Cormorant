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

  /// apply must take at least two arguments.
  func testApplyArity() {
    expectArityErrorFrom("(apply)")
    expectArityErrorFrom("(apply .+)")
  }

  /// apply should work when invoked upon zero-arity functions using an empty sequence.
  func testApplyWithNoArgs() {
    expectThat("(apply (fn [] true) nil)", shouldEvalTo: true)
    expectThat("(apply (fn [] 152) ())", shouldEvalTo: 152)
    expectThat("(apply (fn [] \"foobar\") [])", shouldEvalTo: .StringAtom("foobar"))
    expectThat("(apply (fn [] \\a) {})", shouldEvalTo: .CharAtom("a"))
  }

  /// apply should work when invoked upon a function with a list as the final sequence.
  func testApplyWithArgList() {
    expectThat("(apply .+ '(15 21))", shouldEvalTo: 36)
    expectThat("(apply .concat '((1 2) [3 4 5]))", shouldEvalTo: "'(1 2 3 4 5)")
  }

  /// apply should work when invoked upon a function with a vector as the final sequence.
  func testApplyWithArgVector() {
    expectThat("(apply .+ [15 21])", shouldEvalTo: 36)
    expectThat("(apply .concat ['(1 2 3) [4 5]])", shouldEvalTo: "'(1 2 3 4 5)")
  }

  /// apply should work when invoked upon a function with a map as the final sequence.
  func testApplyWithArgMap() {
    let a = keyword("a")
    let b = keyword("b")
    let c = keyword("c")
    expectThat("(apply .concat {:a 1 :b 2})", shouldEvalToContain: .Keyword(a), 1, .Keyword(b), 2)
    expectThat("(apply .concat {:a 1 :b 2 :c 3})", shouldEvalToContain: .Keyword(a), 1, .Keyword(b), 2, .Keyword(c), 3)
  }

  /// apply should work properly when invoked with a symbol that maps to a function.
  func testSymbolResolution() {
    runCode("(def myfn (fn [a b c] (.+ a (.+ b c))))")
    expectThat("(apply myfn [1 3 7])", shouldEvalTo: 11)
    runCode("(def myfn 1000)")
    expectThat("(apply myfn [1 3 7])", shouldFailAs: .NotEvalableError)
  }

  /// apply should work when invoked with 'nil' as the sequence (last argument).
  func testFinalNil() {
    expectThat("(apply .+ 15 28 nil)", shouldEvalTo: 43)
    expectThat("(apply .concat [1 2] [3 4] [5 6] nil)", shouldEvalTo: "'(1 2 3 4 5 6)")
  }

  /// apply should work when invoked with leading arguments before a non-nil final list.
  func testLeadingArgsThenList() {
    expectThat("(apply .+ 15 '(28))", shouldEvalTo: 43)
    expectThat("(apply .+ 15 28 ())", shouldEvalTo: 43)
    expectThat("(apply .concat [1] [2] [3] '([4 5] [6 7]))", shouldEvalTo: "'(1 2 3 4 5 6 7)")
    expectThat("(apply .concat [1] [2] [3] [4 5] [6 7] ())", shouldEvalTo: "'(1 2 3 4 5 6 7)")
  }

  /// apply should work when invoked with leading arguments before a non-nil final vector.
  func testLeadingArgsThenVector() {
    expectThat("(apply .+ 15 [28])", shouldEvalTo: 43)
    expectThat("(apply .+ 15 28 [])", shouldEvalTo: 43)
    expectThat("(apply .concat '(1) '(2) '(3) ['(4 5) '(6 7)])", shouldEvalTo: "'(1 2 3 4 5 6 7)")
    expectThat("(apply .concat '(1) '(2) '(3) '(4 5) '(6 7) [])", shouldEvalTo: "'(1 2 3 4 5 6 7)")
  }

  /// apply should work when invoked with leading arguments before a non-nil final map.
  func testLeadingArgsThenMap() {
    let a = keyword("a")
    let b = keyword("b")
    expectThat("(apply .concat [1 2] [3 4] {:a 15 :b 16})",
      shouldEvalToContain: 1, 2, 3, 4, .Keyword(a), 15, .Keyword(b), 16)
    expectThat("(apply .concat [1 2] [3 4] [:a 15 :b 16] {})",
      shouldEvalToContain: 1, 2, 3, 4, .Keyword(a), 15, .Keyword(b), 16)
  }

  /// apply should work properly when a vector is used as the function.
  func testApplyOnVector() {
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] 0 nil)", shouldEvalTo: .StringAtom("foo"))
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] '(1))", shouldEvalTo: .StringAtom("bar"))
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] [2])", shouldEvalTo: .StringAtom("baz"))
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] 15 nil)", shouldFailAs: .OutOfBoundsError)
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] -1 ())", shouldFailAs: .OutOfBoundsError)
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] ())", shouldFailAs: .ArityError)
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] 0 '(1))", shouldFailAs: .ArityError)
    expectThat("(apply [\"foo\" \"bar\" \"baz\"] 0 558 nil)", shouldFailAs: .ArityError)
  }

  /// apply should work properly when a map is used as the function.
  func testApplyOnMap() {
    expectThat("(apply {:a 1 'b 2 \\c 3} :a nil)", shouldEvalTo: 1)
    expectThat("(apply {:a 1 'b 2 \\c 3} '(b))", shouldEvalTo: 2)
    expectThat("(apply {:a 1 'b 2 \\c 3} [\\c])", shouldEvalTo: 3)
    expectThat("(apply {:a 1 'b 2 \\c 3} :d nil)", shouldEvalTo: .Nil)
    expectThat("(apply {:a 1 'b 2 \\c 3} '(:d))", shouldEvalTo: .Nil)
    expectThat("(apply {:a 1 'b 2 \\c 3} :d \"foo\" nil)", shouldEvalTo: .StringAtom("foo"))
    expectThat("(apply {:a 1 'b 2 \\c 3} '(:d \"foo\"))", shouldEvalTo: .StringAtom("foo"))
    expectThat("(apply {:a 1 'b 2 \\c 3} :a :b nil)", shouldEvalTo: 1)
    expectThat("(apply {:a 1 'b 2 \\c 3} :a :b :c nil)", shouldFailAs: .ArityError)
    expectThat("(apply {:a 1 'b 2 \\c 3} '(:a :b :c))", shouldFailAs: .ArityError)
    expectThat("(apply {:a 1 'b 2 \\c 3} nil)", shouldFailAs: .ArityError)
  }

  /// apply should work properly when a symbol is used as the function.
  func testApplyOnSymbol() {
    expectThat("(apply 'a {'a 1 'b 2 'c 3} nil)", shouldEvalTo: 1)
    expectThat("(apply 'b '({a 1 b 2 c 3}))", shouldEvalTo: 2)
    expectThat("(apply 'c [{'a 1 'b 2 'c 3}])", shouldEvalTo: 3)
    expectThat("(apply 'd {'a 1 'b 2 'c 3} nil)", shouldEvalTo: .Nil)
    expectThat("(apply 'd \"foobar\" nil)", shouldEvalTo: .Nil)
    expectThat("(apply 'd {'a 1 'b 2 'c 3} \"bar\" nil)", shouldEvalTo: .StringAtom("bar"))
    expectThat("(apply 'd '({a 1 b 2 c 3} \"bar\"))", shouldEvalTo: .StringAtom("bar"))
    expectThat("(apply 'a {'a 1 'b 2 'c 3} \"bar\" nil)", shouldEvalTo: 1)
    expectThat("(apply 'a {'a 1 'b 2 'c 3} true false nil)", shouldFailAs: .ArityError)
    expectThat("(apply 'a '({a 1 b 2 c 3} true false))", shouldFailAs: .ArityError)
    expectThat("(apply 'a nil)", shouldFailAs: .ArityError)
  }

  /// apply should work properly when a keyword is used as the function.
  func testApplyOnKeyword() {
    expectThat("(apply :a {:a 1 :b 2 :c 3} nil)", shouldEvalTo: 1)
    expectThat("(apply :b '({:a 1 :b 2 :c 3}))", shouldEvalTo: 2)
    expectThat("(apply :c [{:a 1 :b 2 :c 3}])", shouldEvalTo: 3)
    expectThat("(apply :d {:a 1 :b 2 :c 3} nil)", shouldEvalTo: .Nil)
    expectThat("(apply :d \"foobar\" nil)", shouldEvalTo: .Nil)
    expectThat("(apply :d {:a 1 :b 2 :c 3} \"bar\" nil)", shouldEvalTo: .StringAtom("bar"))
    expectThat("(apply :d '({:a 1 :b 2 :c 3} \"bar\"))", shouldEvalTo: .StringAtom("bar"))
    expectThat("(apply :a {:a 1 :b 2 :c 3} \"bar\" nil)", shouldEvalTo: 1)
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
    expectInvalidArgumentErrorFrom("(apply .print true)")
    expectInvalidArgumentErrorFrom("(apply .print false)")
    expectInvalidArgumentErrorFrom("(apply .print 152)")
    expectInvalidArgumentErrorFrom("(apply .print -299.123)")
    expectInvalidArgumentErrorFrom("(apply .print \"hello\")")
    expectInvalidArgumentErrorFrom("(apply .print \\c)")
    expectInvalidArgumentErrorFrom("(apply .print 'c)")
    expectInvalidArgumentErrorFrom("(apply .print :c)")
    expectInvalidArgumentErrorFrom("(apply .print .print)")
  }

  /// apply should reject a last argument that isn't nil or a valid sequence.
  func testNonSeqLastArg() {
    expectInvalidArgumentErrorFrom("(apply .print \"foo\" \"bar\" true)")
    expectInvalidArgumentErrorFrom("(apply .print \"foo\" \"bar\" false)")
    expectInvalidArgumentErrorFrom("(apply .print \"foo\" \"bar\" 152)")
    expectInvalidArgumentErrorFrom("(apply .print \"foo\" \"bar\" -299.123)")
    expectInvalidArgumentErrorFrom("(apply .print \"foo\" \"bar\" \"hello\")")
    expectInvalidArgumentErrorFrom("(apply .print \"foo\" \"bar\" \\c)")
    expectInvalidArgumentErrorFrom("(apply .print \"foo\" \"bar\" 'c)")
    expectInvalidArgumentErrorFrom("(apply .print \"foo\" \"bar\" :c)")
    expectInvalidArgumentErrorFrom("(apply .print \"foo\" \"bar\" .print)")
  }

  /// apply should fully evaluate all of its parameters when invoked, but not multiple times.
  func testSideEffects() {
    expectThat("(apply (do (.print \"az\") .+) (do (.print \"by\") 1) (do (.print \"cx\") [2]))", shouldEvalTo: 3)
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
    expectThat("(apply (fn [a b & c] c) 1 2 nil)", shouldEvalTo: .Nil)
    // This should evaluate to "(3)"
    expectThat("(apply (fn [a b & c] c) 1 2 3 nil)", shouldEvalTo: "'(3)")
    // This should evaluate to "(3 4 5)"
    expectThat("(apply (fn [a b & c] c) 1 2 3 4 5 nil)", shouldEvalTo: "'(3 4 5)")
    // This should evaluate to "(3 4 5 6 7)"
    expectThat("(apply (fn [a b & c] c) 1 2 3 4 '(5 6 7))", shouldEvalTo: "'(3 4 5 6 7)")
  }
}

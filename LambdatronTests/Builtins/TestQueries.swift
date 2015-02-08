//
//  TestQueries.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/19/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class testIsNil : InterpreterTest {
  /// .nil? should return true for 'nil'.
  func testIsNilWithNil() {
    expectThat("(.nil? nil)", shouldEvalTo: .BoolAtom(true))
  }

  /// .nil? should return false for any non-nil value or type, even those that are falsy.
  func testIsNilWithOthers() {
    expectThat("(.nil? 0)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.nil? 0.0)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.nil? true)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.nil? false)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.nil? \"\")", shouldEvalTo: .BoolAtom(false))
    expectThat("(.nil? \\a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.nil? 'a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.nil? :a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.nil? [])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.nil? '())", shouldEvalTo: .BoolAtom(false))
    expectThat("(.nil? {})", shouldEvalTo: .BoolAtom(false))
    expectThat("(.nil? .cons)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.nil? (fn [] nil))", shouldEvalTo: .BoolAtom(false))
  }

  /// .nil? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.nil?)")
    expectArityErrorFrom("(.nil? nil nil)")
  }
}

class testIsNumber : InterpreterTest {
  /// .number? should return true for any integer.
  func testIsNumberWithInts() {
    expectThat("(.number? 0)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.number? 1)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.number? -1)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.number? 12345)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.number? -12345)", shouldEvalTo: .BoolAtom(true))
  }

  /// .number? should return true for any floating-point value.
  func testIsNumberWithFloats() {
    expectThat("(.number? 0.0)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.number? 1.0001)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.number? -1.12345)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.number? 12345.000)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.number? -12345.009)", shouldEvalTo: .BoolAtom(true))
  }

  /// .number? should return false for any non-numeric type.
  func testIsNumberWithOthers() {
    expectThat("(.number? nil)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.number? true)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.number? false)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.number? \"\")", shouldEvalTo: .BoolAtom(false))
    expectThat("(.number? \\a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.number? 'a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.number? :a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.number? [])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.number? '())", shouldEvalTo: .BoolAtom(false))
    expectThat("(.number? {})", shouldEvalTo: .BoolAtom(false))
    expectThat("(.number? .cons)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.number? (fn [] 0))", shouldEvalTo: .BoolAtom(false))
  }

  /// .number? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.number?)")
    expectArityErrorFrom("(.number? 0 0)")
  }
}

class testIsInt : InterpreterTest {
  /// .int? should return true for any integer.
  func testIsIntWithInts() {
    expectThat("(.int? 0)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.int? 1)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.int? -1)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.int? 12345)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.int? -12345)", shouldEvalTo: .BoolAtom(true))
  }

  /// .int? should return false for any floating-point value.
  func testIsIntWithFloats() {
    expectThat("(.int? 0.0)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.int? 1.0001)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.int? -1.12345)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.int? 12345.000)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.int? -12345.009)", shouldEvalTo: .BoolAtom(false))
  }

  /// .int? should return false for any non-numeric type.
  func testIsIntWithOthers() {
    expectThat("(.int? nil)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.int? true)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.int? false)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.int? \"\")", shouldEvalTo: .BoolAtom(false))
    expectThat("(.int? \\a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.int? 'a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.int? :a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.int? [])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.int? '())", shouldEvalTo: .BoolAtom(false))
    expectThat("(.int? {})", shouldEvalTo: .BoolAtom(false))
    expectThat("(.int? .cons)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.int? (fn [] 0))", shouldEvalTo: .BoolAtom(false))
  }

  /// .int? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.int?)")
    expectArityErrorFrom("(.int? 1 1)")
  }
}

class testIsFloat : InterpreterTest {
  /// .float? should return false for any integer.
  func testIsFloatWithInts() {
    expectThat("(.float? 0)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.float? 1)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.float? -1)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.float? 12345)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.float? -12345)", shouldEvalTo: .BoolAtom(false))
  }

  /// .float? should return true for any floating-point value.
  func testIsFloatWithFloats() {
    expectThat("(.float? 0.0)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.float? 1.0001)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.float? -1.12345)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.float? 12345.000)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.float? -12345.009)", shouldEvalTo: .BoolAtom(true))
  }

  /// .float? should return false for any non-numeric type.
  func testIsFloatWithOthers() {
    expectThat("(.float? nil)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.float? true)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.float? false)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.float? \"\")", shouldEvalTo: .BoolAtom(false))
    expectThat("(.float? \\a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.float? 'a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.float? :a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.float? [])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.float? '())", shouldEvalTo: .BoolAtom(false))
    expectThat("(.float? {})", shouldEvalTo: .BoolAtom(false))
    expectThat("(.float? .cons)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.float? (fn [] 0))", shouldEvalTo: .BoolAtom(false))
  }

  /// .float? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.float?)")
    expectArityErrorFrom("(.float? 1.1 1.1)")
  }
}

class testIsString : InterpreterTest {
  /// .string? should return true for strings.
  func testIsStringWithString() {
    expectThat("(.string? \"\")", shouldEvalTo: .BoolAtom(true))
    expectThat("(.string? \"foobar\")", shouldEvalTo: .BoolAtom(true))
    expectThat("(.string? \"hello \\n world!!\")", shouldEvalTo: .BoolAtom(true))
  }

  /// .string? should return false for any non-string type.
  func testIsStringWithOthers() {
    expectThat("(.string? 10)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.string? 515.15151)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.string? nil)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.string? true)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.string? false)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.string? \\a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.string? 'a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.string? :a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.string? [])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.string? '())", shouldEvalTo: .BoolAtom(false))
    expectThat("(.string? {})", shouldEvalTo: .BoolAtom(false))
    expectThat("(.string? .cons)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.string? (fn [] 0))", shouldEvalTo: .BoolAtom(false))
  }

  /// .string? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.string?)")
    expectArityErrorFrom("(.string? \"foo\" \"bar\")")
  }
}

class testIsChar : InterpreterTest {
  /// .char? should return true for characters.
  func testIsCharWithCharacter() {
    runCode("(def a \\a)")
    expectThat("(.char? \\a)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.char? \\newline)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.char? a)", shouldEvalTo: .BoolAtom(true))
  }

  /// .char? should return false for any non-character type.
  func testIsCharWithOthers() {
    expectThat("(.char? 1025)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.char? 3.141592)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.char? nil)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.char? true)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.char? false)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.char? \"\")", shouldEvalTo: .BoolAtom(false))
    expectThat("(.char? 'a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.char? :a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.char? [])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.char? '())", shouldEvalTo: .BoolAtom(false))
    expectThat("(.char? {})", shouldEvalTo: .BoolAtom(false))
    expectThat("(.char? .cons)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.char? (fn [a b] :hello))", shouldEvalTo: .BoolAtom(false))
  }

  /// .char? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.char?)")
    expectArityErrorFrom("(.char? \\\\ \\a)")
  }
}

class testIsSymbol : InterpreterTest {
  /// .symbol? should return true for symbols.
  func testIsSymbolWithSymbol() {
    runCode("(def a 'b)")
    expectThat("(.symbol? 'a)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.symbol? 'mysymbol)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.symbol? a)", shouldEvalTo: .BoolAtom(true))
  }

  /// .symbol? should return false for any non-symbol type.
  func testIsSymbolWithOthers() {
    expectThat("(.symbol? 1025)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.symbol? 3.141592)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.symbol? nil)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.symbol? true)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.symbol? false)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.symbol? \"\")", shouldEvalTo: .BoolAtom(false))
    expectThat("(.symbol? \\a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.symbol? :a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.symbol? [])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.symbol? '())", shouldEvalTo: .BoolAtom(false))
    expectThat("(.symbol? {})", shouldEvalTo: .BoolAtom(false))
    expectThat("(.symbol? .cons)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.symbol? (fn [a b] :hello))", shouldEvalTo: .BoolAtom(false))
  }

  /// .symbol? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.symbol?)")
    expectArityErrorFrom("(.symbol? 'a 'a)")
  }
}

class testIsKeyword : InterpreterTest {
  /// .keyword? should return true for keywords.
  func testIsKeywordWithKeyword() {
    runCode("(def a :some-keyword)")
    expectThat("(.keyword? :a)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.keyword? :else)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.keyword? a)", shouldEvalTo: .BoolAtom(true))
  }

  /// .keyword? should return false for any non-keyword type.
  func testIsKeywordWithOthers() {
    expectThat("(.keyword? 1025)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.keyword? 3.141592)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.keyword? nil)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.keyword? true)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.keyword? false)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.keyword? \"\")", shouldEvalTo: .BoolAtom(false))
    expectThat("(.keyword? \\a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.keyword? 'a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.keyword? [])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.keyword? '())", shouldEvalTo: .BoolAtom(false))
    expectThat("(.keyword? {})", shouldEvalTo: .BoolAtom(false))
    expectThat("(.keyword? .cons)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.keyword? (fn [a b] :hello))", shouldEvalTo: .BoolAtom(false))
  }

  /// .keyword? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.keyword?)")
    expectArityErrorFrom("(.keyword? :a :a)")
  }
}

class testIsFn : InterpreterTest {
  /// .fn? should return true for user-defined functions.
  func testIsFnWithUserDefined() {
    expectThat("(.fn? (fn [a b] (.+ a b)))", shouldEvalTo: .BoolAtom(true))
    runCode("(def testfn (fn [a b] (.+ 1 2 a b)))")
    expectThat("(.fn? testfn)", shouldEvalTo: .BoolAtom(true))
  }

  /// .fn? should return true for built-in functions.
  func testIsFnWithBuiltIns() {
    expectThat("(.fn? .+)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.fn? .fn?)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.fn? .cons)", shouldEvalTo: .BoolAtom(true))
  }

  /// .fn? should return false for any non-function type.
  func testIsFnWithOthers() {
    expectThat("(.fn? 1025)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.fn? 3.141592)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.fn? nil)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.fn? true)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.fn? false)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.fn? \"\")", shouldEvalTo: .BoolAtom(false))
    expectThat("(.fn? \\a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.fn? 'a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.fn? :a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.fn? [])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.fn? '())", shouldEvalTo: .BoolAtom(false))
    expectThat("(.fn? {})", shouldEvalTo: .BoolAtom(false))
  }

  // .fn? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.fn?)")
    expectArityErrorFrom("(.fn? .+ .+)")
  }
}

class testIsEval : InterpreterTest {
  // TODO
}

class testIsTrue : InterpreterTest {
  // .true? should return true for the value true.
  func testIsTrueWithBooleans() {
    expectThat("(.true? true)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.true? false)", shouldEvalTo: .BoolAtom(false))
  }

  // .true? should return false for any value that isn't exactly true.
  func testIsTrueWithOthers() {
    expectThat("(.true? 0)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.true? 0.0)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.true? nil)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.true? \"\")", shouldEvalTo: .BoolAtom(false))
    expectThat("(.true? \\a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.true? 'a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.true? :a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.true? [])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.true? '())", shouldEvalTo: .BoolAtom(false))
    expectThat("(.true? {})", shouldEvalTo: .BoolAtom(false))
    expectThat("(.true? (fn [] 0))", shouldEvalTo: .BoolAtom(false))
    expectThat("(.true? .+)", shouldEvalTo: .BoolAtom(false))
  }

  // .true? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.true?)")
    expectArityErrorFrom("(.true? true true)")
  }
}

class testIsFalse : InterpreterTest {
  // .false? should return true for the value false.
  func testIsFalseWithBooleans() {
    expectThat("(.false? true)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.false? false)", shouldEvalTo: .BoolAtom(true))
  }

  // .false? should return false for any value that isn't exactly false.
  func testIsFalseWithOthers() {
    expectThat("(.false? 0)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.false? 0.0)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.false? nil)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.false? \"\")", shouldEvalTo: .BoolAtom(false))
    expectThat("(.false? \\a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.false? 'a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.false? :a)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.false? [])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.false? '())", shouldEvalTo: .BoolAtom(false))
    expectThat("(.false? {})", shouldEvalTo: .BoolAtom(false))
    expectThat("(.false? (fn [] 0))", shouldEvalTo: .BoolAtom(false))
    expectThat("(.false? .+)", shouldEvalTo: .BoolAtom(false))
  }

  // .false? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.false?)")
    expectArityErrorFrom("(.false? false false)")
  }
}

class testIsList : InterpreterTest {
  /// .list? should return true when called with list arguments.
  func testIsListWithLists() {
    expectThat("(.list? ())", shouldEvalTo: .BoolAtom(true))
    expectThat("(.list? '(1 2 3 4 5))", shouldEvalTo: .BoolAtom(true))
    expectThat("(.list? '(true nil \"foobar\" \\c :c 'c))", shouldEvalTo: .BoolAtom(true))
  }

  /// .list? should return false when called with non-list arguments.
  func testIsListWithOthers() {
    expectThat("(.list? nil)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.list? true)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.list? false)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.list? 1523)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.list? -92.123571)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.list? \\v)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.list? 'v)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.list? :v)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.list? \"foobar\")", shouldEvalTo: .BoolAtom(false))
    expectThat("(.list? [1 2 3])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.list? {:a 1 :b 2})", shouldEvalTo: .BoolAtom(false))
    expectThat("(.list? .list?)", shouldEvalTo: .BoolAtom(false))
  }

  /// .list? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.list?)")
    expectArityErrorFrom("(.list? () ())")
  }
}

class testIsVector : InterpreterTest {
  /// .vector? should return true when called with vector arguments.
  func testIsListWithLists() {
    expectThat("(.vector? [])", shouldEvalTo: .BoolAtom(true))
    expectThat("(.vector? [1 2 3 4 5])", shouldEvalTo: .BoolAtom(true))
    expectThat("(.vector? [true nil \"foobar\" \\c :c 'c])", shouldEvalTo: .BoolAtom(true))
  }

  /// .vector? should return false when called with non-vector arguments.
  func testIsListWithOthers() {
    expectThat("(.vector? nil)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.vector? true)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.vector? false)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.vector? 1523)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.vector? -92.123571)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.vector? \\v)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.vector? 'v)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.vector? :v)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.vector? \"foobar\")", shouldEvalTo: .BoolAtom(false))
    expectThat("(.vector? '(1 2 3))", shouldEvalTo: .BoolAtom(false))
    expectThat("(.vector? {:a 1 :b 2})", shouldEvalTo: .BoolAtom(false))
    expectThat("(.vector? .vector?)", shouldEvalTo: .BoolAtom(false))
  }

  /// .vector? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.vector?)")
    expectArityErrorFrom("(.vector? () ())")
  }
}

class testIsMap : InterpreterTest {
  // TODO
}

class testIsSeq : InterpreterTest {
  // TODO
}

class testIsPos : InterpreterTest {
  // TODO
}

class testIsNeg : InterpreterTest {
  // TODO
}

class testIsZero : InterpreterTest {
  // .zero? should return true for numerical zero values.
  func testIsZeroWithNumbers() {
    expectThat("(.zero? 0)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.zero? 0.0)", shouldEvalTo: .BoolAtom(true))
    expectThat("(.zero? 1)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.zero? -999)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.zero? 0.00001)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.zero? -1293.58812)", shouldEvalTo: .BoolAtom(false))
  }

  // .zero? should fail for any non-number type.
  func testIsZeroWithOthers() {
    expectThat("(.zero? nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.zero? true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.zero? false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.zero? \"\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.zero? \\a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.zero? 'a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.zero? :a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.zero? [])", shouldFailAs: .InvalidArgumentError)
    expectThat("(.zero? '())", shouldFailAs: .InvalidArgumentError)
    expectThat("(.zero? {})", shouldFailAs: .InvalidArgumentError)
    expectThat("(.zero? (fn [] 0))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.zero? .+)", shouldFailAs: .InvalidArgumentError)
  }

  /// .zero? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.zero?)")
    expectArityErrorFrom("(.zero? 0 0)")
  }
}

class testIsSubnormal : InterpreterTest {
  /// .subnormal? should return true for subnormal double values and false for non-subnormal double values.
  func testWithDoubles() {
    expectThat("(.subnormal? 0.00000000001)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.subnormal? -0.00000000001)", shouldEvalTo: .BoolAtom(false))
    // Build a subnormal number (1 / 2048^93)
    runCode("(def a ((fn [val ctr] (if (.= 0 ctr) val (recur (./ val 2048.0) (.- ctr 1)))) 1.0 93))")
    expectThat("(.subnormal? a)", shouldEvalTo: .BoolAtom(true))
  }

  /// .subnormal? should return false for integers.
  func testWithInts() {
    expectThat("(.subnormal? 0)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.subnormal? 152)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.subnormal? -38)", shouldEvalTo: .BoolAtom(false))
  }

  /// .subnormal? should cause an invalid argument error if called on non-numeric types.
  func testWithNonNumericTypes() {
    expectThat("(.subnormal? nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.subnormal? true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.subnormal? false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.subnormal? \"\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.subnormal? \\a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.subnormal? 'a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.subnormal? :a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.subnormal? [])", shouldFailAs: .InvalidArgumentError)
    expectThat("(.subnormal? '())", shouldFailAs: .InvalidArgumentError)
    expectThat("(.subnormal? {})", shouldFailAs: .InvalidArgumentError)
    expectThat("(.subnormal? (fn [] 0))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.subnormal? .+)", shouldFailAs: .InvalidArgumentError)
  }

  /// .subnormal? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.subnormal?)")
    expectArityErrorFrom("(.subnormal? 0.0 0.0)")
  }
}

class testIsInfinite : InterpreterTest {
  /// .infinite? should return true for infinite double values and false for non-infinite double values.
  func testWithDoubles() {
    expectThat("(.infinite? 100000000000000.0)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.infinite? -100000000000000.0)", shouldEvalTo: .BoolAtom(false))
    // Test with positive infinity
    expectThat("(.infinite? (./ 1 0.0))", shouldEvalTo: .BoolAtom(true))
    expectThat("(.infinite? (./ 1.0 0))", shouldEvalTo: .BoolAtom(true))
    expectThat("(.infinite? (./ -1.0 -0.0))", shouldEvalTo: .BoolAtom(true))
    // Test with negative infinity
    expectThat("(.infinite? (./ 1 -0.0))", shouldEvalTo: .BoolAtom(true))
    expectThat("(.infinite? (./ -1.0 0))", shouldEvalTo: .BoolAtom(true))
    expectThat("(.infinite? (./ -1.0 0.0))", shouldEvalTo: .BoolAtom(true))
  }

  /// .infinite? should return false for integers.
  func testWithInts() {
    expectThat("(.infinite? 0)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.infinite? 152)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.infinite? -38)", shouldEvalTo: .BoolAtom(false))
  }

  /// .infinite? should cause an invalid argument error if called on non-numeric types.
  func testWithNonNumericTypes() {
    expectThat("(.infinite? nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.infinite? true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.infinite? false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.infinite? \"\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.infinite? \\a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.infinite? 'a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.infinite? :a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.infinite? [])", shouldFailAs: .InvalidArgumentError)
    expectThat("(.infinite? '())", shouldFailAs: .InvalidArgumentError)
    expectThat("(.infinite? {})", shouldFailAs: .InvalidArgumentError)
    expectThat("(.infinite? (fn [] 0))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.infinite? .+)", shouldFailAs: .InvalidArgumentError)
  }

  /// .infinite? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.infinite?)")
    expectArityErrorFrom("(.infinite? 0.0 0.0)")
  }
}

class testIsNaN : InterpreterTest {
  /// .nan? should return true for double values equal to NaN, and false for non-NaN double values.
  func testWithDoubles() {
    expectThat("(.nan? 100000000000000.0)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.nan? -100000000000000.0)", shouldEvalTo: .BoolAtom(false))
    // Test with 0.0/0/0
    expectThat("(.nan? (./ 0 0.0))", shouldEvalTo: .BoolAtom(true))
    expectThat("(.nan? (./ 0.0 0))", shouldEvalTo: .BoolAtom(true))
    expectThat("(.nan? (./ 0.0 0.0))", shouldEvalTo: .BoolAtom(true))
    // test with negatives
    expectThat("(.nan? (./ 0 -0.0))", shouldEvalTo: .BoolAtom(true))
    expectThat("(.nan? (./ 0.0 -0))", shouldEvalTo: .BoolAtom(true))
    expectThat("(.nan? (./ -0.0 -0.0))", shouldEvalTo: .BoolAtom(true))
  }

  /// .nan? should return false for integers.
  func testWithInts() {
    expectThat("(.nan? 0)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.nan? 152)", shouldEvalTo: .BoolAtom(false))
    expectThat("(.nan? -38)", shouldEvalTo: .BoolAtom(false))
  }

  /// .nan? should cause an invalid argument error if called on non-numeric types.
  func testWithNonNumericTypes() {
    expectThat("(.nan? nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.nan? true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.nan? false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.nan? \"\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.nan? \\a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.nan? 'a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.nan? :a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.nan? [])", shouldFailAs: .InvalidArgumentError)
    expectThat("(.nan? '())", shouldFailAs: .InvalidArgumentError)
    expectThat("(.nan? {})", shouldFailAs: .InvalidArgumentError)
    expectThat("(.nan? (fn [] 0))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.nan? .+)", shouldFailAs: .InvalidArgumentError)
  }

  /// .nan? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.nan?)")
    expectArityErrorFrom("(.nan? 0.0 0.0)")
  }
}

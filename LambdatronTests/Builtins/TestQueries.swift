//
//  TestQueries.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/19/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestIsNil : InterpreterTest {
  /// .nil? should return true for 'nil'.
  func testIsNilWithNil() {
    expectThat("(.nil? nil)", shouldEvalTo: true)
  }

  /// .nil? should return false for any non-nil value or type, even those that are falsy.
  func testIsNilWithOthers() {
    expectThat("(.nil? 0)", shouldEvalTo: false)
    expectThat("(.nil? 0.0)", shouldEvalTo: false)
    expectThat("(.nil? true)", shouldEvalTo: false)
    expectThat("(.nil? false)", shouldEvalTo: false)
    expectThat("(.nil? \"\")", shouldEvalTo: false)
    expectThat("(.nil? \\a)", shouldEvalTo: false)
    expectThat("(.nil? 'a)", shouldEvalTo: false)
    expectThat("(.nil? :a)", shouldEvalTo: false)
    expectThat("(.nil? [])", shouldEvalTo: false)
    expectThat("(.nil? '())", shouldEvalTo: false)
    expectThat("(.nil? {})", shouldEvalTo: false)
    expectThat("(.nil? .cons)", shouldEvalTo: false)
    expectThat("(.nil? (fn [] nil))", shouldEvalTo: false)
  }

  /// .nil? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.nil?)")
    expectArityErrorFrom("(.nil? nil nil)")
  }
}

class TestIsNumber : InterpreterTest {
  /// .number? should return true for any integer.
  func testIsNumberWithInts() {
    expectThat("(.number? 0)", shouldEvalTo: true)
    expectThat("(.number? 1)", shouldEvalTo: true)
    expectThat("(.number? -1)", shouldEvalTo: true)
    expectThat("(.number? 12345)", shouldEvalTo: true)
    expectThat("(.number? -12345)", shouldEvalTo: true)
  }

  /// .number? should return true for any floating-point value.
  func testIsNumberWithFloats() {
    expectThat("(.number? 0.0)", shouldEvalTo: true)
    expectThat("(.number? 1.0001)", shouldEvalTo: true)
    expectThat("(.number? -1.12345)", shouldEvalTo: true)
    expectThat("(.number? 12345.000)", shouldEvalTo: true)
    expectThat("(.number? -12345.009)", shouldEvalTo: true)
  }

  /// .number? should return false for any non-numeric type.
  func testIsNumberWithOthers() {
    expectThat("(.number? nil)", shouldEvalTo: false)
    expectThat("(.number? true)", shouldEvalTo: false)
    expectThat("(.number? false)", shouldEvalTo: false)
    expectThat("(.number? \"\")", shouldEvalTo: false)
    expectThat("(.number? \\a)", shouldEvalTo: false)
    expectThat("(.number? 'a)", shouldEvalTo: false)
    expectThat("(.number? :a)", shouldEvalTo: false)
    expectThat("(.number? [])", shouldEvalTo: false)
    expectThat("(.number? '())", shouldEvalTo: false)
    expectThat("(.number? {})", shouldEvalTo: false)
    expectThat("(.number? .cons)", shouldEvalTo: false)
    expectThat("(.number? (fn [] 0))", shouldEvalTo: false)
  }

  /// .number? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.number?)")
    expectArityErrorFrom("(.number? 0 0)")
  }
}

class TestIsInt : InterpreterTest {
  /// .int? should return true for any integer.
  func testIsIntWithInts() {
    expectThat("(.int? 0)", shouldEvalTo: true)
    expectThat("(.int? 1)", shouldEvalTo: true)
    expectThat("(.int? -1)", shouldEvalTo: true)
    expectThat("(.int? 12345)", shouldEvalTo: true)
    expectThat("(.int? -12345)", shouldEvalTo: true)
  }

  /// .int? should return false for any floating-point value.
  func testIsIntWithFloats() {
    expectThat("(.int? 0.0)", shouldEvalTo: false)
    expectThat("(.int? 1.0001)", shouldEvalTo: false)
    expectThat("(.int? -1.12345)", shouldEvalTo: false)
    expectThat("(.int? 12345.000)", shouldEvalTo: false)
    expectThat("(.int? -12345.009)", shouldEvalTo: false)
  }

  /// .int? should return false for any non-numeric type.
  func testIsIntWithOthers() {
    expectThat("(.int? nil)", shouldEvalTo: false)
    expectThat("(.int? true)", shouldEvalTo: false)
    expectThat("(.int? false)", shouldEvalTo: false)
    expectThat("(.int? \"\")", shouldEvalTo: false)
    expectThat("(.int? \\a)", shouldEvalTo: false)
    expectThat("(.int? 'a)", shouldEvalTo: false)
    expectThat("(.int? :a)", shouldEvalTo: false)
    expectThat("(.int? [])", shouldEvalTo: false)
    expectThat("(.int? '())", shouldEvalTo: false)
    expectThat("(.int? {})", shouldEvalTo: false)
    expectThat("(.int? .cons)", shouldEvalTo: false)
    expectThat("(.int? (fn [] 0))", shouldEvalTo: false)
  }

  /// .int? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.int?)")
    expectArityErrorFrom("(.int? 1 1)")
  }
}

class TestIsFloat : InterpreterTest {
  /// .float? should return false for any integer.
  func testIsFloatWithInts() {
    expectThat("(.float? 0)", shouldEvalTo: false)
    expectThat("(.float? 1)", shouldEvalTo: false)
    expectThat("(.float? -1)", shouldEvalTo: false)
    expectThat("(.float? 12345)", shouldEvalTo: false)
    expectThat("(.float? -12345)", shouldEvalTo: false)
  }

  /// .float? should return true for any floating-point value.
  func testIsFloatWithFloats() {
    expectThat("(.float? 0.0)", shouldEvalTo: true)
    expectThat("(.float? 1.0001)", shouldEvalTo: true)
    expectThat("(.float? -1.12345)", shouldEvalTo: true)
    expectThat("(.float? 12345.000)", shouldEvalTo: true)
    expectThat("(.float? -12345.009)", shouldEvalTo: true)
  }

  /// .float? should return false for any non-numeric type.
  func testIsFloatWithOthers() {
    expectThat("(.float? nil)", shouldEvalTo: false)
    expectThat("(.float? true)", shouldEvalTo: false)
    expectThat("(.float? false)", shouldEvalTo: false)
    expectThat("(.float? \"\")", shouldEvalTo: false)
    expectThat("(.float? \\a)", shouldEvalTo: false)
    expectThat("(.float? 'a)", shouldEvalTo: false)
    expectThat("(.float? :a)", shouldEvalTo: false)
    expectThat("(.float? [])", shouldEvalTo: false)
    expectThat("(.float? '())", shouldEvalTo: false)
    expectThat("(.float? {})", shouldEvalTo: false)
    expectThat("(.float? .cons)", shouldEvalTo: false)
    expectThat("(.float? (fn [] 0))", shouldEvalTo: false)
  }

  /// .float? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.float?)")
    expectArityErrorFrom("(.float? 1.1 1.1)")
  }
}

class TestIsString : InterpreterTest {
  /// .string? should return true for strings.
  func testIsStringWithString() {
    expectThat("(.string? \"\")", shouldEvalTo: true)
    expectThat("(.string? \"foobar\")", shouldEvalTo: true)
    expectThat("(.string? \"hello \\n world!!\")", shouldEvalTo: true)
  }

  /// .string? should return false for any non-string type.
  func testIsStringWithOthers() {
    expectThat("(.string? 10)", shouldEvalTo: false)
    expectThat("(.string? 515.15151)", shouldEvalTo: false)
    expectThat("(.string? nil)", shouldEvalTo: false)
    expectThat("(.string? true)", shouldEvalTo: false)
    expectThat("(.string? false)", shouldEvalTo: false)
    expectThat("(.string? \\a)", shouldEvalTo: false)
    expectThat("(.string? 'a)", shouldEvalTo: false)
    expectThat("(.string? :a)", shouldEvalTo: false)
    expectThat("(.string? [])", shouldEvalTo: false)
    expectThat("(.string? '())", shouldEvalTo: false)
    expectThat("(.string? {})", shouldEvalTo: false)
    expectThat("(.string? .cons)", shouldEvalTo: false)
    expectThat("(.string? (fn [] 0))", shouldEvalTo: false)
  }

  /// .string? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.string?)")
    expectArityErrorFrom("(.string? \"foo\" \"bar\")")
  }
}

class TestIsChar : InterpreterTest {
  /// .char? should return true for characters.
  func testIsCharWithCharacter() {
    runCode("(def a \\a)")
    expectThat("(.char? \\a)", shouldEvalTo: true)
    expectThat("(.char? \\newline)", shouldEvalTo: true)
    expectThat("(.char? a)", shouldEvalTo: true)
  }

  /// .char? should return false for any non-character type.
  func testIsCharWithOthers() {
    expectThat("(.char? 1025)", shouldEvalTo: false)
    expectThat("(.char? 3.141592)", shouldEvalTo: false)
    expectThat("(.char? nil)", shouldEvalTo: false)
    expectThat("(.char? true)", shouldEvalTo: false)
    expectThat("(.char? false)", shouldEvalTo: false)
    expectThat("(.char? \"\")", shouldEvalTo: false)
    expectThat("(.char? 'a)", shouldEvalTo: false)
    expectThat("(.char? :a)", shouldEvalTo: false)
    expectThat("(.char? [])", shouldEvalTo: false)
    expectThat("(.char? '())", shouldEvalTo: false)
    expectThat("(.char? {})", shouldEvalTo: false)
    expectThat("(.char? .cons)", shouldEvalTo: false)
    expectThat("(.char? (fn [a b] :hello))", shouldEvalTo: false)
  }

  /// .char? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.char?)")
    expectArityErrorFrom("(.char? \\\\ \\a)")
  }
}

class TestIsSymbol : InterpreterTest {
  /// .symbol? should return true for symbols.
  func testIsSymbolWithSymbol() {
    runCode("(def a 'b)")
    expectThat("(.symbol? 'a)", shouldEvalTo: true)
    expectThat("(.symbol? 'mysymbol)", shouldEvalTo: true)
    expectThat("(.symbol? a)", shouldEvalTo: true)
  }

  /// .symbol? should return false for any non-symbol type.
  func testIsSymbolWithOthers() {
    expectThat("(.symbol? 1025)", shouldEvalTo: false)
    expectThat("(.symbol? 3.141592)", shouldEvalTo: false)
    expectThat("(.symbol? nil)", shouldEvalTo: false)
    expectThat("(.symbol? true)", shouldEvalTo: false)
    expectThat("(.symbol? false)", shouldEvalTo: false)
    expectThat("(.symbol? \"\")", shouldEvalTo: false)
    expectThat("(.symbol? \\a)", shouldEvalTo: false)
    expectThat("(.symbol? :a)", shouldEvalTo: false)
    expectThat("(.symbol? [])", shouldEvalTo: false)
    expectThat("(.symbol? '())", shouldEvalTo: false)
    expectThat("(.symbol? {})", shouldEvalTo: false)
    expectThat("(.symbol? .cons)", shouldEvalTo: false)
    expectThat("(.symbol? (fn [a b] :hello))", shouldEvalTo: false)
  }

  /// .symbol? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.symbol?)")
    expectArityErrorFrom("(.symbol? 'a 'a)")
  }
}

class TestIsKeyword : InterpreterTest {
  /// .keyword? should return true for keywords.
  func testIsKeywordWithKeyword() {
    runCode("(def a :some-keyword)")
    expectThat("(.keyword? :a)", shouldEvalTo: true)
    expectThat("(.keyword? :else)", shouldEvalTo: true)
    expectThat("(.keyword? a)", shouldEvalTo: true)
  }

  /// .keyword? should return false for any non-keyword type.
  func testIsKeywordWithOthers() {
    expectThat("(.keyword? 1025)", shouldEvalTo: false)
    expectThat("(.keyword? 3.141592)", shouldEvalTo: false)
    expectThat("(.keyword? nil)", shouldEvalTo: false)
    expectThat("(.keyword? true)", shouldEvalTo: false)
    expectThat("(.keyword? false)", shouldEvalTo: false)
    expectThat("(.keyword? \"\")", shouldEvalTo: false)
    expectThat("(.keyword? \\a)", shouldEvalTo: false)
    expectThat("(.keyword? 'a)", shouldEvalTo: false)
    expectThat("(.keyword? [])", shouldEvalTo: false)
    expectThat("(.keyword? '())", shouldEvalTo: false)
    expectThat("(.keyword? {})", shouldEvalTo: false)
    expectThat("(.keyword? .cons)", shouldEvalTo: false)
    expectThat("(.keyword? (fn [a b] :hello))", shouldEvalTo: false)
  }

  /// .keyword? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.keyword?)")
    expectArityErrorFrom("(.keyword? :a :a)")
  }
}

class TestIsFn : InterpreterTest {
  /// .fn? should return true for user-defined functions.
  func testIsFnWithUserDefined() {
    expectThat("(.fn? (fn [a b] (.+ a b)))", shouldEvalTo: true)
    runCode("(def testfn (fn [a b] (.+ 1 2 a b)))")
    expectThat("(.fn? testfn)", shouldEvalTo: true)
  }

  /// .fn? should return true for built-in functions.
  func testIsFnWithBuiltIns() {
    expectThat("(.fn? .+)", shouldEvalTo: true)
    expectThat("(.fn? .fn?)", shouldEvalTo: true)
    expectThat("(.fn? .cons)", shouldEvalTo: true)
  }

  /// .fn? should return false for any non-function type.
  func testIsFnWithOthers() {
    expectThat("(.fn? 1025)", shouldEvalTo: false)
    expectThat("(.fn? 3.141592)", shouldEvalTo: false)
    expectThat("(.fn? nil)", shouldEvalTo: false)
    expectThat("(.fn? true)", shouldEvalTo: false)
    expectThat("(.fn? false)", shouldEvalTo: false)
    expectThat("(.fn? \"\")", shouldEvalTo: false)
    expectThat("(.fn? \\a)", shouldEvalTo: false)
    expectThat("(.fn? 'a)", shouldEvalTo: false)
    expectThat("(.fn? :a)", shouldEvalTo: false)
    expectThat("(.fn? [])", shouldEvalTo: false)
    expectThat("(.fn? '())", shouldEvalTo: false)
    expectThat("(.fn? {})", shouldEvalTo: false)
  }

  // .fn? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.fn?)")
    expectArityErrorFrom("(.fn? .+ .+)")
  }
}

class TestIsEval : InterpreterTest {
  // TODO
}

class TestIsTrue : InterpreterTest {
  // .true? should return true for the value true.
  func testIsTrueWithBooleans() {
    expectThat("(.true? true)", shouldEvalTo: true)
    expectThat("(.true? false)", shouldEvalTo: false)
  }

  // .true? should return false for any value that isn't exactly true.
  func testIsTrueWithOthers() {
    expectThat("(.true? 0)", shouldEvalTo: false)
    expectThat("(.true? 0.0)", shouldEvalTo: false)
    expectThat("(.true? nil)", shouldEvalTo: false)
    expectThat("(.true? \"\")", shouldEvalTo: false)
    expectThat("(.true? \\a)", shouldEvalTo: false)
    expectThat("(.true? 'a)", shouldEvalTo: false)
    expectThat("(.true? :a)", shouldEvalTo: false)
    expectThat("(.true? [])", shouldEvalTo: false)
    expectThat("(.true? '())", shouldEvalTo: false)
    expectThat("(.true? {})", shouldEvalTo: false)
    expectThat("(.true? (fn [] 0))", shouldEvalTo: false)
    expectThat("(.true? .+)", shouldEvalTo: false)
  }

  // .true? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.true?)")
    expectArityErrorFrom("(.true? true true)")
  }
}

class TestIsFalse : InterpreterTest {
  // .false? should return true for the value false.
  func testIsFalseWithBooleans() {
    expectThat("(.false? true)", shouldEvalTo: false)
    expectThat("(.false? false)", shouldEvalTo: true)
  }

  // .false? should return false for any value that isn't exactly false.
  func testIsFalseWithOthers() {
    expectThat("(.false? 0)", shouldEvalTo: false)
    expectThat("(.false? 0.0)", shouldEvalTo: false)
    expectThat("(.false? nil)", shouldEvalTo: false)
    expectThat("(.false? \"\")", shouldEvalTo: false)
    expectThat("(.false? \\a)", shouldEvalTo: false)
    expectThat("(.false? 'a)", shouldEvalTo: false)
    expectThat("(.false? :a)", shouldEvalTo: false)
    expectThat("(.false? [])", shouldEvalTo: false)
    expectThat("(.false? '())", shouldEvalTo: false)
    expectThat("(.false? {})", shouldEvalTo: false)
    expectThat("(.false? (fn [] 0))", shouldEvalTo: false)
    expectThat("(.false? .+)", shouldEvalTo: false)
  }

  // .false? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.false?)")
    expectArityErrorFrom("(.false? false false)")
  }
}

class TestIsList : InterpreterTest {
  /// .list? should return true when called with list arguments.
  func testIsListWithLists() {
    expectThat("(.list? ())", shouldEvalTo: true)
    expectThat("(.list? '(1 2 3 4 5))", shouldEvalTo: true)
    expectThat("(.list? '(true nil \"foobar\" \\c :c 'c))", shouldEvalTo: true)
  }

  /// .list? should return false when called with non-list arguments.
  func testIsListWithOthers() {
    expectThat("(.list? nil)", shouldEvalTo: false)
    expectThat("(.list? true)", shouldEvalTo: false)
    expectThat("(.list? false)", shouldEvalTo: false)
    expectThat("(.list? 1523)", shouldEvalTo: false)
    expectThat("(.list? -92.123571)", shouldEvalTo: false)
    expectThat("(.list? \\v)", shouldEvalTo: false)
    expectThat("(.list? 'v)", shouldEvalTo: false)
    expectThat("(.list? :v)", shouldEvalTo: false)
    expectThat("(.list? \"foobar\")", shouldEvalTo: false)
    expectThat("(.list? [1 2 3])", shouldEvalTo: false)
    expectThat("(.list? {:a 1 :b 2})", shouldEvalTo: false)
    expectThat("(.list? .list?)", shouldEvalTo: false)
  }

  /// .list? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.list?)")
    expectArityErrorFrom("(.list? () ())")
  }
}

class TestIsVector : InterpreterTest {
  /// .vector? should return true when called with vector arguments.
  func testIsListWithLists() {
    expectThat("(.vector? [])", shouldEvalTo: true)
    expectThat("(.vector? [1 2 3 4 5])", shouldEvalTo: true)
    expectThat("(.vector? [true nil \"foobar\" \\c :c 'c])", shouldEvalTo: true)
  }

  /// .vector? should return false when called with non-vector arguments.
  func testIsListWithOthers() {
    expectThat("(.vector? nil)", shouldEvalTo: false)
    expectThat("(.vector? true)", shouldEvalTo: false)
    expectThat("(.vector? false)", shouldEvalTo: false)
    expectThat("(.vector? 1523)", shouldEvalTo: false)
    expectThat("(.vector? -92.123571)", shouldEvalTo: false)
    expectThat("(.vector? \\v)", shouldEvalTo: false)
    expectThat("(.vector? 'v)", shouldEvalTo: false)
    expectThat("(.vector? :v)", shouldEvalTo: false)
    expectThat("(.vector? \"foobar\")", shouldEvalTo: false)
    expectThat("(.vector? '(1 2 3))", shouldEvalTo: false)
    expectThat("(.vector? {:a 1 :b 2})", shouldEvalTo: false)
    expectThat("(.vector? .vector?)", shouldEvalTo: false)
  }

  /// .vector? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.vector?)")
    expectArityErrorFrom("(.vector? () ())")
  }
}

class TestIsMap : InterpreterTest {
  /// .map? should return true when called with map arguments.
  func testIsMapWithMaps() {
    expectThat("(.map? {})", shouldEvalTo: true)
    expectThat("(.map? {:foo \"foo\" 'bar 15293})", shouldEvalTo: true)
    expectThat("(.map? {'(1 2 3) {:foo :bar} [5 6] true \"hello\" nil})", shouldEvalTo: true)
  }

  /// .map? should return false when called with non-map arguments
  func testIsMapWithOthers() {
    expectThat("(.map? nil)", shouldEvalTo: false)
    expectThat("(.map? true)", shouldEvalTo: false)
    expectThat("(.map? false)", shouldEvalTo: false)
    expectThat("(.map? 65182)", shouldEvalTo: false)
    expectThat("(.map? 0.00001238)", shouldEvalTo: false)
    expectThat("(.map? \\y)", shouldEvalTo: false)
    expectThat("(.map? 'y)", shouldEvalTo: false)
    expectThat("(.map? :y)", shouldEvalTo: false)
    expectThat("(.map? \"foobar\")", shouldEvalTo: false)
    expectThat("(.map? #\"[0-9]+\")", shouldEvalTo: false)
    expectThat("(.map? '(1 2 3))", shouldEvalTo: false)
    expectThat("(.map? [1 2 3])", shouldEvalTo: false)
    expectThat("(.map? .map?)", shouldEvalTo: false)
  }

  /// .map? should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.map?)")
    expectArityErrorFrom("(.map? {} {})")
  }
}

class TestIsPos : InterpreterTest {
  // .pos? should return true for positive numbers.
  func testWithPositiveNumbers() {
    expectThat("(.pos? 1)", shouldEvalTo: true)
    expectThat("(.pos? 0.0000001)", shouldEvalTo: true)
  }

  // .pos? should return false for negative numbers.
  func testWithNegativeNumbers() {
    expectThat("(.pos? -1)", shouldEvalTo: false)
    expectThat("(.pos? -0.0000001)", shouldEvalTo: false)
  }

  // .pos? should return false for zero.
  func testWithZero() {
    expectThat("(.pos? 0)", shouldEvalTo: false)
    expectThat("(.pos? 0.0)", shouldEvalTo: false)
  }

  // .pos? should return true for positive infinity.
  func testWithPosInf() {
    expectThat("(.pos? (./ 1.0 0.0))", shouldEvalTo: true)
  }

  // .pos? should return false for other special float values.
  func testWithSpecial() {
    expectThat("(.pos? (./ -1.0 0.0))", shouldEvalTo: false)
    expectThat("(.pos? (./ 0.0 0.0))", shouldEvalTo: false)
  }
}

class TestIsNeg : InterpreterTest {
  // .neg? should return true for negative numbers.
  func testWithNegativeNumbers() {
    expectThat("(.neg? -1)", shouldEvalTo: true)
    expectThat("(.neg? -0.0000001)", shouldEvalTo: true)
  }

  // .neg? should return false for positive numbers.
  func testWithPositiveNumbers() {
    expectThat("(.neg? 1)", shouldEvalTo: false)
    expectThat("(.neg? 0.0000001)", shouldEvalTo: false)
  }

  // .neg? should return false for zero.
  func testWithZero() {
    expectThat("(.neg? 0)", shouldEvalTo: false)
    expectThat("(.neg? 0.0)", shouldEvalTo: false)
  }

  // .neg? should return true for negative infinity.
  func testWithNegInf() {
    expectThat("(.neg? (./ -1.0 0.0))", shouldEvalTo: true)
  }

  // .neg? should return false for other special float values.
  func testWithSpecial() {
    expectThat("(.neg? (./ 1.0 0.0))", shouldEvalTo: false)
    expectThat("(.neg? (./ 0.0 0.0))", shouldEvalTo: false)
  }
}

class TestIsZero : InterpreterTest {
  // .zero? should return true for numerical zero values.
  func testIsZeroWithNumbers() {
    expectThat("(.zero? 0)", shouldEvalTo: true)
    expectThat("(.zero? 0.0)", shouldEvalTo: true)
    expectThat("(.zero? 1)", shouldEvalTo: false)
    expectThat("(.zero? -999)", shouldEvalTo: false)
    expectThat("(.zero? 0.00001)", shouldEvalTo: false)
    expectThat("(.zero? -1293.58812)", shouldEvalTo: false)
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

class TestIsSubnormal : InterpreterTest {
  /// .subnormal? should return true for subnormal double values and false for non-subnormal double values.
  func testWithDoubles() {
    expectThat("(.subnormal? 0.00000000001)", shouldEvalTo: false)
    expectThat("(.subnormal? -0.00000000001)", shouldEvalTo: false)
    // Build a subnormal number (1 / 2048^93)
    runCode("(def a ((fn [val ctr] (if (.= 0 ctr) val (recur (./ val 2048.0) (.- ctr 1)))) 1.0 93))")
    expectThat("(.subnormal? a)", shouldEvalTo: true)
  }

  /// .subnormal? should return false for integers.
  func testWithInts() {
    expectThat("(.subnormal? 0)", shouldEvalTo: false)
    expectThat("(.subnormal? 152)", shouldEvalTo: false)
    expectThat("(.subnormal? -38)", shouldEvalTo: false)
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

class TestIsInfinite : InterpreterTest {
  /// .infinite? should return true for infinite double values and false for non-infinite double values.
  func testWithDoubles() {
    expectThat("(.infinite? 100000000000000.0)", shouldEvalTo: false)
    expectThat("(.infinite? -100000000000000.0)", shouldEvalTo: false)
    // Test with positive infinity
    expectThat("(.infinite? (./ 1 0.0))", shouldEvalTo: true)
    expectThat("(.infinite? (./ 1.0 0))", shouldEvalTo: true)
    expectThat("(.infinite? (./ -1.0 -0.0))", shouldEvalTo: true)
    // Test with negative infinity
    expectThat("(.infinite? (./ 1 -0.0))", shouldEvalTo: true)
    expectThat("(.infinite? (./ -1.0 0))", shouldEvalTo: true)
    expectThat("(.infinite? (./ -1.0 0.0))", shouldEvalTo: true)
  }

  /// .infinite? should return false for integers.
  func testWithInts() {
    expectThat("(.infinite? 0)", shouldEvalTo: false)
    expectThat("(.infinite? 152)", shouldEvalTo: false)
    expectThat("(.infinite? -38)", shouldEvalTo: false)
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

class TestIsNaN : InterpreterTest {
  /// .nan? should return true for double values equal to NaN, and false for non-NaN double values.
  func testWithDoubles() {
    expectThat("(.nan? 100000000000000.0)", shouldEvalTo: false)
    expectThat("(.nan? -100000000000000.0)", shouldEvalTo: false)
    // Test with 0.0/0/0
    expectThat("(.nan? (./ 0 0.0))", shouldEvalTo: true)
    expectThat("(.nan? (./ 0.0 0))", shouldEvalTo: true)
    expectThat("(.nan? (./ 0.0 0.0))", shouldEvalTo: true)
    // test with negatives
    expectThat("(.nan? (./ 0 -0.0))", shouldEvalTo: true)
    expectThat("(.nan? (./ 0.0 -0))", shouldEvalTo: true)
    expectThat("(.nan? (./ -0.0 -0.0))", shouldEvalTo: true)
  }

  /// .nan? should return false for integers.
  func testWithInts() {
    expectThat("(.nan? 0)", shouldEvalTo: false)
    expectThat("(.nan? 152)", shouldEvalTo: false)
    expectThat("(.nan? -38)", shouldEvalTo: false)
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

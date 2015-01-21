//
//  TestQueries.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/19/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class testIsNil : InterpreterTest {
  /// nil? should return true for 'nil'.
  func testIsNilWithNil() {
    expectThat("(.nil? nil)", shouldEvalTo: .BoolLiteral(true))
  }

  /// nil? should return false for any non-nil value or type, even those that are falsy.
  func testIsNilWithOthers() {
    expectThat("(.nil? 0)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.nil? 0.0)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.nil? true)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.nil? false)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.nil? \"\")", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.nil? \\a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.nil? 'a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.nil? :a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.nil? [])", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.nil? '())", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.nil? {})", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.nil? .cons)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.nil? (fn [] nil))", shouldEvalTo: .BoolLiteral(false))
  }

  func testIsNilArity() {
    expectArityErrorFrom("(.nil?)")
    expectArityErrorFrom("(.nil? nil nil)")
  }
}

class testIsNumber : InterpreterTest {
  /// number? should return true for any integer.
  func testIsNumberWithInts() {
    expectThat("(.number? 0)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.number? 1)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.number? -1)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.number? 12345)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.number? -12345)", shouldEvalTo: .BoolLiteral(true))
  }

  /// number? should return true for any floating-point value.
  func testIsNumberWithFloats() {
    expectThat("(.number? 0.0)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.number? 1.0001)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.number? -1.12345)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.number? 12345.000)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.number? -12345.009)", shouldEvalTo: .BoolLiteral(true))
  }

  /// number? should return false for any non-numeric type.
  func testIsNumberWithOthers() {
    expectThat("(.number? nil)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.number? true)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.number? false)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.number? \"\")", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.number? \\a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.number? 'a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.number? :a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.number? [])", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.number? '())", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.number? {})", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.number? .cons)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.number? (fn [] 0))", shouldEvalTo: .BoolLiteral(false))
  }

  func testIsNumberArity() {
    expectArityErrorFrom("(.number?)")
    expectArityErrorFrom("(.number? 0 0)")
  }
}

class testIsInt : InterpreterTest {
  /// int? should return true for any integer.
  func testIsIntWithInts() {
    expectThat("(.int? 0)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.int? 1)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.int? -1)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.int? 12345)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.int? -12345)", shouldEvalTo: .BoolLiteral(true))
  }

  /// int? should return false for any floating-point value.
  func testIsIntWithFloats() {
    expectThat("(.int? 0.0)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.int? 1.0001)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.int? -1.12345)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.int? 12345.000)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.int? -12345.009)", shouldEvalTo: .BoolLiteral(false))
  }

  /// int? should return false for any non-numeric type.
  func testIsIntWithOthers() {
    expectThat("(.int? nil)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.int? true)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.int? false)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.int? \"\")", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.int? \\a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.int? 'a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.int? :a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.int? [])", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.int? '())", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.int? {})", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.int? .cons)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.int? (fn [] 0))", shouldEvalTo: .BoolLiteral(false))
  }

  func testIsIntArity() {
    expectArityErrorFrom("(.int?)")
    expectArityErrorFrom("(.int? 1 1)")
  }
}

class testIsFloat : InterpreterTest {
  /// float? should return false for any integer.
  func testIsFloatWithInts() {
    expectThat("(.float? 0)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.float? 1)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.float? -1)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.float? 12345)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.float? -12345)", shouldEvalTo: .BoolLiteral(false))
  }

  /// float? should return true for any floating-point value.
  func testIsFloatWithFloats() {
    expectThat("(.float? 0.0)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.float? 1.0001)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.float? -1.12345)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.float? 12345.000)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.float? -12345.009)", shouldEvalTo: .BoolLiteral(true))
  }

  /// float? should return false for any non-numeric type.
  func testIsFloatWithOthers() {
    expectThat("(.float? nil)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.float? true)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.float? false)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.float? \"\")", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.float? \\a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.float? 'a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.float? :a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.float? [])", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.float? '())", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.float? {})", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.float? .cons)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.float? (fn [] 0))", shouldEvalTo: .BoolLiteral(false))
  }

  func testIsFloatArity() {
    expectArityErrorFrom("(.float?)")
    expectArityErrorFrom("(.float? 1.1 1.1)")
  }
}

class testIsString : InterpreterTest {
  /// string? should return true for strings.
  func testIsStringWithString() {
    expectThat("(.string? \"\")", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.string? \"foobar\")", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.string? \"hello \\n world!!\")", shouldEvalTo: .BoolLiteral(true))
  }

  /// string? should return false for any non-string type.
  func testIsStringWithOthers() {
    expectThat("(.string? 10)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.string? 515.15151)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.string? nil)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.string? true)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.string? false)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.string? \\a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.string? 'a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.string? :a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.string? [])", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.string? '())", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.string? {})", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.string? .cons)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.string? (fn [] 0))", shouldEvalTo: .BoolLiteral(false))
  }

  func testIsStringArity() {
    expectArityErrorFrom("(.string?)")
    expectArityErrorFrom("(.string? \"foo\" \"bar\")")
  }
}

class testIsChar : InterpreterTest {
  /// char? should return true for characters.
  func testIsCharWithCharacter() {
    runCode("(def a \\a)")
    expectThat("(.char? \\a)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.char? \\newline)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.char? a)", shouldEvalTo: .BoolLiteral(true))
  }

  /// char? should return false for any non-character type.
  func testIsCharWithOthers() {
    expectThat("(.char? 1025)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.char? 3.141592)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.char? nil)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.char? true)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.char? false)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.char? \"\")", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.char? 'a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.char? :a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.char? [])", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.char? '())", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.char? {})", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.char? .cons)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.char? (fn [a b] :hello))", shouldEvalTo: .BoolLiteral(false))
  }

  func testIsCharArity() {
    expectArityErrorFrom("(.char?)")
    expectArityErrorFrom("(.char? \\\\ \\a)")
  }
}

class testIsSymbol : InterpreterTest {
  /// symbol? should return true for symbols.
  func testIsSymbolWithSymbol() {
    runCode("(def a 'b)")
    expectThat("(.symbol? 'a)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.symbol? 'mysymbol)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.symbol? a)", shouldEvalTo: .BoolLiteral(true))
  }

  /// symbol? should return false for any non-symbol type.
  func testIsSymbolWithOthers() {
    expectThat("(.symbol? 1025)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.symbol? 3.141592)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.symbol? nil)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.symbol? true)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.symbol? false)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.symbol? \"\")", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.symbol? \\a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.symbol? :a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.symbol? [])", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.symbol? '())", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.symbol? {})", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.symbol? .cons)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.symbol? (fn [a b] :hello))", shouldEvalTo: .BoolLiteral(false))
  }

  func testIsSymbolArity() {
    expectArityErrorFrom("(.symbol?)")
    expectArityErrorFrom("(.symbol? 'a 'a)")
  }
}

class testIsKeyword : InterpreterTest {
  /// keyword? should return true for keywords.
  func testIsKeywordWithKeyword() {
    runCode("(def a :some-keyword)")
    expectThat("(.keyword? :a)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.keyword? :else)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.keyword? a)", shouldEvalTo: .BoolLiteral(true))
  }

  /// keyword? should return false for any non-keyword type.
  func testIsKeywordWithOthers() {
    expectThat("(.keyword? 1025)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.keyword? 3.141592)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.keyword? nil)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.keyword? true)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.keyword? false)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.keyword? \"\")", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.keyword? \\a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.keyword? 'a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.keyword? [])", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.keyword? '())", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.keyword? {})", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.keyword? .cons)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.keyword? (fn [a b] :hello))", shouldEvalTo: .BoolLiteral(false))
  }

  func testIsKeywordArity() {
    expectArityErrorFrom("(.keyword?)")
    expectArityErrorFrom("(.keyword? :a :a)")
  }
}

class testIsFn : InterpreterTest {
  /// fn? should return true for user-defined functions.
  func testIsFnWithUserDefined() {
    expectThat("(.fn? (fn [a b] (.+ a b)))", shouldEvalTo: .BoolLiteral(true))
    runCode("(def testfn (fn [a b] (.+ 1 2 a b)))")
    expectThat("(.fn? testfn)", shouldEvalTo: .BoolLiteral(true))
  }

  /// fn? should return true for built-in functions.
  func testIsFnWithBuiltIns() {
    expectThat("(.fn? .+)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.fn? .fn?)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.fn? .cons)", shouldEvalTo: .BoolLiteral(true))
  }

  /// fn? should return false for any non-function type.
  func testIsFnWithOthers() {
    expectThat("(.fn? 1025)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.fn? 3.141592)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.fn? nil)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.fn? true)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.fn? false)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.fn? \"\")", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.fn? \\a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.fn? 'a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.fn? :a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.fn? [])", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.fn? '())", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.fn? {})", shouldEvalTo: .BoolLiteral(false))
  }

  func testIsFnArity() {
    expectArityErrorFrom("(.fn?)")
    expectArityErrorFrom("(.fn? .+ .+)")
  }
}

class testIsEval : InterpreterTest {
  // TODO
}

class testIsTrue : InterpreterTest {
  // true? should return true for the value true.
  func testIsTrueWithBooleans() {
    expectThat("(.true? true)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.true? false)", shouldEvalTo: .BoolLiteral(false))
  }

  // true? should return false for any value that isn't exactly true.
  func testIsTrueWithOthers() {
    expectThat("(.true? 0)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.true? 0.0)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.true? nil)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.true? \"\")", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.true? \\a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.true? 'a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.true? :a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.true? [])", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.true? '())", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.true? {})", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.true? (fn [] 0))", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.true? .+)", shouldEvalTo: .BoolLiteral(false))
  }

  func testIsTrueArity() {
    expectArityErrorFrom("(.true?)")
    expectArityErrorFrom("(.true? true true)")
  }
}

class testIsFalse : InterpreterTest {
  // false? should return true for the value false.
  func testIsFalseWithBooleans() {
    expectThat("(.false? true)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.false? false)", shouldEvalTo: .BoolLiteral(true))
  }

  // false? should return false for any value that isn't exactly false.
  func testIsFalseWithOthers() {
    expectThat("(.false? 0)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.false? 0.0)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.false? nil)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.false? \"\")", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.false? \\a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.false? 'a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.false? :a)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.false? [])", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.false? '())", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.false? {})", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.false? (fn [] 0))", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.false? .+)", shouldEvalTo: .BoolLiteral(false))
  }

  func testIsFalseArity() {
    expectArityErrorFrom("(.false?)")
    expectArityErrorFrom("(.false? false false)")
  }
}

class testIsList : InterpreterTest {
  // TODO
}

class testIsVector : InterpreterTest {
  // TODO
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
  // zero? should return true for numerical zero values.
  func testIsZeroWithNumbers() {
    expectThat("(.zero? 0)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.zero? 0.0)", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.zero? 1)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.zero? -999)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.zero? 0.00001)", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.zero? -1293.58812)", shouldEvalTo: .BoolLiteral(false))
  }

  // zero? should fail for any non-number type.
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

  func testIsZeroArity() {
    expectArityErrorFrom("(.zero?)")
    expectArityErrorFrom("(.zero? 0 0)")
  }
}

class testIsSubnormal : InterpreterTest {
  // TODO
}

class testIsInfinite : InterpreterTest {
  // TODO
}

class testIsNaN : InterpreterTest {
  // TODO
}

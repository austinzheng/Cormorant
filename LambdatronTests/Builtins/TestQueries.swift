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
}

class testIsString : InterpreterTest {
  // TODO
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
}

class testIsEval : InterpreterTest {
  // TODO
}

class testIsTrue : InterpreterTest {
  // TODO
}

class testIsFalse : InterpreterTest {
  // TODO
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
  // TODO
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

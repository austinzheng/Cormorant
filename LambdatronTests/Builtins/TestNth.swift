//
//  TestNth.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/16/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestVectorNth : InterpreterTest {
  func testValidIndex() {
    expectThat("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] 2)", shouldEvalTo: .StringLiteral("baz"))
  }

  func testEmptyVector() {
    expectThat("(.nth [] 0)", shouldFailAs: .OutOfBoundsError)
  }

  func testNegativeIndex() {
    expectThat("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] -1)", shouldFailAs: .OutOfBoundsError)
  }

  func testTooLargeIndex() {
    expectThat("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] 4)", shouldFailAs: .OutOfBoundsError)
  }

  func testInvalidTypedIndex() {
    expectThat("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] [1 2 3])", shouldFailAs: .InvalidArgumentError)
  }

  func testValidIndexWithFallback() {
    expectThat("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] 2 999)", shouldEvalTo: .StringLiteral("baz"))
  }

  func testNegativeIndexWithFallback() {
    expectThat("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] -10 999)", shouldEvalTo: .IntegerLiteral(999))
  }

  func testTooLargeIndexWithFallback() {
    expectThat("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] 108 998)", shouldEvalTo: .IntegerLiteral(998))
  }

  func testInvalidTypeOfIndexWithFallback() {
    expectThat("(.nth [\"foo\" \"bar\" \"baz\" \"qux\"] [1 2 3] nil)", shouldFailAs: .InvalidArgumentError)
  }
}

class TestListNth : InterpreterTest {
  func testValidIndex() {
    expectThat("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") 2)", shouldEvalTo: .StringLiteral("baz"))
  }

  func testEmptyList() {
    expectThat("(.nth '() 0)", shouldFailAs: .OutOfBoundsError)
  }

  func testNegativeIndex() {
    expectThat("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") -1)", shouldFailAs: .OutOfBoundsError)
  }

  func testTooLargeIndex() {
    expectThat("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") 4)", shouldFailAs: .OutOfBoundsError)
  }

  func testInvalidTypedIndex() {
    expectThat("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") [1 2 3])", shouldFailAs: .InvalidArgumentError)
  }

  func testValidIndexWithFallback() {
    expectThat("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") 2 999)", shouldEvalTo: .StringLiteral("baz"))
  }

  func testNegativeIndexWithFallback() {
    expectThat("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") -10 997)", shouldEvalTo: .IntegerLiteral(997))
  }

  func testTooLargeIndexWithFallback() {
    expectThat("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") 108 996)", shouldEvalTo: .IntegerLiteral(996))
  }

  func testInvalidTypeOfIndexWithFallback() {
    expectThat("(.nth '(\"foo\" \"bar\" \"baz\" \"qux\") [1 2 3] nil)", shouldFailAs: .InvalidArgumentError)
  }
}

class TestStringNth : InterpreterTest {
  func testValidIndex() {
    expectThat("(.nth \"the quick brown fox\" 10)", shouldEvalTo: .CharacterLiteral("b"))
  }

  func testEmptyList() {
    expectThat("(.nth \"\" 0)", shouldFailAs: .OutOfBoundsError)
  }

  func testNegativeIndex() {
    expectThat("(.nth \"the quick brown fox\" -10)", shouldFailAs: .OutOfBoundsError)
  }

  func testTooLargeIndex() {
    expectThat("(.nth \"the quick brown fox\" 500)", shouldFailAs: .OutOfBoundsError)
  }

  func testInvalidTypedIndex() {
    expectThat("(.nth \"the quick brown fox\" [1 2 3])", shouldFailAs: .InvalidArgumentError)
  }

  func testValidIndexWithFallback() {
    expectThat("(.nth \"the quick brown fox\" 2 999)", shouldEvalTo: .CharacterLiteral("e"))
  }

  func testNegativeIndexWithFallback() {
    expectThat("(.nth \"the quick brown fox\" -10 995)", shouldEvalTo: .IntegerLiteral(995))
  }

  func testTooLargeIndexWithFallback() {
    expectThat("(.nth \"the quick brown fox\" 108 994)", shouldEvalTo: .IntegerLiteral(994))
  }

  func testInvalidTypeOfIndexWithFallback() {
    expectThat("(.nth \"the quick brown fox\" [1 2 3] nil)", shouldFailAs: .InvalidArgumentError)
  }
}

class TestInvalidTypesNth : InterpreterTest {
  func testMapArg() {
    expectThat("(.nth {\"one\" 1, \"two\" 2} 0)", shouldFailAs: .InvalidArgumentError)
  }

  func testCharArg() {
    expectThat("(.nth \\a 0)", shouldFailAs: .InvalidArgumentError)
  }

  func testSymbolArg() {
    expectThat("(.nth 'badarg 0)", shouldFailAs: .InvalidArgumentError)
  }

  func testKeywordArg() {
    expectThat("(.nth :badarg 0)", shouldFailAs: .InvalidArgumentError)
  }

  func testIntegerArg() {
    expectThat("(.nth 12345 0)", shouldFailAs: .InvalidArgumentError)
  }

  func testFloatingPointArg() {
    expectThat("(.nth 3.141592 0)", shouldFailAs: .InvalidArgumentError)
  }
}

class TestNthArity : InterpreterTest {
  func testZeroArity() {
    expectArityErrorFrom("(.nth)")
  }

  func testOneArity() {
    expectArityErrorFrom("(.nth [0 1 2])")
  }

  func testThreeArity() {
    expectArityErrorFrom("(.nth [0 1 2] 0 \\a nil)")
  }
}

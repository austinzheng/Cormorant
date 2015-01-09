//
//  tests-builtin-collections.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/8/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

func collectionFnsTests() -> [LambdatronTest] {
  var buffer : [LambdatronTest] = []
  
  // nth tests
  buffer.append(SucceedOnEvalTest.test("vector nth with valid idx",
    input: "(nth [\"foo\" \"bar\" \"baz\" \"qux\"] 2)",
    shouldEvalTo: .StringLiteral("baz")))
  buffer.append(FailOnEvalTest.test("empty vector",
    input: "(nth [] 0)",
    shouldCauseError: .OutOfBoundsError))
  buffer.append(FailOnEvalTest.test("vector nth with negative idx",
    input: "(nth [\"foo\" \"bar\" \"baz\" \"qux\"] -1)",
    shouldCauseError: .OutOfBoundsError))
  buffer.append(FailOnEvalTest.test("vector nth with too large idx",
    input: "(nth [\"foo\" \"bar\" \"baz\" \"qux\"] 4)",
    shouldCauseError: .OutOfBoundsError))
  buffer.append(FailOnEvalTest.test("vector nth with invalid type of idx",
    input: "(nth [\"foo\" \"bar\" \"baz\" \"qux\"] [1 2 3])",
    shouldCauseError: .InvalidArgumentError))
  buffer.append(SucceedOnEvalTest.test("vector nth with valid idx, fallback",
    input: "(nth [\"foo\" \"bar\" \"baz\" \"qux\"] 2 999)",
    shouldEvalTo: .StringLiteral("baz")))
  buffer.append(SucceedOnEvalTest.test("vector nth with negative idx, fallback",
    input: "(nth [\"foo\" \"bar\" \"baz\" \"qux\"] -10 999)",
    shouldEvalTo: .IntegerLiteral(999)))
  buffer.append(SucceedOnEvalTest.test("vector nth with too large idx, fallback",
    input: "(nth [\"foo\" \"bar\" \"baz\" \"qux\"] 108 999)",
    shouldEvalTo: .IntegerLiteral(999)))
  buffer.append(FailOnEvalTest.test("vector nth with invalid type of idx, fallback",
    input: "(nth [\"foo\" \"bar\" \"baz\" \"qux\"] [1 2 3] nil)",
    shouldCauseError: .InvalidArgumentError))
  
  buffer.append(SucceedOnEvalTest.test("list nth with valid idx",
    input: "(nth '(\"foo\" \"bar\" \"baz\" \"qux\") 2)",
    shouldEvalTo: .StringLiteral("baz")))
  buffer.append(FailOnEvalTest.test("empty list",
    input: "(nth '() 0)",
    shouldCauseError: .OutOfBoundsError))
  buffer.append(FailOnEvalTest.test("list nth with negative idx",
    input: "(nth '(\"foo\" \"bar\" \"baz\" \"qux\") -1)",
    shouldCauseError: .OutOfBoundsError))
  buffer.append(FailOnEvalTest.test("list nth with too large idx",
    input: "(nth '(\"foo\" \"bar\" \"baz\" \"qux\") 4)",
    shouldCauseError: .OutOfBoundsError))
  buffer.append(FailOnEvalTest.test("list nth with invalid type of idx",
    input: "(nth '(\"foo\" \"bar\" \"baz\" \"qux\") [1 2 3])",
    shouldCauseError: .InvalidArgumentError))
  buffer.append(SucceedOnEvalTest.test("list nth with valid idx, fallback",
    input: "(nth '(\"foo\" \"bar\" \"baz\" \"qux\") 2 999)",
    shouldEvalTo: .StringLiteral("baz")))
  buffer.append(SucceedOnEvalTest.test("list nth with negative idx, fallback",
    input: "(nth '(\"foo\" \"bar\" \"baz\" \"qux\") -10 999)",
    shouldEvalTo: .IntegerLiteral(999)))
  buffer.append(SucceedOnEvalTest.test("list nth with too large idx, fallback",
    input: "(nth '(\"foo\" \"bar\" \"baz\" \"qux\") 108 999)",
    shouldEvalTo: .IntegerLiteral(999)))
  buffer.append(FailOnEvalTest.test("list nth with invalid type of idx, fallback",
    input: "(nth '(\"foo\" \"bar\" \"baz\" \"qux\") [1 2 3] nil)",
    shouldCauseError: .InvalidArgumentError))
  
  // Vector in fn position tests
  buffer.append(SucceedOnEvalTest.test("vector in fn position with valid idx",
    input: "([100 200 300 400.0] 3)",
    shouldEvalTo: .FloatLiteral(400.0)))
  buffer.append(FailOnEvalTest.test("vector in fn position with negative idx",
    input: "([100 200 300 400.0] -1)",
    shouldCauseError: .OutOfBoundsError))
  buffer.append(FailOnEvalTest.test("vector in fn position with too large idx",
    input: "([100 200 300 400.0] 100)",
    shouldCauseError: .OutOfBoundsError))
  buffer.append(FailOnEvalTest.test("vector in fn position with fallback",
    input: "([100 200 300 400.0] 0 nil)",
    shouldCauseError: .ArityError))
  buffer.append(FailOnEvalTest.test("list in fn position should fail",
    input: "('(100 200 300 400.0) 0)",
    shouldCauseError: .NotEvalableError))
  return buffer
}

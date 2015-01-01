//
//  tests.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/30/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

struct OverallTestResults {
  let pass : Int
  let fail : Int
  var total : Int {
    return pass + fail
  }
  init(_ pass: Int, _ fail: Int) {
    self.pass = pass; self.fail = fail
  }
}

func +(lhs: OverallTestResults, rhs: OverallTestResults) -> OverallTestResults {
  return OverallTestResults(lhs.pass + rhs.pass, lhs.fail + rhs.fail)
}

func runTests(tests: [LambdatronTest]) -> OverallTestResults {
  var pass = 0
  var fail = 0
  let context = Context.globalContextInstance()
  for test in tests {
    let result = test.run(context)
    switch result {
    case .Pass:
      println("PASSED (\(test.name))")
      pass += 1
    case let .Fail(expected, got):
      println("FAILED (\(test.name)): expected \(expected), got \(got)")
      fail += 1
    case let .Error(error):
      println("ERROR (\(test.name)): \(error)")
      fatalError("Error in test case, aborting.")
    }
  }
  return OverallTestResults(pass, fail)
}

enum TestResult {
  case Pass
  case Fail(expected: String, got: String)
  case Error(String)
}

/// Abstract class representing a Lambdatron test case.
class LambdatronTest {
  let name : String
  
  init(name: String) {
    self.name = name
  }
  
  func run(ctx: Context) -> TestResult {
    fatalError("Subclass must override")
  }
}

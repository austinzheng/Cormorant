//
//  tests-readerexpand.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/1/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Class testing reader macro expansion given an input string to be lexed and parsed, and an output string.
class ReaderMacroTest : LambdatronTest {
  var input : String
  var output : String
  
  init(_ name: String, _ input: String, _ output: String) {
    self.input = input
    self.output = output
    super.init(name: name)
  }
  
  class func test(name: String, input: String, shouldReaderExpandTo output: String) -> ReaderMacroTest {
    return ReaderMacroTest(name, input, output)
  }
  
  override func run(ctx: Context) -> TestResult {
    // TODO: we need to NOT make a new global context instance every time a single test is run.
    //    let context = Context.globalContextInstance()
    let context = ctx
    let lexed = lex(input)
    switch lexed {
    case let .Success(lexed):
      let parsed = parse(lexed, context)
      switch parsed {
      case let .Success(parsed):
        let expanded = parsed.readerExpand()
        let actualOutput = expanded.describe(context)
        if actualOutput == output {
          return .Pass
        }
        else {
          return .Fail(expected: output, got: actualOutput)
        }
      case .Failure:
        return .Error("parse failure")
      }
    case .Failure:
      return .Error("lex failure")
    }
  }
}

func readerExpandTests() -> [LambdatronTest] {
  var buffer : [LambdatronTest] = []
  buffer.append(ReaderMacroTest.test(
    "expand '100",
    input: "'100",
    shouldReaderExpandTo: "(quote 100)"))
  buffer.append(ReaderMacroTest.test(
    "expand 'a",
    input: "'a",
    shouldReaderExpandTo: "(quote a)"))
  buffer.append(ReaderMacroTest.test(
    "expand `a",
    input: "`a",
    shouldReaderExpandTo: "(quote a)"))
  buffer.append(ReaderMacroTest.test(
    "expand `(a)",
    input: "`(a)",
    shouldReaderExpandTo: "(.seq (.concat (.list (quote a))))"))
  buffer.append(ReaderMacroTest.test(
    "expand `(a b)",
    input: "`(a b)",
    shouldReaderExpandTo: "(.seq (.concat (.list (quote a)) (.list (quote b))))"))
  buffer.append(ReaderMacroTest.test(
    "expand `(`a b)",
    input: "`(`a b)",
    shouldReaderExpandTo: "(.seq (.concat (.list (.seq (.concat (.list (quote quote)) (.list (quote a))))) (.list (quote b))))"))
  buffer.append(ReaderMacroTest.test(
    "expand `(a `b)",
    input: "`(a `b)",
    shouldReaderExpandTo: "(.seq (.concat (.list (quote a)) (.list (.seq (.concat (.list (quote quote)) (.list (quote b)))))))"))
  buffer.append(ReaderMacroTest.test(
    "expand `(`a `b)",
    input: "`(`a `b)",
    shouldReaderExpandTo: "(.seq (.concat (.list (.seq (.concat (.list (quote quote)) (.list (quote a))))) (.list (.seq (.concat (.list (quote quote)) (.list (quote b)))))))"))
  buffer.append(ReaderMacroTest.test(
    "expand `(~a)",
    input: "`(~a)",
    shouldReaderExpandTo: "(.seq (.concat (.list a)))"))
  buffer.append(ReaderMacroTest.test(
    "expand `(~a b)",
    input: "`(~a b)",
    shouldReaderExpandTo: "(.seq (.concat (.list a) (.list (quote b))))"))
  buffer.append(ReaderMacroTest.test(
    "expand `(a ~b)",
    input: "`(a ~b)",
    shouldReaderExpandTo: "(.seq (.concat (.list (quote a)) (.list b)))"))
  buffer.append(ReaderMacroTest.test(
    "expand `(~a ~b)",
    input: "`(~a ~b)",
    shouldReaderExpandTo: "(.seq (.concat (.list a) (.list b)))"))
  buffer.append(ReaderMacroTest.test(
    "expand `(~@a)",
    input: "`(~@a)",
    shouldReaderExpandTo: "(.seq (.concat a))"))
  buffer.append(ReaderMacroTest.test(
    "expand `(~@a b)",
    input: "`(~@a b)",
    shouldReaderExpandTo: "(.seq (.concat a (.list (quote b))))"))
  buffer.append(ReaderMacroTest.test(
    "expand `(a ~@b)",
    input: "`(a ~@b)",
    shouldReaderExpandTo: "(.seq (.concat (.list (quote a)) b))"))
  buffer.append(ReaderMacroTest.test(
    "expand `(~@a ~b)",
    input: "`(~@a ~b)",
    shouldReaderExpandTo: "(.seq (.concat a (.list b)))"))
  buffer.append(ReaderMacroTest.test(
    "expand `(~a ~@b)",
    input: "`(~a ~@b)",
    shouldReaderExpandTo: "(.seq (.concat (.list a) b))"))
  buffer.append(ReaderMacroTest.test(
    "expand `(~@a ~@b)",
    input: "`(~@a ~@b)",
    shouldReaderExpandTo: "(.seq (.concat a b))"))
  buffer.append(ReaderMacroTest.test(
    "expand `'a",
    input: "`'a",
    shouldReaderExpandTo: "(.seq (.concat (.list (quote quote)) (.list (quote a))))"))
  buffer.append(ReaderMacroTest.test(
    "expand '`a",
    input: "'`a",
    shouldReaderExpandTo: "(quote (quote a))"))
  buffer.append(ReaderMacroTest.test(
    "expand `~a",
    input: "`~a",
    shouldReaderExpandTo: "a"))
  buffer.append(ReaderMacroTest.test(
    "expand ``~~a",
    input: "``~~a",
    shouldReaderExpandTo: "a"))
  buffer.append(ReaderMacroTest.test(
    "expand ``(~~a)",
    input: "``(~~a)",
    shouldReaderExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list a)))))))))"))
  buffer.append(ReaderMacroTest.test(
    "expand ``(~~@a)",
    input: "``(~~@a)",
    shouldReaderExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) a))))))))"))
  buffer.append(ReaderMacroTest.test(
    "expand ``(~@~a)",
    input: "``(~@~a)",
    shouldReaderExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list a))))))"))
  buffer.append(ReaderMacroTest.test(
    "expand ``(~@~@a)",
    input: "``(~@~@a)",
    shouldReaderExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) a)))))"))
  buffer.append(ReaderMacroTest.test(
    "expand ``(w ~x ~~y)",
    input: "``(w ~x ~~y)",
    shouldReaderExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote w)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (quote x))))) (.list (.seq (.concat (.list (quote .list)) (.list y)))))))))"))
  buffer.append(ReaderMacroTest.test(
    "expand ``(~a `(~b `(~c)))",
    input: "``(~a `(~b `(~c)))",
    shouldReaderExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (quote a))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote b))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote c))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))"))
  buffer.append(ReaderMacroTest.test(
    "expand ``(~@a `(~@b `(~@c)))",
    input: "``(~@a `(~@b `(~@c)))",
    shouldReaderExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (quote a)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote b)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote c)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))"))
  buffer.append(ReaderMacroTest.test(
    "expand `(a `(b ~c ~~d))",
    input: "`(a `(b ~c ~~d))",
    shouldReaderExpandTo: "(.seq (.concat (.list (quote a)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote b)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (quote c))))) (.list (.seq (.concat (.list (quote .list)) (.list d))))))))))))"))
  return buffer
}

//
//  TestSyntaxQuote.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/15/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest

/// Test suite to exercise the quote, syntax-quote, unquote, and unquote-splice reader macro functionality.
class TestSyntaxQuote : XCTestCase {

  var interpreter = Interpreter()

  func test(input: String, shouldExpandTo output: String) {
    let lexed = lex(input)
    switch lexed {
    case let .Success(lexed):
      let parsed = parse(lexed, interpreter.context)
      switch parsed {
      case let .Success(parsed):
        let expanded = parsed.expand()
        switch expanded {
        case let .Success(expanded):
          let actualOutput = expanded.describe(interpreter.context)
          XCTAssert(actualOutput == output, "expected: \(output), got: \(actualOutput)")
        case let .Failure(f):
          XCTFail("reader macro expansion error: \(f.description)")
        }
      case .Failure:
        XCTFail("parser error")
      }
    case .Failure:
      XCTFail("lexer error")
    }
  }

  func testQuoteInteger() {
    test("'100", shouldExpandTo: "(quote 100)")
  }

  func testQuoteSymbol() {
    test("'a", shouldExpandTo: "(quote a)")
  }

  func testSyntaxQuoteSymbol() {
    test("`a", shouldExpandTo: "(quote a)")
  }

  func testSyntaxQuoteList1() {
    test("`(a)", shouldExpandTo: "(.seq (.concat (.list (quote a))))")
  }

  func testSyntaxQuoteList2() {
    test("`(a b)", shouldExpandTo: "(.seq (.concat (.list (quote a)) (.list (quote b))))")
  }

  func testSyntaxQuoteList3() {
    test("`(`a b)", shouldExpandTo: "(.seq (.concat (.list (.seq (.concat (.list (quote quote)) (.list (quote a))))) (.list (quote b))))")
  }

  func testSyntaxQuoteList4() {
    test("`(a `b)", shouldExpandTo: "(.seq (.concat (.list (quote a)) (.list (.seq (.concat (.list (quote quote)) (.list (quote b)))))))")
  }

  func testSyntaxQuoteList5() {
    test("`(`a `b)", shouldExpandTo: "(.seq (.concat (.list (.seq (.concat (.list (quote quote)) (.list (quote a))))) (.list (.seq (.concat (.list (quote quote)) (.list (quote b)))))))")
  }

  func testUnquoteList1() {
    test("`(~a)", shouldExpandTo: "(.seq (.concat (.list a)))")
  }

  func testUnquoteList2() {
    test("`(~a b)", shouldExpandTo: "(.seq (.concat (.list a) (.list (quote b))))")
  }

  func testUnquoteList3() {
    test("`(a ~b)", shouldExpandTo: "(.seq (.concat (.list (quote a)) (.list b)))")
  }

  func testUnquoteList4() {
    test("`(~a ~b)", shouldExpandTo: "(.seq (.concat (.list a) (.list b)))")
  }

  func testUnquoteSplice() {
    test("`(~@a)", shouldExpandTo: "(.seq (.concat a))")
  }

  func testUnquoteSpliceList1() {
    test("`(~@a b)", shouldExpandTo: "(.seq (.concat a (.list (quote b))))")
  }

  func testUnquoteSpliceList2() {
    test("`(a ~@b)", shouldExpandTo: "(.seq (.concat (.list (quote a)) b))")
  }

  func testUnquoteSpliceList3() {
    test("`(~@a ~b)", shouldExpandTo: "(.seq (.concat a (.list b)))")
  }

  func testUnquoteSpliceList4() {
    test("`(~a ~@b)", shouldExpandTo: "(.seq (.concat (.list a) b))")
  }

  func testUnquoteSpliceList5() {
    test("`(~@a ~@b)", shouldExpandTo: "(.seq (.concat a b))")
  }

  func testSyntaxQuoteQuote() {
    test("`'a", shouldExpandTo: "(.seq (.concat (.list (quote quote)) (.list (quote a))))")
  }

  func testQuoteSyntaxQuote() {
    test("'`a", shouldExpandTo: "(quote (quote a))")
  }

  func testSyntaxQuoteUnquote() {
    test("`~a", shouldExpandTo: "a")
  }

  func testDoubleSyntaxQuoteDoubleUnquote() {
    test("``~~a", shouldExpandTo: "a")
  }

  func testTripleSyntaxQuoteTripleUnquote() {
    test("```~~~a", shouldExpandTo: "a")
  }

  func testDoubleSyntaxQuoteListDoubleUnquote() {
    test("``(~~a)", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list a)))))))))")
  }

  func testDoubleSyntaxQuoteListUnquoteUnquoteSplice() {
    test("``(~~@a)", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) a))))))))")
  }

  func testDoubleSyntaxQuoteListUnquoteSpliceUnquote() {
    test("``(~@~a)", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list a))))))")
  }

  func testDoubleSyntaxQuoteListDoubleUnquoteSplice() {
    test("``(~@~@a)", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) a)))))")
  }

  func testDoubleSyntaxQuoteMultiUnquote() {
    test("``(w ~x ~~y)", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote w)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (quote x))))) (.list (.seq (.concat (.list (quote .list)) (.list y)))))))))")
  }

  func testDoubleSyntaxQuoteUnquoteSpliceUnquoteQuote() {
    test("``(~@~(zed 'a 'b))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (zed (quote a) (quote b))))))))")
  }

  func testDoubleSyntaxQuoteUnquoteSpliceUnquoteSyntaxQuote() {
    test("``(~@~(zed `a `b))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (zed (quote a) (quote b))))))))")
  }

  func testDoubleSyntaxQuoteUnquoteUnquoteSpliceQuote() {
    // Mainly: test quotes embedded within an unquote-splice.
    test("``(~~@(zed 'a 'b))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (zed (quote a) (quote b))))))))))")
  }

  func testDoubleSyntaxQuoteUnquoteUnquoteSpliceSyntaxQuote() {
    test("``(~~@(zed `a `b))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (zed (quote a) (quote b))))))))))")
  }

  func testNestedUnquotes() {
    test("``(~(a ~(`b `c) d))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote a)) (.list ((quote b) (quote c))) (.list (quote d)))))))))))))")
  }

  func testDeeplyNestedUnquotes() {
    test("``(a `b ~(`c `(d ~e) ~f) g)", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote a)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote b))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (.seq (.concat (.list (quote quote)) (.list (quote c))))) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote d)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (quote e))))))))))) (.list f))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote g)))))))))))))")
  }

  func testDeeplyNestedUnquotes2() {
    test("``(a ~(b `c ~('d `e (f g)) h))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote a)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote b)) (.list (.seq (.concat (.list (quote quote)) (.list (quote c))))) (.list ((quote d) (quote e) (f g))) (.list (quote h)))))))))))))")
  }

  func testDeeplyNestedUnquotes3() {
    test("``(a ~(~(b `c `d)))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote a)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (b (quote c) (quote d))))))))))))))")
  }

  func testNestedUnquoteSplices() {
    test("``(~@(a ~@(`b `c) d))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote a)) ((quote b) (quote c)) (.list (quote d))))))))))")
  }

  func testDeeplyNestedUnquoteSplices() {
    test("``(a `b ~@(`c `(d ~@e) ~@f) g)", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote a)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote b))))))))))))))))) (.list (.seq (.concat (.list (.seq (.concat (.list (quote quote)) (.list (quote c))))) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote d)))))))) (.list (quote e)))))))) f))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote g)))))))))))))")
  }

  func testDeeplyNestedUnquoteSplices2() {
    test("``(a ~@(b `c ~@('d `e (f g)) h))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote a)))))))) (.list (.seq (.concat (.list (quote b)) (.list (.seq (.concat (.list (quote quote)) (.list (quote c))))) ((quote d) (quote e) (f g)) (.list (quote h))))))))))")
  }

  func testDeeplyNestedUnquoteSplices3() {
    test("``(a ~@(~@(b `c `d)))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote a)))))))) (.list (.seq (.concat (b (quote c) (quote d))))))))))")
  }

  func testNestedUnquotesAndUnquoteSplices() {
    test("``(~(a ~@(`b `c) d))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote a)) ((quote b) (quote c)) (.list (quote d)))))))))))))")
  }

  func testDeeplyNestedUnquotesAndUnquoteSplices() {
    test("``(a `b ~(`c `(d ~@e) ~f) g)", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote a)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote b))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (.seq (.concat (.list (quote quote)) (.list (quote c))))) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote d)))))))) (.list (quote e)))))))) (.list f))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote g)))))))))))))")
  }

  func testDeeplyNestedUnquotesAndUnquoteSplices2() {
    test("``(a ~(b `c ~@('d `e (f g)) h))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote a)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote b)) (.list (.seq (.concat (.list (quote quote)) (.list (quote c))))) ((quote d) (quote e) (f g)) (.list (quote h)))))))))))))")
  }

  func testDeeplyNestedUnquotesAndUnquoteSplices3() {
    test("``(a ~@(~(b `c `d)))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote a)))))))) (.list (.seq (.concat (.list (b (quote c) (quote d)))))))))))")
  }

  func testListInSyntaxQuotedList() {
    test("`(a (b c) d)", shouldExpandTo: "(.seq (.concat (.list (quote a)) (.list (.seq (.concat (.list (quote b)) (.list (quote c))))) (.list (quote d))))")
  }

  func testUnquotedList() {
    test("`(a ~(b `c))", shouldExpandTo: "(.seq (.concat (.list (quote a)) (.list (b (quote c)))))")
  }

  func testSyntaxUnquotedList() {
    test("`(a ~@(b `c))", shouldExpandTo: "(.seq (.concat (.list (quote a)) (b (quote c))))")
  }

  func testArrayInSyntaxQuotedList() {
    test("`(a [b c] d)", shouldExpandTo: "(.seq (.concat (.list (quote a)) (.list (apply .vector (.seq (.concat (.list (quote b)) (.list (quote c)))))) (.list (quote d))))")
  }

  func testUnquotedArray() {
    test("`(a ~[b `c])", shouldExpandTo: "(.seq (.concat (.list (quote a)) (.list [b (quote c)])))")
  }

  func testUnquoteSplicedArray() {
    test("`(a ~@[b `c])", shouldExpandTo: "(.seq (.concat (.list (quote a)) [b (quote c)]))")
  }

  func testMapInSyntaxQuotedList() {
    test("`(a {b c} d)", shouldExpandTo: "(.seq (.concat (.list (quote a)) (.list (apply .hashmap (.seq (.concat (.list (quote b)) (.list (quote c)))))) (.list (quote d))))")
  }

  func testUnquotedMap() {
    test("`(a ~{b `c})", shouldExpandTo: "(.seq (.concat (.list (quote a)) (.list {b (quote c)})))")
  }

  func testUnquoteSplicedMap() {
    test("`(a ~@{b `c})", shouldExpandTo: "(.seq (.concat (.list (quote a)) {b (quote c)}))")
  }

  func testDoubleSyntaxQuoteDeeplyNested1() {
    test("``(~a `(~b `(~c)))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (quote a))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote b))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote c))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))")
  }

  func testDoubleSyntaxQuoteDeeplyNested2() {
    test("``(~@a `(~@b `(~@c)))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (quote a)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote b)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote c)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))")
  }

  func testDoubleSyntaxQuoteDeeplyNested3() {
    test("`(a `(b ~c ~~d))", shouldExpandTo: "(.seq (.concat (.list (quote a)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote b)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (quote c))))) (.list (.seq (.concat (.list (quote .list)) (.list d))))))))))))")
  }

  func testDefnMix() {
    test("`(a ~b (c ~@d))", shouldExpandTo: "(.seq (.concat (.list (quote a)) (.list b) (.list (.seq (.concat (.list (quote c)) d)))))")
  }
}

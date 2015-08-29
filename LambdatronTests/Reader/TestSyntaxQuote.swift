//
//  TestSyntaxQuote.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/15/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test suite to exercise the quote, syntax-quote, unquote, and unquote-splice reader macro functionality.
class TestSyntaxQuote : InterpreterTest {

  func testQuoteInteger() {
    expect("'100", shouldExpandTo: "(quote 100)")
  }

  func testQuoteSymbol() {
    expect("'a", shouldExpandTo: "(quote a)")
  }

  func testQuoteQualifiedSymbol() {
    expect("'foo/bar", shouldExpandTo: "(quote foo/bar)")
  }

  func testSyntaxQuoteSymbol() {
    expect("`a", shouldExpandTo: "(quote user/a)")
  }

  func testSyntaxQuoteQualifiedSymbol() {
    expect("`foo/bar", shouldExpandTo: "(quote foo/bar)")
  }

  func testSyntaxQuoteList1() {
    expect("`(a)", shouldExpandTo: "(.seq (.concat (.list (quote user/a))))")
  }

  func testSyntaxQuoteList2() {
    expect("`(a b)", shouldExpandTo: "(.seq (.concat (.list (quote user/a)) (.list (quote user/b))))")
  }

  func testSyntaxQuoteList3() {
    expect("`(`a b)",
      shouldExpandTo: "(.seq (.concat (.list (.seq (.concat (.list (quote quote)) (.list (quote user/a))))) (.list (quote user/b))))")
  }

  func testSyntaxQuoteList4() {
    expect("`(a `b)",
      shouldExpandTo: "(.seq (.concat (.list (quote user/a)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/b)))))))")
  }

  func testSyntaxQuoteList5() {
    expect("`(`a `b)",
      shouldExpandTo: "(.seq (.concat (.list (.seq (.concat (.list (quote quote)) (.list (quote user/a))))) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/b)))))))")
  }

  func testUnquoteList1() {
    expect("`(~a)", shouldExpandTo: "(.seq (.concat (.list a)))")
  }

  func testUnquoteList2() {
    expect("`(~a b)", shouldExpandTo: "(.seq (.concat (.list a) (.list (quote user/b))))")
  }

  func testUnquoteList3() {
    expect("`(a ~b)", shouldExpandTo: "(.seq (.concat (.list (quote user/a)) (.list b)))")
  }

  func testUnquoteList4() {
    expect("`(~a ~b)", shouldExpandTo: "(.seq (.concat (.list a) (.list b)))")
  }

  func testUnquoteSplice() {
    expect("`(~@a)", shouldExpandTo: "(.seq (.concat a))")
  }

  func testUnquoteSpliceList1() {
    expect("`(~@a b)", shouldExpandTo: "(.seq (.concat a (.list (quote user/b))))")
  }

  func testUnquoteSpliceList2() {
    expect("`(a ~@b)", shouldExpandTo: "(.seq (.concat (.list (quote user/a)) b))")
  }

  func testUnquoteSpliceList3() {
    expect("`(~@a ~b)", shouldExpandTo: "(.seq (.concat a (.list b)))")
  }

  func testUnquoteSpliceList4() {
    expect("`(~a ~@b)", shouldExpandTo: "(.seq (.concat (.list a) b))")
  }

  func testUnquoteSpliceList5() {
    expect("`(~@a ~@b)", shouldExpandTo: "(.seq (.concat a b))")
  }

  func testSyntaxQuoteQuote() {
    expect("`'a", shouldExpandTo: "(.seq (.concat (.list (quote quote)) (.list (quote user/a))))")
  }

  func testQuoteSyntaxQuote() {
    expect("'`a", shouldExpandTo: "(quote (quote user/a))")
  }

  func testSyntaxQuoteUnquote() {
    expect("`~a", shouldExpandTo: "a")
  }

  func testDoubleSyntaxQuoteDoubleUnquote() {
    expect("``~~a", shouldExpandTo: "a")
  }

  func testTripleSyntaxQuoteTripleUnquote() {
    expect("```~~~a", shouldExpandTo: "a")
  }

  func testDoubleSyntaxQuoteListDoubleUnquote() {
    expect("``(~~a)", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list a)))))))))")
  }

  func testDoubleSyntaxQuoteListUnquoteUnquoteSplice() {
    expect("``(~~@a)", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) a))))))))")
  }

  func testDoubleSyntaxQuoteListUnquoteSpliceUnquote() {
    expect("``(~@~a)", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list a))))))")
  }

  func testDoubleSyntaxQuoteListDoubleUnquoteSplice() {
    expect("``(~@~@a)", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) a)))))")
  }

  func testDoubleSyntaxQuoteMultiUnquote() {
    expect("``(w ~x ~~y)",
      shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/w)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (quote user/x))))) (.list (.seq (.concat (.list (quote .list)) (.list y)))))))))")
  }

  func testDoubleSyntaxQuoteUnquoteSpliceUnquoteQuote() {
    expect("``(~@~(zed 'a 'b))",
      shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (zed (quote a) (quote b))))))))")
  }

  func testDoubleSyntaxQuoteUnquoteSpliceUnquoteSyntaxQuote() {
    expect("``(~@~(zed `a `b))",
      shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (zed (quote user/a) (quote user/b))))))))")
  }

  func testDoubleSyntaxQuoteUnquoteUnquoteSpliceQuote() {
    // Mainly: test quotes embedded within an unquote-splice.
    expect("``(~~@(zed 'a 'b))",
      shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (zed (quote a) (quote b))))))))))")
  }

  func testDoubleSyntaxQuoteUnquoteUnquoteSpliceSyntaxQuote() {
    expect("``(~~@(zed `a `b))",
      shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (zed (quote user/a) (quote user/b))))))))))")
  }

  func testNestedUnquotes() {
    expect("``(~(a ~(`b `c) d))",
      shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote user/a)) (.list ((quote user/b) (quote user/c))) (.list (quote user/d)))))))))))))")
  }

  func testDeeplyNestedUnquotes() {
    expect("``(a `b ~(`c `(d ~e) ~f) g)",
      shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/a)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/b))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (.seq (.concat (.list (quote quote)) (.list (quote user/c))))) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/d)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (quote user/e))))))))))) (.list f))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/g)))))))))))))")
  }

  func testDeeplyNestedUnquotes2() {
    expect("``(a ~(b `c ~('d `e (f g)) h))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/a)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote user/b)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/c))))) (.list ((quote d) (quote user/e) (f g))) (.list (quote user/h)))))))))))))")
  }

  func testDeeplyNestedUnquotes3() {
    expect("``(a ~(~(b `c `d)))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/a)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (b (quote user/c) (quote user/d))))))))))))))")
  }

  func testNestedUnquoteSplices() {
    expect("``(~@(a ~@(`b `c) d))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote user/a)) ((quote user/b) (quote user/c)) (.list (quote user/d))))))))))")
  }

  func testDeeplyNestedUnquoteSplices() {
    expect("``(a `b ~@(`c `(d ~@e) ~@f) g)",
      shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/a)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/b))))))))))))))))) (.list (.seq (.concat (.list (.seq (.concat (.list (quote quote)) (.list (quote user/c))))) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/d)))))))) (.list (quote user/e)))))))) f))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/g)))))))))))))")
  }

  func testDeeplyNestedUnquoteSplices2() {
    expect("``(a ~@(b `c ~@('d `e (f g)) h))",
      shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/a)))))))) (.list (.seq (.concat (.list (quote user/b)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/c))))) ((quote d) (quote user/e) (f g)) (.list (quote user/h))))))))))")
  }

  func testDeeplyNestedUnquoteSplices3() {
    expect("``(a ~@(~@(b `c `d)))", shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/a)))))))) (.list (.seq (.concat (b (quote user/c) (quote user/d))))))))))")
  }

  func testNestedUnquotesAndUnquoteSplices() {
    expect("``(~(a ~@(`b `c) d))",
      shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote user/a)) ((quote user/b) (quote user/c)) (.list (quote user/d)))))))))))))")
  }

  func testDeeplyNestedUnquotesAndUnquoteSplices() {
    expect("``(a `b ~(`c `(d ~@e) ~f) g)",
      shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/a)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/b))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (.seq (.concat (.list (quote quote)) (.list (quote user/c))))) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/d)))))))) (.list (quote user/e)))))))) (.list f))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/g)))))))))))))")
  }

  func testDeeplyNestedUnquotesAndUnquoteSplices2() {
    expect("``(a ~(b `c ~@('d `e (f g)) h))",
      shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/a)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote user/b)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/c))))) ((quote d) (quote user/e) (f g)) (.list (quote user/h)))))))))))))")
  }

  func testDeeplyNestedUnquotesAndUnquoteSplices3() {
    expect("``(a ~@(~(b `c `d)))",
      shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/a)))))))) (.list (.seq (.concat (.list (b (quote user/c) (quote user/d)))))))))))")
  }

  func testListInSyntaxQuotedList() {
    expect("`(a (b c) d)",
      shouldExpandTo: "(.seq (.concat (.list (quote user/a)) (.list (.seq (.concat (.list (quote user/b)) (.list (quote user/c))))) (.list (quote user/d))))")
  }

  func testUnquotedList() {
    expect("`(a ~(b `c))", shouldExpandTo: "(.seq (.concat (.list (quote user/a)) (.list (b (quote user/c)))))")
  }

  func testSyntaxUnquotedList() {
    expect("`(a ~@(b `c))", shouldExpandTo: "(.seq (.concat (.list (quote user/a)) (b (quote user/c))))")
  }

  func testArrayInSyntaxQuotedList() {
    expect("`(a [b c] d)",
      shouldExpandTo: "(.seq (.concat (.list (quote user/a)) (.list (apply .vector (.seq (.concat (.list (quote user/b)) (.list (quote user/c)))))) (.list (quote user/d))))")
  }

  func testUnquotedArray() {
    expect("`(a ~[b `c])", shouldExpandTo: "(.seq (.concat (.list (quote user/a)) (.list [b (quote user/c)])))")
  }

  func testUnquoteSplicedArray() {
    expect("`(a ~@[b `c])", shouldExpandTo: "(.seq (.concat (.list (quote user/a)) [b (quote user/c)]))")
  }

  func testMapInSyntaxQuotedList() {
    expect("`(a {b c} d)",
      shouldExpandTo: "(.seq (.concat (.list (quote user/a)) (.list (apply .hashmap (.seq (.concat (.list (quote user/b)) (.list (quote user/c)))))) (.list (quote user/d))))")
  }

  func testUnquotedMap() {
    expect("`(a ~{b `c})", shouldExpandTo: "(.seq (.concat (.list (quote user/a)) (.list {b (quote user/c)})))")
  }

  func testUnquoteSplicedMap() {
    expect("`(a ~@{b `c})", shouldExpandTo: "(.seq (.concat (.list (quote user/a)) {b (quote user/c)}))")
  }

  func testDoubleSyntaxQuoteDeeplyNested1() {
    expect("``(~a `(~b `(~c)))",
      shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (quote user/a))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/b))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/c))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))")
  }

  func testDoubleSyntaxQuoteDeeplyNested2() {
    expect("``(~@a `(~@b `(~@c)))",
      shouldExpandTo: "(.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (quote user/a)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/b)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/c)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))")
  }

  func testDoubleSyntaxQuoteDeeplyNested3() {
    expect("`(a `(b ~c ~~d))",
      shouldExpandTo: "(.seq (.concat (.list (quote user/a)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/b)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (quote user/c))))) (.list (.seq (.concat (.list (quote .list)) (.list d))))))))))))")
  }

  func testDefnMix() {
    expect("`(a ~b (c ~@d))",
      shouldExpandTo: "(.seq (.concat (.list (quote user/a)) (.list b) (.list (.seq (.concat (.list (quote user/c)) d)))))")
  }
}

/// Test suite to exercise the auto-gensym feature.
class TestSyntaxQuoteAutoGensym : InterpreterTest {
  // Note that these tests are a bit fragile. The numbers (e.g. __10__) may need to be adjusted if the stdlib is changed
  //  (specifically, if gensym definitions are added or removed there).

  /// Syntax-quote should properly gensym a bare symbol.
  func testBareSymbol() {
    expect("`someSymbol#", shouldExpandTo: "(quote someSymbol__2__auto__)")
  }

  /// Syntax-quote should produce only one gensym per unique #-qualified symbol in a list.
  func testOneGensymPerUniqueSymbol() {
    expect("`(a# b# a# c# b#)",
      shouldExpandTo: "(.seq (.concat (.list (quote a__2__auto__)) (.list (quote b__3__auto__)) (.list (quote a__2__auto__)) (.list (quote c__4__auto__)) (.list (quote b__3__auto__))))")
  }

  /// Syntax-quote should properly produce gensyms within nested collections.
  func testNestedCollections() {
    expect("`(a# (b# c#) [a#] {c# b#} d#)",
      shouldExpandTo: "(.seq (.concat (.list (quote a__2__auto__)) (.list (.seq (.concat (.list (quote b__3__auto__)) (.list (quote c__4__auto__))))) (.list (apply .vector (.seq (.concat (.list (quote a__2__auto__)))))) (.list (apply .hashmap (.seq (.concat (.list (quote c__4__auto__)) (.list (quote b__3__auto__)))))) (.list (quote d__5__auto__))))")
  }

  /// Syntax-quote should not gensym qualified or normal unqualified symbols.
  func testNonGensymSymbols() {
    expect("`(a b a# b# foo/a foo/b)",
      shouldExpandTo: "(.seq (.concat (.list (quote user/a)) (.list (quote user/b)) (.list (quote a__2__auto__)) (.list (quote b__3__auto__)) (.list (quote foo/a)) (.list (quote foo/b))))")
  }

  /// A nested syntax-quoted expression should have its own gensym context relative to an outer expression.
  func testNestedSyntaxQuotes() {
    expect("`(a# b# `(a# b# `(a# b#) a# b#) a# b#)",
      shouldExpandTo: "(.seq (.concat (.list (quote a__6__auto__)) (.list (quote b__7__auto__)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/a__4__auto__)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/b__5__auto__)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .seq)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .concat)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/a__2__auto__)))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote .list)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote .seq)) (.list (.seq (.concat (.list (quote .concat)) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote quote)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/b__3__auto__)))))))))))))))))))))))))))))))))))))))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/a__4__auto__)))))))) (.list (.seq (.concat (.list (quote .list)) (.list (.seq (.concat (.list (quote quote)) (.list (quote user/b__5__auto__)))))))))))))) (.list (quote a__6__auto__)) (.list (quote b__7__auto__))))")
  }

  /// Symbols in a syntax-quoted vector should be properly gensym'ed.
  func testVectors() {
    expect("`[a# b# c# b# c# a#]",
      shouldExpandTo: "(apply .vector (.seq (.concat (.list (quote a__2__auto__)) (.list (quote b__3__auto__)) (.list (quote c__4__auto__)) (.list (quote b__3__auto__)) (.list (quote c__4__auto__)) (.list (quote a__2__auto__)))))")
  }

  /// Symbols in a syntax-quoted map should be properly gensym'ed.
  func testMaps() {
    expect("`{a# b# c# a# d# b#}",
      shouldExpandTo: "(apply .hashmap (.seq (.concat (.list (quote a__2__auto__)) (.list (quote b__3__auto__)) (.list (quote d__4__auto__)) (.list (quote b__3__auto__)) (.list (quote c__5__auto__)) (.list (quote a__2__auto__)))))")
  }
}

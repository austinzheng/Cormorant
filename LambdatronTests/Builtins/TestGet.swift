//
//  TestGet.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/15/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

// Test the '.get' built-in function.
class TestGetBuiltin : InterpreterTest {

  /// .get should properly retrieve an in-bounds character from a string when no fallback is provided.
  func testStrInBoundsNoFallback() {
    expectThat("(.get \"foobar\" 0)", shouldEvalTo: .char("f"))
    expectThat("(.get \"foobar\" 5)", shouldEvalTo: .char("r"))
    expectThat("(.get \"the quick brown fox jumps over the lazy dog\" 31)", shouldEvalTo: .char("t"))
  }

  /// .get should properly retrieve an in-bounds character from a string when a fallback is provided.
  func testStrInBoundsWithFallback() {
    expectThat("(.get \"foobar\" 0 \"fallback\")", shouldEvalTo: .char("f"))
    expectThat("(.get \"foobar\" 5 \"fallback\")", shouldEvalTo: .char("r"))
    expectThat("(.get \"the quick brown fox jumps over the lazy dog\" 31 \"fallback\")", shouldEvalTo: .char("t"))
  }

  /// .get should properly return nil when asked to retrieve an out-of-bounds character from a string.
  func testStrBadBoundsNoFallback() {
    expectThat("(.get \"\" 0)", shouldEvalTo: .nilValue)
    expectThat("(.get \"foobar\" 6)", shouldEvalTo: .nilValue)
    expectThat("(.get \"foobar\" -1)", shouldEvalTo: .nilValue)
    expectThat("(.get \"the quick brown fox jumps over the lazy dog\" 1052)", shouldEvalTo: .nilValue)
  }

  /// .get should properly return the fallback when asked to retrieve an out-of-bounds character from a string.
  func testStrBadBoundsWithFallback() {
    expectThat("(.get \"\" 0 \\z)", shouldEvalTo: .char("z"))
    expectThat("(.get \"foobar\" 6 \"fallback\")", shouldEvalTo: .string("fallback"))
    expectThat("(.get \"foobar\" -1 12345)", shouldEvalTo: 12345)
    expectThat("(.get \"the quick brown fox jumps over the lazy dog\" 1052 true)", shouldEvalTo: true)
  }

  /// .get should properly return nil when asked to retrieve a character from a string with an invalid index.
  func testStrInvalidIdxNoFallback() {
    expectThat("(.get \"foobar\" true)", shouldEvalTo: .nilValue)
    expectThat("(.get \"foobar\" false)", shouldEvalTo: .nilValue)
    expectThat("(.get \"foobar\" 1.00002)", shouldEvalTo: .nilValue)
    expectThat("(.get \"foobar\" :0)", shouldEvalTo: .nilValue)
    expectThat("(.get \"foobar\" \\0)", shouldEvalTo: .nilValue)
    expectThat("(.get \"foobar\" ())", shouldEvalTo: .nilValue)
    expectThat("(.get \"foobar\" [])", shouldEvalTo: .nilValue)
    expectThat("(.get \"foobar\" {})", shouldEvalTo: .nilValue)
    expectThat("(.get \"foobar\" #\"0+\")", shouldEvalTo: .nilValue)
    expectThat("(.get \"foobar\" \"0\")", shouldEvalTo: .nilValue)
  }

  /// .get should properly return the fallback when asked to retrieve a character from a string with an invalid index.
  func testStrInvalidIdxWithFallback() {
    expectThat("(.get \"foobar\" true 1349)", shouldEvalTo: 1349)
    expectThat("(.get \"foobar\" false 1322)", shouldEvalTo: 1322)
    expectThat("(.get \"foobar\" 1.00002 6921)", shouldEvalTo: 6921)
    expectThat("(.get \"foobar\" :0 778)", shouldEvalTo: 778)
    expectThat("(.get \"foobar\" \\0 5617)", shouldEvalTo: 5617)
    expectThat("(.get \"foobar\" () 12)", shouldEvalTo: 12)
    expectThat("(.get \"foobar\" [] 86)", shouldEvalTo: 86)
    expectThat("(.get \"foobar\" {} 3)", shouldEvalTo: 3)
    expectThat("(.get \"foobar\" #\"0+\" 999)", shouldEvalTo: 999)
    expectThat("(.get \"foobar\" \"0\" -8126)", shouldEvalTo: -8126)
  }

  /// .get should properly retrieve an in-bounds item from a vector when no fallback is provided.
  func testVectorInBoundsNoFallback() {
    expectThat("(.get [true false \"foo\" 152 \"bar\"] 0)", shouldEvalTo: true)
    expectThat("(.get [true false \"foo\" 152 \"bar\"] 4)", shouldEvalTo: .string("bar"))
    expectThat("(.get [true false \"foo\" 152 \"bar\"] 3)", shouldEvalTo: 152)
    expectThat("(.get [3.141592] 0)", shouldEvalTo: 3.141592)
  }

  /// .get should properly retrieve an in-bounds item from a vector when a fallback is provided.
  func testVectorInBoundsWithFallback() {
    expectThat("(.get [true false \"foo\" 152 \"bar\"] 0 \"fallback\")", shouldEvalTo: true)
    expectThat("(.get [true false \"foo\" 152 \"bar\"] 4 \"fallback\")", shouldEvalTo: .string("bar"))
    expectThat("(.get [true false \"foo\" 152 \"bar\"] 3 \"fallback\")", shouldEvalTo: 152)
    expectThat("(.get [3.141592] 0  \"fallback\")", shouldEvalTo: 3.141592)
  }

  /// .get should properly return nil when asked to retrieve an out-of-bounds item from a vector.
  func testVectorBadBoundsNoFallback() {
    expectThat("(.get [] 0)", shouldEvalTo: .nilValue)
    expectThat("(.get [true false \"foo\" 152 \"bar\"] 5)", shouldEvalTo: .nilValue)
    expectThat("(.get [true false \"foo\" 152 \"bar\"] -1)", shouldEvalTo: .nilValue)
    expectThat("(.get [true false \"foo\" 152 \"bar\"] 9001)", shouldEvalTo: .nilValue)
  }

  /// .get should properly return the fallback when asked to retrieve an out-of-bounds item from a vector.
  func testVectorBadBoundsWithFallback() {
    expectThat("(.get [] 0 \"foo\")", shouldEvalTo: .string("foo"))
    expectThat("(.get [true false \"foo\" 152 \"bar\"] 5 998)", shouldEvalTo: 998)
    expectThat("(.get [true false \"foo\" 152 \"bar\"] -1 nil)", shouldEvalTo: .nilValue)
    expectThat("(.get [true false \"foo\" 152 \"bar\"] 9001 \\i)", shouldEvalTo: .char("i"))
  }

  /// .get should properly return nil when asked to retrieve a item from a vector with an invalid index.
  func testVectorInvalidIdxNoFallback() {
    expectThat("(.get [0 1 2 3 4] true)", shouldEvalTo: .nilValue)
    expectThat("(.get [0 1 2 3 4] false)", shouldEvalTo: .nilValue)
    expectThat("(.get [0 1 2 3 4] 1.00002)", shouldEvalTo: .nilValue)
    expectThat("(.get [0 1 2 3 4] :0)", shouldEvalTo: .nilValue)
    expectThat("(.get [0 1 2 3 4] \\0)", shouldEvalTo: .nilValue)
    expectThat("(.get [0 1 2 3 4] ())", shouldEvalTo: .nilValue)
    expectThat("(.get [0 1 2 3 4] [])", shouldEvalTo: .nilValue)
    expectThat("(.get [0 1 2 3 4] {})", shouldEvalTo: .nilValue)
    expectThat("(.get [0 1 2 3 4] #\"0+\")", shouldEvalTo: .nilValue)
    expectThat("(.get [0 1 2 3 4] \"0\")", shouldEvalTo: .nilValue)
  }

  /// .get should properly return the fallback when asked to retrieve a item from a vector with an invalid index.
  func testVectorInvalidIdxWithFallback() {
    expectThat("(.get [0 1 2 3 4] true -98)", shouldEvalTo: -98)
    expectThat("(.get [0 1 2 3 4] false \"foobar\")", shouldEvalTo: .string("foobar"))
    expectThat("(.get [0 1 2 3 4] 1.00002 \\space)", shouldEvalTo: .char(" "))
    expectThat("(.get [0 1 2 3 4] :0 699812.259)", shouldEvalTo: 699812.259)
    expectThat("(.get [0 1 2 3 4] \\0 1276)", shouldEvalTo: 1276)
    expectThat("(.get [0 1 2 3 4] () false)", shouldEvalTo: false)
    expectThat("(.get [0 1 2 3 4] [] nil)", shouldEvalTo: .nilValue)
    expectThat("(.get [0 1 2 3 4] {} 111992)", shouldEvalTo: 111992)
    expectThat("(.get [0 1 2 3 4] #\"0+\" \"deadbeef\")", shouldEvalTo: .string("deadbeef"))
    expectThat("(.get [0 1 2 3 4] \"0\" \\u)", shouldEvalTo: .char("u"))
  }

  /// .get should properly retrieve an item from a map with a valid key when no fallback is provided.
  func testMapValidKeyNoFallback() {
    expectThat("(.get {:foo \"foo\" \"bar\" \"bar\" 'baz 152} :foo)", shouldEvalTo: .string("foo"))
    expectThat("(.get {:foo \"foo\" \"bar\" \"bar\" 'baz 152} \"bar\")", shouldEvalTo: .string("bar"))
    expectThat("(.get {:foo \"foo\" \"bar\" \"bar\" 'baz 152} 'baz)", shouldEvalTo: 152)
    expectThat("(.get {152 true} 152)", shouldEvalTo: true)
  }

  /// .get should properly retrieve an item from a map with a valid key when a fallback is provided.
  func testMapValidKeyWithFallback() {
    expectThat("(.get {:foo \"foo\" \"bar\" \"bar\" 'baz 152} :foo \"fallback\")", shouldEvalTo: .string("foo"))
    expectThat("(.get {:foo \"foo\" \"bar\" \"bar\" 'baz 152} \"bar\" \"fallback\")", shouldEvalTo: .string("bar"))
    expectThat("(.get {:foo \"foo\" \"bar\" \"bar\" 'baz 152} 'baz \"fallback\")", shouldEvalTo: 152)
    expectThat("(.get {152 true} 152 \"fallback\")", shouldEvalTo: true)
  }

  /// .get should properly return nil when asked to retrieve an item from a map with an invalid key with no fallback.
  func testMapInvalidKeyNoFallback() {
    expectThat("(.get {} \"foo\")", shouldEvalTo: .nilValue)
    expectThat("(.get {:foo \\f :bar \\b :baz \\z} :qux)", shouldEvalTo: .nilValue)
    expectThat("(.get {:foo \\f :bar \\b :baz \\z} 15)", shouldEvalTo: .nilValue)
    expectThat("(.get {:foo \\f :bar \\b :baz \\z} nil)", shouldEvalTo: .nilValue)
    expectThat("(.get {:foo \\f :bar \\b :baz \\z} \"foo\")", shouldEvalTo: .nilValue)
    expectThat("(.get {:foo \\f :bar \\b :baz \\z} 'foo)", shouldEvalTo: .nilValue)
  }

  /// .get should properly return nil when asked to retrieve an item from a map with an invalid key with a fallback.
  func testMapInvalidKeyWithFallback() {
    expectThat("(.get {} \"foo\" 9612)", shouldEvalTo: 9612)
    expectThat("(.get {:foo \\f :bar \\b :baz \\z} :qux \"meela\")", shouldEvalTo: .string("meela"))
    expectThat("(.get {:foo \\f :bar \\b :baz \\z} 15 nil)", shouldEvalTo: .nilValue)
    expectThat("(.get {:foo \\f :bar \\b :baz \\z} nil 61)", shouldEvalTo: 61)
    expectThat("(.get {:foo \\f :bar \\b :baz \\z} \"foo\" true)", shouldEvalTo: true)
    expectThat("(.get {:foo \\f :bar \\b :baz \\z} 'foo \"fooooo\")", shouldEvalTo: .string("fooooo"))
  }

  /// .get should properly return nil when invoked on an invalid type.
  func testGetInvalidTypeNoFallback() {
    expectThat("(.get '(1 2 3 4 5 6) 1)", shouldEvalTo: .nilValue)
    expectThat("(.get \\c 0)", shouldEvalTo: .nilValue)
    expectThat("(.get :c 0)", shouldEvalTo: .nilValue)
    expectThat("(.get 'c 0)", shouldEvalTo: .nilValue)
    expectThat("(.get true 0)", shouldEvalTo: .nilValue)
    expectThat("(.get false 0)", shouldEvalTo: .nilValue)
    expectThat("(.get 1523 0)", shouldEvalTo: .nilValue)
    expectThat("(.get -9.991238 0)", shouldEvalTo: .nilValue)
    expectThat("(.get #\"hello\" 0)", shouldEvalTo: .nilValue)
  }

  /// .get should properly return the fallback when invoked on an invalid type.
  func testGetInvalidTypeWithFallback() {
    expectThat("(.get '(1 2 3 4 5 6) 1 5097)", shouldEvalTo: 5097)
    expectThat("(.get \\c 0 nil)", shouldEvalTo: .nilValue)
    expectThat("(.get :c 0 \\z)", shouldEvalTo: .char("z"))
    expectThat("(.get 'c 0 0)", shouldEvalTo: 0)
    expectThat("(.get true 0 812)", shouldEvalTo: 812)
    expectThat("(.get false 0 11011)", shouldEvalTo: 11011)
    expectThat("(.get 1523 0 2738.886188241)", shouldEvalTo: 2738.886188241)
    expectThat("(.get -9.991238 0 true)", shouldEvalTo: true)
    expectThat("(.get #\"hello\" 0 \\newline)", shouldEvalTo: .char("\n"))
  }

  /// .get should take either two or three arguments.
  func testArity() {
    expectArityErrorFrom("(.get)")
    expectArityErrorFrom("(.get [])")
    expectArityErrorFrom("(.get [nil] 0 \"fallback\" :another)")
  }
}

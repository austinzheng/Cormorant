Lambdatron
==========

[![Build Status](https://travis-ci.org/austinzheng/Lambdatron.svg?branch=master)](https://travis-ci.org/austinzheng/Lambdatron)
*CI disabled pending final release of Xcode 6.3*

An interpreter for a dialect of [Clojure](http://clojure.org/), implemented in Swift. The interpreter endeavors to match Clojure's behavior as closely as possible. The eventual goal is a library that can be used independently of the REPL front-end.


Application
-----------

Lambdatron is an OS X command-line application written in Swift. You will need Xcode 6.3 (beta 3) or later to build. Lambdatron runs on 10.9 or higher. Note that there is a `swift1.1` branch with the last Swift 1.1-compatible version of the codebase.

Run the executable either from within Xcode, or directly from the command line. Run with no arguments to start the interactive REPL, or run with the argument `-f <FILENAME>` to have the interpreter run code within a file. When in the REPL, type expressions at the command prompt and press 'Enter'.

[Grimoire](http://conj.io/) is a high-quality Clojure API reference, and can be used to reference the intended behavior of all included functions and special forms.

Need ideas? Try:

**Basic arithmetic**

- `(+ (* 2 4) (- 8 6) (+ (+ 1 3) 4))`

**Working with collections**

- `(cons 1 '(2 3 4))`
- `(rest '(1 2 3 4 5))`
- `(concat '(1 2 3) [4 5] {"six" 6 "seven" 7})`
- `(seq {1 "one" 2 true "three" [nil]})`

**Defining and calling a function**

- `(defn myfunc [a b] (+ a b 1))`, then `(myfunc 10 20)`
- Functions returning functions: `(defn f1 [arg1] (fn [arg2] (+ arg1 arg2)))`, then `(let [plusone (f1 1)] (plusone 3))`

**Recursion and iteration**

- Basic recursion: `(defn r [a] (print a " ") (if (> a 0) (r (- a 1))))`, then `(r 10)`
- Tail-call recursion using recur: `(defn recadd [mylist sofar] (if (= (first mylist) nil) sofar (recur (rest mylist) (+ (first mylist) sofar))))`, then `(recadd '(1 2 3 4 5) 0)`
- Iteration using loops: `(loop [a 10 b 0] (if (= a 0) b (recur (- a 1) (+ b a))))`

**Creating and using a macro**

- ``(defmacro my-when [predicate then-do] `(if ~predicate ~then-do nil))``, then `(my-when (= 1 1) "good")` or `(my-when (= 1 2) (do (print "this shouldn't show up") "bad"))`


### Current Limitations

Lambdatron has a couple of limitations, due mostly to its work-in-progress status:

- The REPL can only take one form at a time.
- There currently isn't any symbol mangling, so be careful when defining macros (e.g. don't use `& rest` as a vararg).

These will disappear as the feature set is filled out.


Features
--------

Lambdatron has a number of possibly useful features. Lambdatron's data structures should share identical semantics with Clojure's data structures (in that they are immutable and persistent), although some of them are implemented using Swift's naive copy-on-write features rather than as proper persistent data structures.

**Sequences**, like in Clojure. Sequences are immutable, and come in several flavors. You can prepend items using `cons`, extract the first element using `first`, or get the sequence consisting of all but the first element using `rest`. Create a sequence or get a sequence view using `seq`.

* Cons lists, the bread and butter of Lisp. Create the empty list using `()`. Or use the `list` function to create a list from zero or more arguments.
* Lazy sequences, which store a [thunk](http://en.wikipedia.org/wiki/Thunk) whose evaluation is deferred until absolutely necessary, after which they cache their value. Create a lazy sequence using the stdlib `lazy-seq` macro. Some of the stdlib and built-in functions may also return lazy sequences.
* Lightweight views into strings, vectors, and hashmaps, which allow treating those collections like sequences without requiring expensive copying operations. These are transparent to the end user.
* Contiguous lists backed by an `Array`. These are transparent to the end user.

**Vectors**, declared using square brackets: `[1 2 true "Lisp"]`, or the `vector` function. Unlike lists, vectors can't be used to invoke functions. Vectors can be used in function position with an integer index argument.

**Maps**, declared using braces: `{"one" 1 "two" nil "three" [1 2 3]}`, or the `hash-map` function. Maps can be used in function position in order to get a value for a key.

**Strings**, declared using double quotes: `"this is a string literal"`. Strings can be manipulated using `first`, `rest`, etc. Lambdatron also supports a mutating **string builder** which can be used to efficiently construct strings through concatenation. Create one using `sb`, work with the buffer using `sb-append` and `sb-reverse`, and turn it back into a string using `str`.

**Regular expressions**, declared as such: `#"[0-9]+"`, and backed by `NSRegularExpression`. Use `re-pattern` to create a regex at runtime. Use `re-first` to get the first match of a pattern in a string, and `re-seq` to get a list of all matches of a pattern in a string. Call `re-iterate` with a pattern, a string, and a function that takes two arguments; the function will be called once for each match with a vector of match tokens and a vector of ranges. The function can return `true` to end iteration, or any other value to allow iteration to continue.

**Functions** are first-class citizens which capture their environment (except for values defined using `def`). Create them using `fn`, followed by an optional name, a vector containing parameter bindings, and one or more forms comprising the function body. Or create a function bound to a global name using `defn`. Multiple arities can be defined by passing in one or more lists, each of which starts with a vector containing parameter bindings followed by the function body. Define varargs by passing in a parameter binding vector ending with `&` and the name of a vector to place the rest of the arguments (e.g. `[a b & others]`).

**Macros** are like functions, except that their arguments aren't evaluated before being passed in and the output is intended to be a form which can be further evaluated at runtime. Like functions, macros capture their (non parameter binding) context. Create them using `defmacro`. Macros can be defined with multiple arities and/or varargs.

**Let-binding**, using `let`, allows you to create a lexical context with new bindings available only within the scope of that context.

**Vars** are mutable memory cells that are interned within a namespace, and can be referred to by a qualified or unqualified symbol. Create them using `def` (e.g. `def myVar 100`). Vars are reified. Use the `var` special form to get the Var that a symbol corresponds to, and `deref` to extract the value contained within a Var.

**Basic types** include:
* Booleans (`true` and `false`)
* `nil`
* integers
* floating-point numbers (e.g. `1.234`)
* character literals (`\a`, `\tab`, `\space`, `\newline`, `\return`), which can be used in function position. Character literals can also be specified using the hexadecimal `\uNNNN` or octal `\oNNN` forms.
* keywords (`:else`), which can be used in function position

**Namespaces** make organizing your code easier. Currently, all stdlib code is contained within the `core` namespace, and the user begins in the `user` namespace. Namespaces are reified and can be manipulated as normal objects using some of the built-in functions.

**Syntax-quote** makes defining macros slightly less tedious. Use `'` to denote a normal quoted form. Use `` ` `` to denote a quote that should be syntax-quoted; within such a form `~` (unquote) can be used to force evaluation of the unquote form, while `~@` (unquote-splice) can be used to force evaluation of a form to a collection whose elements are then spliced in.

**Comments** start with a semicolon and continue until the end of the current line: `; this is a comment`

The following special forms, reader macros, and functions are built into the interpreter:

- Special forms: `quote`, `if`, `do`, `def`, `let`, `var`, `fn`, `defmacro`, `loop`, `recur`, `apply`, `attempt`
- Reader macros: `'`, `` ` ``, `~`, `~@`, `#'`, `@`
- Namespace manipulation: `ns-create`, `ns-set`, `ns-get`, `ns-name`, `ns-all`, `ns-find`, `ns-unmap`, `ns-alias`, `ns-aliases`, `ns-unalias`, `ns-refer`, `ns-map`, `ns-interns`, `ns-refers`, `ns-resolve`, `ns-remove`
- Collection manipulation: `list`, `vector`, `hash-map`, `cons`, `first`, `rest`, `next`, `conj`, `concat`, `nth`, `seq`, `lazy-seq`, `get`, `assoc`, `dissoc`, `count`, `reduce`
- Primitive manipulation: `symbol`, `keyword`, `int`, `double`
- String manipulation: `str`, `subs`, `lower-case`, `upper-case`, `replace`, `replace-first`
- String building: `sb`, `sb-append`, `sb-reverse`
- Regular expressions: `re-pattern`, `re-first`, `re-seq`, `re-iterate`, `re-quote-replacement`
- I/O: `read`, `print`, `println`
- Testing: `nil?`, `number?`, `int?`, `float?`, `string?`, `char?`, `symbol?`, `keyword?`, `fn?`, `eval?`, `true?`, `false?`, `var?`, `seq?`, `vector?`, `map?`, `pos?`, `neg?`, `zero?`, `subnormal?`, `infinite?`, `nan?`
- Arithmetic: `+`, `-`, `*`, `/`, `rem`, `quot`
- Comparison: `=`, `==`, `<`, `<=` `>`, `>=`
- Miscellaneous: `deref`, `gensym`, `read-string`, `rand`, `eval`, `fail`

Additional functions and macros are available as part of the standard library.


Development
-----------

Some notes on Lambdatron development tools follow.

### Debugging

Note that running (or profiling) Lambdatron in Xcode will open the REPL up in a new instance of Terminal.app, rather than in Xcode's built-in console. If you wish to debug, after starting Lambdatron, go to the Debug menu in Xcode --> Attach to Process, and then choose the process named "Lambdatron" (it should show up under "Likely Targets").


### Profiling

Unfortunately profiling is a little more cumbersome to set up. After you've chosen which Instrument you want to use, you have to click the red Record button, then wait half a second, then click on the dropdown list that says "Terminal.app" and select "Lambdatron" from the "System Processes" section. Then press the square Stop button, and press it again to begin recording in earnest.

The current Xcode scheme is set to build an optimized version of Lambdatron when profiling (and a debug version when running normally). There is a significant performance difference between the two versions, be aware.


### Logging

Logging is in an embryonic state. In the REPL, type `?logging <DOMAIN> on` or `?logging <DOMAIN> off` to turn logging on or off for a given domain, or omit the `<DOMAIN>` argument to turn logging on or off globally.

The only currently supported domain is `eval`. This logging domain prints out messages detailing how macros, functions, etc are evaluated, and can be useful to see exactly what the interpreter is doing when it evaluates a form.


### Benchmarking

The REPL includes a basic benchmarking tool. Invoke it using `?benchmark <SOME_FORM> <ITERATIONS>`, where `<SOME_FORM>` is a valid code snippet and `<ITERATIONS>` is the number of times to repeat the execution. The benchmark tool will print the average, minimum, and maximum run times (in milliseconds).

The code snippet is lexed, parsed, and expanded before the benchmark, and the expanded data structure is cached between benchmark iterations, so the benchmarking tool only measures evaluation time. As well, the context is not cleared between executions, so side effects caused by one iteration are visible to all subsequent iterations.


### Unit Tests

Lambdatron has a comprehensive unit test suite that exercises the interpreter (not the standard library). Run the unit tests from within Xcode.

Lambdatron relies on Travis CI for continuous integration. Click on the badge at the top of the README to see more information about CI testing.


Development Objectives
----------------------

Development objectives can be divided into two categories.

### Working On

These are objectives I am working on right now, or plan on doing in the near future.

- Expanding standard library
- Support for sets
- Ability to type in multiple forms at the top level
- Metacontext - allow consumer to define custom functions visible to the user
- Performance optimization (once development stabilizes)
- Full unit test suite (once development stabilizes)
- Metadata


### (Very) Long Term Goals

These are objectives that are either too big in scope to schedule, too technically challenging at this time, or of uncertain utility.

- Persistent data structures
- STM and support for multithreading
- Destructuring via pattern matching
- Custom types (e.g. `deftype`) and multimethods (may not be possible at the moment)
- Rationals and bignums (may need to wait for a suitable Swift library handling these first)
- Interpreter rewrite (compile to bytecode rather than direct interpretation) - probably as a separate project
- Full Foundation/Cocoa bindings
- Better Swift runtime interop (if proper reflection support ever comes to Swift)
- Port to Rust


Differences From Clojure
------------------------

Aside from the (long) list of features not yet implemented (see the *Working On* and *(Very) Long Term Goals* sections above), there are a couple of intentional deviations from Clojure's API or conventions:

* Hashmap iteration is not guaranteed to traverse the elements in the same order as in Clojure. No guarantees are made on hashmap iteration except that each key-value pair is visited exactly once. This has implications for any function that converts a map into an ordered sequence.
* `ifn?` doesn't exist; use `eval?` instead. This is because Lambdatron does not use protocols (i.e. interfaces) to define constructs that can be used in function position.
* `try` doesn't exist. `attempt` is a (very basic) error handling facility. It takes one or more forms, executing each sequentially, and returns the first successful value (or the error from executing the final form).
* The `byte`, `short`, `long`, and `float` functions are not implemented, as Lambdatron only has an integer and a double-precision floating point numerical data type.
* The `subnormal?`, `infinite?`, and `nan?` functions return false for integer arguments, and can be used to test whether floating point numbers are subnormal, infinite, or NaN (respectively).
* `keyword` returns `nil` if given an empty string as an argument, not an invalid empty symbol.
* `read` does not take an optional argument representing a reader object.
* `char-escape-string` returns `nil` for the `\formfeed` and `\backspace` arguments, since Swift does not recognize the `\f` and `\b` escape sequences.
* Regex support follows Cocoa conventions, since `NSRegularExpression` is very different from `java.util.pattern.Regex` and `java.util.pattern.Match`. `re-iterate` provides an idiomatic wrapper for `enumerateMatchesInString:options:range:usingBlock:`.
* Once a namespace has been marked for deletion using 'ns-remove', all its aliases are automatically unregistered, and new aliases or refers can no longer be set for it.


License
-------

Lambdatron © 2015 Austin Zheng, released as open-source software subject to the following terms.

The use and distribution terms for this software are covered by the Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php) which can be found in the file epl-v10.html at the root of this distribution. By using this software in any fashion, you are agreeing to be bound by the terms of this license. You must not remove this notice, or any other, from this software.

Lambdatron
==========

An interpreter for a Lisp dialect, implemented in Swift. Syntax and conventions are modeled off [Clojure's](http://clojure.org/), and the interpreter endeavors to match Clojure's behavior as closely as possible. Eventual goal is a library that can be used independently of the REPL front-end.

The name is provisional and will be changed once I come up with something better.


Application
-----------

Lambdatron is an OS X command-line application written in Swift. You will need Xcode 6.1 or later to build.

Run the executable either from within Xcode, or directly from the command line. Run with no arguments to start the interactive REPL, or run with the argument `-f <FILENAME>` to have the interpreter run code within a file. When in the REPL, type expressions at the command prompt and press 'Enter'.

Note that running (or profiling) Lambdatron in Xcode will open the REPL up in a new instance of Terminal.app, rather than in Xcode's built-in console. If you wish to debug, after starting the Lambdatron process, go to the Debug menu in Xcode --> Attach to Process, and then choose the process named "Lambdatron" (it should show up under "Likely Targets").

[Grimoire](http://conj.io/) is a high-quality Clojure API reference, and can be used to reference the intended behavior of all included functions and special forms.

Need ideas? Try:

**Basic arithmetic**

- `(+ (* 2 4) (- 8 6) (+ (+ 1 3) 4))`

**Working with collectionss**

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
- Large parts of the error handling system aren't implemented yet. Asserts will cause the REPL to quit if something goes wrong during evaluation.
- There currently isn't any namespacing or symbol mangling, so be careful when defining macros (e.g. don't use `& rest` as a vararg).
- Macros are cumbersome to define since the syntax-quote system hasn't yet been implemented.

These will disappear as the feature set is filled out.


Features
--------

Lambdatron has the following features:

**Lists**, the bread and butter of Lisp. Create a list using `cons`, extract the first element using `first`, or create a list without its first element using `rest`. Create the empty list using `'()`. Or use the `list` function to create a list from zero or more arguments.

**Vectors**, declared using square brackets: `[1 2 true "Lisp"]`, or the `vector` function. Unlike lists, vectors can't be used to invoke functions.

**Maps**, declared using braces: `{"one" 1 "two" nil "three" [1 2 3]}`, or the `hash-map` function. Maps can be used in function position in order to get a value for a key.

**Functions** are first-class citizens which capture their environment (except for values defined using `def`). Create them using `fn`, followed by an optional name, a vector containing parameter bindings, and one or more forms comprising the function body. Or create a function bound to a global name using `defn`. Multiple arities can be defined by passing in one or more lists, each of which starts with a vector containing parameter bindings followed by the function body. Define varargs by passing in a parameter binding vector ending with `&` and the name of a vector to place the rest of the arguments (e.g. `[a b & others]`).

**Macros** are like functions, except that their arguments aren't evaluated before being passed in and the output is intended to be a form which can be further evaluated at runtime. Like functions, macros capture their (non parameter binding) context. Create them using `defmacro`. Macros can be defined with multiple arities and/or varargs.

**Let-binding**, using `let`, allows you to create a lexical context with new bindings available only within the scope of that context.

**Vars** are global bindings to a value that can be rebound as desired. Create them using `def` (e.g. `def myVar 100`).

**Basic types** include booleans (`true` and `false`), `nil`, integers, floating-point numbers (e.g. `1.234`), and string literals (e.g. `"this is a string literal"`).

**Syntax-quote** makes defining macros slightly less tedious. Use `'` to denote a normal quoted form. Use `` ` `` to denote a quote that should be syntax-quoted; within such a form `~` can be used to force evaluation of the unquote form, while `~@` can be used to force evaluation of a form to a collection whose elements are then spliced in.

**Comments** start with a semicolon and continue until the end of the current line: `; this is a comment`


### Completed

- Interpreter core
- Lexer and parser
- Special forms: `quote`, `if`, `do`, `def`, `let`, `fn`, `defmacro`, `loop`, `recur`, `apply`
- Reader macros: `'` (normal quote), `` ` `` (syntax-quote), `~` (unquote), `~@` (unquote-splice) 
- Collection built-in functions: `list`, `vector`, `hash-map`, `cons`, `first`, `rest`, `concat`, `seq`, `get`, `assoc`, `dissoc`
- I/O built-in functions: `print`
- Type-checking built-in functions: `number?`, `int?`, `float?`, `string?`, `symbol?`, `fn?`, `eval?`, `true?`, `false?`, `list?`, `vector?`, `map?`
- Arithmetic built-in functions: `+`, `-`, `*`, `/`
- Comparison built-in functions: `=`, `<`, `>`
- Standard library functions and macros: `defn`, `not`, `and`, `or`


### Working On

- Standard library
- Support for character literals
- Support for sets
- Support for keywords
- Basic namespacing
- Better error handling than simply crashing the REPL
- Ability to type in multiple forms at the top level
- Metacontext - allow consumer to define custom functions visible to the user
- Performance optimization (once development stabilizes)
- Full unit test suite (once development stabilizes)


### Very Long Term Goals

- Persistent data structures
- Proper support for lazy collections
- STM and support for multithreading
- Destructuring via pattern matching
- Interpreter rewrite (compile to bytecode rather than direct interpretation) - probably as a separate project
- Full Foundation/Cocoa bindings
- Better Swift runtime interop (if proper reflection support ever comes to Swift)
- Port to Rust


License
-------

Lambdatron © 2014 Austin Zheng, released as open-source software subject to the following terms.

The use and distribution terms for this software are covered by the Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php) which can be found in the file epl-v10.html at the root of this distribution. By using this software in any fashion, you are agreeing to be bound by the terms of this license. You must not remove this notice, or any other, from this software.

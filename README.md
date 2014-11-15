Lambdatron
==========

An interpreter for a simple Lisp dialect, implemented in Swift. Syntax and conventions are modeled off [Clojure's](http://clojure.org/). Eventual goal is a library that can be used independently of the REPL front-end.

The name is provisional and will be changed once I come up with something better.


Application
-----------

Lambdatron is an OS X command-line application written in Swift. Type expressions at the command prompt and press 'Enter'.

Need ideas? Try:

**Basic arithmetic**

- `(+ (* 2 4) (- 8 6) (+ (+ 1 3) 4))`

**Working with lists**

- `(cons 1 '(2 3 4))`
- `(rest '(1 2 3 4 5))`

**Defining and calling a function**

- `(def myfunc (fn [a b] (+ a b 1)))`, then `(myfunc 10 20)`

**Recursively calling a function**

- `(def r (fn [a] (print a " ") (if (> a 0) (r (- a 1)))))`, then `(r 10)`

**Creating and using a macro**

- `(defmacro when [__MACRO_pred __MACRO_do] (list 'if __MACRO_pred __MACRO_do nil))`, then `(when (= 1 1) "good")` or `(when (= 1 2) "bad")`

**Defining a function returning another one**

- `(def f1 (fn [arg1] (fn [arg2] (+ arg1 arg2))))`, then `(let [plusone (f1 1)] (plusone 3))`


Features
--------

Lambdatron has the following features:

**Lists**, the bread and butter of Lisp. Create a list using `cons`, extract the first element using `first`, or create a list without its first element using `rest`. Create the empty list using `'()`. Or use the `list` function to create a list from zero or more arguments.

**Vectors**, declared using square brackets: `[1 2 true "Lisp"]`. Unlike lists, vectors can't be eval'ed.

**Functions** are first-class citizens which capture their environment (except for values defined using `def`). Create them using `fn`, followed by an optional name, a vector containing parameter bindings, and one or more forms comprising the function body. Right now, only single-arity functions can be defined (although functions can have an optional vararg at the end of their parameter list).

**Macros** are like functions, except that their arguments aren't evaluated before being passed in and the output is intended to be a form which can be further evaluated at runtime. As well, when macros are expanded, they do so using the bindings at the time they are expanded, not the bindings at the time they were created (like functions). Create them using `defmacro`.

**Let-binding**, using `let`, allows you to create a lexical context with new bindings available only within the scope of that context.


### Completed

- Interpreter core
- Lexer and parser
- Special forms: `quote`, `if`, `do`, `def`, `let`, `fn`, `cons`, `first`, `rest`, `defmacro`
- Reader macros: `'` (for quoting)
- Collection built-in functions: `list`, `vector`
- I/O built-in functions: `print` 
- Arithmetic built-in functions: `+`, `-`, `*`, `/`
- Comparison built-in functions: `=`, `<`, `>`


### Working On

- I/O functions
- Special forms
- Basic control flow
- Logical operators
- Distinction between integers and floating-point values
- Support for maps
- Support for keywords
- Support for syntax quoting
- Tail-call recursion optimization
- Better error handling than simply crashing the REPL
- Multiple arities for functions/macros
- Ability to type in multiple forms at the top level; ability to read and execute from file
- Metacontext - allow consumer to define custom functions visible to the user
- Full unit test suite (once development stabilizes)


License
-------

Lambdatron © 2014 Austin Zheng. Lambdatron is open-source software, released under the terms of the MIT License.

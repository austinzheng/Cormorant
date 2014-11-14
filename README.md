Lambdatron
==========

A (very in-progress) interpreter for a simple Lisp dialect, implemented in Swift. Syntax and conventions are modeled off [Clojure's](http://clojure.org/). Eventual goal is a library that can be used independently of the REPL front-end.


Application
-----------

Lambdatron is an OS X command-line application written in Swift. Type expressions at the command prompt and press 'Enter'.

Need ideas? Try:

- `(+ (* 2 4) (- 8 6) (+ (+ 1 3) 4))`
- `(cons 1 '(2 3 4))`
- `(def myfunc (fn [a b] (+ a b 1)))`, then `(myfunc 10 20)`
- `(def r (fn [a] (print a " ") (if (> a 0) (r (- a 1)))))` then `(r 10)`


Completed Features
------------------

- Interpreter core
- Basic lexing and parsing of text input into cons-based AST
- Special forms: `quote`, `if`, `do`, `def`, `let`, `fn`, `cons`, `first`, `rest`
- Reader macros: `'` (for quoting)
- I/O functions: `print` 
- Arithmetic functions: `+`, `-`, `*`, `/`
- Comparison functions: `=`, `<`, `>`
- Vectors


Working On
----------

- I/O functions
- Special forms
- Basic control flow
- Logical operators
- Distinction between integers and floating-point values
- Support for maps
- Support for keywords
- Support for macros
- Support for syntax quoting
- Tail-call recursion optimization
- Better error handling than simply crashing the REPL
- Multiple arities for functions
- Support for control characters when parsing input (e.g. \" for double quote literal in a string)
- Ability to type in multiple forms at the top level; ability to read and execute from file
- Metacontext - allow consumer to define custom functions visible to the user
- Full unit test suite (once development stabilizes)


License
-------

Lambdatron © 2014 Austin Zheng. Lambdatron is open-source software, released under the terms of the MIT License.

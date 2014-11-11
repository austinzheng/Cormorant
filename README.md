Lambdatron
==========

A personal project attempting to implement a simple REPL for a Lisp-like language. The initial goal is to build a REPL that can interpret arbitrarily nested prefix arithmetic (e.g. (+ (/ 1 2) (* 3 (- 5 2)))). The (very distant) eventual goal is to build something that conforms to the Scheme standard.

Setup
-----

Lambdatron is an OS X command-line application written in Swift. Type expressions at the command prompt and press 'Enter'.

Need ideas? Try:

- `(+ 1 2 3)`
- `(+ (* 2 4) (- 8 6) (+ (+ 1 3) 4))`
- `(cons 1 (quote (2 3 4)))`
- `(first (quote (6 7 8)))`
- `(rest (quote (6 7 8)))`


Completed Features
------------------

- Interpreter core
- Basic lexing and parsing of text input into cons-based AST
- Arithmetic functions: +, -, *, /
- List operations: cons, first, rest


Working On
----------

- I/O functions
- Special forms
- Basic control flow
- Logical operators
- Distinction between integers and floating-point values
- Support for vectors
- Support for keywords
- Support for macros
- Support for syntax quoting
- Better error handling than simply crashing the REPL
- User-defined functions
- Closures
- Proper lexical scope and function stack


License
-------

Lambdatron © 2014 Austin Zheng. Lambdatron is open-source software, released under the terms of the MIT License.

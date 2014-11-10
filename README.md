Lambdatron
==========

A personal project attempting to implement a simple REPL for a Lisp-like language. The initial goal is to build a REPL that can interpret arbitrarily nested prefix arithmetic (e.g. (+ (/ 1 2) (* 3 (- 5 2)))). The (very distant) eventual goal is to build something that conforms to the Scheme standard.


Completed Features
------------------

- Interpreter core
- Basic lexing and parsing of text input into cons-based AST
- Arithmetic functions: +, -, *, /


Working On
----------

- I/O functions: print, println, read
- List operations: cons, first, rest, list
- Basic control flow: if
- Support for vectors
- Support for keywords


License
-------

Lambdatron © 2014 Austin Zheng. Released under the terms of the MIT License.

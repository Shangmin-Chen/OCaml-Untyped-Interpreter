# OCaml Untyped Interpreter

## Overview

This project implements an interpreter for an untyped subset of OCaml, developed as part of the CAS CS 320: Principles of Programming Languages course at Boston University (Spring 2025). The interpreter supports parsing and evaluation using big-step operational semantics, handling constructs like literals, conditionals, operators, functions, and let-expressions. Unlike later projects in the course, it does not include type checking, relying on substitution-based evaluation to manage variable bindings.

Written in OCaml, the interpreter is built using a Dune project structure, with core logic in `interp1/lib/interp1.ml`. This project showcases skills in functional programming, parsing, and dynamic semantics, demonstrated through a variety of test cases and example programs.

## Features

- **Parsing**: Converts input strings into an internal `expr` representation, respecting operator precedence and associativity.
- **Evaluation**: Executes expressions to produce values (e.g., integers, booleans, functions) using big-step semantics and substitution.
- **Error Handling**: Manages runtime errors like division by zero, invalid conditionals, unknown variables, and invalid function applications.
- **Testing**: Includes a test suite in `test/test_interp1.ml` and example programs in `examples/` (e.g., `sum_of_squares` in `04.ml`) to validate functionality.

## Supported Constructs

The interpreter supports the following OCaml constructs:
- **Literals**: `()`, `true`, `false`, integers
- **Variables**: Variable references (checked for scope during evaluation)
- **Conditionals**: `if e1 then e2 else e3`
- **Operators**: Arithmetic (`+`, `-`, `*`, `/`, `mod`), comparisons (`<`, `<=`, `>`, `>=`, `=`, `<>`), logical (`&&`, `||`)
- **Functions**: Anonymous functions (`fun x -> e`) and function application
- **Let-Expressions**: `let x = e1 in e2` for variable bindings

**Operator Precedence** (highest to lowest):
| Operators         | Associativity |
|-------------------|---------------|
| `*`, `/`, `mod`   | Left          |
| `+`, `-`          | Left          |
| `<`, `<=`, `>`, `>=`, `=`, `<>` | Left |
| `&&`              | Right         |
| `||`              | Right         |

## Implementation Details

The project is implemented in `lib/interp1.ml`, with supporting lexer, parser, and types in `lib/lexer.mll`, `lib/parser.mly`, and `lib/utils.ml`.

### Parsing
- Uses `Parser.prog` and `Lexer.read` to parse input strings into a `prog` (alias for `expr`), handling the grammar defined in `spec.pdf`.
- Returns `Some expr` for valid programs or `None` for invalid ones, using regular expressions for numbers (e.g., `-?['0'-'9']+`) and variables (e.g., `['a'-'z'_']['a'-'z''A'-'Z''0'-'9'_''']*`).
- Supports complex expressions, such as nested let-bindings and function applications (e.g., `let x = 1 + 2 * 3 in x + 4` in `test_interp1.ml`).
- Respects operator precedence and associativity, as tested in `test_interp1.ml` (e.g., `(1 + 2) * 3`).

### Substitution
- Implements `subst` to replace variables with values in expressions, crucial for `Let` and `App` evaluation.
- Handles shadowing in `Let` and `Fun` by skipping substitution when variables are bound (e.g., `if y = x then ...`).
- Converts values (`VNum`, `VBool`, `VUnit`, `VFun`) to expressions (`Num`, `True`, `False`, `Unit`, `Fun`) for substitution, as tested in `test_interp1.ml` (e.g., substituting `VUnit` for `y`).

### Evaluation
Implements `eval` using big-step semantics:
- **Literals**: Maps `Num n` to `VNum n`, `True`/`False` to `VBool`, `Unit` to `VUnit`.
- **Operators**: Evaluates operands left-to-right, checking types:
  - Arithmetic (`Add`, `Sub`, etc.) requires `VNum`, raises `InvalidArgs` otherwise (e.g., `2 * true` in `06.ml` raises `InvalidArgs`).
  - Comparisons (`Lt`, `Gte`, etc.) require `VNum`, produce `VBool` (e.g., `2 < 3` in `01.ml`).
  - Logical (`And`, `Or`) implements short-circuiting (e.g., `false && a` in `12.ml` skips evaluating `a`).
  - Raises `DivByZero` for division/modulus by zero (e.g., `2 / 0` in `06.ml`).
- **Conditionals**: Evaluates `If` based on `VBool` condition, raises `InvalidIfCond` for non-booleans (e.g., `if x < 0 then ...` in `02.ml`).
- **Let-Expressions**: Evaluates `e1`, substitutes its value into `e2` using `subst`, then evaluates (e.g., `let x_squared = x * x in ...` in `04.ml`).
- **Functions**: Maps `Fun (x, e)` to `VFun (x, e)` (e.g., `fun x -> x` in `10.ml`).
- **Applications**: Evaluates `e1` to `VFun`, substitutes `e2`’s value into the function body, raises `InvalidApp` for non-functions (e.g., `f 2 (3 + 3)` in `10.ml` raises `InvalidApp` due to extra argument).
- **Variables**: Raises `UnknownVar` for free variables.
- Returns `Ok value` or `Error err` (e.g., `DivByZero`, `InvalidArgs`).
- Non-terminating expressions, like `omega omega` in `05.ml`, may cause infinite recursion, as the interpreter does not handle recursion natively.

### Interp Function
- Combines parsing and evaluation, returning `Error ParseFail` if `parse` fails, or the result of `eval` (e.g., `let x = true || false in x && true` in `test_interp1.ml` returns `VBool true`).

## Project Structure

- `lib/interp1.ml`: Core implementation of parsing, substitution, and evaluation.
- `lib/utils.ml`: Defines types (`expr`, `value`, `bop`, etc.).
- `lib/lexer.mll` and `lib/parser.mly`: Lexer and parser for the language grammar.
- `test/test_interp1.ml`: OUnit test suite for `parse`, `subst`, `eval`, and `interp`.
- `examples/`:
  - `01.ml`: Tests arithmetic, comparison, and logical operators.
  - `02.ml`: Tests nested conditionals with mixed return types.
  - `03.ml`: Tests higher-order functions and curried applications.
  - `04.ml`: Implements `sum_of_squares`, evaluating to `VNum 34`.
  - `05.ml`: Tests non-terminating `omega` combinator.
  - `06.ml` and `07.ml`: Tests error handling for division by zero and type mismatches.
  - `08.ml`: Tests the interpreter's error handling for a non-boolean condition in an if-expression
  - `09.ml`: Tests the interpreter's handling of an invalid self-referential variable definition and non-terminating function application, expecting a parse error or non-termination.
  - `10.ml`: Tests invalid function application.
  - `11.ml` and `12.ml`: Tests short-circuiting with non-terminating expressions.
- Dune build system for compilation and testing.

## Setup and Installation

### Prerequisites
- OCaml 4.14 or later
- Dune 3.0 or later
- Git

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/ocaml-untyped-interpreter.git
   cd ocaml-untyped-interpreter
   ```
2. Build the project:
   ```bash
   eval $(opam env)
   dune build
   ```

### Running Tests
Execute the test suite:
```bash
dune test
```
For debugging, run individual tests in `test/test_interp1.ml` or evaluate example programs in `examples/` using `dune utop`. Example:
```ocaml
let sum_of_squares = fun x -> fun y ->
    let x_squared = x * x in
    let y_squared = y * y in
    x_squared + y_squared
in sum_of_squares 3 (-5)
(* Returns VNum 34 *)
```

## Usage

Use the `interp` function to parse and evaluate programs:
```ocaml
let input = "let x = 3 in x + 2" in
match interp input with
| Ok value -> (* Returns VNum 5 *)
| Error ParseFail -> (* Handles parse errors *)
| Error (UnknownVar v) -> (* Handles free variables *)
| Error err -> (* Handles runtime errors *)
```

## Notes

- The interpreter is untyped, distinguishing it from Mini-Project 2 (type checking) and Mini-Project 3 (type inference).
- It does not support recursion natively, as seen in `05.ml`, `11.ml`, and `12.ml`, where `omega` causes non-termination (extra credit for `let rec` was not implemented).
- The implementation adheres to the course’s skeleton code and exact function signatures in `interp1.ml`.
- The test suite in `test/test_interp1.ml` validates core functionality (e.g., parsing arithmetic, substitution, function application), with additional testing via `examples/01.ml` to `12.ml`.
- Substitution in `subst` respects scoping rules, avoiding capture issues, as shown in `test_interp1.ml`.

## Acknowledgments

- CAS CS 320 course staff for providing the project specification and skeleton code.
- Example programs in `examples/` (e.g., `sum_of_squares` in `04.ml`) and test cases in `test/test_interp1.ml` for validating the interpreter’s correctness.
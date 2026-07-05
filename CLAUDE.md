# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`eeeval` is a Crystal shard implementing a lightweight expression evaluator/parser: a mathematical expression engine (`CalcFuncParser`/`CalcParser`) and a boolean/conditional expression engine (`CondParser`). It also ships a CLI binary (`eeval`).

## Commands

```bash
shards install          # install dependencies (num.cr)
crystal spec            # run the full spec suite
crystal spec spec/eeeval_spec.cr -e "Evaluate simple expression"   # run a single example by name
crystal spec --tag sci_notation                                     # run examples by tag (specs use `tags:` liberally)
shards build eeval       # build the CLI binary to ./bin/eeval
./bin/eeval "sin(pi/2) + e"
crystal run src/cli.cr -- "sin(pi/2) + e"   # run CLI without building
crystal examples/gaussian.cr                 # run a standalone example script
```

There is no separate lint/format check configured beyond `.editorconfig` (2-space indent for `.cr` files); `crystal tool format` can be used if formatting is needed.

## Architecture

Pipeline for both engines is tokenize → build tree → evaluate, but the two engines are structurally different:

- **Math engine** (`src/eval/shunting_yard_calc.cr`, `src/eval/ast.cr`, `src/eval/token.cr`): `CalcParser.tokenize` lexes the string into `Token`s, `CalcParser.build_ast` runs Shunting Yard to produce an `EEEval::AST::Node` tree (`NumberNode`, `VariableNode`, `BinaryOpNode`, `UnaryOpNode`, `FunctionNode`), and `Node#evaluate(env)` walks the tree. `CalcFuncParser` (`src/eeeval.cr`) is the public-facing wrapper: it merges `Constants::DEFAULT_ENV` with any user vars and exposes `evaluate`/`compile`/`tokenize`/`build_ast`.
  - **Constant folding happens during AST construction**, not as a separate pass: in `build_ast`'s `push_op` closure, if all operands to an operator/function/unary op are already `NumberNode`s, the node is evaluated immediately using `Constants::DEFAULT_ENV` and collapsed into a single `NumberNode`. This means adding a new function/operator requires updating the `evaluate` case statement in `ast.cr` in a way that's safe to call eagerly with only constants in scope.
  - **Dual evaluation surface**: every `AST::Node` implements `evaluate` twice — once for `Hash(String, Float64)` and once for `Hash(String, Tensor(Float64, CPU(Float64)))` (via `num.cr`). The Tensor overload lets a compiled AST be evaluated over an entire vector of inputs in one pass (used by the CLI's range mode: `-v`/`-s`/`-e`/`-d`). When adding a new function or operator, both `evaluate` overloads in `ast.cr` must be updated (the Tensor branch usually calls the equivalent Tensor method or `.map`).
  - New function/operator names must also be added to `CalcParser::FUNC_NAMES` (tokenizer) and to any docs (README "Built-in Support" table, CLI banner in `src/cli.cr`).
- **Conditional engine** (`src/eval/shunting_yard_cond.cr`): a separate, self-contained Shunting Yard → RPN → stack evaluator (`infix_to_rpn`, `evaluate_rpn`) operating purely on `Token`s (no AST, no constant folding, no variables). Supports `==`, `!=`, `&&`, `||`, numeric/string operands (single-quoted strings), and parentheses. `CondParser.evaluate` (in `src/eeeval.cr`) first checks parentheses are balanced (respecting quoted strings) then delegates to `infix_to_rpn`/`evaluate_rpn`.
- **Constants** (`src/constants.cr`): `Constants::DEFAULT_ENV` (a `Hash(String, Float64)`) is the single source of truth for built-in named constants (`pi`, `e`, `tau`, `sqrt2`, `phi`, `rad2deg`, `deg2rad`, `g`, `inf`, `nan`) and is what's merged into user environments and used for constant folding. Crystal-level `PI`/`E`/etc. constants are kept in sync separately for direct use from Crystal code.
- **CLI** (`src/cli.cr`): thin `OptionParser`-based wrapper over the two engines. Notable modes: single eval, `-D var=val` fixed variables, range/vector eval (`-v`/`-s`/`-e`/`-d`, builds a Tensor and evaluates the AST once over it), `-c` conditional mode, `-i` interactive REPL.

## Notes for changes

- The two token/AST types are shared (`src/eval/token.cr`) but the math and conditional engines otherwise don't share parsing logic — don't assume a fix in one applies to the other.
- Tests in `spec/eeeval_spec.cr` are organized by engine (`CondParser`, `CalcParser`, `CalcFuncParser`) and rely heavily on `tags:` per example rather than nested `describe` blocks — follow that pattern for new examples.
- CI (`.github/workflows/crystal.yml`) just runs `shards install && crystal spec` on Ubuntu inside the `crystallang/crystal` container.

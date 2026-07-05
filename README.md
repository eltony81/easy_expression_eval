# Easy Expression Eval (eeeval)

![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/eltony81/easy_expression_eval?display_name=tag&cacheSeconds=300)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/eltony81/easy_expression_eval/crystal.yml?cacheSeconds=300)

**eeeval** is a lightweight and efficient expression evaluator for Crystal. It supports mathematical calculations, user-defined variables, pre-compiled ASTs for performance, and conditional expressions.

---

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     eeeval:
       github: eltony81/easy_expression_eval
   ```

2. Run `shards install`

## Features

### Mathematical Evaluation

You can evaluate complex mathematical expressions containing numbers, functions, and operators:

```crystal
require "eeeval"

# Simple evaluation
result = EEEval::CalcFuncParser.evaluate("sin(pi/2) + e")
puts result # => 3.718281828459045
```

#### Variables Support (Native & Efficient)

Pass a hash of variables to the evaluator. No string replacement is performed; variables are resolved during AST evaluation:

```crystal
require "eeeval"

vars = {"x" => 3.0, "y" => 1.5}
result = EEEval::CalcFuncParser.evaluate("x^2 + sin(y)", vars)
puts result
```

#### Pre-compilation (AST)

For performance-critical code (such as evaluations inside loops), compile the expression once into an AST, then evaluate it repeatedly with different variables:

```crystal
require "eeeval"

# Compile the expression once
ast = EEEval::CalcFuncParser.compile("sin(x) * phi")

# Evaluate multiple times without re-parsing
(0..100).each do |i|
  res = EEEval::CalcFuncParser.evaluate(ast, {"x" => i.to_f64})
  puts "f(#{i}) = #{res}"
end
```

### Conditional Expressions

The library includes a `CondParser` for boolean logic:

```crystal
require "eeeval"

# Numeric comparisons
EEEval::CondParser.evaluate("10 == 10")    # => true
EEEval::CondParser.evaluate("5 != 3")      # => true

# String comparisons
EEEval::CondParser.evaluate("'hello' == 'hello'") # => true

# Logical operators
EEEval::CondParser.evaluate("(1 == 1) && (2 != 3)") # => true
EEEval::CondParser.evaluate("1 == 0 || 1 == 1")     # => true
```

### Built-in Support

- **Constants**: `pi`, `e`, `tau`, `sqrt2`, `phi`, `rad2deg`, `deg2rad`, `g`, `inf`, `nan`.
- **Functions**: `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `log`, `log2`, `log10`, `exp`, `exp2`, `sqrt`, `abs`, `floor`, `ceil`, `round`, `sgn`, `sinh`, `cosh`, `tanh`, `gamma`.
- **Operators**: `+`, `-`, `*`, `/`, `%` (modulo), `^` (power).

## Performance

`eeeval` is designed for high-performance mathematical evaluation, especially in scenarios requiring repetitive calculations. Beyond using a pre-compiled **AST**, it employs several key strategies:

- **Vectorization (Tensor Integration)**: Built on top of `num.cr`, the evaluator can process entire Tensors in a single pass. When evaluating ranges, operations are performed on data blocks using SIMD-like patterns, drastically reducing overhead compared to standard loops.
- **Constant Folding**: During AST compilation, sub-expressions containing only constants (e.g., `sin(pi/2) * 10`) are pre-calculated and replaced with a single numeric node, eliminating redundant math at runtime.
- **Native Symbol Resolution**: Variables and constants are resolved directly via an environment hash. No string replacement or regex manipulation is performed during evaluation.
- **Single-Pass Parsing**: Uses an optimized Shunting-Yard algorithm to build the AST in a single tokenization pass, ensuring minimal memory allocation and fast startup.

---

## Examples

The repository includes standalone scripts in the `examples/` directory to demonstrate advanced usage:

- **Gaussian Distribution**: Calculation of PDF and ASCII visualization.
- **Mandelbrot Set**: ASCII rendering of the famous fractal.
- **Monte Carlo Pi**: Estimation of π using random sampling.

Run them with:
```bash
crystal examples/gaussian.cr
```

---

## CLI Usage

The library includes a powerful CLI tool (`eeval`) for quick evaluations, range calculations, and interactive sessions.

### Installation
Build the executable using shards:
```bash
shards build eeval
```
The binary will be available at `./bin/eeval`.

### Parameters:
- `-r, --range VAR=START:END:STEP`: Range/vector evaluation over `VAR` from `START` to `END` (`STEP` defaults to `1` and may be omitted, e.g. `-r x=0:10`).
- `-c, --cond`: Use the conditional evaluator for boolean logic.
- `-i, --interactive`: Start an interactive REPL session.

Any trailing `name=value` argument defines a variable for the expression (fixed variables can be combined with `-r` for the range variable itself).

### Examples:

**Single expression evaluation:**
```bash
./bin/eeval "sin(pi/2) + e"
```

**Using custom variables:**
```bash
./bin/eeval "a^b + 10" a=5 b=2
```

**Range evaluation (vector calculation):**
Evaluate `x^2 + sin(x)` for `x` from `0` to `10` with a step of `0.5`.
```bash
./bin/eeval -r x=0:10:0.5 "x^2 + sin(x)"
```

**Interactive REPL:**
```bash
./bin/eeval -i
```

---

## Contributing

1. Fork it (<https://github.com/eltony81/easy_expression_eval/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [eltony81](https://github.com/eltony81) - creator and maintainer


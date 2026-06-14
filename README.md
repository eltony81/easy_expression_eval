# Easy Expression Eval (eeeval)

![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/eltony81/easy_expression_eval?display_name=tag)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/eltony81/easy_expression_eval/crystal.yml)

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

- **Constants**: `pi`, `e`, `tau`, `sqrt2`, `phi` (available inside environments by default).
- **Functions**: `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `log`, `log2`, `log10`, `exp`, `exp2`, `sqrt`, `abs`.
- **Operators**: `+`, `-`, `*`, `/`, `^` (power).

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
- `-v, --var VAR`: Specify the variable name to use in the range evaluation (e.g., `x`, `t`).
- `-s, --start VAL`: Set the starting value for the range evaluation.
- `-e, --end VAL`: Set the ending value for the range evaluation.
- `-d, --step VAL`: Set the increment step size (defaults to `1.0`).
- `-D, --define VAR=VAL`: Define a fixed variable (e.g., `-D offset=10`).
- `-c, --cond`: Use the conditional evaluator for boolean logic.
- `-i, --interactive`: Start an interactive REPL session.

### Examples:

**Single expression evaluation:**
```bash
./bin/eeval "sin(pi/2) + e"
```

**Range evaluation (vector calculation):**
Evaluate `x^2 + sin(x)` for `x` from `0` to `10` with a step of `0.5`.
```bash
./bin/eeval -v x -s 0 -e 10 -d 0.5 "x^2 + sin(x)"
```

**Using custom variables:**
```bash
./bin/eeval -D a=5 -D b=2 "a^b + 10"
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


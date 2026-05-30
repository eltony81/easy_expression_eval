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

You can evaluate complex mathematical expressions with a single call:

```crystal
require "eeeval"

# Simple evaluation
result = EEEval::CalcFuncParser.evaluate("(14.2 + 14.2) * 4 / 2 * 10.5 ^ (2 / 0.5)")
puts result
```

#### Variables Support

Pass a hash of variables to the evaluator:

```crystal
vars = {"x" => 3.0, "y" => 1.5}
result = EEEval::CalcFuncParser.evaluate("x^2 + sin(y)", vars)
puts result
```

#### Pre-compilation (AST)

For performance-critical code (e.g., inside loops), compile the expression into an AST once and reuse it:

```crystal
ast = EEEval::CalcFuncParser.compile("sin(x) * phi")

(0..100).each do |i|
  res = EEEval::CalcFuncParser.evaluate(ast, {"x" => i.to_f})
  puts "f(#{i}) = #{res}"
end
```

### Conditional Expressions

The library includes a `CondParser` for boolean logic:

```crystal
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

- **Constants**: `pi`, `e`, `tau`, `sqrt2`, `phi`.
- **Functions**: `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `log`, `log2`, `log10`, `exp`, `exp2`, `sqrt`, `abs`.
- **Operators**: `+`, `-`, `*`, `/`, `^` (power).

---

## CLI Usage

The library includes a CLI tool for quick evaluations and range calculations.

```bash
# Single expression
crystal run src/cli.cr -- "sin(pi/2) + e"

# Range evaluation with variables
crystal run src/cli.cr -- -v x -s 0 -e 10 -d 0.5 "x^2 + sin(x)"
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


# eeeval

Easy Expression Eval

![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/eltony81/easy_expression_eval?display_name=tag)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     eeeval:
       github: eltony81/easy_expression_eval
   ```

2. Run `shards install`

## Usage

```crystal
require "eeeval"

expression = "(14.2 + 14.2) * 4 / 2 * 10.5 ^ (2 / 0.5) + sin(2^1+cos(2+7.9-6))"
result = EEEval::CalcFuncParser.evaluate(expression)
puts result
```
Note: the current implementation does support only sin, cos, log, exp function




## Contributing

1. Fork it (<https://github.com/your-github-user/eeeval/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [eltony81](https://github.com/eltony81) - creator and maintainer


require "./eeeval"
require "./constants"
require "option_parser"

# CLI for easy_expression_eval
# Usage examples:
#   crystal run src/cli.cr -- "sin(pi/2) + e"
#   crystal run src/cli.cr -- "x + y" x=1 y=2
#   crystal run src/cli.cr -- -r x=0:10:0.5 "x^2 + sin(x)"

VAR_DEF_PATTERN = /\A([A-Za-z_][A-Za-z0-9_]*)=(.+)\z/

# Expressions may start with '-' (e.g. "-2^2"). OptionParser would otherwise
# try (and fail) to interpret such an argument as a flag, so positional
# arguments (the expression and "name=value" variable definitions) are
# separated from real flags ourselves before OptionParser ever sees them.
option_tokens = [] of String
positional_args = [] of String

args = ARGV.to_a
i = 0
while i < args.size
  token = args[i]
  case token
  when "-r", "--range"
    option_tokens << token
    i += 1
    if i < args.size
      option_tokens << args[i]
    end
  when "-c", "--cond", "-i", "--interactive", "-h", "--help"
    option_tokens << token
  when "--"
    positional_args.concat(args[(i + 1)..])
    i = args.size
  else
    positional_args << token
  end
  i += 1
end

var_name    : String?  = nil
range_start : Float64? = nil
range_end   : Float64? = nil
range_step  : Float64  = 1.0
interactive = false
conditional = false

option_parser = OptionParser.parse(option_tokens) do |opts|
  opts.banner = <<-BANNER
  Usage: eeval [options] "<expression>" [name=value ...]

  Built-in constants: pi, e, tau, sqrt2, phi, rad2deg, deg2rad, g, inf, nan
  Built-in functions: sin, cos, tan, asin, acos, atan, log, log2, log10,
                      exp, exp2, sqrt, abs, floor, ceil, round, sgn,
                      sinh, cosh, tanh, gamma

  Examples:
    eeval "sin(pi/2) + e"
    eeval "x + y" x=1 y=2
    eeval -r x=0:5:1 "x^2 + sin(x)"
    eeval -c "(1 == 1) && ('a' == 'a')"
    eeval -i
  BANNER

  opts.on("-r VAR=START:END:STEP", "--range VAR=START:END:STEP",
    "Range evaluation over VAR from START to END (STEP defaults to 1)") do |v|
    name, range = v.split('=', 2)
    parts = range.split(':')
    raise "Invalid range: expected VAR=START:END[:STEP]" unless parts.size == 2 || parts.size == 3
    var_name    = name
    range_start = parts[0].to_f64
    range_end   = parts[1].to_f64
    range_step  = parts.size == 3 ? parts[2].to_f64 : 1.0
  end
  opts.on("-c", "--cond", "Use conditional expression evaluator") { conditional = true }
  opts.on("-i", "--interactive", "Start interactive REPL mode") { interactive = true }
  opts.on("-h", "--help",        "Show this help")              { puts opts; exit 0 }
end

extra_vars = {} of String => Float64
positional_args.each do |arg|
  if match = arg.match(VAR_DEF_PATTERN)
    extra_vars[match[1]] = match[2].to_f64
  end
end

if interactive
  puts "Easy Expression Eval REPL (type 'exit' or 'quit' to leave, prefix with '?' for cond)"
  loop do
    print "> "
    input = gets
    break if input.nil? || input.strip == "exit" || input.strip == "quit"
    next if input.strip.empty?

    begin
      if input.starts_with?('?')
        res = EEEval::CondParser.evaluate(input[1..-1])
        puts "=> #{res}"
      else
        result = EEEval::CalcFuncParser.evaluate(input, extra_vars)
        puts "=> #{result}"
      end
    rescue ex : Exception
      puts "Error: #{ex.message}"
    end
  end
  exit 0
end

if positional_args.empty?
  puts option_parser
  exit 1
end

expr = positional_args[0]

begin
  if conditional
    result = EEEval::CondParser.evaluate(expr)
    puts "Result: #{result}"
  elsif var_name && range_start && range_end
    raise "Step must be > 0" if range_step <= 0.0

    # Compile the AST once
    ast     = EEEval::CalcFuncParser.compile(expr)
    current = range_start.not_nil!
    limit   = range_end.not_nil!

    # Compute step count and build target coordinate Tensor
    steps = ((limit - current) / range_step).to_i + 1
    x_tensor = Tensor(Float64, CPU(Float64)).new([steps]) { |i| current + i * range_step }

    # Build full tensor environment
    tensor_vars = Hash(String, Tensor(Float64, CPU(Float64))).new
    extra_vars.each do |name, value|
      tensor_vars[name] = Tensor(Float64, CPU(Float64)).new([1]) { value }
    end
    tensor_vars[var_name.not_nil!] = x_tensor

    # Evaluate the AST over the entire vector in a single step
    results_tensor = EEEval::CalcFuncParser.evaluate(ast, tensor_vars)

    puts "Vector (#{results_tensor.size} values):"
    results_tensor.each_with_index { |v, i| puts "  [#{i}] #{v}" }

  else
    # Single evaluation
    result = EEEval::CalcFuncParser.evaluate(expr, extra_vars)
    puts "Result: #{result}"
  end

rescue ex : Exception
  STDERR.puts "Error: #{ex.message}"
  exit 1
end

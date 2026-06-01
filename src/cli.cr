require "./eeeval"
require "./constants"
require "option_parser"

# CLI for easy_expression_eval
# Usage examples:
#   crystal run src/cli.cr -- "sin(pi/2) + e"
#   crystal run src/cli.cr -- -v x -s 0 -e 10 -d 0.5 "x^2 + sin(x)"

var_name    : String?  = nil
range_start : Float64? = nil
range_end   : Float64? = nil
range_step  : Float64  = 1.0

option_parser = OptionParser.parse do |opts|
  opts.banner = <<-BANNER
  Usage: crystal run src/cli.cr -- [options] "<expression>"

  Built-in constants: pi, e, tau, sqrt2, phi
  Built-in functions: sin, cos, tan, asin, acos, atan, log, log2, log10,
                      exp, exp2, sqrt, abs

  Examples:
    crystal run src/cli.cr -- "sin(pi/2) + e"
    crystal run src/cli.cr -- -v x -s 0 -e 5 -d 1 "x^2 + sin(x)"
  BANNER

  opts.on("-v VAR", "--var VAR",     "Variable name (e.g. x, t)")         { |v| var_name    = v }
  opts.on("-s VAL", "--start VAL",   "Range start value")                  { |v| range_start = v.to_f64 }
  opts.on("-e VAL", "--end VAL",     "Range end value")                    { |v| range_end   = v.to_f64 }
  opts.on("-d VAL", "--step VAL",    "Range step size (default: 1.0)")     { |v| range_step  = v.to_f64 }
  opts.on("-h",     "--help",        "Show this help")                     { puts opts; exit 0 }
end

if ARGV.empty?
  puts option_parser
  exit 1
end

expr = ARGV[0]

begin
  if var_name && range_start && range_end
    raise "Step must be > 0" if range_step <= 0.0

    # Compile the AST once
    ast     = EEEval::CalcFuncParser.compile(expr)
    current = range_start.not_nil!
    limit   = range_end.not_nil!

    # Compute step count and build target coordinate Tensor
    steps = ((limit - current) / range_step).to_i + 1
    x_tensor = Tensor(Float64, CPU(Float64)).new([steps]) { |i| current + i * range_step }

    # Evaluate the AST over the entire vector in a single step
    results_tensor = EEEval::CalcFuncParser.evaluate(ast, {var_name.not_nil! => x_tensor})

    puts "Vector (#{results_tensor.size} values):"
    results_tensor.each_with_index { |v, i| puts "  [#{i}] #{v}" }

  else
    # Single evaluation — no variables needed
    result = EEEval::CalcFuncParser.evaluate(expr)
    puts "Result: #{result}"
  end

rescue ex : Exception
  STDERR.puts "Error: #{ex.message}"
  exit 1
end

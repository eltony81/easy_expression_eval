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
extra_vars  = {} of String => Float64
interactive = false
conditional = false

option_parser = OptionParser.parse do |opts|
  opts.banner = <<-BANNER
  Usage: eeval [options] ["<expression>"]

  Built-in constants: pi, e, tau, sqrt2, phi, rad2deg, deg2rad, g, inf, nan
  Built-in functions: sin, cos, tan, asin, acos, atan, log, log2, log10,
                      exp, exp2, sqrt, abs, floor, ceil, round, sgn,
                      sinh, cosh, tanh, gamma

  Examples:
    eeval "sin(pi/2) + e"
    eeval -v x -s 0 -e 5 -d 1 "x^2 + sin(x)"
    eeval -D x=10 -D y=20 "x + y"
    eeval -c "10 > 5 && 'a' == 'a'"
    eeval -i
  BANNER

  opts.on("-v VAR", "--var VAR",     "Variable name for range evaluation (e.g. x, t)") { |v| var_name    = v }
  opts.on("-s VAL", "--start VAL",   "Range start value")                              { |v| range_start = v.to_f64 }
  opts.on("-e VAL", "--end VAL",     "Range end value")                                { |v| range_end   = v.to_f64 }
  opts.on("-d VAL", "--step VAL",    "Range step size (default: 1.0)")                 { |v| range_step  = v.to_f64 }
  opts.on("-D VAR=VAL", "--define VAR=VAL", "Define a variable (e.g. -D x=10)") do |v|
    name, val = v.split('=', 2)
    extra_vars[name] = val.to_f64
  end
  opts.on("-c", "--cond", "Use conditional expression evaluator") { conditional = true }
  opts.on("-i", "--interactive", "Start interactive REPL mode") { interactive = true }
  opts.on("-h", "--help",        "Show this help")              { puts opts; exit 0 }
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

if ARGV.empty?
  puts option_parser
  exit 1
end

expr = ARGV[0]

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

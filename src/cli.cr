require "eeeval"
require "./constants"

# Simple CLI that evaluates a mathematical expression passed as a single argument.
# Usage: crystal run src/cli.cr "sin(pi/2) + e"

if ARGV.empty?
  puts "Usage: #{PROGRAM_NAME} <expression>"
  exit 1
end

expr = ARGV[0]

begin
  # The parser will automatically resolve constants defined in EEEval::Constants
  result = EEEval::CalcFuncParser.evaluate(expr)
  puts "Result: #{result}"
rescue ex : Exception
  STDERR.puts "Error evaluating expression: #{ex.message}"
  exit 1
end

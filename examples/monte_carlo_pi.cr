require "../src/eeeval"

# Monte Carlo Pi Estimation
# We check if x^2 + y^2 <= 1 for many random points (x, y) in [0, 1]x[0, 1]

cond_expr = "x^2 + y^2 <= 1"
# Note: EEEval::CondParser doesn't support '^' directly as it's for logic,
# but we can use CalcParser to get a value and then compare, 
# or use a numeric expression.
# Since CondParser is limited to basic comparisons, let's use a numeric one
# and check if the result is <= 1.

expr = "x^2 + y^2"
ast = EEEval::CalcFuncParser.compile(expr)

samples = 10000
inside = 0

puts "Estimating Pi using Monte Carlo method (#{samples} samples)..."

samples.times do
  x = rand
  y = rand
  
  # Evaluate AST
  val = EEEval::CalcFuncParser.evaluate(ast, {"x" => x, "y" => y})
  inside += 1 if val <= 1.0
end

estimated_pi = 4.0 * inside / samples
error = (estimated_pi - Math::PI).abs

puts "Estimated Pi: #{estimated_pi}"
puts "Actual Pi:    #{Math::PI}"
puts "Error:       #{error} (#{(error/Math::PI*100).round(4)}%)"

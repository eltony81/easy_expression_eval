require "../src/eeeval"

# Gaussian (Normal) Distribution
# Formula: f(x) = (1 / (s * sqrt(2 * pi))) * exp(-0.5 * ((x - m) / s)^2)
# where m is the mean and s is the standard deviation.

gauss_expr = "1/(s * sqrt(2*pi)) * exp(-0.5 * ((x-m)/s)^2)"

# 1. Single evaluation
vars = {"s" => 1.0, "m" => 0.0, "x" => 0.0}
result = EEEval::CalcFuncParser.evaluate(gauss_expr, vars)
puts "Gaussian at x=0 (s=1, m=0): #{result}"

# 2. Vector evaluation (efficient)
puts "\nGenerating Gaussian points from -3 to 3:"
ast = EEEval::CalcFuncParser.compile(gauss_expr)

# Parameters
mean = 0.0
std_dev = 1.0
start_x = -3.0
end_x = 3.0
step = 0.5

steps = ((end_x - start_x) / step).to_i + 1
x_tensor = Tensor(Float64, CPU(Float64)).new([steps]) { |i| start_x + i * step }

# Fixed parameters as single-element tensors
env = {
  "x" => x_tensor,
  "m" => Tensor(Float64, CPU(Float64)).new([1]) { mean },
  "s" => Tensor(Float64, CPU(Float64)).new([1]) { std_dev }
}

results = EEEval::CalcFuncParser.evaluate(ast, env)

x_tensor.each_with_index do |x, i|
  y = results[i].value
  bar = "*" * (y * 50).to_i
  printf "x=%5.1f | y=%8.5f | %s\n", x, y, bar
end

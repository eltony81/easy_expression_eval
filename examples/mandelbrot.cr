require "../src/eeeval"

# Mandelbrot Set Visualization (CLI ASCII)
# z_next = z^2 + c
# We evaluate the magnitude |z| after several iterations.
# Since EEEval is real-valued, we manually implement complex multiplication:
# (x + iy)^2 + (cx + icy) = (x^2 - y^2 + cx) + i(2xy + cy)

# Expressions for next x and next y
x_next_expr = "x^2 - y^2 + cx"
y_next_expr = "2 * x * y + cy"

x_ast = EEEval::CalcFuncParser.compile(x_next_expr)
y_ast = EEEval::CalcFuncParser.compile(y_next_expr)

width = 80
height = 40
max_iter = 30

# Viewport
x_min, x_max = -2.0, 1.0
y_min, y_max = -1.2, 1.2

puts "Mandelbrot Set Generator"

(0...height).each do |py|
  cy = y_min + (y_max - y_min) * py / height
  (0...width).each do |px|
    cx = x_min + (x_max - x_min) * px / width
    
    x, y = 0.0, 0.0
    iter = 0
    
    while iter < max_iter && (x*x + y*y) <= 4.0
      # Use the evaluator for the iteration step
      # Note: For maximum performance in a tight loop like this, 
      # native code is preferred, but this demonstrates AST evaluation.
      vars = {"x" => x, "y" => y, "cx" => cx, "cy" => cy}
      new_x = EEEval::CalcFuncParser.evaluate(x_ast, vars)
      new_y = EEEval::CalcFuncParser.evaluate(y_ast, vars)
      x, y = new_x, new_y
      iter += 1
    end
    
    if iter == max_iter
      print "#"
    elsif iter > 10
      print "*"
    elsif iter > 5
      print "."
    else
      print " "
    end
  end
  puts
end

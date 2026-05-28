require "log"

module Math
  extend self

  def abs(value : Float64) : Float64
    value.abs
  end
end

module EEEval
  class MathFuncResolver
    FUNC_NAMES = %w(log exp sin cos sqrt tan atan asin acos exp2 log10 log2 abs)

    def self.resolve_math_function(func_name : String, arg : Float64) : Float64
      case func_name
      when "log"   then Math.log(arg)
      when "exp"   then Math.exp(arg)
      when "sin"   then Math.sin(arg)
      when "cos"   then Math.cos(arg)
      when "sqrt"  then Math.sqrt(arg)
      when "tan"   then Math.tan(arg)
      when "atan"  then Math.atan(arg)
      when "asin"  then Math.asin(arg)
      when "acos"  then Math.acos(arg)
      when "exp2"  then Math.exp2(arg)
      when "log10" then Math.log10(arg)
      when "log2"  then Math.log2(arg)
      when "abs"   then Math.abs(arg)
      else raise "Unknown function #{func_name}"
      end
    end

    def self.search_expr(expression)
      left_par = 0
      right_par = 0
      new_expr = nil

      expression.each_char_with_index do |chr, idx|
        if (chr == '(')
          left_par = left_par + 1
        end
        if (chr == ')')
          right_par = right_par + 1
        end

        if (left_par == right_par)
          new_expr = expression[1, idx - 1]
          break
        end
      end

      new_expr
    end

    def self.resolved?(expression)
      !expression.matches?(/\b(log|exp|sin|cos|sqrt|tan|atan|asin|acos|exp2|log10|log2|abs)\b/)
    end

    def self.evaluate(expression)
      Log.trace { "RESOLVER 1: evaluating expression: #{expression}" }
      expression = resolve(expression)
      i = 0
      until resolved?(expression)
        if (expression.as? String)
          expression = EEEval::CalcParser.convert_scinot(expression.as(String))
        end
        expression = resolve(expression)
        i = i + 1
        raise "Cannot evaluate #{expression}" if i > 1000
      end
      expression = EEEval::CalcParser.evaluate_expr(expression)
      Log.trace { "evaluated expression: #{expression}" }
      expression
    end

    # Transform an expression with math function if the argument is a number e.g.: cos(3) is translated to Math.cos(3)
    def self.resolve(expression)
      # Match any of the function names with a number/scientific notation inside parenthesis
      expression = expression.gsub(/\b(log|exp|sin|cos|sqrt|tan|atan|asin|acos|exp2|log10|log2|abs)\(([+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?)\)/) do |match, md|
        func_name = md[1]
        arg_val = md[2].to_f64
        val = resolve_math_function(func_name, arg_val)
        Log.trace { "RESOLVER 1.1: matched #{match} replacement #{val}" }
        val.to_s
      end

      expression = resolve_expr(expression)
      Log.trace { "RESOLVER 1.2: #{expression}" }
      expression
    end

    # Transform an expression inside a math function e.g.: cos(3+1) matches in (3+1) then (3+1) is evaluated to 4 and the expression is translated to Math.cos(4)
    def self.resolve_expr(expression)
      replaces = Hash(String, Float64).new

      expression.scan(/\b(log|exp|sin|cos|sqrt|tan|atan|asin|acos|exp2|log10|log2|abs)\(/) do |md|
        func_name = md[1]
        start_idx = md.begin(0)
        sub_str = expression[start_idx + func_name.size..-1]
        expr_str = search_expr(sub_str)
        expr_str.try do |expr|
          if resolved?(expr)
            key = "#{func_name}(#{expr})"
            num = EEEval::CalcParser.evaluate_expr(expr)
            Log.trace { "RESOLVER 2.1: #{func_name}(#{num})" }
            replaces[key] = resolve_math_function(func_name, num.to_f64)
          end
        end
      end

      replaces.each do |key, value|
        expression = expression.gsub(key) { value }
        Log.trace { "RESOLVER 2.2: #{expression}" }
      end
      expression
    end
  end
end

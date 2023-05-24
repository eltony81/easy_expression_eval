require "log"

module Math
  extend self

  def abs(value : Float64) : Float64
    value.abs
  end
end

module EEEval

  class MathFuncResolver
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

    macro mfunc_evaluator

      {% funcs = %w(log exp sin cos sqrt tan atan asin acos exp2 log10 log2 abs) %}

      def self.resolved?(expression)
        {% tmp = "" %}
        {% for mfunc in funcs %}
        {% tmp = tmp + mfunc + "|" %}
        {% end %}
        {% tmp = tmp + "end" %}
        !expression.matches? /{{tmp.id}}/
      end

      def self.evaluate(expression)
        Log.trace { "RESOLVER 1: evaluating expression: #{expression}" }
        expression = resolve(expression)
        i=0
        until resolved?(expression)
          if(expression.as? String)
            expression = EEEval::CalcParser.convert_scinot(expression.as(String))
          end
          expression = resolve(expression)
          i=i+1
          raise "Cannot evaluate #{expression}" if i > 1000
        end
        expression = EEEval::CalcParser.evaluate_expr(expression)
        Log.trace { "evaluated expression: #{expression}" }
        expression
      end

      # Transform an expression with math function if the argument is a number e.g.: cos(3) is translated to Math.cos(3)
      def self.resolve(expression)
        replaces = Hash(String, Float64).new

        {% for mfunc in funcs %}
        expression.scan(/\w{2,}\([+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)\)/) do |md|
          if md[0].starts_with?("{{mfunc.id}}")
            num = md[0].delete("{{mfunc.id}}(").delete(")")
            replaces[md[0]] = Math.{{mfunc.id}}(num.to_f64)
          end
        end
        {% end %}

        replaces.each do |key, value|
          expression = expression.gsub(key) { value }
          Log.trace { "RESOLVER 1.1: #{expression}" }
        end
        expression = resolve_expr(expression)
        Log.trace { "RESOLVER 1.2: #{expression}" }
        expression
      end

      # Transform an expression inside a math function e.g.: cos(3+1) matches in (3+1) then (3+1) is evauated to 4 and the expression is translated to Math.cos(4)
      def self.resolve_expr(expression)
        replaces = Hash(String, Float64).new

        {% for mfunc in funcs %}
        expression.scan(/(?<={{mfunc.id}})\([\d+\s\)\(\*\-\+\/\^\.]*/) do |md|
          expr = search_expr(md[0])
          expr.try do |expr|
            key = "{{mfunc.id}}(#{expr})"
            num = EEEval::CalcParser.evaluate_expr(expr)
            Log.trace { "RESOLVER 2.1: {{mfunc.id}}(#{num})" }
            replaces[key] = Math.{{mfunc.id}}(num.to_f64)
          end
        end
        {% end %}

        replaces.each do |key, value|
          expression = expression.gsub(key) { value }
          Log.trace { "RESOLVER 2.2: #{expression}" }
        end
        expression
      end
    end

    mfunc_evaluator
  end
end

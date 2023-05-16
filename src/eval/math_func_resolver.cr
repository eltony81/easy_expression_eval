module EEEval
  FUNC_REGEX_CONST      = /\w{2,}\([+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)\)/
  FUNC_REGEX_INNER_EXPR = /^((?![a-zA-Z]+).)*$/

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

      def self.resolved?(expression)
        {% tmp = "" %}
        {% for mfunc in %w(log exp sin cos) %}
        {% tmp = tmp + mfunc + "|" %}
        {% end %}
        {% tmp = tmp + "end" %}
        !expression.matches? /{{tmp.id}}/
      end

      def self.evaluate(expression)
        #puts "RESOLVER 1: evaluating expression: #{expression}"
        expression = resolve(expression)
        i=0
        until resolved?(expression)
          expression = resolve(expression)
          i=i+1
          break if i > 1000
        end
        expression = EEEval::CalcParser.evaluate(expression)
        #puts "evaluated expression: #{expression}"
        expression
      end

      def self.resolve(expression)
        replaces = Hash(String, Float64).new

        {% for mfunc in %w(log exp sin cos) %}
        expression.scan(FUNC_REGEX_CONST) do |md|
          if md[0].starts_with?("{{mfunc.id}}")
            num = md[0].delete("{{mfunc.id}}(").delete(")")
            replaces[md[0]] = Math.{{mfunc.id}}(num.to_f64)
          end
        end
        {% end %}

        replaces.each do |key, value|
          expression = expression.gsub(key) { value }
          #puts "RESOLVER 1.1: #{expression}"
        end
        expression = resolve_expr(expression)
        expression
      end

      def self.resolve_expr(expression)
        replaces = Hash(String, Float64).new

        {% for mfunc in %w(log exp sin cos) %}
        expression.scan(/(?<={{mfunc.id}})\([\d+\s\)\(\-\+\/\^\.]*/) do |md|
          expr = search_expr(md[0])
          expr.try do |expr|
            key = "{{mfunc.id}}(#{expr})"
            num = EEEval::CalcParser.evaluate(expr)
            #puts "RESOLVER 2.1: {{mfunc.id}}(#{num})"
            replaces[key] = Math.{{mfunc.id}}(num.to_f64)
          end
        end
        {% end %}

        replaces.each do |key, value|
          expression = expression.gsub(key) { value }
          #puts "RESOLVER 2.2: #{expression}"
        end
        expression
      end
    end

    mfunc_evaluator
  end
end

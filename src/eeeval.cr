require "log"
require "./eval/*"

# TODO: Write documentation for `EasyExpressionEval`
module EEEval

  class CondParser
    def self.parentheses_balanced?(expression)
      in_string = false
      count = 0
      expression.each_char do |chr|
        if chr == '\''
          in_string = !in_string
        elsif !in_string
          if chr == '('
            count += 1
          elsif chr == ')'
            count -= 1
            return false if count < 0
          end
        end
      end
      count == 0
    end

    def self.evaluate(expression)
      raise Exception.new("malformed expression: check parentheeses") unless parentheses_balanced?(expression)
      evaluate_rpn(infix_to_rpn expression).value == "true"
    end
  end

  class CalcParser

    def self.clear_expression(expression)
      Log.trace {"clearing expression #{expression}"}
      cleaned = expression.delete(" ")
      raise Exception.new("malformed expression: check parentheeses") if cleaned.count('(') != cleaned.count(')')
      cleaned
    end

    def self.evaluate_expr(expression)
      Log.trace { "evaluate_expr: #{expression}" }
      val = evaluate_rpn(infix_to_rpn expression).value
      val.is_a?(String) ? val.to_f64 : val
    end

    def self.evaluate(expression)
      expression = clear_expression(expression)
      evaluate_expr(expression)
    end

  end

  class CalcFuncParser
    def self.evaluate(expression)
      Log.trace {" INIT evaluation"}
      CalcParser.evaluate(expression)
    end
  end
end

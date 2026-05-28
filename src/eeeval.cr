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
      expression = expression.delete(" ").gsub("+-", "-").gsub("-+", "-").gsub("--", "+").gsub("++", "+")
      expression = expression.gsub(/(?<=\()\-/, "0-").gsub(/(?<=\()\+/, "0+").gsub(/^\-/, "0-").gsub(/^\+/, "0+")
      raise Exception.new("malformed expression: check parentheeses") if(expression.count('(') != expression.count(')'))
      expression
    end

    def self.convert_scinot(expression)
      expression.gsub(/(?<=\d)e[+-]?\d+/) do |match|
        "*#{match.sub("e", "10^(0+")})"
      end
    end

    def self.convert_multdiv_sign(expression)
      expression.gsub(/([*\/^])([\-\+][\d\.]+)/, "\\1(0\\2)")
    end

    def self.evaluate_expr(expression)
      expression = convert_scinot(expression)
      expression = convert_multdiv_sign(expression)
      expression = clear_expression(expression)
      Log.trace { "evaluate_expr: #{expression}" }
      value = ""
      unless (expression.to_f?)
        evaluate_rpn(infix_to_rpn expression).value
      else
        convert_scinot(expression)
      end
    end

    def self.evaluate(expression)
      expression = clear_expression(expression)
      evaluate_expr(expression)
    end

  end

  class CalcFuncParser
    def self.evaluate(expression)
      Log.trace {" INIT evaluation"}
      expression = CalcParser.clear_expression(expression)
      unless (expression.to_f?)
        MathFuncResolver.evaluate(expression)
      else
        expression
      end
    end
  end
end

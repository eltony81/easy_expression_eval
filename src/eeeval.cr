require "log"
require "./eval/*"

# TODO: Write documentation for `EasyExpressionEval`
module EEEval

  class CondParser
    def self.evaluate(expression)
      raise Exception.new("malformed expression: check parentheeses") if(expression.count('(') != expression.count(')'))
      expression = expression.delete(" ").gsub("+-") { "-" }.gsub("-+") { "-" }.gsub("--") { "+" }.gsub("++") { "+" }
      evaluate_rpn(infix_to_rpn expression).value == "true"
    end
  end

  class CalcParser
    def self.clear_expression(expression)
      expression = expression.delete(" ").gsub("+-", "-").gsub("-+", "-").gsub("--", "+").gsub("++", "+")
      expression = expression.gsub(/(?<=\()\-/, "0-").gsub(/(?<=\()\+/, "0+").gsub(/^\-/, "0-").gsub(/^\+/, "0+")
      raise Exception.new("malformed expression: check parentheeses") if(expression.count('(') != expression.count(')'))
      expression
    end

    def self.convert_scinot(expression)
      sci_not_to_replace = Hash(String, String).new
      expression.scan(/(?<=\d{1})e[+-]\d+/) do |md|
        Log.trace { "sci_not: #{md[0]}" }
        sci_not_to_replace[md[0]] = "*#{md[0].sub("e", "10^(0+")})"
      end
      sci_not_to_replace.each do |key, value|
        expression = expression.sub(key, value)
      end
      expression
    end

    def self.convert_multdiv_sign(expression)
      multdiv_sign = Hash(String, String).new
      expression.scan(/(?<=\*)[\-\+][\d\.]*/) do |md|
        Log.trace { "multdiv_sign: #{md[0]}" }
        multdiv_sign[md[0]] = "(0#{md[0]})"
      end
      multdiv_sign.each do |key, value|
        expression = expression.sub(key, value)
      end
      expression
    end

    def self.evaluate_expr(expression)
      expression = convert_scinot(expression)
      expression = convert_multdiv_sign(expression)
      expression = expression.gsub("+-", "-").gsub("-+", "-").gsub("--", "+").gsub("++", "+")
      Log.trace { "evaluate_expr: #{expression}" }
      unless (expression.to_f?)
        evaluate_rpn(infix_to_rpn expression).value
      else
        expression
      end
    end

    def self.evaluate(expression)
      expression = clear_expression(expression)
      evaluate_expr(expression)
    end

  end

  class CalcFuncParser
    def self.evaluate(expression)
      expression = CalcParser.clear_expression(expression)
      unless (expression.to_f?)
        MathFuncResolver.evaluate(expression)
      else
        expression
      end
    end
  end
end

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
    def self.evaluate(expression)
      raise Exception.new("malformed expression: check parentheeses") if(expression.count('(') != expression.count(')'))
      expression = expression.delete(" ").gsub("+-") { "-" }.gsub("-+") { "-" }.gsub("--") { "+" }.gsub("++") { "+" }
      expression = expression.gsub(/(?<!\d)\-/, "0-").gsub(/(?<!\d)\+/, "0+")
      unless (expression.to_f64?)
        evaluate_rpn(infix_to_rpn expression).value
      else
        expression
      end
    end
  end

  class CalcFuncParser
    def self.evaluate(expression)
      expression = expression.delete(" ").gsub("+-") { "-" }.gsub("-+") { "-" }.gsub("--") { "-" }.gsub("++") { "+" }
      unless (expression.to_f64?)
        EEEval::MathFuncResolver.evaluate(expression)
      else
        expression
      end
    end
  end
end

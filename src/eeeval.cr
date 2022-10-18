require "./eval/*"

# TODO: Write documentation for `EasyExpressionEval`
module EEEval
  class CondParser
    def self.evaluate(expression)
      evaluate_rpn(infix_to_rpn expression).value == "true"
    end
  end

  class CalcParser
    def self.evaluate(expression)
      evaluate_rpn(infix_to_rpn expression).value
    end
  end
end

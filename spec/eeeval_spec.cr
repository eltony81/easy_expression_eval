require "./spec_helper"

describe EEEval::CondParser do
  describe "#infix_to_rpn", tags: "nospaces" do
    it "Convert infix notation to rpn no spaces" do
      expression = "14==14&&'ciao'=='ciao'"
      tokens = EEEval::CondParser.infix_to_rpn(expression)
      tokens.size.should eq(7)
      expected = ["14", "14", "==", "ciao", "ciao", "==", "&&"]
      result = tokens.map &.value
      result.should eq(expected)
    end
    it "Convert infix notation to rpn" do
      expression = "14==14 && 1 == 3||(1==3 && 4==2) && '2' != '3'||'ciao' == 'ciao'"
      tokens = EEEval::CondParser.infix_to_rpn(expression)
      tokens.size.should eq(23)
      expected = ["14", "14", "==", "1", "3", "==", "&&", "1", "3", "==", "4", "2", "==", "&&", "||", "2", "3", "!=", "&&", "ciao", "ciao", "==", "||"]
      result = tokens.map &.value
      result.should eq(expected)
    end
  end

  describe "#evaluate_rpn" do
    it "Evaluate rpn expression returning boolean literal string" do
      expression = "14.2 == 14.2 && 1 == 3 || (1==3 && 4==2) && '2' != '3' || 'ciao' == 'ciao'"
      tokens = EEEval::CondParser.infix_to_rpn(expression)
      result = EEEval::CondParser.evaluate_rpn(tokens)
      result.value.should eq("true")
      result.type.should eq(EEEval::Token::Type::Boolean)
    end
  end

  describe "#evaluate" do
    it "Evaluate rpn expression returning boolean value" do
      expression = "14.2 == 14.2 && 1 == 3 || (1==3 && 4==2) && '2' != '3' || 'ciao' == 'ciao'"
      result = EEEval::CondParser.evaluate(expression)
      result.should eq(true)
    end
  end
end

describe EEEval::CalcParser do
  describe "#infix_to_rpn", tags: "nospaces" do
    it "Convert infix notation to rpn no spaces" do
      expression = "(14.2+14.2)"
      tokens = EEEval::CalcParser.infix_to_rpn(expression)
      tokens.size.should eq(3)
      expected = ["14.2", "14.2", "+"]
      result = tokens.map &.value
      result.should eq(expected)
    end
    it "Convert infix notation to rpn" do
      expression = "(14.2 + 14.2) * 4 / 2 *10.5^2"
      tokens = EEEval::CalcParser.infix_to_rpn(expression)
      tokens.size.should eq(11)
      expected = ["14.2", "14.2", "+", "4", "*", "2", "/", "10.5", "2", "^", "*"]
      result = tokens.map &.value
      result.should eq(expected)
    end
  end

  describe "#evaluate_rpn" do
    it "Evaluate rpn expression returning numeric value" do
      expression = "(14.2 + 14.2) * 4 / 2 * 10.5 ^ 2"
      tokens = EEEval::CalcParser.infix_to_rpn(expression)
      result = EEEval::CalcParser.evaluate_rpn(tokens)
      result.value.should eq(6262.2)
    end
  end

  describe "#evaluate" do
    it "Evaluate expression returning numeric value" do
      expression = "(14.2 + 14.2) * 4 / 2 * 10.5 ^ 2"
      result = EEEval::CalcParser.evaluate(expression)
      result.should eq(6262.2)
    end
  end

  describe "#infix_to_rpn_exp_complex" do
    it "Convert infix notation to rpn with complex exp expr" do
      expression = "(14.2 + 14.2) * 4 / 2 * 10.5 ^ (2 / 0.5)"
      tokens = EEEval::CalcParser.infix_to_rpn(expression)
      tokens.size.should eq(13)
      expected = ["14.2", "14.2", "+", "4", "*", "2", "/", "10.5", "2", "0.5", "/", "^", "*"]
      result = tokens.map &.value
      result.should eq(expected)
    end
  end

  describe "#evaluate" do
    it "Evaluate expression returning numeric value with complex exp expr" do
      expression = "(14.2 + 14.2) * 4 / 2 * 10.5 ^ (2 / 0.5)"
      result = EEEval::CalcParser.evaluate(expression)
      result.to_f.format(separator: ".", delimiter: "", decimal_places: 2).should eq("690407.55")
    end
  end

  describe "#evaluate" do
    it "Evaluate expression returning numeric value for very long expr" do
      expression = "(((((10 / 2) * 5) - 8) + 15) / 5) * ((7 - 3) * 6) - (11 + 3) * 2 + 9 * (((9 / 3) * 2) - 1) - 5 * (12 - 3) + 16 / 4 + 20 - 9 * (5 - 3) + ((((((2 + 3) * 4) - 6) / 2) + 5) * ((7 - 4) * 3) - (9 + 1) * 4 + 8 * (((4 / 2) * 3) - 1) - 7 * (5 - 2) + 14 / 2 + 19 - 5 * (6 - 4) + (((((8 / 2) * 6) - 9) + 3) / 3) * ((5 - 2) * 4) - (10 + 2) * 3 + 7 * (((6 / 3) * 5) - 2) - 4 * (8 - 6) + 12 / 2 + 15 - 8 * (4 - 2)))"
      result = EEEval::CalcParser.evaluate(expression)
      result.to_f.format(separator: ".", delimiter: "", decimal_places: 2).should eq("323.60")
    end
  end
end

describe EEEval::MathFuncResolver do
  describe "#resolve" do
    it "Resolve math func expr" do
      expression = EEEval::MathFuncResolver.resolve("( log(14.2) + log(15.2) - log(16 + 4 + log(4 + 1)) )")
    end
  end

  describe "#search_expr" do
    it "search_expr paremthesees closed" do
      expr = EEEval::MathFuncResolver.search_expr("(16 + 4 + 45 / 8) + 67 / (23 - 4)")
      expected = "16 + 4 + 45 / 8"
      expr.should eq(expected)
    end

    it "search_expr paremthesees opened" do
      expr = EEEval::MathFuncResolver.search_expr("(16 + 4 + 45 / 8 + 67 / (23 - 4)")
      expr.should eq(nil)
    end
  end

  describe "#evaluate" do
    it "Evaluate" do
      expression = EEEval::MathFuncResolver.evaluate("cos(2.5 + sin(4))")
      expression.to_f64.should eq(-0.17154842342764115)
    end
  end

  describe "#evaluate" do
    it "Resolve math func expr" do
      expression = EEEval::MathFuncResolver.evaluate("( log(14.2) + log(15.2) - log(16 + 4 + log(4 + 1)) )")
      expression.should eq(2.3014072328095136)
    end
  end

  describe "#evaluate" do
    it "Resolve math func expr" do
      expression = EEEval::MathFuncResolver.evaluate("1 + exp(log(14.2))")
      expression.should eq(15.2)
    end
  end

  describe "#evaluate" do
    it "Resolve math func expr" do
      expression = EEEval::MathFuncResolver.evaluate("sin(0.5)^2 + cos(0.5)^2")
      expression.should eq(1)
    end
  end

end

describe EEEval::CalcFuncParser do
  describe "#evaluate" do
    it "Resolve math func expr" do
      expression = EEEval::CalcFuncParser.evaluate("sin(0.5)^2 + cos(0.5 + log(4/6))^2")
      expression.should eq(1.2209385919826568)
    end
  end
end

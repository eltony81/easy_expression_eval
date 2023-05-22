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
      expression = "(((((10 / 2) * 5) - 8) + 15) / 5) * ((7 - 3) * 6) - (11 + 3) * 2 + 9 * (((9 / 3) * 2) - 1) - 5 * (12 - 3) + 16 / 4 + 20 - 9 * (5 - 3) + ((((((2 + 3) * 4) - 6) / 2) + 5) * ((7 - 4) * 3) - (9 + 1) * 4 + 8 * (((4 / 2) * 3) - 1) - 7 * (5 - 2) + 14 / 2 + 19 - 5 * (6 - 4) + (((((8 / 2) * 6) - 9) + 3) / 3) * ((5 - 2) * 4) - (10 + 2) * 3 + 7 * (((6 / 3) * 5) - 2) - 4 * (8 - 6) + 12 / 2 + 15 - 8 * (4 - 2))"
      result = EEEval::CalcParser.evaluate(expression)
      result.to_f.format(separator: ".", delimiter: "", decimal_places: 2).should eq("323.60")
    end
  end

  describe "#evaluate", tags: "sign" do
    it "Evaluate expression with minus/plus sign" do
      expression = "((-10-10)^2)"
      result = EEEval::CalcParser.evaluate(expression)
      puts result
    end
  end

  describe "#evaluate", tags: "sci_notation" do
    it "Evaluate expression with minus/plus sign" do
      expression = "1+4.006529739295107e-5"
      expression = EEEval::CalcParser.evaluate(expression)
      expression.should eq(1.0000400652973929)
    end
  end

  describe "#evaluate", tags: "mult_neg" do
    it "Evaluate expression with multiply followed by negative num" do
      expression = "(0-(0.0-2)^2)/(2*-0.1^2)"
      expression = EEEval::CalcParser.evaluate(expression)
      expression.should eq(-199.99999999999997)
    end
  end

end

describe EEEval::MathFuncResolver do
  describe "#resolve" do
    it "Resolve math func expr" do
      expression = EEEval::MathFuncResolver.resolve("( log(14.2) + log(15.2) - log(16 + 4 + log(4 + 1)) )")
      expression.should eq("( 2.653241964607215 + 2.7212954278522306 - log(16 + 4 + 1.6094379124341003) )")
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
      expression = EEEval::MathFuncResolver.evaluate("cos(6^(exp(2/cos(7.6/8))))")
      expression.to_f64.should eq(-0.7590461129784705)
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

  describe "#evaluate", tags: "sign" do
    it "Resolve math func expr sign" do
      expression = EEEval::CalcFuncParser.evaluate("1+sin(-1/2)")
      expression.should eq(0.520574461395797)
    end
  end

  describe "#evaluate", tags: "gauss" do
    it "Resolve math func gauss" do
      gauss_expression = "1/(sqrt(2*pi)*s)*exp( (-(x-m)^2)/(2*s^2) )"
      s = 0.1
      m = 2
      pi = Math::PI
      x = 2
      gauss_expression = gauss_expression.gsub(/(?<!\w)s(?!\w)/, s).gsub(/(?<!\w)m(?!\w)/, m).gsub(/(?<!\w)pi(?!\w)/, pi)
      value = EEEval::CalcFuncParser.evaluate(gauss_expression.gsub(/(?<!\w)x(?!\w)/, x))
      value.should eq(3.989422804014327)
    end
  end

  describe "#evaluate", tags: "gauss_s_neg" do
    it "Resolve math func gauss negative sigma" do
      gauss_expression = "1/(sqrt(2*pi)*s)*exp( (-(x-m)^2)/(2*s^2) )"
      s = -0.1
      m = 2
      pi = Math::PI
      x = 2
      gauss_expression = gauss_expression.gsub(/(?<!\w)s(?!\w)/, s).gsub(/(?<!\w)m(?!\w)/, m).gsub(/(?<!\w)pi(?!\w)/, pi)
      value = EEEval::CalcFuncParser.evaluate(gauss_expression.gsub(/(?<!\w)x(?!\w)/, x))
      value.should eq(-3.989422804014327)
    end
  end
end

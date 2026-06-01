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

    it "Evaluate string comparison preserving space inside string literals" do
      EEEval::CondParser.evaluate("'hello world' == 'hello world'").should eq(true)
      EEEval::CondParser.evaluate("'hello world' == 'helloworld'").should eq(false)
    end

    it "Evaluate string comparison with parentheses inside string literals" do
      EEEval::CondParser.evaluate("'(' == '('").should eq(true)
    end

    it "Evaluate numeric comparison with signed numbers" do
      EEEval::CondParser.evaluate("1 == -1").should eq(false)
      EEEval::CondParser.evaluate("-5.5 == -5.5").should eq(true)
      EEEval::CondParser.evaluate("+2.3 == 2.3").should eq(true)
    end
  end
end

describe EEEval::CalcParser do
  describe "#parse" do
    it "Evaluate simple expression" do
      expression = "(14.2 + 14.2)"
      result = EEEval::CalcParser.parse(expression, EEEval::Constants::DEFAULT_ENV)
      result.should eq(28.4)
    end

    it "Evaluate complex expression" do
      expression = "(14.2 + 14.2) * 4 / 2 * 10.5^2"
      result = EEEval::CalcParser.parse(expression, EEEval::Constants::DEFAULT_ENV)
      result.should eq(6262.2)
    end
  end

  describe "#evaluate" do
    it "Evaluate expression returning numeric value" do
      expression = "(14.2 + 14.2) * 4 / 2 * 10.5 ^ 2"
      result = EEEval::CalcParser.evaluate(expression)
      result.should eq(6262.2)
    end
  end

  describe "#compile and AST evaluate" do
    it "Evaluate pre-compiled expression" do
      expression = "(14.2 + 14.2) * 4 / 2 * 10.5 ^ (2 / 0.5)"
      ast = EEEval::CalcParser.compile(expression)
      result = ast.evaluate(EEEval::Constants::DEFAULT_ENV)
      result.format(separator: ".", delimiter: "", decimal_places: 2).should eq("690407.55")
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
      result.should eq(400.0)
    end
  end

  describe "#evaluate", tags: "sci_notation" do
    it "Evaluate expression with scientific notation" do
      expression = "1+4.006529739295107e-5"
      result = EEEval::CalcParser.evaluate(expression)
      result.should eq(1.0000400652973929)
    end
  end

  describe "#evaluate", tags: "sci_notation_nosign" do
    it "Evaluate expression with scientific notation without sign" do
      EEEval::CalcParser.evaluate("1e5").should eq(100000.0)
      EEEval::CalcParser.evaluate("2.5e3").should eq(2500.0)
    end
  end

  describe "#evaluate", tags: "signed_exponents" do
    it "Evaluate expression with signed exponents" do
      EEEval::CalcParser.evaluate("10.5 ^ -2").should eq(10.5 ** -2)
      EEEval::CalcParser.evaluate("2 ^ -3").should eq(0.125)
      EEEval::CalcParser.evaluate("2.5 ^ +2").should eq(6.25)
    end
  end
end


describe EEEval::CalcFuncParser do
  describe "#evaluate" do
    it "Resolve math func expr" do
      expression = EEEval::CalcFuncParser.evaluate("sin(0.5)^2 + cos(0.5 + log(4/6))^2")
      expression.should eq(1.2209385919826568)
    end

    it "Evaluate with user-defined variables" do
      result = EEEval::CalcFuncParser.evaluate("x^2 + y", {"x" => 3.0, "y" => 1.0})
      result.should eq(10.0)
    end
  end

  describe "#evaluate", tags: "sign" do
    it "Resolve math func expr sign" do
      expression = EEEval::CalcFuncParser.evaluate("1+sin(-1/2)")
      expression.should eq(0.520574461395797)
    end
  end

  describe "#evaluate", tags: "multdiv_sign" do
    it "Resolve math func expr multdivsign" do
      expression = EEEval::CalcFuncParser.evaluate("(2*-0.3^2)+(2*-0.39999^2) ")
      expression.should be_close(0.4999840002, 1e-10)
      expression = EEEval::CalcFuncParser.evaluate("(2/-0.3^2) ")
      expression.should be_close(22.22222222222222, 1e-10)
    end
  end

  describe "#evaluate", tags: "gauss" do
    it "Resolve math func gauss using variables" do
      gauss_expression = "1/(sqrt(2*pi)*s)*exp( (-(x-m)^2)/(2*s^2) )"
      vars = {
        "s" => 0.1,
        "m" => 2.0,
        "x" => 2.0
      }
      value = EEEval::CalcFuncParser.evaluate(gauss_expression, vars)
      value.should be_close(3.989422804014327, 1e-9)
    end
  end

  describe "#evaluate", tags: "gauss_s_neg" do
    it "Resolve math func gauss negative sigma" do
      gauss_expression = "1/(sqrt(2*pi)*s)*exp( (-(x-m)^2)/(2*s^2) )"
      vars = {
        "s" => -0.1,
        "m" => 2.0,
        "x" => 2.0
      }
      value = EEEval::CalcFuncParser.evaluate(gauss_expression, vars)
      value.should be_close(-3.989422804014327, 1e-9)
    end
  end

  describe "#evaluate", tags: "abs" do
    it "Calculate expression with abs" do
      expression = "1/abs(45)"
      val1 = EEEval::CalcFuncParser.evaluate(expression).to_f
      expression = "1/abs(-45)"
      val2 = EEEval::CalcFuncParser.evaluate(expression).to_f
      val1.should be_close(0.022222222222222223, 1e-10)
      val2.should be_close(0.022222222222222223, 1e-10)
    end
  end

  describe "#evaluate", tags: "acos" do
    it "Calculate expression with acos" do
      expression = "cos(2) + acos(-1)"
      val1 = EEEval::CalcFuncParser.evaluate(expression).to_f
      val1.should be_close(2.7254458170426505, 1e-10)
    end
  end

  describe "#evaluate", tags: "func_sci_notation" do
    it "Evaluate math functions with scientific notation inputs" do
      result = EEEval::CalcFuncParser.evaluate("exp(1e5)")
      result.to_f.should eq(Float64::INFINITY)

      EEEval::CalcFuncParser.evaluate("sin(1e-10)").to_f.should be_close(Math.sin(1e-10), 1e-20)
    end

    it "Evaluate math functions with signed exponents inside" do
      EEEval::CalcFuncParser.evaluate("cos(2^-3)").to_f.should be_close(Math.cos(0.125), 1e-10)
    end
  end

  describe "#evaluate", tags: "fourier" do
    it "Evaluate Fourier series terms using variables" do
      expression = "4/pi * sin(2*pi*f*t)"
      vars = {
        "f" => 0.05,
        "t" => 5.0
      }
      val = EEEval::CalcFuncParser.evaluate(expression, vars).to_f
      val.should be_close(4.0 / Math::PI, 1e-9)

      expression2 = "sqrt(real^2 + imag^2) / total"
      vars2 = {
        "real" => 1.2,
        "imag" => -3.4,
        "total" => 200.0
      }
      val2 = EEEval::CalcFuncParser.evaluate(expression2, vars2).to_f
      val2.should be_close(Math.sqrt(1.2**2 + (-3.4)**2) / 200.0, 1e-9)
    end
  end

  describe "#evaluate", tags: "new_features" do
    it "Evaluate modulo operator" do
      EEEval::CalcParser.evaluate("10 % 3").should eq(1.0)
      EEEval::CalcParser.evaluate("10.5 % 3").should eq(1.5)
    end

    it "Evaluate new constants" do
      EEEval::CalcParser.evaluate("rad2deg").should be_close(180.0 / Math::PI, 1e-10)
      EEEval::CalcParser.evaluate("deg2rad").should be_close(Math::PI / 180.0, 1e-10)
      EEEval::CalcParser.evaluate("g").should eq(9.80665)
      EEEval::CalcParser.evaluate("inf").should eq(Float64::INFINITY)
      EEEval::CalcParser.evaluate("nan").nan?.should be_true
    end

    it "Evaluate new functions" do
      EEEval::CalcFuncParser.evaluate("floor(3.9)").should eq(3.0)
      EEEval::CalcFuncParser.evaluate("ceil(3.1)").should eq(4.0)
      EEEval::CalcFuncParser.evaluate("round(3.5)").should eq(4.0)
      EEEval::CalcFuncParser.evaluate("sgn(-5.5)").should eq(-1.0)
      EEEval::CalcFuncParser.evaluate("sgn(0)").should eq(0.0)
      EEEval::CalcFuncParser.evaluate("sgn(2.3)").should eq(1.0)
      EEEval::CalcFuncParser.evaluate("sinh(1)").should be_close(Math.sinh(1), 1e-10)
      EEEval::CalcFuncParser.evaluate("cosh(1)").should be_close(Math.cosh(1), 1e-10)
      EEEval::CalcFuncParser.evaluate("tanh(1)").should be_close(Math.tanh(1), 1e-10)
      EEEval::CalcFuncParser.evaluate("gamma(5)").should eq(24.0) # (5-1)!
    end
  end

  describe "#evaluate with Tensor" do
    it "Evaluate pre-compiled expression with Tensor environment" do
      ast = EEEval::CalcFuncParser.compile("x^2 + sin(x)")
      x_tensor = Tensor(Float64, CPU(Float64)).new([3]) { |i| i.to_f }
      
      result = EEEval::CalcFuncParser.evaluate(ast, {"x" => x_tensor})
      
      result.shape.should eq([3])
      result[0].value.should be_close(0.0, 1e-9)
      result[1].value.should be_close(1.0 + Math.sin(1.0), 1e-9)
      result[2].value.should be_close(4.0 + Math.sin(2.0), 1e-9)
    end
  end
end

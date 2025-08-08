require "./spec_helper"

describe EEEval::CalcParser do
  describe ".clear_expression" do
    it "removes all whitespace" do
      expression = "1 + 2 - 3 * 4 / 5"
      cleared = EEEval::CalcParser.clear_expression(expression)
      cleared.should eq("1+2-3*4/5")
    end

    it "normalizes operators" do
      expression = "1 +- 2 -+ 3 -- 4 ++ 5"
      cleared = EEEval::CalcParser.clear_expression(expression)
      cleared.should eq("1-2-3+4+5")
    end

    it "handles leading signs" do
      expression = "-1 + 2"
      cleared = EEEval::CalcParser.clear_expression(expression)
      cleared.should eq("0-1+2")

      expression = "+1 - 2"
      cleared = EEEval::CalcParser.clear_expression(expression)
      cleared.should eq("0+1-2")
    end

    it "handles signs after parentheses" do
      expression = "(-1 + 2)"
      cleared = EEEval::CalcParser.clear_expression(expression)
      cleared.should eq("(0-1+2)")

      expression = "(+1 - 2)"
      cleared = EEEval::CalcParser.clear_expression(expression)
      cleared.should eq("(0+1-2)")
    end

    it "raises an exception for mismatched parentheses" do
      expression = "(1 + 2"
      expect_raises(Exception, "malformed expression: check parentheeses") do
        EEEval::CalcParser.clear_expression(expression)
      end

      expression = "1 + 2)"
      expect_raises(Exception, "malformed expression: check parentheeses") do
        EEEval::CalcParser.clear_expression(expression)
      end
    end
  end
  describe ".convert_scinot" do
    it "converts a simple scientific notation" do
      expression = "1e+5"
      converted = EEEval::CalcParser.convert_scinot(expression)
      converted.should eq("1*10^(0+5)")
    end

    it "converts multiple scientific notations" do
      expression = "1e+5+2.5e-3"
      converted = EEEval::CalcParser.convert_scinot(expression)
      converted.should eq("1*10^(0+5)+2.5*10^(0-3)")
    end

    it "does not change expression without scientific notation" do
      expression = "1+2-3"
      converted = EEEval::CalcParser.convert_scinot(expression)
      converted.should eq("1+2-3")
    end
  end
  describe ".convert_multdiv_sign" do
    it "converts multiplication with a signed number" do
      expression = "2*-0.5"
      converted = EEEval::CalcParser.convert_multdiv_sign(expression)
      converted.should eq("2*(0-0.5)")
    end

    it "converts division with a signed number" do
      expression = "4/-0.5"
      converted = EEEval::CalcParser.convert_multdiv_sign(expression)
      converted.should eq("4/(0-0.5)")
    end

    it "converts multiple occurrences" do
      expression = "2*-0.5+4/-0.5"
      converted = EEEval::CalcParser.convert_multdiv_sign(expression)
      converted.should eq("2*(0-0.5)+4/(0-0.5)")
    end

    it "does not change expression without such patterns" do
      expression = "2*0.5+4/0.5"
      converted = EEEval::CalcParser.convert_multdiv_sign(expression)
      converted.should eq("2*0.5+4/0.5")
    end
  end
end

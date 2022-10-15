require "./spec_helper"

describe EEEval::CondParser do
  # TODO: Write tests

  describe "#infix_to_rpn" do
    it "Convert infix notation to rpn" do
      expression = "14 == 14 && 1 == 3 || (1==3 && 4==2) && '2' != '3' || 'ciao' == 'ciao'"
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

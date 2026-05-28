module EEEval
  class CalcParser
    def self.precedence(operator : String) : Int32
      case operator
      when "^" then 3
      when "*", "/" then 2
      when "+", "-" then 1
      else -1
      end
    end

    def self.has_left_associativity(operator : String) : Bool
      operator == "+" || operator == "-" || operator == "/" || operator == "*"
    end

    def self.infix_to_rpn(expression : String) : Array(Token)
      output = [] of Token
      stack = [] of String
      chars = expression.chars
      expr_length = chars.size
      i = 0
      while (i < expr_length)
        chr = chars[i]
        if (chr == ' ')
          i = i + 1
          next
        end

        if (chr == '+' || chr == '-' || chr == '*' || chr == '/' || chr == '^')
          operator = chr.to_s
          while (!stack.empty? && precedence(operator) <= precedence(stack.last) && has_left_associativity(operator))
            output << Token.new(stack.pop, Token::Type::Operator)
          end
          stack.push(operator)
          i = i + 1
        elsif (chr == '(')
          stack.push(chr.to_s)
          i = i + 1
        elsif (chr == ')')
          while (!stack.empty?)
            if (stack.last == "(")
              stack.pop
              break
            end
            output << Token.new(stack.pop, Token::Type::Operator)
          end
          i = i + 1
        elsif (chr.number?)
          start_idx = i
          while (i + 1 < expr_length && (chars[i + 1].number? || chars[i + 1] == '.'))
            i = i + 1
          end
          num = chars[start_idx..i].join
          output.push(Token.new(num, Token::Type::Number))
          i = i + 1
        end
      end

      while (!stack.empty?)
        if (stack.last == "(")
          raise "This expression is invalid"
        end
        output << Token.new(stack.pop, Token::Type::Operator)
      end

      output
    end

    def self.evaluate_rpn(tokens : Array(Token)) : Token
      stack = [] of Token

      i = 0
      while (i < tokens.size)
        token = tokens[i]
        if (token.type != Token::Type::Operator)
          stack.push token
        else
          operand2 = stack.pop
          operand1 = stack.pop
          val1 = operand1.value.to_f
          val2 = operand2.value.to_f
          value = case token.value
                  when "+" then val1 + val2
                  when "-" then val1 - val2
                  when "*" then val1 * val2
                  when "/" then val1 / val2
                  when "^" then val1 ** val2
                  else raise "Unknown operator #{token.value}"
                  end
          stack.push(Token.new(value, Token::Type::Number))
        end
        i = i + 1
      end
      stack.pop
    end
  end
end

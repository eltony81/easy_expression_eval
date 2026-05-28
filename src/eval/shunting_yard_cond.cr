module EEEval
  class CondParser
    def self.precedence(operator : String) : Int32
      case operator
      when "==", "!=" then 2
      when "||", "&&" then 1
      else -1
      end
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

        if (chr == '=' || chr == '!' || chr == '|' || chr == '&')
          if (i + 1 < expr_length)
            operator = chars[i..i+1].join
            i += 2
          else
            operator = chr.to_s
            i += 1
          end
          while (!stack.empty? && precedence(operator) <= precedence(stack.last))
            output << Token.new(stack.pop, Token::Type::Operator)
          end
          stack.push(operator)
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
        elsif (chr == '+' || chr == '-')
          next_idx = i + 1
          while (next_idx < expr_length && chars[next_idx] == ' ')
            next_idx += 1
          end
          if (next_idx < expr_length && chars[next_idx].number?)
            start_num_idx = next_idx
            i = next_idx
            while (i + 1 < expr_length && (chars[i + 1].number? || chars[i + 1] == '.'))
              i = i + 1
            end
            num = chr.to_s + chars[start_num_idx..i].join
            output.push(Token.new(num, Token::Type::Number))
            i = i + 1
          else
            i = i + 1
          end
        elsif (chr.number?)
          start_idx = i
          while (i + 1 < expr_length && (chars[i + 1].number? || chars[i + 1] == '.'))
            i = i + 1
          end
          num = chars[start_idx..i].join
          output.push(Token.new(num, Token::Type::Number))
          i = i + 1
        elsif (chr == '\'')
          start_idx = i + 1
          i = i + 1
          while (i < expr_length && chars[i] != '\'')
            i = i + 1
          end
          str = chars[start_idx...i].join
          output.push(Token.new(str, Token::Type::String))
          i = i + 1
        else
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

          case token.value
          when "=="
            if (operand1.type == Token::Type::String)
              truth = operand1.value == operand2.value
            else
              truth = operand1.value.to_f == operand2.value.to_f
            end
            stack.push(Token.new(truth.to_s, Token::Type::Boolean))
          when "!="
            if (operand1.type == Token::Type::String)
              truth = operand1.value != operand2.value
            else
              truth = operand1.value.to_f != operand2.value.to_f
            end
            stack.push(Token.new(truth.to_s, Token::Type::Boolean))
          when "||"
            truth = operand1.value == "true" || operand2.value == "true"
            stack.push(Token.new(truth.to_s, Token::Type::Boolean))
          when "&&"
            truth = operand1.value == "true" && operand2.value == "true"
            stack.push(Token.new(truth.to_s, Token::Type::Boolean))
          else
            raise "Unknown operator #{token.value}"
          end
        end
        i = i + 1
      end
      stack.pop
    end
  end
end

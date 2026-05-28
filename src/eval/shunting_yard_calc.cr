module EEEval
  class CalcParser
    FUNC_NAMES = %w(log exp sin cos sqrt tan atan asin acos exp2 log10 log2 abs)

    def self.resolve_math_function(func_name : String, arg : Float64) : Float64
      case func_name
      when "log"   then Math.log(arg)
      when "exp"   then Math.exp(arg)
      when "sin"   then Math.sin(arg)
      when "cos"   then Math.cos(arg)
      when "sqrt"  then Math.sqrt(arg)
      when "tan"   then Math.tan(arg)
      when "atan"  then Math.atan(arg)
      when "asin"  then Math.asin(arg)
      when "acos"  then Math.acos(arg)
      when "exp2"  then Math.exp2(arg)
      when "log10" then Math.log10(arg)
      when "log2"  then Math.log2(arg)
      when "abs"   then arg.abs
      else raise "Unknown function #{func_name}"
      end
    end

    def self.precedence(operator : String) : Int32
      case operator
      when "u-", "u+" then 4
      when "^" then 3
      when "*", "/" then 2
      when "+", "-" then 1
      else -1
      end
    end

    def self.has_left_associativity(operator : String) : Bool
      operator == "+" || operator == "-" || operator == "/" || operator == "*"
    end

    def self.should_pop?(op1 : String, op2 : String) : Bool
      p1 = precedence(op1)
      p2 = precedence(op2)
      p2 > p1 || (p2 == p1 && has_left_associativity(op1))
    end

    def self.infix_to_rpn(expression : String) : Array(Token)
      output = [] of Token
      stack = [] of String
      chars = expression.chars
      expr_length = chars.size
      i = 0
      expect_operand = true

      while (i < expr_length)
        chr = chars[i]
        if (chr == ' ')
          i = i + 1
          next
        end

        if (chr == '+' || chr == '-')
          operator = chr.to_s
          if expect_operand
            stack.push("u" + operator)
            i += 1
          else
            while (!stack.empty? && should_pop?(operator, stack.last))
              output << Token.new(stack.pop, Token::Type::Operator)
            end
            stack.push(operator)
            expect_operand = true
            i += 1
          end
        elsif (chr == '*' || chr == '/' || chr == '^')
          operator = chr.to_s
          while (!stack.empty? && should_pop?(operator, stack.last))
            output << Token.new(stack.pop, Token::Type::Operator)
          end
          stack.push(operator)
          expect_operand = true
          i += 1
        elsif (chr == '(')
          stack.push(chr.to_s)
          expect_operand = true
          i += 1
        elsif (chr == ')')
          while (!stack.empty?)
            if (stack.last == "(")
              stack.pop
              if !stack.empty? && FUNC_NAMES.includes?(stack.last)
                output << Token.new(stack.pop, Token::Type::Operator)
              end
              break
            end
            output << Token.new(stack.pop, Token::Type::Operator)
          end
          expect_operand = false
          i += 1
        elsif (chr.number?)
          start_idx = i
          while (i + 1 < expr_length && (chars[i + 1].number? || chars[i + 1] == '.'))
            i = i + 1
          end
          # Check for scientific notation exponent
          if i + 1 < expr_length && (chars[i + 1] == 'e' || chars[i + 1] == 'E')
            j = i + 1
            if j + 1 < expr_length && (chars[j + 1] == '+' || chars[j + 1] == '-')
              j += 1
            end
            if j + 1 < expr_length && chars[j + 1].number?
              i = j + 1
              while (i + 1 < expr_length && chars[i + 1].number?)
                i = i + 1
              end
            end
          end
          num = chars[start_idx..i].join
          output.push(Token.new(num, Token::Type::Number))
          expect_operand = false
          i += 1
        elsif (chr.ascii_letter?)
          start_idx = i
          while (i + 1 < expr_length && (chars[i + 1].ascii_letter? || chars[i + 1].number?))
            i = i + 1
          end
          word = chars[start_idx..i].join
          if FUNC_NAMES.includes?(word)
            stack.push(word)
            expect_operand = true
          else
            raise "Unknown word: #{word}"
          end
          i += 1
        else
          i += 1
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
          if FUNC_NAMES.includes?(token.value)
            operand = stack.pop
            arg = operand.value.is_a?(Float64) ? operand.value.as(Float64) : operand.value.as(String).to_f64
            val = resolve_math_function(token.value.as(String), arg)
            stack.push(Token.new(val, Token::Type::Number))
          elsif token.value == "u-"
            operand = stack.pop
            arg = operand.value.is_a?(Float64) ? operand.value.as(Float64) : operand.value.as(String).to_f64
            stack.push(Token.new(-arg, Token::Type::Number))
          elsif token.value == "u+"
            operand = stack.pop
            arg = operand.value.is_a?(Float64) ? operand.value.as(Float64) : operand.value.as(String).to_f64
            stack.push(Token.new(arg, Token::Type::Number))
          else
            operand2 = stack.pop
            operand1 = stack.pop
            val1 = operand1.value.is_a?(Float64) ? operand1.value.as(Float64) : operand1.value.as(String).to_f64
            val2 = operand2.value.is_a?(Float64) ? operand2.value.as(Float64) : operand2.value.as(String).to_f64
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
        end
        i = i + 1
      end
      stack.pop
    end
  end
end

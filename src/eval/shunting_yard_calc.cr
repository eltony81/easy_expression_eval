module EEEval
  class CalcParser
    def self.precedence(operator : String)
      precedence : Int32
      if (operator == "^")
        precedence = 3
      elsif (operator == "*" || operator == "/")
        precedence = 2
      elsif (operator == "+" || operator == "-")
        precedence = 1
      else
        precedence = -1
      end
    end

    def self.has_left_associativity(operator : String)
      if (operator == "+" || operator == "-" || operator == "/" || operator == "*")
        true
      else
        false
      end
    end

    def self.infix_to_rpn(expression : String)
      output = [] of Token
      stack = [] of String
      expr_length = expression.chars.size
      i = 0
      chr : Char
      while (i < expr_length)
        chr = expression[i]
        if (chr == ' ')
          i = i + 1
          next
        end

        if (chr == '+' || chr == '-' || chr == '*' || chr == '/' || chr == '^')
          operator = "#{chr}"
          while (!stack.empty? && precedence(operator) <= precedence(stack.last) && has_left_associativity(operator))
            output << Token.new(stack.pop, Token::Type::Operator)
          end
          stack.push(operator)
          i = i + 1
        elsif (chr == '(')
          stack.push(chr.to_s)
        elsif (chr == ')')
          while (!stack.empty?)
            if (stack.last == "(")
              stack.pop
              break
            end
            output << Token.new(stack.pop, Token::Type::Operator)
          end
        elsif (chr.number?)
          num = chr.to_s
          while (i + 1 < expr_length && (expression[i + 1].number? || expression[i + 1] == '.'))
            num = num + expression[i + 1].to_s
            i = i + 1
          end
          output.push(Token.new(num, Token::Type::Number))
        end
        i = i + 1
      end

      while (!stack.empty?)
        if (stack.last == "(")
          raise "This expression is invalid"
        end
        output << Token.new(stack.pop, Token::Type::Operator)
      end

      output
    end

    def self.evaluate_rpn(tokens)
      tmp = tokens.map do |tk|
        tk.value
      end

      operand1 : Token = Token.new("", Token::Type::Undefined)
      operand2 : Token = Token.new("", Token::Type::Undefined)
      result : Token = Token.new("", Token::Type::Undefined)

      stack = [] of Token

      i = 0
      while (i < tokens.size)
        if (tokens[i].type != Token::Type::Operator)
          stack.push tokens[i]
          tmp = stack.map do |tk|
            tk.value
          end
        elsif (tokens[i].type == Token::Type::Operator && tokens[i].value == "+")
          parser_operator PLUS
        elsif (tokens[i].type == Token::Type::Operator && tokens[i].value == "-")
          parser_operator MINUS
        elsif (tokens[i].type == Token::Type::Operator && tokens[i].value == "/")
          parser_operator DIVIDE
        elsif (tokens[i].type == Token::Type::Operator && tokens[i].value == "*")
          parser_operator MULTIPLY
        elsif (tokens[i].type == Token::Type::Operator && tokens[i].value == "^")
          parser_operator EXP
        end

        i = i + 1
      end
      stack.pop
    end

    macro parser_operator(operator)
      operand2 = stack.pop
      operand1 = stack.pop
      {% op = "undefined" %}
      {% op = "+" if operator.id == "PLUS" %}
      {% op = "-" if operator.id == "MINUS" %}
      {% op = "*" if operator.id == "MULTIPLY" %}
      {% op = "/" if operator.id == "DIVIDE" %}
      {% op = "**" if operator.id == "EXP" %}
      if (operand1.type == Token::Type::Number)
        value = operand1.value.to_f {{op.id}} operand2.value.to_f
        result = Token.new(value, Token::Type::Number)
        stack.push(result)
        tmp = stack.map do |tk|
          tk.value
        end
      end
    end
  end
end

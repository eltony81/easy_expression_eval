module EEEval
  class Token
    property value : String = ""
    property type : Type = Type::Undefined

    def initialize(@value, @type)
    end

    enum Type
      Operator
      String
      Number
      Boolean
      Undefined
    end
  end

  class CondParser
    def self.precedence(operator : String)
      precedence : Int32
      if (operator == "==" || operator == "!=")
        precedence = 2
      elsif (operator == "||" || operator == "&&")
        precedence = 1
      else
        precedence = -1
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

        if (chr == '=' || chr == '!' || chr == '|' || chr == '&')
          operator = "#{chr}#{expression[i + 1]}"
          while (!stack.empty? && precedence(operator) <= precedence(stack.last))
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
        elsif (chr == '\'')
          str = ""
          while (i + 1 < expr_length)
            str = str + expression[i + 1].to_s if expression[i + 1] != '\''
            i = i + 1
            if (expression[i] == '\'')
              break
            end
          end
          output.push(Token.new(str, Token::Type::String))
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
          stack.push tokens[i + 1]
          i = i + 1
          tmp = stack.map do |tk|
            tk.value
          end
        elsif (tokens[i].type == Token::Type::Operator && tokens[i].value == "==")
          parser_condition EQUAL
        elsif (tokens[i].type == Token::Type::Operator && tokens[i].value == "!=")
          parser_condition NOT_EQUAL
        elsif (tokens[i].type == Token::Type::Operator && tokens[i].value == "||")
          parser_condition_bool OR
        elsif (tokens[i].type == Token::Type::Operator && tokens[i].value == "&&")
          parser_condition_bool AND
        end

        i = i + 1
      end
      stack.pop
    end

    macro parser_condition(operator)
    operand1 = stack.pop
    operand2 = stack.pop
    {% op = "undefined" %}
    {% op = "==" if operator.id == "EQUAL" %}
    {% op = "!=" if operator.id == "NOT_EQUAL" %}
    if (operand1.type == Token::Type::String)
      truth = operand1.value {{op.id}} operand2.value
      result = Token.new(truth.to_s, Token::Type::Boolean)
      stack.push(result)
      tmp = stack.map do |tk|
        tk.value
      end
    elsif (operand1.type == Token::Type::Number)
      truth = operand1.value.to_f {{op.id}} operand2.value.to_f
      result = Token.new(truth.to_s, Token::Type::Boolean)
      stack.push(result)
      tmp = stack.map do |tk|
        tk.value
      end
    end
    end

    macro parser_condition_bool(operator)
    operand1 = stack.pop
    operand2 = stack.pop
    {% op = "undefined" %}
    {% op = "||" if operator.id == "OR" %}
    {% op = "&&" if operator.id == "AND" %}
    if (operand1.type == Token::Type::Boolean)
      truth = (operand1.value == "true" {{op.id}} operand2.value == "true").to_s
      result = Token.new(truth, Token::Type::Boolean)
      stack.push(result)
      tmp = stack.map do |tk|
        tk.value
      end
    end
    end
  end
end

module EEEval
  class CalcParser
    FUNC_NAMES = %w(log exp sin cos sqrt tan atan asin acos exp2 log10 log2 abs floor ceil round sgn sinh cosh tanh gamma)

    # -------------------------------------------------------------------------
    # Token types (extended to support Variable)
    # -------------------------------------------------------------------------

    # Tokenizes an infix expression string into an Array of Token.
    # Variables (unknown words that are not functions) are emitted as
    # Token::Type::Variable tokens so they can become VariableNode in the AST.
    def self.tokenize(expression : String) : Array(Token)
      tokens = [] of Token
      expr_length = expression.size
      i = 0
      expect_operand = true

      while i < expr_length
        chr = expression[i]

        if chr.whitespace?
          i += 1
          next
        end

        if chr == '+' || chr == '-'
          operator = chr.to_s
          if expect_operand
            tokens << Token.new("u" + operator, Token::Type::Operator)
          else
            tokens << Token.new(operator, Token::Type::Operator)
          end
          expect_operand = true
          i += 1

        elsif chr == '*' || chr == '/' || chr == '^' || chr == '%'
          tokens << Token.new(chr.to_s, Token::Type::Operator)
          expect_operand = true
          i += 1

        elsif chr == '('
          tokens << Token.new("(", Token::Type::Operator)
          expect_operand = true
          i += 1

        elsif chr == ')'
          tokens << Token.new(")", Token::Type::Operator)
          expect_operand = false
          i += 1

        elsif chr.number?
          start_idx = i
          while i + 1 < expr_length && (expression[i + 1].number? || expression[i + 1] == '.')
            i += 1
          end
          # Scientific notation (e.g. 1.5e-3)
          if i + 1 < expr_length && (expression[i + 1] == 'e' || expression[i + 1] == 'E')
            j = i + 1
            j += 1 if j + 1 < expr_length && (expression[j + 1] == '+' || expression[j + 1] == '-')
            if j + 1 < expr_length && expression[j + 1].number?
              i = j + 1
              while i + 1 < expr_length && expression[i + 1].number?
                i += 1
              end
            end
          end
          tokens << Token.new(expression[start_idx..i], Token::Type::Number)
          expect_operand = false
          i += 1

        elsif chr.ascii_letter? || chr == '_'
          start_idx = i
          while i + 1 < expr_length && (expression[i + 1].ascii_letter? || expression[i + 1].number? || expression[i + 1] == '_')
            i += 1
          end
          word = expression[start_idx..i]
          if FUNC_NAMES.includes?(word)
            tokens << Token.new(word, Token::Type::Operator)  # function treated as operator
          else
            tokens << Token.new(word, Token::Type::Variable)  # variable / constant
          end
          expect_operand = false
          i += 1

        else
          i += 1
        end
      end

      tokens
    end

    # -------------------------------------------------------------------------
    # Build AST from flat token list using the Shunting Yard algorithm.
    # Returns the root AST node.
    # -------------------------------------------------------------------------
    def self.build_ast(tokens : Array(Token)) : AST::Node
      output  = [] of AST::Node   # operand stack
      ops     = [] of String      # operator / function stack

      push_op = ->(op : String) do
        if FUNC_NAMES.includes?(op)
          arg = output.pop
          if arg.is_a?(AST::NumberNode)
            # Constant folding for functions
            output << AST::NumberNode.new(AST::FunctionNode.new(op, arg).evaluate(Constants::DEFAULT_ENV))
          else
            output << AST::FunctionNode.new(op, arg)
          end
        elsif op == "u-" || op == "u+"
          operand = output.pop
          if operand.is_a?(AST::NumberNode)
            # Constant folding for unary operators
            output << AST::NumberNode.new(AST::UnaryOpNode.new(op, operand).evaluate(Constants::DEFAULT_ENV))
          else
            output << AST::UnaryOpNode.new(op, operand)
          end
        else
          right = output.pop
          left  = output.pop
          if left.is_a?(AST::NumberNode) && right.is_a?(AST::NumberNode)
            # Constant folding for binary operators
            output << AST::NumberNode.new(AST::BinaryOpNode.new(op, left, right).evaluate(Constants::DEFAULT_ENV))
          else
            output << AST::BinaryOpNode.new(op, left, right)
          end
        end
      end

      tokens.each do |token|
        case token.type
        when Token::Type::Number
          output << AST::NumberNode.new(token.value.as(String).to_f64)

        when Token::Type::Variable
          output << AST::VariableNode.new(token.value.as(String))

        when Token::Type::Operator
          val = token.value.as(String)

          if val == "("
            ops << val

          elsif val == ")"
            while !ops.empty? && ops.last != "("
              push_op.call(ops.pop)
            end
            ops.pop  # discard "("
            if !ops.empty? && FUNC_NAMES.includes?(ops.last)
              push_op.call(ops.pop)
            end

          elsif FUNC_NAMES.includes?(val)
            ops << val

          elsif val == "u-" || val == "u+"
            # Unary — right-associative, highest precedence before functions
            while !ops.empty? && ops.last != "(" && precedence(ops.last) > precedence(val)
              push_op.call(ops.pop)
            end
            ops << val

          else
            # Binary operator
            while !ops.empty? && ops.last != "(" && should_pop?(val, ops.last)
              push_op.call(ops.pop)
            end
            ops << val
          end
        else
          # ignore
        end
      end

      while !ops.empty?
        op = ops.pop
        raise "Mismatched parentheses in expression" if op == "("
        push_op.call(op)
      end

      raise "Invalid expression: empty result" if output.empty?
      output.last
    end

    # -------------------------------------------------------------------------
    # High-level parse: tokenize → build AST → evaluate with env
    # -------------------------------------------------------------------------
    def self.parse(expression : String, env : Hash(String, Float64)) : Float64
      raise "Empty expression" if expression.strip.empty?
      tokens = tokenize(expression)
      ast    = build_ast(tokens)
      ast.evaluate(env)
    end

    # -------------------------------------------------------------------------
    # Compile only: return AST root for repeated evaluation
    # -------------------------------------------------------------------------
    def self.compile(expression : String) : AST::Node
      raise "Empty expression" if expression.strip.empty?
      build_ast(tokenize(expression))
    end

    # -------------------------------------------------------------------------
    # Operator helpers (unchanged)
    # -------------------------------------------------------------------------
    def self.precedence(operator : String) : Int32
      case operator
      when "u-", "u+" then 4
      when "^"        then 3
      when "*", "/", "%" then 2
      when "+", "-"   then 1
      else -1
      end
    end

    def self.has_left_associativity(operator : String) : Bool
      operator == "+" || operator == "-" || operator == "/" || operator == "*" || operator == "%"
    end

    def self.should_pop?(op1 : String, op2 : String) : Bool
      p1 = precedence(op1)
      p2 = precedence(op2)
      p2 > p1 || (p2 == p1 && has_left_associativity(op1))
    end

    # -------------------------------------------------------------------------
    # Legacy methods kept for internal backward compatibility
    # -------------------------------------------------------------------------
    def self.clear_expression(expression : String)
      Log.trace { "clearing expression #{expression}" }
      cleaned = expression.delete(" ")
      raise "Malformed expression: check parentheses" if cleaned.count('(') != cleaned.count(')')
      cleaned
    end

    def self.evaluate(expression : String)
      parse(expression, Constants::DEFAULT_ENV)
    end
  end
end

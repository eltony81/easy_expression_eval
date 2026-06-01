require "num"

module EEEval
  module AST
    # Base class for all AST nodes
    abstract class Node
      abstract def evaluate(env : Hash(String, Float64)) : Float64
      abstract def evaluate(env : Hash(String, Tensor(Float64, CPU(Float64)))) : Tensor(Float64, CPU(Float64))
    end

    # Leaf node: a literal number (e.g. 3.14, -2.0)
    class NumberNode < Node
      def initialize(@value : Float64)
      end

      def evaluate(env : Hash(String, Float64)) : Float64
        @value
      end

      def evaluate(env : Hash(String, Tensor(Float64, CPU(Float64)))) : Tensor(Float64, CPU(Float64))
        Tensor(Float64, CPU(Float64)).new([1]) { @value }
      end
    end

    # Leaf node: a named variable or constant (e.g. x, pi, t)
    # resolved at evaluation time via the env hash
    class VariableNode < Node
      def initialize(@name : String)
      end

      def evaluate(env : Hash(String, Float64)) : Float64
        val = env[@name]?
        raise "Undefined variable or constant: '#{@name}'" unless val
        val
      end

      def evaluate(env : Hash(String, Tensor(Float64, CPU(Float64)))) : Tensor(Float64, CPU(Float64))
        val = env[@name]?
        raise "Undefined variable or constant: '#{@name}'" unless val
        val
      end
    end

    # Internal node: binary operator (+, -, *, /, ^)
    class BinaryOpNode < Node
      def initialize(@op : String, @left : Node, @right : Node)
      end

      def evaluate(env : Hash(String, Float64)) : Float64
        l = @left.evaluate(env)
        r = @right.evaluate(env)
        case @op
        when "+" then l + r
        when "-" then l - r
        when "*" then l * r
        when "/" then l / r
        when "^" then l ** r
        when "%" then l % r
        else raise "Unknown operator: '#{@op}'"
        end
      end

      def evaluate(env : Hash(String, Tensor(Float64, CPU(Float64)))) : Tensor(Float64, CPU(Float64))
        l = @left.evaluate(env)
        r = @right.evaluate(env)
        case @op
        when "+" then l + r
        when "-" then l - r
        when "*" then l * r
        when "/" then l / r
        when "^" then l ** r
        when "%" then l % r
        else raise "Unknown operator: '#{@op}'"
        end
      end
    end

    # Internal node: unary operator (u-, u+)
    class UnaryOpNode < Node
      def initialize(@op : String, @operand : Node)
      end

      def evaluate(env : Hash(String, Float64)) : Float64
        val = @operand.evaluate(env)
        case @op
        when "u-" then -val
        when "u+" then val
        else raise "Unknown unary operator: '#{@op}'"
        end
      end

      def evaluate(env : Hash(String, Tensor(Float64, CPU(Float64)))) : Tensor(Float64, CPU(Float64))
        val = @operand.evaluate(env)
        case @op
        when "u-" then -val
        when "u+" then val
        else raise "Unknown unary operator: '#{@op}'"
        end
      end
    end

    # Internal node: math function call (sin, cos, log, …)
    class FunctionNode < Node
      def initialize(@func : String, @arg : Node)
      end

      def evaluate(env : Hash(String, Float64)) : Float64
        arg = @arg.evaluate(env)
        case @func
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
        when "floor" then arg.floor
        when "ceil"  then arg.ceil
        when "round" then arg.round
        when "sgn"   then arg.sign.to_f
        when "sinh"  then Math.sinh(arg)
        when "cosh"  then Math.cosh(arg)
        when "tanh"  then Math.tanh(arg)
        when "gamma" then Math.gamma(arg)
        else raise "Unknown function: '#{@func}'"
        end
      end

      def evaluate(env : Hash(String, Tensor(Float64, CPU(Float64)))) : Tensor(Float64, CPU(Float64))
        arg = @arg.evaluate(env)
        case @func
        when "log"   then arg.log
        when "exp"   then arg.exp
        when "sin"   then arg.sin
        when "cos"   then arg.cos
        when "sqrt"  then arg.sqrt
        when "tan"   then arg.tan
        when "atan"  then arg.atan
        when "asin"  then arg.asin
        when "acos"  then arg.acos
        when "exp2"  then arg.exp2
        when "log10" then arg.log10
        when "log2"  then arg.log2
        when "abs"   then arg.map { |x| x.abs }
        when "floor" then arg.map { |x| x.floor }
        when "ceil"  then arg.map { |x| x.ceil }
        when "round" then arg.map { |x| x.round }
        when "sgn"   then arg.map { |x| x.sign.to_f }
        when "sinh"  then arg.sinh
        when "cosh"  then arg.cosh
        when "tanh"  then arg.tanh
        when "gamma" then arg.gamma
        else raise "Unknown function: '#{@func}'"
        end
      end
    end
  end
end

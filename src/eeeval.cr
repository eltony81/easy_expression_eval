require "log"
require "num"
require "./constants"
require "./eval/*"

# EEEval — Easy Expression Evaluator
#
# Public API:
#
#   # Simple evaluation (constants like pi, e, tau, sqrt2, phi built in)
#   EEEval::CalcFuncParser.evaluate("sin(pi/2) + e")  # => 3.718...
#
#   # Evaluation with user-defined variables
#   EEEval::CalcFuncParser.evaluate("x^2 + y", {"x" => 3.0, "y" => 1.0})  # => 10.0
#
#   # Pre-compile expression for efficient repeated evaluation
#   ast = EEEval::CalcFuncParser.compile("sin(x) * phi")
#   (0..100).each { |i| ast.evaluate({"x" => i.to_f64}.merge(EEEval::Constants::DEFAULT_ENV)) }
#
module EEEval

  class CondParser
    def self.parentheses_balanced?(expression)
      in_string = false
      count = 0
      expression.each_char do |chr|
        if chr == '\''
          in_string = !in_string
        elsif !in_string
          if chr == '('
            count += 1
          elsif chr == ')'
            count -= 1
            return false if count < 0
          end
        end
      end
      count == 0
    end

    def self.evaluate(expression)
      raise Exception.new("malformed expression: check parentheses") unless parentheses_balanced?(expression)
      evaluate_rpn(infix_to_rpn expression).value == "true"
    end
  end

  class CalcFuncParser

    # -----------------------------------------------------------------------
    # evaluate(expression) — backward-compatible single-argument form.
    # Built-in constants (pi, e, tau, sqrt2, phi) are always available.
    # -----------------------------------------------------------------------
    def self.evaluate(expression : String) : Float64
      Log.trace { "INIT evaluation: #{expression}" }
      CalcParser.parse(expression, Constants::DEFAULT_ENV)
    end

    # -----------------------------------------------------------------------
    # evaluate(expression, vars) — evaluates with user-defined variables.
    # User vars are merged on top of the built-in constants, so user can
    # override a constant if needed (e.g. redefine "pi" for testing).
    # -----------------------------------------------------------------------
    def self.evaluate(expression : String, vars : Hash(String, Float64)) : Float64
      Log.trace { "INIT evaluation with vars: #{expression}" }
      env = Constants::DEFAULT_ENV.merge(vars)
      CalcParser.parse(expression, env)
    end

    # -----------------------------------------------------------------------
    # evaluate(ast, vars) — evaluates a pre-compiled AST with an environment.
    # Most efficient form: use this inside loops / range evaluations.
    # -----------------------------------------------------------------------
    def self.evaluate(ast : AST::Node, vars : Hash(String, Float64)) : Float64
      env = Constants::DEFAULT_ENV.merge(vars)
      ast.evaluate(env)
    end

    # -----------------------------------------------------------------------
    # evaluate(ast, vars) — evaluates a pre-compiled AST with a Tensor environment.
    # -----------------------------------------------------------------------
    def self.evaluate(ast : AST::Node, vars : Hash(String, Tensor(Float64, CPU(Float64)))) : Tensor(Float64, CPU(Float64))
      tensor_env = Hash(String, Tensor(Float64, CPU(Float64))).new
      Constants::DEFAULT_ENV.each do |k, v|
        tensor_env[k] = Tensor(Float64, CPU(Float64)).new([1]) { v }
      end
      env = tensor_env.merge(vars)
      ast.evaluate(env)
    end

    # -----------------------------------------------------------------------
    # compile(expression) — parses the expression once and returns the AST.
    # Use this when the same expression will be evaluated many times with
    # different variable values (e.g. CLI range, plotting, benchmarks).
    #
    # Example:
    #   ast = EEEval::CalcFuncParser.compile("sin(x) * phi")
    #   (0..100).each do |i|
    #     EEEval::CalcFuncParser.evaluate(ast, {"x" => i.to_f})
    #   end
    # -----------------------------------------------------------------------
    def self.compile(expression : String) : AST::Node
      Log.trace { "Compiling expression: #{expression}" }
      CalcParser.compile(expression)
    end

    # -----------------------------------------------------------------------
    # tokenize(expression) — public access to the tokenizer.
    # Returns the flat Array(Token) produced by lexical analysis.
    # Useful for debugging or building custom evaluators.
    # -----------------------------------------------------------------------
    def self.tokenize(expression : String) : Array(Token)
      CalcParser.tokenize(expression)
    end

    # -----------------------------------------------------------------------
    # build_ast(tokens) — public access to the AST builder.
    # Converts a pre-tokenized Array(Token) into an AST::Node tree.
    # -----------------------------------------------------------------------
    def self.build_ast(tokens : Array(Token)) : AST::Node
      CalcParser.build_ast(tokens)
    end

  end
end

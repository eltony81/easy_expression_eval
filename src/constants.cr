module EEEval
  module Constants
    # Default environment: named mathematical constants available in every
    # expression without explicit declaration.
    DEFAULT_ENV = {
      "pi"    => Math::PI,
      "e"     => Math::E,
      "tau"   => Math::TAU,
      "sqrt2" => Math.sqrt(2.0),
      "phi"   => (1.0 + Math.sqrt(5.0)) / 2.0,
    } of String => Float64

    # Crystal-level constants kept for direct use in Crystal code
    PI    = Math::PI
    E     = Math::E
    TAU   = Math::TAU
    SQRT2 = Math.sqrt(2.0)
    PHI   = (1.0 + Math.sqrt(5.0)) / 2.0
  end
end

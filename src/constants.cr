module EEEval
  module Constants
    # Default environment: named mathematical constants available in every
    # expression without explicit declaration.
    DEFAULT_ENV = {
      "pi"      => Math::PI,
      "e"       => Math::E,
      "tau"     => Math::TAU,
      "sqrt2"   => Math.sqrt(2.0),
      "phi"     => (1.0 + Math.sqrt(5.0)) / 2.0,
      "rad2deg" => 180.0 / Math::PI,
      "deg2rad" => Math::PI / 180.0,
      "g"       => 9.80665,
      "inf"     => Float64::INFINITY,
      "nan"     => Float64::NAN,
    } of String => Float64

    # Crystal-level constants kept for direct use in Crystal code
    PI      = Math::PI
    E       = Math::E
    TAU     = Math::TAU
    SQRT2   = Math.sqrt(2.0)
    PHI     = (1.0 + Math.sqrt(5.0)) / 2.0
    RAD2DEG = 180.0 / Math::PI
    DEG2RAD = Math::PI / 180.0
    G       = 9.80665
    INF     = Float64::INFINITY
    NAN     = Float64::NAN
  end
end

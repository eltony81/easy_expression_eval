module EEEval

  class Token
    property value : String | Float64
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
end

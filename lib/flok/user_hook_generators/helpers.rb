module Flok
  #This class helps construct javascript expressions like ((a == 3 || b == 4) && (a == 5 || c == 6))
  #Usually you have an outer-level JSTermGroup that represents all the things being anded togeather
  #and then you have multiple inner groups that each represent ored terms. Search POS form on wikipedia
  #e.g.
  # #Convert ((a == 3 || b == 4) && (a == 5 || c == 6)) 
  #
  # This will hold the entire result
  # ands = JSTermGroup.new
  # 
  # Compute a small section of the result, the group (a == 3 || b == 4) and
  # then add it as a group of the entire result in || form
  # ors1 = JSTermGroup.new
  # ors1 << "a == 3"
  # ors1 << "b == 4"
  # ands << ors1.to_or_js
  #
  # Same thing but now we compute the second part which is (a == 5 || c == 5)
  # ors2 = JSTermGroup.new
  # ors2 << "a == 5"
  # ors2 << "c == 6"
  # ands << ors2.to_or_js
  #
  # Finally get the result by &&ing all the ||s groups togeather
  # result = ands.to_and_js
  class JSTermGroup
    def initialize
      @terms = []
    end

    #Add a javascript expression that evaluates to either true or false. May or may not contain parantheses
    def << expr
      @terms << "(#{expr})"
    end

    #Join expressions via || statements and yield an expression that contains parantheses
    def to_or_js
      "(#{[*@terms, "false"].join(" || ")})"
    end

    #Join expressions via && statements and yield an expression that contains parantheses
    def to_and_js
      "(#{[*@terms, "true"].join(" && ")})"
    end
  end
end

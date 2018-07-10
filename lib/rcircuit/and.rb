# Represents an AND gate
class AndGate < Gate

  # Called when inputs change.
  # Calculates AND of all inputs and sets output port to that value.
  # @param vals [Array<Integer>] List of values for connected ports.
  def inputs_changed(vals)
    andval=nil
    vals.each do |val|
      if andval==nil
        andval=val
      else
        andval=andval&val
      end
    end
    out.setval(andval)
  end
end

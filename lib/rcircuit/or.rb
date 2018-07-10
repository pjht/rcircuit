# Represents an OR gate
class OrGate < Gate

  # Called when inputs change.
  # Calculates OR of all inputs and sets output port to that value.
  def inputs_changed(vals)
    orval=nil
    vals.each do |val|
      if orval==nil
        orval=val
      else
        orval=orval|val
      end
    end
    out.setval(orval)
  end
end

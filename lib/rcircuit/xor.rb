# Represents an XOR gate
class XorGate < Gate

  # Called when inputs change.
  # Calculates XOR of all inputs and sets output port to that value.
  def inputs_changed(vals)
    xorval=nil
    vals.each do |val|
      if xorval==nil
        xorval=val
      else
        xorval=xorval^val
      end
    end
    out.setval(xorval)
  end
end

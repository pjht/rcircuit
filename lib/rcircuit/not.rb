# Represents a NOT gate
class NotGate < Gate

  # Add a port to the gate. As this is a NOT gate, there may only be one port.
  # @param (see Gate#add_input)
  # @return [void]
  def add_input(input_port)
    if @inputs.length > 0 then
      raise ArgumentError, "Cannot add multiple inputs to a NOT gate"
    end
    super
  end

  # Called when inputs change.
  #  Calculates NOT of input and sets output port to that value.
  # @param vals [Array<Integer>] List of values for connected ports.
  def inputs_changed(vals)
    out.setval((~vals[0]) & ((2**@width)-1))
  end
end

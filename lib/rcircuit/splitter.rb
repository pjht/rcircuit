## Outputs a specified subset of the bits from an input port
class Splitter < Device
  # @param port [Port] A the splitter input port
  # @param bits [Integer,Array,Range] The bits from the input port that are output by the splitter
  # @return [void]
  def initialize(port, bits)
    if bits.is_a?(Integer)
      width = 1
      @bitlist = [bits]
    elsif bits.is_a?(Array) 
      width = bits.size
      @bitlist = bits.reverse #store in MSB order
    elsif bits.is_a?(Range)
      width = bits.size
      @bitlist = bits.to_a.reverse #store in MSB order 
    else
      raise ArgumentError.new("bits argument must be of type Integer, Array , or Range")
    end
    @bits = bits
    add_output("out", width)
    port.add_callback { |val| on_change(val) }
    on_change(port.val)
  end

  private
  # Called when there is a change to inputs
  def on_change(input_val)
    outval = 0
    @bitlist.each do |bit|
      outval *= 2
      outval += ((input_val >> bit) & 1)
    end
    out.setval(outval)
  end
  
end

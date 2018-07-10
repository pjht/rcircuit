# @abstract Subclass and override {#inputs_changed} to implement a gate
## Base class for gates
class Gate

  # @!attribute [r] out
    # @return [Port] the output port of the gate
  attr_reader :out

  # @param args [Array<Port>] These are the ports to be added to the gate.
  # @note The first argument determines the width of the gate.
  def initialize(*args)
    @inputs=[]
    @width=args[0].width
    @out=Port.new(@width)
    args.each do |input|
      add_input(input)
    end
  end

  # Add a port to the gate.
  # @param port [Port] The port to be added. It must match the width of the gate.
  # @return [void]
  def add_input(port)
    if port.width != @width then
      raise ArgumentError, "Incorrect width #{port.width}, expected #{@width}"
    end
    @inputs.push(port)
    port.add_callback do |value|
      vals=[]
      @inputs.each do |port|
        vals.push port.val
      end
      inputs_changed(vals)
     end
    vals=[]
    @inputs.each do |port|
      vals.push port.val
    end
    inputs_changed(vals)
  end

  # Test a truth table for a gate.
  # @param table [Array<Array<Integer>>] The truth table,
  #   which is an array of entries. The last value in the entry is the expected output,
  #   the rest are the inputs to the ports.
  def self.test_table(table)
    ports=[]
    (table[0].length-1).times do
      ports.push Port.new(1)
    end
    gate=self.new(*ports)
    table.each do |entry|
      i=0
      ports.each do |port|
        port.setval(entry[i])
        i+=1
      end
      return false if gate.out!=entry.last
    end
    return true
  end

  # Called when inputs change.
  # @abstract Override this to implement a gate.
  # @param vals [Array<Integer>] List of values for connected ports.
  def inputs_changed(vals); raise NotImplementedError; end
end

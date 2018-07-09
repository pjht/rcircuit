require_relative "port.rb"

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

  # @abstract Override this to implement a gate.
  # @param vals [Array<Integer>] List of values for connected ports.
  def inputs_changed(vals); raise NotImplementedError; end
end

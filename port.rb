## Represents an IO port of a device

class Port
  include Comparable

  # @!attribute [r] val
    # @return [Integer] the current value of the port
  attr_reader :val

  # @!attribute [r] width
    # @return [Integer] the width of the port
  attr_reader :width

  # Returns a new instance of Port
  # @overload set(width)
  #   @param width [Integer] The width of the port
  # @overload set(width, name)
  #   @param width [Integer] The width of the port
  #   @param name [String] The name of the port
  def initialize(width, name="")
    @connected=[]
    @propagating=false
    @val=0
    @width=width
    @maxval = (2**@width)-1
    @strname=name
  end

  # Sets the port's value
  # @param val [Integer] The new value for the port
  # @return [void]
  def setval(val)
    # Prevent infinite loops when the connected port calls back when propagating.
    if !@propagating
      if val<=@maxval
        @val=val
      else
        raise ArgumentError,"#{val} is over maximum of #{@maxval}"
      end
      @propagating=true
      propagate()
      @propagating=false
    end
  end

  # Connects this port to another port
  # @param port [Port] The port to connect to
  # @return [void]
  def connect(port)
    @connected.push port
    port.connect_back(self)
  end

  # Returns a string representation for debugging
  # @return [String] String name of the port, or super if none
  def to_s()
    return super if @strname==""
    return @strname
  end

  # Method for Comparable module to use for comparasions.
  # @param obj [Object] Object to compare to
  # @return [void]
  def <=>(obj)
    if obj.class==Port
      return @val<=>obj.val
    elsif obj.is_a? Integer
      return @val<=>obj
    end
  end

  # Used by connect when setting up bidirectional connection.
  # @api private
  # @param (see #connect)
  # @return [void]
  def connect_back(port)
    @connected.push port
  end

  private

  # Propagates the value to all connected ports
  # @return [void]
  def propagate()
    @connected.each do |port|
      port.setval(@val)
    end
  end

end

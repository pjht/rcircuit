## Class for devices such as adders and registers
class Device
  # Add an input port
  # @param name [String] Name of the port
  # @param width [Integer] Width of the port
  # @return [void]
  def add_input(name, width=1)
    port = Port.new(width)
    instance_variable_set("@#{name}", port)
    port.add_callback { |val| on_change() }
  end

  # Add an output port
  # @param name [String] Name of the port
  # @param width [Integer] Width of the port
  # @return [void]
  def add_output(name, width=1)
    self.class.class_eval{attr_reader name.to_sym}
    port = Port.new(width)
    instance_variable_set("@#{name}", port)
  end

  # Add a subdevice
  # @param name [String] Name of the subdevice
  # @param device [Device] Device to add
  # @return [void]
  def define_device(name, device)
    instance_variable_set("@#{name}", device)
    self.class.class_eval{attr_reader name.to_sym}
  end

  private
  # Used to set the ports from the argument hash in initialize
  # @param hash [Hash{String=>Port}] Hash of names to ports
  # @return [void]
  def init_assign(hash)
    hash.each do |name, port|
      #check if there is a defined method (port) that matches
      if self.respond_to?(name)
        instance_variable_get("@#{name}").connect(port)
      else
        raise ArgumentError, "No defined input '#{name}'"
      end
    end
  end
end

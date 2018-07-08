require 'set'
#endpoints for nets
class NetPort

  def initialize(width=1)
    @callbacks = []
    @updating = false
    #set up a new net with a matching width
    Net.new(self, width)
  end

  def connect(other)
    if other.is_defined?
      self.value = other.value #drive into the new net first
    end
    Net.get_net(self).connect(other)
    self  #return self for call chaining
  end

  def value
    Net.get_net(self).value
  end
  def bvalue
    unless Net.get_net(self).value==nil
      Net.get_net(self).value.to_s(2)
    end
  end
  def width
    Net.get_net(self).width
  end

  def value=(new_value)
    Net.get_net(self).drive(new_value)
  end

  def posedge?
    Net.get_net(self).posedge?
  end

  def negedge?
    Net.get_net(self).negedge?
  end

  def is_defined?
    self.value != nil
  end

  def undefine
    self.value = nil 
  end

  #called by Net, do not call directly 
  def _update(value)
    if @updating
      raise RuntimeError, "Signal loop detected in #{self.get_name}"
    end
    @updating = true
    #send new value to each listener
    @callbacks.each do |callback|
      callback.call(value)
    end
    @updating = false
  end

  def add_callback(&callback)
    #add block to the list, put at head
    @callbacks.insert(0, callback)
    self  #return self for call chaining
  end

  def add_late_callback(&callback)
    #add block to the list, put at end to be called last
    @callbacks.push(callback)
    self  #return self for call chaining
  end

  def set_name(name)
    @name = name
  end

  def set_parent(parent)
    @parent = parent
  end

  def get_name
    if @name == nil
      @name = self.class
    end
    if @parent != nil
      @parent.get_name + "." + @name
    else
      @name
    end 
  end

end

class Net
  @@assignments = {} #table of nets assigned to ports
  @@propagate_list = [] #nets that have changed during propagate call
  @@propagate_flag = false

  def initialize(port, width=1)
    if @@assignments.has_key?(port)
      raise ArgumentError, "Repeat assignment of port to new net"
    end
    @ports = Set.new
    @ports.add(port)
    @width = width
    @max_value = 2**@width - 1
    @value = nil
    @posedge = false
    @negedge = false
    @@assignments[port] = self
  end

  def ports
    @ports
  end

  def width
    @width
  end

  def connect(other)
    if @width != other.width
      raise ArgumentError, "Cannot connect nets of different widths"
    end
    if @@assignments.has_key?(other)
       #net already assigned to other port. 
       #Merge them and update @@assignments table
       other_net = @@assignments[other]
       @ports.merge(other_net.ports)
       other_net.ports.each { |port_in_other| @@assignments[port_in_other] = self }
    else
       #unassigned port, just add it
       @ports.add(other)
       @@assignments[other] = self
    end
  end

  def drive(new_value)
    if new_value.is_a?(NetPort)
      new_value=new_value.value
    end
    if new_value != nil && (new_value < 0 || new_value > @max_value)
      raise ArgumentError, "Invalid value (#{new_value}) for net"
    end
    if new_value != @value
      @new_value = new_value
      @@propagate_list.push(self) #schedule to run update
      if not @@propagate_flag
        #automatically propagate the change and all changes that result
        @@propagate_flag = true #prevent recursion
        Net.propagate
        @@propagate_flag = false  #unlock for next time
      end
    end   
  end

  #loops until all updates complete
  def self.propagate
    #propagate list will grow as downstream nets are changed
    #keep updating until none are left
    while @@propagate_list.length > 0 do
      net = @@propagate_list.shift
      net.update
    end
  end

  def update
    @posedge = (@value == 0 && @new_value != nil && @new_value > 0)
    @negedge = (@value != nil && @value > 0 && @new_value == 0)
    @value = @new_value
    @ports.each { |driven| driven._update(@new_value) }
    #edges only last for the current update
    @posedge = false
    @negedge = false
  end

  def value
    @value
  end

  def posedge?
    @posedge
  end

  def negedge?
    @negedge
  end

  def value=(new_value)
    drive(new_value)
  end

  #get net currently assigned to the given port (or a new one)
  def self.get_net(port)
    if @@assignments.has_key?(port)
      @@assignments[port]
    else
      self.new(port)
    end
  end

  def self.test
    a = NetPort.new(4).add_callback { |value| puts "A set to #{value}" }
    b = NetPort.new(4).add_callback { |value| puts "B set to #{value}" }
    c = NetPort.new(4).add_callback { |value| puts "C set to #{value}" }
    d = NetPort.new(4).add_callback { |value| puts "D set to #{value}" }

    #connect A-B and C-D
    a.connect(b)
    c.connect(d)

    a.value = 1
    c.value = 2
    #connect them all together
    b.connect(c)
    a.value = 3 
    d.value = 4
  end
end 

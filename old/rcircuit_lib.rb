# Ruby Circuit Simulator
# Library file

# holds a digital value
# can call listener callbacks when value changes

require_relative "net"
#add some extra functionality to the basic NetPort
class Port < NetPort
  include Comparable

  #override to handle bitstrings
  def value=(new_value)
    if new_value.class == String
      if new_value.length != self.width
        raise ArgumentError, "Wrong width for bitstring: #{new_value}"
      end
      numval = 0
      new_value.reverse.each do |bit|
        numval = numval << 1
	if bit == "1"
          numval += 1
        elsif bit != "0"
          raise ArgumentError, "String values (#{new_value}) must be binary"
        end
      end
      super(numval)
    else
      super(new_value)
    end
  end

  def convert_port(otherval)
    #checks if argument is a port or number
    #if it is a number, convert it to a contant port
    if otherval.class == Integer
      return PortConstant.new(self.width, otherval)
    else
      return otherval
    end
  end

  def &(other)
    other = convert_port(other)
    return AndGate.new(self,other).out
  end

  def |(other)
    other = convert_port(other)
    return OrGate.new(self,other).out
  end

  def ^(other)
    other = convert_port(other)
    return XorGate.new(self, other).out
  end

  def !
    return NotGate.new(self).out
  end

  def +(other)
    other = convert_port(other)
    return Adder.new(self.width,{"a"=>self,"b"=>other}).out
  end

  def -(other)
    other = convert_port(other)
    return Subtractor.new(self.width,{"a"=>self,"b"=>other}).out
  end

  def slice(index)
    if index.class==Integer
      port=Port.new(1)  #single line
      mask = 1 << index
      shift = index
    else
      port=Port.new(index.size) #range
      mask = (2**(index.size) - 1) << index.first
      shift = index.first
    end
    #copies slice to new port
    self.add_callback do |new_value|
      port.value = (new_value & mask) >> shift
    end
    return port
  end

  def join(other,last=false)
    port=Port.new(self.width+other.width)
    def update_port(last,port,other)
      if self.is_defined? && other.is_defined?
        if last
          port.value=(other.value << self.width) + self.value
        else
          port.value=(self.value << other.width)  + other.value
        end
      else
        port.undefine
      end
    end
    self.add_callback {|value| update_port(last,port,other)}
    other.add_callback {|value| update_port(last,port,other)}
    return port
  end

  def <=>(other)
    other = convert_port(other)
    return self.value<=>other.value
  end

  def >>(shiftbits)
    return LSR.new(self.width, shiftbits).in(self).out
  end

  def <<(shiftbits)
    return LSL.new(self.width, shiftbits).in(self).out
  end

  def bitstring
    if is_defined?
      mask = 1 << (self.width - 1)
      strval = ""
      self.width.times do
        if (self.value & mask) > 0
          strval += "1"
        else
          strval += "0"
        end
        mask = mask >> 1
      end
      strval
    else
      "X"*self.width
    end
  end

  def method_missing(m, *args, &block)
      return self
  end
end

class PortConstant < Port
  def initialize(width, value)
    super(width)
    @assigned = false
    self.value = value
    @assigned = true
  end

  def _update(newvalue)
    if @assigned
      #not initial assigment
      #raise RuntimeError, "Cannot change value of constant port"
    end
  end
end


class Gate
  def initialize(*args)
    @inputs = []
    if args.length==0
      @width=1
      @out = Port.new(@width)
    elsif args[0].class==Integer
      @width=args.shift
      @out = Port.new(@width)
      args.each do |input|
        add_input(input)
      end
    else
      @width=args[0].width
      @out = Port.new(@width)
      args.each do |input|
        add_input(input)
      end
    end
  end

  def add_input(input_port)
    if input_port.width != @width then
      raise ArgumentError, "Incorrect port width"
    end
    @inputs.push(input_port)
    input_port.add_callback {|value| self.input_changed(value)}
    input_changed(input_port.value)
  end

  def out
    return @out
  end

end


class NotGate < Gate
  def initialize(*args)
    super
    @outmask = (2**@width)-1
  end

  def add_input(input_port)
    if @inputs.length > 0 then
      raise ArgumentError, "Cannot add multiple inputs to NotGate"
    end
    super
  end

  alias set_input add_input

  def input_changed(new_value)
    inport=@inputs[0]
    if inport.is_defined?
      out.value = (~inport.value) & @outmask
    else
      out.undefine
    end
  end

  def self.test
    puts "NOT Test:"
    nin = Port.new()
    not_gate = NotGate.new(nin)
    dbg = Dbg.new( {"in"=>nin, "out"=>not_gate.out})
    dbg.out
    nin.value = 0
    dbg.out
    nin.value = 1
    dbg.out
  end
end

class AndGate < Gate

  def input_changed(new_value)
    andval = nil
    @inputs.each do |inport|
      if inport.is_defined?
        if andval == nil
          andval = inport.value
        else
          andval = andval & inport.value
        end
      else
        out.undefine
        return
      end
    end
    out.value = andval
  end

  def self.test()
    puts "AND Test:"
    in_a = Port.new()
    in_b = Port.new()
    and_gate = AndGate.new(in_a, in_b)
    dbg = Dbg.new( {"a"=>in_a, "b"=>in_b, "out"=>and_gate.out})
    dbg.out
    in_a.value=0
    in_b.value=0
    dbg.out
    in_a.value=1
    in_b.value=0
    dbg.out
    in_a.value=0
    in_b.value=1
    dbg.out
    in_a.value=1
    in_b.value=1
    dbg.out
  end
end

class OrGate < Gate

  def input_changed(new_value)
    orval = nil
    @inputs.each do |inport|
      if inport.is_defined?
        if orval == nil
          orval = inport.value
        else
          orval = orval | inport.value
        end
      else
        out.undefine
        return
      end
    end
    out.value = orval
  end

  def self.test()
    puts "OR Test:"
    in_a = Port.new()
    in_b = Port.new()
    or_gate = OrGate.new(in_a, in_b)
    dbg = Dbg.new( {"a"=>in_a, "b"=>in_b, "out"=>or_gate.out})
    dbg.out
    in_a.value=0
    in_b.value=0
    dbg.out
    in_a.value=1
    in_b.value=0
    dbg.out
    in_a.value=0
    in_b.value=1
    dbg.out
    in_a.value=1
    in_b.value=1
    dbg.out
  end
end


class XorGate < Gate

  def input_changed(new_value)
    xorval = nil
    @inputs.each do |inport|
      if inport.is_defined?
        if xorval == nil
          xorval = inport.value
        else
          xorval = xorval ^ inport.value
        end
      else
        out.undefine
        return
      end
    end
    out.value = xorval
  end

  def self.test()
    puts "XOR Test:"
    in_a = Port.new()
    in_b = Port.new()
    or_gate = OrGate.new(in_a, in_b)
    dbg = Dbg.new( {"a"=>in_a, "b"=>in_b, "out"=>or_gate.out})
    dbg.out
    in_a.value=0
    in_b.value=0
    dbg.out
    in_a.value=1
    in_b.value=0
    dbg.out
    in_a.value=0
    in_b.value=1
    dbg.out
    in_a.value=1
    in_b.value=1
    dbg.out
  end
end


class Device
  def define_port(name, width=1, &callback)
    #create a method with the same name as the input
    #to assign a port to the input
    var_name = "@" + name
    port = Port.new(width)
    port.set_name(name)
    port.set_parent(self)
    instance_variable_set(var_name, port)
    define_singleton_method(name) do |other=nil|
      if other.class == NilClass  #avoids overloaded compare for Port
        #getter
        instance_variable_get(var_name)
      else
	#connect to given port
        if other.class == Integer
          #convert constant
          other = PortConstant.new(width, other)
        end
        instance_variable_get(var_name).connect(other)
	self #for chained init calls
      end
    end
    if block_given?
      port.add_callback(&callback)
    end
    port
  end

  def define_input(name, width=1)
    #automatically connects to on_change method
    define_port(name, width) { |new_value| on_change(new_value) }
  end

  #for contained subdevices
  def define_device(name, device)
    var_name = "@" + name
    instance_variable_set(var_name, device)
    define_singleton_method(name) { instance_variable_get(var_name) }
    device.set_parent(self)
    device.set_name(name)
  end

  #call on the hash of arguments at init
  def init_assign(hash)
    hash.each do |name, port|
      #check if there is a defined method (port) that matches
      if self.respond_to?(name)
        method(name).call(port)
      else
        raise ArgumentError, "No defined input '#{name}'"
      end
    end
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

#logical shift right
class LSR < Device
  def initialize(width, bitshift, init_args={})
    define_input("in", width)
    define_port("out", width)
    @bitshift = bitshift
    init_assign(init_args)
  end

  def on_change(data_val)
    if @in.is_defined?
      out.value = @in.value >> @bitshift
    else
      out.undefine
    end
  end
end

#logical shift left
class LSL < Device
  def initialize(width, bitshift, init_args={})
    define_input("in", width)
    define_port("out", width)
    @bitshift = bitshift
    @outmask = (2**width) - 1
    init_assign(init_args)
  end

  def on_change(data_val)
    if @in.is_defined?
      out.value = (@in.value << @bitshift) & @outmask
    else
      out.undefine
    end
  end
end


class Reg < Device
  def initialize(width, init_args={})
    define_input("in", width)
    define_port("out", width)
    define_input("clk")
    define_input("en")
    define_input("rst")
    init_assign(init_args)
  end

  def on_change(data_val)
    if rst.value == 1
      out.value = 0
    elsif en.value == 1 && clk.posedge?
      out.value = @in.value
    end
  end
end

class Counter < Device
  def initialize(width, init_args={})
    define_input("in", width)
    define_port("out", width)
    define_input("clk")
    define_input("load")
    define_input("rst")
    init_assign(init_args)
  end

  def on_change(data_val)
    #puts "on_change, clk=#{clk.value}, rst=#{rst.value}"
    if out.undefined?
      out.value=0
    end
    if rst.value == 1
      #puts "resetting"
      out.value = 0
    elsif clk.posedge?
      #puts "posedge"
      if load.value == 1
        out.value = @in.value
      else
        #puts "no load, old out=#{out.value}"
        out.value = out.value + 1
        #puts "new out=#{out.value}"
      end
    end
  end

  def self.test
    puts "Reg Test:"
    din = Port.new(8)
    c = Port.new
    e = Port.new
    r = Port.new
    reg = Reg.new(8,{"in"=>din,"clk"=>c,"en"=>e,"rst"=>r})
    dbg = Dbg.new({"in"=>din, "clk"=>c, "en"=>e, "rst"=>r, "out"=>reg.out})
    r.value = 1
    c.value = 0
    e.value = 0
    din.value = 23
    dbg.out
    r.value = 1
    dbg.out
    r.value = 0
    dbg.out
    c.value = 1
    dbg.out
    e.value = 1
    dbg.out
    c.value = 0
    dbg.out
    c.value = 1
    dbg.out
    din.value = 37
    dbg.out
  end

end

class Mux < Device
  def initialize(data_width=1, select_width=1, init_args={})
    num_inputs = 2**select_width
    i=0
    @inputs = []
    num_inputs.times do
      @inputs << define_input("in"+i.to_s, data_width)
      i += 1
    end
    define_input("sel", select_width)
    define_port("out", data_width)
    init_assign(init_args)
  end

  def on_change(new_value)
    if sel.is_defined?

      out.value = @inputs[sel.value].value
    else
      out.undefine
    end
  end

  def self.test
    puts "Mux test:"
    select = Port.new(1)
    a = Port.new(4)
    b = Port.new(4)
    mux = Mux.new(4, 1).sel(select).in0(a).in1(b)
    dbg = Dbg.new({"sel"=>select, "0"=>a, "1"=>b, "out"=>mux.out})
    a.value = 3
    b.value = 14
    dbg.out
    select.value = 0
    dbg.out
    select.value = 1
    dbg.out
  end
end


class Decoder < Device
  def initialize(width, init_args={})
    @width=width
    define_input("sel", width)
    define_input("en")
    num_of_outputs=2**width
    i=0
    @outputs = []
    num_of_outputs.times do
      #create an ordered list of all the outputs
      @outputs << define_port("o"+i.to_s)
      i+=1
    end
    init_assign(init_args)
  end

  def on_change(data_val)
    if en
      if sel.is_defined?
        channel=sel.value
        i=0
        (@width**2).times do
          if i==channel
            @outputs[i].value=1
          else
            @outputs[i].value=0
          end
          i+=1
        end
      else
        i=0
        (@width**2).times do
          @outputs[i].undefine
          i+=1
        end
      end
    else
      i=0
      (@width**2).times do
        @outputs[i].value=0
        i+=1
      end
    end
  end

  def self.test
    puts "Decoder Test:"
    select=Port.new(2)
    decoder=Decoder.new(2,"sel"=>select)
    dbg = Dbg.new({"sel"=>select, "0"=>decoder.o0, "1"=>decoder.o1, "2"=>decoder.o2, "3"=>decoder.o3})
    dbg.out
    select.value=0
    dbg.out
    select.value=1
    dbg.out
    select.value=2
    dbg.out
    select.value=3
    dbg.out
  end
end

class PEncoder < Device
  def initialize(width, init_args={})
    define_port("out", width)
    @inputs = []
    @num_inputs = width**2
    (0...@num_inputs).each do |i|
      @inputs << define_input("in#{i}", 1)
    end
    init_assign(init_args)
  end

  def on_change(data_val)
    (0...@num_inputs).each do |i|
      if @inputs[i].is_defined?
        if @inputs[i].value == 1
          out.value = i
          return
        end
      else
        out.undefine
        return
      end
    end
    out.value = 0  #default, no active inputs
  end

  def self.test
    puts "PEncoder test:"
    in0 = Port.new
    in1 = Port.new
    in2 = Port.new
    in3 = Port.new
    out = Port.new(2)
    dut = PEncoder.new(2).in0(in0)
                         .in1(in1)
                         .in2(in2)
                         .in3(in3)
                         .out(out)
    dbg = Dbg.new({"0"=>dut.in0, "1"=>dut.in1, "2"=>dut.in2, "3"=>dut.in3, "Out"=>dut.out})
    dbg.out
    in0.value = 0
    in1.value = 0
    in2.value = 0
    in3.value = 0
    dbg.out
    in2.value = 1
    dbg.out
    in1.value = 1
    dbg.out
    in3.value = 1
    dbg.out
  end
end

class Adder < Device
  def initialize(width, init_args)
    define_input("a", width)
    define_input("b", width)
    define_port("out", width)
    init_assign(init_args)
    @mask = 2**width - 1
  end

  def on_change(data_val)
    if a.is_defined? && b.is_defined?
      out.value = (a.value + b.value) & @mask
    else
      out.undefine
    end
  end
end

class Subtractor < Device
  def initialize(width, init_args)
    define_input("a", width)
    define_input("b", width)
    define_port("out", width)
    init_assign(init_args)
    @mask = 2**width - 1
  end

  def on_change(data_val)
    if a.is_defined? && b.is_defined?
      out.value = (a.value - b.value) & @mask
    else
      out.undefine
    end
  end
end

class Ram < Device
  def initialize(data_width, addr_width, init_args={})
    @mem=[]
    define_input("in", data_width)
    define_port("out", data_width)
    define_input("addr", addr_width)
    define_input("clk")
    define_input("wr")
    init_assign(init_args)
  end

  def set_data(init_array)
    @mem = init_array
  end

  def on_change(data_val)
    if wr.value == 1 && clk.posedge?
      @mem[addr.value]=@in.value
      out.undefine
    elsif addr.is_defined? && @mem[addr.value] != nil
      out.value=@mem[addr.value]
    else
      out.value=0
    end
  end

  def [](addr)
    return @mem[addr]
  end
  def []=(addr,value)
    if value.class==String
      @mem[addr]=value.to_i(2)
    else
      @mem[addr]=value
    end
  end
  def self.test
    puts "RAM test:"
    din=Port.new(8)
    addr=Port.new(8)
    wr=Port.new
    clk=Port.new
    ram=Ram.new(8,8,{"in"=>din,"addr"=>addr,"wr"=>wr,"clk"=>clk})
    dbg=Dbg.new({"in"=>din,"out"=>ram.out,"addr"=>addr,"wr"=>wr,"clk"=>clk})
    clk.value=0
    din.value=11
    addr.value=0
    wr.value=1
    clk.value=1
    dbg.out
    clk.value=0
  end
end

class Dbg
  def initialize(ports,show_num=false)
    @names = []
    @ports = {}
    @show_num=show_num
    ports.each do |name,port|
      @names.push(name)
      @ports[name] = port
    end
  end

  def add_trigger(port_name)
    @ports[port_name].add_late_callback { |value| self.out }
  end

  def out
    watch_str = ""
    if @show_num
      @names.each { |name| watch_str += "#{name}=#{@ports[name].value} " }
    else
      @names.each { |name| watch_str += "#{name}=#{@ports[name].bitstring} " }
    end
    puts watch_str
  end
end

def test()
  classes = []
  ObjectSpace.each_object { |o| classes.push o if o.class == Class }
  classes.each do |c|
    if c!=Object && c.methods.include?(:test)
      c.test
    end
  end
end

# PEncoder.test
test()

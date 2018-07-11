# creates VCD file from port states

require "set"

def create_vcd_id(index)
  #VCD uses short id codes for signals.
  #Generate a unique id given a numeric index, 'a' to 'z'
  #then 'aa', ab',...
  new_id = ""
  loop do
    new_id = ('a'.ord + index%26).chr + new_id
    index = (index - index%26)
    break if index < 1
    index = index / 26 - 1
  end
  return new_id
end

def test_vcd_id
  [0, 1, 25, 26, 30, 26*26-1, 26*26, 27*26, 27*26+1].each do |i|
    puts "#{i} -> #{create_vcd_id(i)}"
  end
end

#test_vcd_id()

class VCD
  def initialize(filename, timescale="1ps")
    @fd = File.open(filename, 'w')
    @time=0
    @id_index = 0
    @changeset = Set.new()
    @timescale = timescale
    @portmap = {}
    @idmap = {}
    write_header
  end
  
  def start
    @portmap.keys.each do |portname|
      port = @portmap[portname]
      id = @idmap[portname]
      @fd.write("$var wire #{port.width} #{id} #{portname} $end\n")
    end
    @fd.write("$dumpvars\n")
    @portmap.keys.each do |portname|
      write_port_state(portname)
    end
    @fd.write("$end\n")
    @fd.write("\#0\n")
    return self
  end
  
  def finish
    @fd.close
  end
  
  def attach(port, portname=nil)
    if portname == nil
      portname = port.to_s
    end
    raise RunTimeError.new("Duplicate port name '#{portname}'") if @portmap.has_key?(portname)
    @idmap[portname] = create_vcd_id(@id_index)
    @id_index += 1
    @portmap[portname] = port
    port.add_callback do |value|
      @changeset.add(portname)
    end
    return self
  end
  
  def advance(timesteps)
    @time += timesteps
    @fd.write("\##{@time.to_s}\n")
    return self
  end
  
  def write
    #write out any changes and clear the changed set
    @changeset.each do |portname|
      write_port_state(portname)
    end
    @changeset.clear
  end
  
  def write_header
    @fd.write("$date\n#{Time.now.asctime}\n$end\n")
    @fd.write("$version\nRCircuit VCD Generator Version 0.0\n$end\n")
    @fd.write("$timescale #{@timescale} $end\n")
  end

  def write_port_state(portname)
    #writes VCD line for state of port, using id
    port = @portmap[portname]
    if port.width == 1
      state = port.val.to_s
    else
      state = "b#{port.val.to_s(2)} "  #include a space
    end
    @fd.write(state + @idmap[portname] + "\n")
  end
    
end
  

  
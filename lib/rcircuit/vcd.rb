# creates VCD file from port states

require "set"

class VCD

  def initialize(filename, timescale="1ps")
    @fd = File.open(filename, 'w')
    @time=0
    @timescale = timescale
    @portmap = {}
    @idmap = {}
    @id = "a"
    write_header
  end

  def start
    @fd.puts "$scope module TOP $end"
    @portmap.each do |portname,port|
      id = @idmap[portname]
      @fd.puts "$var wire #{port.width} #{id} #{portname} $end"
    end
    @fd.puts "$upscope $end"
    @fd.puts "$enddefinitions $end"
    @fd.puts "$dumpvars"
    @portmap.keys.each do |portname|
      write_port_state(portname)
    end
    @fd.puts "$end"
    @fd.puts "\#0"
  end

  def finish
    @fd.close
  end

  def attach(port, portname)
    raise ArgumentError.new("Duplicate port name '#{portname}'") if @portmap.has_key?(portname)
    if port.width > 1
      portname="#{portname}[0:#{port.width-1}]"
    end
    @idmap[portname] = @id
    @id=@id.next()
    @portmap[portname] = port
    port.add_callback do |value|
      write_port_state(portname)
    end
  end

  def advance(timesteps)
    @time += timesteps
    @fd.puts "\##{@time.to_s}"
  end

  private

  def write_header
    @fd.puts "$version\nRCircuit VCD Generator Version 0.0\n$end"
    @fd.puts "$date\n#{Time.now.asctime}\n$end"
    @fd.puts "$timescale #{@timescale} $end"
  end

  def write_port_state(portname)
    #writes VCD line for state of port, using id
    port = @portmap[portname]
    if port.width == 1
      state = port.val.to_s
    else
      state = "b#{port.val.to_s(2)} "#include a space
    end
    @fd.puts state+@idmap[portname]
  end

end

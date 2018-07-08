
require_relative "rcircuit_lib"


class ALU < Device
  def initialize(init_args={},width)
    #define inputs and outputs
    define_port('a', width)
    define_port('b', width)
    define_port('op', 4)
    define_port('out', width)
    #connect ports in init arguments
    init_assign(init_args)
    #create internal components
    define_device("mux", Mux.new(8, 4).sel(op)
                                      .in0(a + b)
                                      .in1(a - b)
                                      .in2(a & b)
                                      .in3(a | b)
                                      .in4(a ^ b)
                                      .in5(!a)
                                      .in6(!b)
                                      .in7(a)
                                      .in8(b)
                                      .in9(a << 1)
                                      .in10(a >> 1)
                                      .in11(a + 1)
                                      .in12(a - 1)
                                      .in13(0)
                                      .in14(0)
                                      .in15(0) )
    mux.out.connect(out)
  end	
end

def ALU.test
  puts "ALU test:"
  a=Port.new(8)
  b=Port.new(8)
  op=Port.new(4)
  alu=ALU.new({"a"=>a,"b"=>b,"op"=>op},8)
  dbg=Dbg.new({"a"=>a,"b"=>b,"op"=>op,"out"=>alu.out},true)
  a.value=3
  b.value=10
  dbg.add_trigger("op")
  for i in (0..15) do
    op.value=i
  end
end
class KT8Decoder < Device
  def initialize(init_args={})
    define_port("ins",8)
    init_assign(init_args)
    define_port("aen")
    define_port("ben")
    define_port("ren")
    define_port("wr")
    define_port("rbsel")
    define_port("den")
    @ins4to7=ins.slice(4..7)
    @ins0to3=ins.slice(0..3)
    define_device("dec", Decoder.new(4)
                                .sel(@ins4to7)
                                .en(1)
                                .o0(aen)
                                .o1(ben)
                                .o2(wr)
                                .o3(rbsel)
                                .o8(ren)
                                .o11(den) )
    define_device("dec1", Decoder.new(4).sel(@ins0to3).en(den) )
  end
  def on_change(new_val)
    puts "ins:#{ins.value},ins[5:7]:#{@ins5to7.value},ins[4:7]:#{@ins4to7.value}"
    if @ins5to7.value==0
      puts "5to7=0"
      aen.value=1
      ben.value=0    
      ren.value=0
      wr.value=0
      rbsel.value=0
    end
    if @ins5to7.value==1
      puts "5to7=1"
      aen.value=0
      ben.value=1
      ren.value=0
      wr.value=0
      rbsel.value=0
    end
    if @ins5to7.value==2
      puts "5to7=2"
      aen.value=0
      ben.value=0
      ren.value=0
      wr.value=1
      rbsel.value=0
    end
    if @ins4to7.value==6
      puts "4to7=6"
      aen.value=0
      ben.value=0
      ren.value=0
      wr.value=0
      rbsel.value=1
    end
    if @ins4to7.value==7
      puts "4to7=7"
      aen.value=0
      ben.value=0
      ren.value=0
      wr.value=0
      rbsel.value=2
    end
    if @ins4to7.value==8
      puts "4to7=8"
      aen.value=0
      ben.value=0
      ren.value=1
      wr.value=0
      rbsel.value=0
    end
  end
end
#start of KT8 parts
class KT8 < Device
 def initialize(init_args={})
  define_port("clk")
  define_port("rst")
  define_port("dout",8)
  define_port("ins",8)
  init_assign(init_args)
  define_port("wr")
  define_port("paddr",8)
  define_port("daddr",5)
  define_port("din",8)
  define_device("dec", KT8Decoder.new().ins(ins).wr(wr))
  define_device("pc", Counter.new(8).clk(clk).rst(rst).load(0).out(paddr))
  define_device("reg_a", Reg.new(8).clk(clk).rst(rst).en(dec.aen))
  define_device("reg_b",Reg.new(8).clk(clk).rst(rst).en(dec.ben))
  define_device("reg_r",Reg.new(8).clk(clk).rst(rst).en(dec.ren))
  define_device("alu",ALU.new(8).a(reg_a.out).b(reg_b.out).op(ins.slice(0..3)).out(reg_r.in))
  daddr.connect(ins.slice(0..4))
  din.connect(reg_r.out)
  #reg A input is always from data memory
  reg_a.in(dout)
  #reg B can be from memory or current value combined with immediate bits
  low_bit_combine = reg_b.out.slice(4..7).join(ins.slice(0..3))
  high_bit_combine = ins.out.slice(0..3).join(reg_b.out.slice(0..3))
  reg_b_source = Mux.new(8,1).in0(dout).in1(low_bit_combine).sel(dec.rbsel)
  reg_b.in(reg_b_source.out)
  end
end

clk=Port.new
rst=Port.new
prog_mem=Ram.new(8,8)
data_mem=Ram.new(8,5)
kt8=KT8.new("clk"=>clk,"rst"=>rst,"dout"=>data_mem.out,"ins"=>prog_mem.out)
prog_mem.addr(kt8.paddr).clk(clk).wr(0).in(0)
data_mem.addr(kt8.daddr).clk(clk).wr(kt8.wr).in(kt8.din)
dbg=Dbg.new("paddr"=>kt8.paddr,"daddr"=>kt8.daddr,"aval"=>kt8.reg_a.out,"rval"=>kt8.reg_r.out,"ins"=>kt8.ins,"aen"=>kt8.dec.aen,"ben"=>kt8.dec.ben,"ren"=>kt8.dec.ren,"wr"=>kt8.dec.wr,"rbsel"=>kt8.dec.rbsel,"aluop"=>prog_mem.out.slice(0..3))
prog_mem[0]="00000000"
prog_mem[1]="10000111"
prog_mem[2]="01000001"
data_mem[0]="1011"
rst.value=0
clk.value=0
rst.value=1
rst.value=0
dbg.out
clk.value=1
dbg.out
clk.value=0
clk.value=1
dbg.out
clk.value=0
clk.value=1
dbg.out

puts "Putting.."
puts data_mem[1].inspect

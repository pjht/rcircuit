#xor_test.rb

require_relative "lib/rcircuit/port.rb"
require_relative "lib/rcircuit/gate.rb"
require_relative "lib/rcircuit/xor.rb"
require_relative "lib/rcircuit/vcd.rb"

in_a = Port.new(1, "A")
in_b = Port.new(1, "B")
gate = XorGate.new(in_a, in_b)

vcd = VCD.new("vcd_test.vcd").attach(in_a)
                             .attach(in_b)
                             .attach(gate.out, "OUT")

in_a.setval(0)
in_b.setval(0)
vcd.start
in_a.setval(1)
vcd.advance(1000).write
in_b.setval(1)
vcd.advance(1000).write
in_a.setval(0)
vcd.advance(1000).write
vcd.advance(1000)
vcd.finish


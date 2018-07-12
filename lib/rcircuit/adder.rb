class Adder < Device
  def initialize(width, init_args)
    add_input("a", width)
    add_input("b", width)
    add_output("out", width)
    init_assign(init_args)
    @mask=(2**width)-1
  end

  def on_change(data_val)
    out.setval((a.val+b.val)&@mask)
  end
end

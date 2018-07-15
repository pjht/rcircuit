## Adder device
class Adder < Device
  # @param (see Device#initialize)
  def initialize(width, init_args)
    add_input("a", width)
    add_input("b", width)
    add_output("out", width)
    init_assign(init_args)
    @mask=(2**width)-1
  end

  private
  # Called when there is a change to inputs
  def on_change()
    out.setval((a.val+b.val)&@mask)
  end
end

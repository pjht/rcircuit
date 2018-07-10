describe Gate do
  let(:klass) do
    Class.new(Gate) do
      def inputs_changed(vals)
        tot=0
        vals.each do |val|
          tot+=val
        end
        out.setval(tot)
      end
    end
  end
  it "calls #inputs_changed when input values change or an input is added" do
    a=Port.new(8)
    b=Port.new(8)
    gate=klass.new(a,b)
    expect(gate).to receive(:inputs_changed).with([8,0])
    a.setval(8)
    expect(gate).to receive(:inputs_changed).with([8,10])
    b.setval(10)
  end

  it "can perform computations in #inputs_changed" do
    a=Port.new(8)
    b=Port.new(8)
    gate=klass.new(a,b)
    a.setval(8)
    b.setval(10)
    expect(gate.out.val).to eq(18)
  end
end

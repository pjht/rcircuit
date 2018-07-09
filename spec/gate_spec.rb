require_relative "../port.rb"
require_relative "../gate.rb"
require_relative "../not.rb"
require_relative "../and.rb"
require_relative "../or.rb"
require_relative "../xor.rb"
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

  context "NotGate" do
    it "should NOT the input" do
      table=[
        [0,1],
        [1,0]
      ]
      ok=NotGate.test_table(table)
      expect(ok).to eq true
    end
  end

  context "AndGate" do
    it "should AND together all inputs" do
      table=[
        [0,0,0],
        [0,1,0],
        [1,0,0],
        [1,1,1],
      ]
      ok=AndGate.test_table(table)
      expect(ok).to eq true
    end
  end

  context "OrGate" do
    it "should OR together all inputs" do
      table=[
        [0,0,0],
        [0,1,1],
        [1,0,1],
        [1,1,1],
      ]
      ok=OrGate.test_table(table)
      expect(ok).to eq true
    end
  end

  context "XorGate" do
    it "should XOR together all inputs" do
      table=[
        [0,0,0],
        [0,1,1],
        [1,0,1],
        [1,1,0],
      ]
      ok=XorGate.test_table(table)
      expect(ok).to eq true
    end
  end
end

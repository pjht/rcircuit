describe Splitter do
  it "should extract bits from an input port" do
    inp = Port.new(8)
    splitter = Splitter.new(inp, [1,6])
    inp.setval(0x03)
    expect(splitter.out.val).to eq 1
    inp.setval(0x18)
    expect(splitter.out.val).to eq 0
    inp.setval(0xC0)
    expect(splitter.out.val).to eq 2
    inp.setval(0xF3)
    expect(splitter.out.val).to eq 3
    #test port indexing
    expect(inp[7].val).to eq 1 
    expect(inp[4..7].val).to eq 15
    expect(inp[2,3,4].val).to eq 4
  end
end

describe VCD do
  it "Outputs VCD files" do
    a=Port.new(1)
    b=Port.new(1)
    gate=XorGate.new(a,b)
    vcd=VCD.new("vcd_test.vcd")
    obj=double()
    allow(obj).to receive(:puts)
    allow(obj).to receive(:close)
    vcd.fd=obj
    `rm vcd_test.vcd`
    vcd.attach(a,"a")
    vcd.attach(b,"b")
    vcd.attach(gate.out, "out")
    expect(obj).to receive(:puts).with("$scope module TOP $end")
    expect(obj).to receive(:puts).with("$var wire 1 a a $end")
    expect(obj).to receive(:puts).with("$var wire 1 b b $end")
    expect(obj).to receive(:puts).with("$var wire 1 c out $end")
    expect(obj).to receive(:puts).with("$upscope $end")
    expect(obj).to receive(:puts).with("$enddefinitions $end")
    expect(obj).to receive(:puts).with("$dumpvars")
    expect(obj).to receive(:puts).with("0a")
    expect(obj).to receive(:puts).with("0b")
    expect(obj).to receive(:puts).with("0c")
    expect(obj).to receive(:puts).with("$end")
    expect(obj).to receive(:puts).with("#0")
    vcd.start
    expect(obj).to receive(:puts).with("1a")
    expect(obj).to receive(:puts).with("1c")
    a.setval(1)
    expect(obj).to receive(:puts).with("#1")
    vcd.advance(1)
    expect(obj).to receive(:puts).with("1b")
    expect(obj).to receive(:puts).with("0c")
    b.setval(1)
    expect(obj).to receive(:puts).with("#2")
    vcd.advance(1)
    expect(obj).to receive(:puts).with("0a")
    expect(obj).to receive(:puts).with("1c")
    a.setval(0)
    vcd.stop
  end
end

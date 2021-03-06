describe Port do
  it "should set the port's value when we call #setval" do
    a=Port.new(4)
    a.setval(1)
    expect(a).to eq 1
  end

  it "should propagate values when we call #setval" do
    a=Port.new(4)
    b=Port.new(4)
    c=Port.new(4)
    d=Port.new(4)

    #connect A-B and C-D
    a.connect(b)
    c.connect(d)

    a.setval(1)
    c.setval(2)
    expect(a).to eq 1
    expect(b).to eq 1
    expect(c).to eq 2
    expect(d).to eq 2

    #connect them all together
    b.connect(c)
    a.setval(3)
    expect(a).to eq 3
    expect(b).to eq 3
    expect(c).to eq 3
    expect(d).to eq 3
    d.setval(4)
    expect(a).to eq 4
    expect(b).to eq 4
    expect(c).to eq 4
    expect(d).to eq 4
  end

  it "should not allow value to go over max allowed by width" do
    a=Port.new(4)
    expect {a.setval(16)}.to raise_error ArgumentError
  end

  it "should call registered callbacks" do
    a=Port.new(4)
    expect { |b|  a.add_callback(&b); a.setval(10) }.to yield_with_args(10)
    expect { |b| a.add_callback(&b); a.setval(8) }.to yield_with_args(8)
  end
end

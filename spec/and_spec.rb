describe AndGate do
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

describe NotGate do
  it "should NOT the input" do
    table=[
      [0,1],
      [1,0]
    ]
    ok=NotGate.test_table(table)
    expect(ok).to eq true
  end
end

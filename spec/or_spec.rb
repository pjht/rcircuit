require_relative "../or.rb"
describe OrGate do
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

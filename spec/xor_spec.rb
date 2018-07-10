require_relative "../xor.rb"
describe XorGate do
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

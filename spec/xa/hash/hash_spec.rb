require 'xa/hash/deep'

describe 'deep methods on Hash' do
  subject(:hash) do
    h = {
      'a' => 1,
      'b' => {
        'x' => { 'a' => 1, 'b' => 2 },
        'y' => 2,
      },
    }
  end
  
  it 'can fetch a nested value using dot-notation' do
    expect(hash.deep_fetch('a')).to eql(1)
    expect(hash.deep_fetch('b.y')).to eql(2)
    expect(hash.deep_fetch('b.x.a')).to eql(1)
    expect(hash.deep_fetch('b.x.b')).to eql(2)
  end
end

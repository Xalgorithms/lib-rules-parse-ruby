require 'xa/util/tables'

describe XA::Util::Tables do
  include XA::Util::Tables

  it 'should convert tables collection to a list of documents' do
    expectations = [
      {
        from: {
          'tbl0' => [{ 'x' => '00' }, { 'x' => '01' }],
          'tbl1' => [{ 'y' => '10' }, { 'y' => '11' }],
        },
        to: [
          { 'x' => '00', 'y' => '10' },
          { 'x' => '01', 'y' => '11' },
        ],
      },
      {
        from: {
          'tbl0' => [{ 'x' => '00' }],
          'tbl1' => [{ 'y' => '10' }, { 'y' => '11' }],
        },
        to: [
          { 'x' => '00', 'y' => '10' },
          { 'y' => '11' },
        ],
      },
      {
        from: {
          'tbl0' => [{ 'x' => '01' }],
          'tbl1' => [{ 'y' => '10' }, { 'y' => '11' }],
        },
        to: [
          { 'x' => '01', 'y' => '10' },
          { 'y' => '11' },
        ],
      },
    ]

    expectations.each do |ex|
      expect(tables_to_documents(ex[:from])).to eql(ex[:to])
    end
  end
end

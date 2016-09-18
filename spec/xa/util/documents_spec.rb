require 'xa/util/documents'

describe XA::Util::Documents do
  include XA::Util::Documents

  it 'can transform documents given a map' do
    expectations = [
      {
        # general case
        original: {
          'x' => {
            'y' => {
              'z' => 'z_val',
              'q' => 'q_val',
            },
          },
          'a' => {
            'b' => 'b_val'
          },
          'p' => 'p_val',
          'q' => {
            'r' => 'r_val',
          },
          'f' => 'f_val',
        },
        map: {
          'x.y.z' => 'zzz',
          'x.y.q' => 't.s',
          'p'     => 'pp',
          'f'     => 't.r',
        },
        result: {
          'zzz' => 'z_val',
          't' => {
            'r' => 'f_val',
            's' => 'q_val',
          },
          'pp' => 'p_val',
        },
        result_invert: {
          'x' => {
            'y' => {
              'z' => 'z_val',
              'q' => 'q_val',
            },
          },
          'p' => 'p_val',
          'f' => 'f_val',
        }
      },
      # map contains keys that are not in the original
      {
        original: {
          'x' => {
            'y' => {
              'z' => 'z_val',
              'q' => 'q_val',
            },
          },
          'a' => {
            'b' => 'b_val'
          },
          'p' => 'p_val',
          'q' => {
            'r' => 'r_val',
          },
          'f' => 'f_val',
        },
        map: {
          'x.y.p' => 'zzz',
          'p'     => 'pp',
          'g'     => 't.r',
        },
        result: {
          'pp' => 'p_val',
        },
        result_invert: {
          'p' => 'p_val',
        }
      },
    ]

    expectations.each do |ex|
      res = transform_by_map(ex[:original], ex[:map])
      expect(res).to eql(ex[:result])
      expect(transform_by_inverted_map(res, ex[:map])).to eql(ex[:result_invert])
    end
  end

  it 'can merge two documents' do
    expectations = [
      {
        a: {
          'x' => 'x_val',
          'y' => 'missing',
        },
        b: {
          'y' => 'y_val',
        },
        result: {
          'x' => 'x_val',
          'y' => 'y_val',
        }
      },
      {
        a: {
          'x' => {
            'y' => 'xy_val',
            'z' => 'missing',
          },
        },
        b: {
          'x' => {
            'q' => 'xq_val',
            'z' => {
              'p' => 'xzp_val',
              'q' => 'xzq_val',
            },
          },
        },
        result: {
          'x' => {
            'y' => 'xy_val',
            'q' => 'xq_val',
            'z' => {
              'p' => 'xzp_val',
              'q' => 'xzq_val',
            },
          },
        }
      },
      {
        a: {
          'x' => {
            'y' => {
              'z' => 'xyz_val',
            },
          },
        },
        b: {
          'x' => {
            'y' => {
              'q' => 'xyq_val',
            },
            'z' => {
              'q' => 'xzq_val',
            },
          },
        },
        result: {
          'x' => {
            'y' => {
              'z' => 'xyz_val',
              'q' => 'xyq_val',
            },
            'z' => {
              'q' => 'xzq_val',
            },
          },
        }
      },
    ]

    expectations.each do |ex|
      expect(merge_document(ex[:a], ex[:b])).to eql(ex[:result])
    end
  end
  
  it 'can combine documents' do
    docs = [
      {
        'x' => {
          'y' => {
            's' => 'xys_value',
          },
        },
        't' => {
          's' => 'ts_value',
        },
        'p' => 'p_value',
      },
      {
        'x' => {
          'y' => {
            'z' => 'xyz_value',
          },
        },
        't' => {
          'r' => 'tr_value',
        },
        'q' => 'q_value_that_dies',
      },
      {
        'q' => 'q_value',
        'z' => 'z_value',
        'b' => 'missing',
      },
      {
        'a' => [1, 2, 3],
        'b' => [4, 5, 6],
        'c' => [{ 'x' => 1, 'y' => 2}],
        'd' => [{ 'q' => 11}],
      },
      {
        'd' => 100,
        'c' => [{ 'x' => 11, 'z' => 3}],
      },
    ]

    expected = {
      'x' => {
        'y' => {
          'z' => 'xyz_value',
          's' => 'xys_value',
        },
      },
      't' => {
        's' => 'ts_value',
        'r' => 'tr_value',
      },
      'p' => 'p_value',
      'q' => 'q_value',
      'z' => 'z_value',
      'a' => [1, 2, 3],
      'b' => [4, 5, 6],
      'c' => [{ 'x' => 11, 'y' => 2, 'z' => 3 }],
      'd' => 100,
    }

    expect(combine_documents(docs)).to eql(expected)
  end

  it 'can determine if a path is present in a document' do
    expectations = [
      {
        # general case
        document: {
          'x' => {
            'y' => {
              'z' => 'z_val',
              'q' => 'q_val',
            },
          },
          'a' => {
            'b' => 'b_val'
          },
          'p' => 'p_val',
          'q' => {
            'r' => 'r_val',
          },
          'f' => 'f_val',
        },
        keys: {
          'x.y.z' => true,
          'x.y.x' => false,
          'a'     => true,
          'q.r'   => true,
          'd'     => false,
        },
      },
      {
        document: {
          'x' => {
            'y' => {
              'z' => 'z_val',
              'q' => 'q_val',
            },
          },
          'a' => {
            'b' => 'b_val'
          },
          'p' => 'p_val',
          'q' => {
            'r' => 'r_val',
          },
          'f' => 'f_val',
        },
        keys: {
          'x.y.z' => true,
          'x'     => true,
          'x.z'   => false,
          'g'     => false,
        },
      },
    ]

    expectations.each do |ex|
      ex[:keys].keys.each do |k|
        expect(document_contains_path(ex[:document], k)).to eql(ex[:keys][k])
      end
    end
  end

  it 'should extract a subset of a document based on the keys of another document' do
    expectations = [
      {
        doc: {
          'x' => {
            'y' => 1,
            'z' => 2,
          },
          'p' => 3,
          'q' => 4,
        },
        assoc: {
          'x' => {
            'z' => 'a2',
          },
          'q' => 'a4',
        },
        result: {
          'x' => {
            'z' => 2,
          },
          'q' => 4,          
        },
      },
      {
        doc: {
          'p' => 1,
          'x' => {
            'y' => {
              'xx' => 1,
              'yy' => 2,
            },
            'z' => {
              'xx' => 3,
              'yy' => 4,
            }
          },
        },
        assoc: {
          'p' => 'a1',
        },
        result: {
          'p' => 1,          
        },
      },
      {
        doc: {
          'a' => [
            { 'x' => 1 },
            { 'x' => 2 },
            { 'x' => 3 },
            { 'x' => 4 },
          ],
        },
        assoc: {
          'a' => 'a1',
        },
        result: {
          'a' => [
            { 'x' => 1 },
            { 'x' => 2 },
            { 'x' => 3 },
            { 'x' => 4 },
          ],
        },
        doc: {
          'a' => [
            {
              'x' => {
                'x' => 'xx_doc0',
                'y' => 'xy_doc0',
              },
              'z' => 'z_doc0',
            },
            {
              'x' => {
                'x' => 'xx_doc0',
                'y' => 'xy_doc1',
              },
              'z' => 'z_doc1',
            },
          ],
        },
        assoc: {
          'a' => [
            {
              'x' => {
                'y' => 'xy_assoc0',
              },
            },
            {
              'x' => {
                'y' => 'xy_assoc1',
              },
            },
          ],
        },
        result: {
          'a' => [
            {
              'x' => {
                'y' => 'xy_doc0',
              },
            },
            {
              'x' => {
                'y' => 'xy_doc1',
              },
            },
          ],
        },
      },
    ]

    expectations.each do |ex|
      expect(extract_corresponding(ex[:doc], ex[:assoc])).to eql(ex[:result])
    end
  end
end
  

module Randomness
  DEFAULT_COUNT = 10
  
  def rand_one(a)
    a[rand(a.length)]
  end
  
  def rand_times(i = DEFAULT_COUNT)
    (1 + rand(i)).times
  end
  
  def rand_partition(a, n)
    i = rand(a.length / 3) + 1
    n == 1 ? [a] : [a.take(i).map(&:dup)] + rand_partition(a.drop(i), n - 1)
  end

  def rand_array(n = DEFAULT_COUNT)
    rand_times(n).map { yield }
  end

  def rand_array_of_words(n = DEFAULT_COUNT)
    rand_array(n) { Faker::Hipster.word }
  end

  def rand_array_of_uuids(n = DEFAULT_COUNT)
    rand_array(n) { UUID.generate }
  end

  def rand_array_of_hexes(n = DEFAULT_COUNT)
    rand_array(n) { Faker::Number.hexadecimal(6) }
  end

  def rand_array_of_urls(n = DEFAULT_COUNT)
    rand_array(n) { Faker::Internet.url }
  end

  def randomly_happen
    yield if rand(2) > 0
  end

  def rand_table
    ks = rand_array_of_words
    rand_array do
      ks.inject({}) do |o, k|
        o.merge(k => Faker::Number.hexadecimal(6))
      end
    end
  end

  def rand_array_of_tables(n=DEFAULT_COUNT)
    rand_array(n) { rand_table }
  end

  def rand_hash_of_tables(n=DEFAULT_COUNT)
    rand_array_of_words.inject({}) do |o, k|
      o.merge(Faker::Lorem.word => rand_table)
    end
  end

  def rand_some(a)
    a.take(rand(a.length)).map(&:dup)
  end
end

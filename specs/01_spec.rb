describe "Array#to_hash" do
  it "converts an array to a hash" do
    [[:one, 1], [:two, 2]].to_hash.should eq(one: 1, two: 2)
  end

  it "uses the last pair when a key is present multiple times" do
    [[1, 2], [3, 4], [1, 3]].to_hash.should eq(1 => 3, 3 => 4)
  end

  it "works when the keys and values are arrays" do
    [[1, [2, 3]], [[4, 5], 6]].to_hash.should eq(1 => [2, 3], [4, 5] => 6)
  end

  it "works on empty arrays" do
    [].to_hash.should eq({})
  end

  it "works with boolean keys" do
    [
      [nil, 'nil'],
      [true, 'true'],
      [false, 'false'],
    ].to_hash.should eq({
      nil => 'nil',
      true => 'true',
      false => 'false',
    })
  end
end

describe "Array#index_by" do
  it "indexes the array elemens by a block" do
    ['John Coltrane', 'Miles Davis'].index_by { |name| name.split(' ').last }.should eq('Coltrane' => 'John Coltrane', 'Davis' => 'Miles Davis')
  end

  it "takes the last element when multiple elements evaluate to the same key" do
    [11, 21, 31, 41].index_by { |n| n % 10 }.should eq(1 => 41)
  end

  it "works on empty arrays" do
    [].index_by { |n| :something }.should eq({})
  end

  it "works with false and nil keys" do
    [nil, false].index_by { |n| n }.should eq(nil => nil, false => false)
  end
end

describe "Array#subarray_count(subarray)" do
  it "counts the number of times the argument is present as a sub-array" do
    [1, 1, 2, 1, 1, 1].subarray_count([1, 1]).should eq 3
  end

  it "works with arrays with non-numeric keys" do
    %w[a b c b c].subarray_count(%w[b c]).should eq 2
  end

  it "work with empty arrays" do
    [].subarray_count([1]).should be_zero
  end

  it "work when the argument is larger than the array" do
    [1].subarray_count([1, 2]).should eq 0
  end
end

describe "Array#occurences_count" do
  it "counts how many times an element is present in an array" do
    [:foo, :bar, :foo].occurences_count.should eq(foo: 2, bar: 1)
    %w[a b a b c].occurences_count.should eq('a' => 2, 'b' => 2, 'c' => 1)
  end

  it "returns a hash that defaults to 0 when the key is not present" do
    [].occurences_count[:something].should eq 0
  end

  it "works with arrays containing nil and false" do
    [nil, false, nil, false, true].occurences_count.should eq(nil => 2, false => 2, true => 1)
  end

  it "returns a hash, that does not change when indexed with a non-occuring element" do
    hash = %w[a a].occurences_count

    hash['b'].should eq 0
    hash.should eq('a' => 2)
  end
end

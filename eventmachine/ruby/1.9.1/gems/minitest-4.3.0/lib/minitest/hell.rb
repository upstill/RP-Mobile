class Minitest::Unit::TestCase
  class << self
    alias :old_test_order :test_order

    def test_order # :nodoc:
      :parallel
    end
  end
end

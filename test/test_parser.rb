require_relative "helper"

class TestParser < Minitest::Test
  def test_good_parsing
    test_file = File.join(File.dirname(__FILE__), 'data', 'test_statement.pdf')
    json_file = File.join(File.dirname(__FILE__), 'data', 'test_statement.json')

    statement = CapitalOneStatement.new test_file
    actual    = JSON.parse(statement.to_json)
    expected  = JSON.parse(IO.read(json_file))

    assert_equal expected, actual
  end

  def test_bad_parsing
    Dir[File.join(File.dirname(__FILE__), 'data', 'bad_statement*.pdf')].each do |path|
      assert_raises(RuntimeError) do
        CapitalOneStatement.new(path)
      end
    end
  end
end

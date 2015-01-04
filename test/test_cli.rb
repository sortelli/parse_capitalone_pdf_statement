require_relative "helper"

class TestCli < Minitest::Test
  def test_cli
    dir       = File.dirname __FILE__
    bin_file  = File.join(dir, '..', 'bin', 'capitalone_pdf_to_json.rb')
    test_file = File.join(dir, 'data', 'test_statement.pdf')
    json_file = File.join(dir, 'data', 'test_statement.json')

    json      = %x{"#{bin_file}" "#{test_file}"}
    actual    = JSON.parse(json)
    expected  = JSON.parse(IO.read(json_file))

    assert_equal expected, actual
  end
end

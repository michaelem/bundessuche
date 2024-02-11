require "test_helper"

class UnitDateTest < ActiveSupport::TestCase
  test "Parses a date range correctly" do
    xml_string = <<~HEREDOC
      <?xml version="1.0" encoding="UTF-8"?>
        <unitdate encodinganalog="3.1.3" era="ce" calendar="gregorian" normal="1959-01-01/1959-12-31">1959</unitdate>
      </xml>
    HEREDOC

    node = Nokogiri.XML(xml_string).xpath("unitdate").first

    date_parser = UnitDate.new(node)

    assert date_parser.range?
    assert_equal Date.new(1959, 1, 1), date_parser.start_date
    assert_equal Date.new(1959, 12, 31), date_parser.end_date
  end

  test "Parses a single date correctly" do
    xml_string = <<~HEREDOC
      <?xml version="1.0" encoding="UTF-8"?>
        <unitdate encodinganalog="3.1.3" era="ce" calendar="gregorian" normal="1920-01-01">1. 1. 1920</unitdate>
      </xml>
    HEREDOC

    node = Nokogiri.XML(xml_string).xpath("unitdate").first

    date_parser = UnitDate.new(node)

    refute date_parser.range?
    assert_equal Date.new(1920, 1, 1), date_parser.start_date
    assert_equal Date.new(1920, 1, 1), date_parser.end_date
  end

  test "Fails gracefully when the date is not parseable" do
    xml_string = <<~HEREDOC
      <?xml version="1.0" encoding="UTF-8"?>
        <unitdate encodinganalog="3.1.3" era="ce" calendar="gregorian" normal="">Kein Datum</unitdate>
      </xml>
    HEREDOC

    node = Nokogiri.XML(xml_string).xpath("unitdate").first

    date_parser = UnitDate.new(node)

    refute date_parser.range?
    assert_nil date_parser.start_date
    assert_nil date_parser.end_date
  end

  test "Fails gracefully when normalised date is not prsent" do
    xml_string = <<~HEREDOC
      <?xml version="1.0" encoding="UTF-8"?>
        <unitdate encodinganalog="3.1.3">Kein Datum</unitdate>
      </xml>
    HEREDOC

    node = Nokogiri.XML(xml_string).xpath("unitdate").first

    date_parser = UnitDate.new(node)

    refute date_parser.range?
    assert_nil date_parser.start_date
    assert_nil date_parser.end_date
  end
end

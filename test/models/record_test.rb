require "test_helper"

class RecordTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "source_date_years" do
    record = Record.new(source_date_start: Date.new(2020, 1, 1))
    assert_equal "2020", record.source_date_years

    record.source_date_end = Date.new(2020, 12, 31)
    assert_equal "2020", record.source_date_years

    record.source_date_end = Date.new(2021, 12, 31)
    assert_equal "2020 - 2021", record.source_date_years
  end
end

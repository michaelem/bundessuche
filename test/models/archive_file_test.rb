require "test_helper"

class ArchiveFileTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "source_date_years" do
    archive_file = ArchiveFile.new(source_date_start: Date.new(2020, 1, 1))
    assert_equal "2020", archive_file.source_date_years

    archive_file.source_date_end = Date.new(2020, 12, 31)
    assert_equal "2020", archive_file.source_date_years

    archive_file.source_date_end = Date.new(2021, 12, 31)
    assert_equal "2020 - 2021", archive_file.source_date_years
  end
end

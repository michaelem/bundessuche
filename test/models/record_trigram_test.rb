require "test_helper"

class RecordTrigramTest < ActiveSupport::TestCase
  def setup
    BundesarchivImporter.new("test/fixtures/files/dataset-tiny").run
    Record.reindex

    @example_record = Record.last
  end

  test "search finds records by title" do
    assert_equal 1, RecordTrigram.search(@example_record.title).count
  end

  test "search finds records by call number" do
    assert_equal 1, RecordTrigram.search(@example_record.call_number).count
  end
end

require "test_helper"

class BundesarchivImporterTest < ActiveSupport::TestCase
  test "importer creates right amount of Records from test files" do
    assert_equal 0, Record.count
    BundesarchivImporter.new("test/fixtures/files").run
    assert_equal 794, Record.count
  end
end

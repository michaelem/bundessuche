require "test_helper"

class ArchiveFileTrigramTest < ActiveSupport::TestCase
  def setup
    BundesarchivImporter.new("test/fixtures/files/dataset-tiny").run
    ArchiveFile.reindex

    @example_archive_file = ArchiveFile.last
  end

  test "search finds archive files by title" do
    assert_equal 1, ArchiveFileTrigram.search(@example_archive_file.title).count
  end

  test "search finds archive files by call number" do
    assert_equal 1, ArchiveFileTrigram.search(@example_archive_file.call_number).count
  end
end

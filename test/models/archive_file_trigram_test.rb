require "test_helper"

class ArchiveFileTrigramTest < ActiveSupport::TestCase
  def setup
    BundesarchivImporter.new("test/fixtures/files/dataset-tiny").run
    ArchiveFile.reindex

    @example_archive_file = ArchiveFile.find_by(source_id: "DE-1958_8a0ff3f6-46b3-443a-9e48-946e790301e0")
  end

  test "search finds archive files by title" do
    assert_equal 1, ArchiveFileTrigram.search(@example_archive_file.title).count
  end

  test "search finds archive files by call number" do
    assert_equal 1, ArchiveFileTrigram.search(@example_archive_file.call_number).count
  end
end

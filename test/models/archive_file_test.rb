require "test_helper"

class ArchiveFileTest < ActiveSupport::TestCase
  test "source_dates" do
    archive_file = ArchiveFile.new(source_date_start: Date.new(1984, 1, 24))
    assert_equal ["1984-01-24"], archive_file.source_dates

    archive_file.source_date_end = Date.new(1985, 10, 1)
    assert_equal ["1984-01-24", "1985-10-01"], archive_file.source_dates
  end

  test "parents walks the node tree root first, ending at the file's own node" do
    BundesarchivImporter.new("test/fixtures/files/dataset-tiny").run
    archive_file = ArchiveFile.find_by(source_id: "DE-1958_8a0ff3f6-46b3-443a-9e48-946e790301e0")

    chain = archive_file.parents

    assert_operator chain.size, :>, 1, "the fixture file is expected to sit below the root"
    assert_equal archive_file.archive_node, chain.last
    assert_nil chain.first.parent_node_id
    # Every step is the parent of the one after it.
    chain.each_cons(2) { |parent, child| assert_equal parent.id, child.parent_node_id }
  end

  test "parents is empty without a node" do
    assert_equal [], ArchiveFile.new.parents
  end

  test "preload_parents fills the same chains in one go" do
    BundesarchivImporter.new("test/fixtures/files/dataset-tiny").run
    expected = ArchiveFile.all.to_h { |file| [file.id, file.parents.map(&:id)] }

    files = ArchiveFile.preload_parents(ArchiveFile.all)

    assert_equal expected.size, files.size
    # No further queries: the chains are already in memory.
    assert_no_queries do
      files.each { |file| assert_equal expected[file.id], file.parents.map(&:id) }
    end
  end

  test "source_date_years" do
    archive_file = ArchiveFile.new(source_date_start: Date.new(2020, 1, 1))
    assert_equal ["2020"], archive_file.source_date_years

    archive_file.source_date_end = Date.new(2020, 12, 31)
    assert_equal ["2020"], archive_file.source_date_years

    archive_file.source_date_end = Date.new(2021, 12, 31)
    assert_equal ["2020", "2021"], archive_file.source_date_years
  end
end

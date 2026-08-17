require "test_helper"

class ArchiveFileSearchTest < ActiveSupport::TestCase
  def setup
    BundesarchivImporter.new("test/fixtures/files/dataset-tiny").run
    ArchiveFile.reindex

    @example_archive_file = ArchiveFile.find_by(source_id: "DE-1958_8a0ff3f6-46b3-443a-9e48-946e790301e0")
    @dated_archive_file = ArchiveFile.find_by(source_id: "DE-1958_a3f843cb-07dd-4d39-a8a3-fa5ede2f69ab")
  end

  test "reindex with show_progress does not raise" do
    capture_io { ArchiveFile.reindex(true) }
    assert ArchiveFile.search(@example_archive_file.title).count > 0
  end

  test "search finds archive files by title" do
    assert_equal 1, ArchiveFile.search(@example_archive_file.title).count
  end

  test "search finds archive files by call number" do
    assert_equal 1, ArchiveFile.search(@example_archive_file.call_number).count
  end

  test "search finds archive files by the name of the node holding them" do
    node = @example_archive_file.archive_node

    assert_includes ArchiveFile.search(node.name).ids, @example_archive_file.id
  end

  test "search finds archive files by the name of a node further up the tree" do
    root = @example_archive_file.archive_node.parents.first
    assert_not_equal root, @example_archive_file.archive_node

    assert_includes ArchiveFile.search(root.name).ids, @example_archive_file.id
  end

  test "search finds archive files by the name of one of their origins" do
    origin = @example_archive_file.origins.first
    assert_not_nil origin, "the fixture file is expected to have an origin"

    assert_includes ArchiveFile.search(origin.name).ids, @example_archive_file.id
  end

  test "search treats a quote in the query as text rather than as FTS syntax" do
    assert_nothing_raised do
      ArchiveFile.search(%(Akte "mit" Anfuehrungszeichen)).count
      ArchiveFile.search(%(unbalanced " quote)).count
    end
  end

  test "source_dated_between prefers the parsed date over the imported columns" do
    # The imported columns say 1958, the parsed date says 1966.
    ParsedSourceDate.create!(
      source_text: @dated_archive_file.source_date_text,
      start_date: Date.new(1966, 1, 1),
      end_date: Date.new(1966, 12, 31)
    )
    search = ArchiveFile.search(@dated_archive_file.title)
    assert_equal 1, search.count

    assert_equal 1, search.source_dated_between(Date.new(1966, 6, 1), Date.new(1970, 1, 1)).count
    assert_equal 1, search.source_dated_between(nil, Date.new(1966, 1, 1)).count
    assert_equal 0, search.source_dated_between(Date.new(1958, 1, 1), Date.new(1958, 12, 31)).count
  end

  test "source_dated_between falls back to the imported columns without a parsed date" do
    # Imported as 1954 to 1967, its source date text is blank.
    search = ArchiveFile.search(@example_archive_file.title)

    assert_equal 1, search.source_dated_between(Date.new(1960, 1, 1), Date.new(1961, 1, 1)).count
    assert_equal 1, search.source_dated_between(Date.new(1967, 12, 31), nil).count
    assert_equal 0, search.source_dated_between(Date.new(1968, 1, 1), nil).count
    assert_equal 0, search.source_dated_between(nil, Date.new(1953, 12, 31)).count
  end

  test "source_dated_between falls back to a start date without an end date" do
    @example_archive_file.update!(source_date_end: nil)
    search = ArchiveFile.search(@example_archive_file.title)

    assert_equal 1, search.source_dated_between(Date.new(1954, 1, 1), Date.new(1954, 1, 1)).count
    assert_equal 0, search.source_dated_between(Date.new(1955, 1, 1), nil).count
  end

  test "source_dated_between without boundaries filters nothing" do
    search = ArchiveFile.search(@dated_archive_file.title)

    assert_equal 1, search.source_dated_between(nil, nil).count
  end

  test "source_dated_between drops files without any date" do
    undated = ArchiveFile.create!(
      archive_node: @example_archive_file.archive_node,
      source_id: "file-without-dates",
      title: "Akte ohne jede Datierung",
      parents: []
    )
    search = ArchiveFile.search(undated.title)
    assert_equal 1, search.count

    assert_equal 0, search.source_dated_between(Date.new(1900, 1, 1), Date.new(2000, 1, 1)).count
    assert_equal 0, search.source_dated_between(Date.new(1900, 1, 1), nil).count
    assert_equal 0, search.source_dated_between(nil, Date.new(2000, 1, 1)).count
  end
end

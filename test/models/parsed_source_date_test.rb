require "test_helper"

class ParsedSourceDateTest < ActiveSupport::TestCase
  test "parsed?" do
    refute ParsedSourceDate.new(source_text: "o. Dat.").parsed?
    assert ParsedSourceDate.new(source_text: "1948", start_date: Date.new(1948, 1, 1)).parsed?
  end

  test "range?" do
    single_day = ParsedSourceDate.new(
      source_text: "28. Mai 1948",
      start_date: Date.new(1948, 5, 28),
      end_date: Date.new(1948, 5, 28)
    )
    refute single_day.range?

    span = ParsedSourceDate.new(
      source_text: "1948",
      start_date: Date.new(1948, 1, 1),
      end_date: Date.new(1948, 12, 31)
    )
    assert span.range?
  end

  test "confident" do
    ParsedSourceDate.create!(source_text: "1948", confidence: 0.9)
    ParsedSourceDate.create!(source_text: "nach Mai 1953", confidence: 0.3)

    assert_equal ["1948"], ParsedSourceDate.confident.pluck(:source_text)
    assert_equal 2, ParsedSourceDate.confident(0.1).count
  end

  test "is associated with archive files through the source date text" do
    archive_node = ArchiveNode.create!(name: "Bestand", source_id: "node-1")
    archive_file = ArchiveFile.create!(
      archive_node: archive_node,
      source_id: "file-1",
      source_date_text: "28. Mai 1948"
    )
    parsed = ParsedSourceDate.create!(
      source_text: "28. Mai 1948",
      start_date: Date.new(1948, 5, 28),
      end_date: Date.new(1948, 5, 28),
      confidence: 1.0
    )

    assert_equal parsed, archive_file.reload.parsed_source_date
    assert_equal [archive_file], parsed.archive_files
  end

  test "archive files without a source date text stay valid" do
    archive_node = ArchiveNode.create!(name: "Bestand", source_id: "node-1")

    assert ArchiveFile.new(archive_node: archive_node, source_id: "file-1", source_date_text: "").valid?
  end
end

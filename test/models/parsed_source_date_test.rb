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

  test "boundaries expand years and pass dates through" do
    assert_equal Date.new(1948, 1, 1), ParsedSourceDate.start_boundary("1948")
    assert_equal Date.new(1948, 12, 31), ParsedSourceDate.end_boundary("1948")
    assert_equal Date.new(1948, 5, 28), ParsedSourceDate.start_boundary(" 1948-05-28 ")
    assert_equal Date.new(1948, 5, 28), ParsedSourceDate.end_boundary("1948-05-28")
  end

  test "boundaries expand months to their first and last day" do
    assert_equal Date.new(1948, 5, 1), ParsedSourceDate.start_boundary("1948-05")
    assert_equal Date.new(1948, 5, 31), ParsedSourceDate.end_boundary("1948-05")
    assert_equal Date.new(1948, 2, 29), ParsedSourceDate.end_boundary("1948-02")
    assert_equal Date.new(1949, 2, 28), ParsedSourceDate.end_boundary("1949-2")
  end

  test "boundaries ignore blank and unparsable input" do
    assert_nil ParsedSourceDate.start_boundary(nil)
    assert_nil ParsedSourceDate.start_boundary("")
    assert_nil ParsedSourceDate.end_boundary("irgendwann")
    assert_nil ParsedSourceDate.end_boundary("1948-13-45")
    assert_nil ParsedSourceDate.end_boundary("1948-13")
  end

  test "boundaries reject years before the common era" do
    assert_nil ParsedSourceDate.start_boundary("-1948")
    assert_nil ParsedSourceDate.start_boundary("-01-01")
  end

  test "compose joins the separate date fields" do
    assert_equal "1948", ParsedSourceDate.compose(year: "1948")
    assert_equal "1948-05", ParsedSourceDate.compose(year: "1948", month: "5")
    assert_equal "1948-05-28", ParsedSourceDate.compose(year: " 1948 ", month: "05", day: "28")
  end

  test "compose stops at the first blank field" do
    assert_equal "", ParsedSourceDate.compose(month: "5", day: "28")
    assert_equal "", ParsedSourceDate.compose(year: nil)
    assert_equal "1948", ParsedSourceDate.compose(year: "1948", month: "", day: "28")
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

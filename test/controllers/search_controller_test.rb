require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  def setup
    BundesarchivImporter.new("test/fixtures/files/dataset-tiny").run
    ArchiveFile.reindex

    @archive_file = ArchiveFile.find_by(source_id: "DE-1958_a3f843cb-07dd-4d39-a8a3-fa5ede2f69ab")
    ParsedSourceDate.create!(
      source_text: @archive_file.source_date_text,
      start_date: Date.new(1958, 1, 1),
      end_date: Date.new(1958, 12, 31)
    )

    # No source date text, so this one is only covered by the imported columns,
    # which say 1954 to 1967.
    @unparsed_archive_file = ArchiveFile.find_by(source_id: "DE-1958_8a0ff3f6-46b3-443a-9e48-946e790301e0")
  end

  test "searching without a date filter finds the file" do
    get root_path, params: { q: @archive_file.title }

    assert_response :success
    assert_includes response.body, @archive_file.call_number
  end

  test "a date range covering the file keeps it" do
    get root_path, params: { q: @archive_file.title, from_year: "1950", to_year: "1958" }

    assert_response :success
    assert_includes response.body, @archive_file.call_number
  end

  test "a date range outside the file filters it out" do
    get root_path, params: { q: @archive_file.title, from_year: "1959", to_year: "1960" }

    assert_response :success
    assert_includes response.body, "Keine Akten gefunden."
  end

  test "a month or a day narrows the range further" do
    get root_path,
        params: { q: @archive_file.title, from_year: "1958", from_month: "6", to_year: "1958", to_month: "7" }

    assert_response :success
    assert_includes response.body, @archive_file.call_number

    get root_path,
        params: {
          q: @archive_file.title, from_year: "1959", from_month: "1", from_day: "1",
          to_year: "1959", to_month: "1", to_day: "31"
        }

    assert_response :success
    assert_includes response.body, "Keine Akten gefunden."
  end

  test "a day or month without a year does not filter" do
    get root_path, params: { q: @archive_file.title, from_month: "6", from_day: "1", to_day: "2" }

    assert_response :success
    assert_includes response.body, @archive_file.call_number
  end

  test "the date fields keep their submitted values" do
    get root_path, params: { q: @archive_file.title, from_day: "28", from_month: "5", from_year: "1948" }

    assert_response :success
    assert_select "input[name=from_day][value=28]"
    assert_select "input[name=from_month][value=5]"
    assert_select "input[name=from_year][value=1948]"
  end

  test "a file without a parsed date is filtered by its imported dates" do
    get root_path, params: { q: @unparsed_archive_file.title, from_year: "1960", to_year: "1961" }

    assert_response :success
    assert_includes response.body, @unparsed_archive_file.call_number

    get root_path, params: { q: @unparsed_archive_file.title, from_year: "1968" }

    assert_response :success
    assert_includes response.body, "Keine Akten gefunden."
  end
end

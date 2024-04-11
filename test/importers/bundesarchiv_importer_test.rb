require "test_helper"

class BundesarchivImporterTest < ActiveSupport::TestCase
  test "importer creates right amount of Records from test files" do
    assert_equal 0, Record.count
    BundesarchivImporter.new("test/fixtures/files/dataset-tiny").run
    assert_equal 794, Record.count
  end

  # DE-1958_ed3ff8a0-c65e-4efd-b5d3-96950687d291 is part of DE-1958_B_153.xml in the fixture files
  test "importer extracts the correct date for DE-1958_ed3ff8a0-c65e-4efd-b5d3-96950687d291" do
    BundesarchivImporter.new("test/fixtures/files/dataset-tiny").run

    record =
      Record.find_by(source_id: "DE-1958_ed3ff8a0-c65e-4efd-b5d3-96950687d291")
    assert_equal Date.iso8601("1961-01-01"), record.source_date_start
    assert_equal Date.iso8601("1963-12-31"), record.source_date_end
    assert_equal "", record.source_date_text
    assert_equal 2, record.origins.count

    first_origin = record.origins[0]
    assert_equal "Bundesministerium für Familie und Jugend (BMFa)",
                 first_origin.name
    assert_equal "final", first_origin.label

    second_origin = record.origins[1]
    assert_equal "J 4 (1961)", second_origin.name
    assert_equal "organisational unit", second_origin.label
  end
end

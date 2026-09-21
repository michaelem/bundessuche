# frozen_string_literal: true

require 'test_helper'

class BibTexExporterTest < ActiveSupport::TestCase
  test 'it renders the correct bibtex' do
    bibtex = BibTexExporter.new(archive_file).export

    assert_equal <<~BIB, bibtex
      @unpublished{BArch_DC_20_797,
        title = {Test Title},
        abstract = {Test Summary},
        language = {ger},
        year = {1961},
        note = {issued:1961/1963},
        month = jan,
      }
    BIB
  end

  test 'the institution holding the file is braced against name reordering' do
    file = archive_file
    file.preloaded_parents = [ArchiveNode.new(name: 'Müller & Co.')]

    assert_includes BibTexExporter.new(file).export, 'author = {{Müller & Co.}},'
  end

  test 'braces and backslashes out of the archive text are dropped' do
    file = archive_file(title: 'A {braced} title\\dangerous')

    assert_includes BibTexExporter.new(file).export, 'title = {A braced titledangerous},'
  end

  test 'a summary carrying line breaks is indented under its field' do
    file = archive_file(summary: "Enthält v.a.:Stenobl\u00f6cke\nEnthält:Passierscheine")

    assert_includes BibTexExporter.new(file).export,
                    "  abstract = {Enthält v.a.:Stenoblöcke\n    Enthält:Passierscheine},\n"
  end

  test 'fields the archive knows nothing about are left out' do
    bibtex = BibTexExporter.new(ArchiveFile.new(call_number: 'DC 20/797')).export

    assert_equal "@unpublished{BArch_DC_20_797,\n\n}\n", bibtex
  end

  test 'a file without a call number falls back to its source id' do
    file = archive_file(call_number: nil)

    assert_includes BibTexExporter.new(file).export,
                    '@unpublished{BArch_DE-1958-ed3ff8a0-c65e-4efd-b5d3-96950687d291,'
  end

  private

  def archive_file(**overrides)
    ArchiveFile.new({
      source_id: 'DE-1958_ed3ff8a0-c65e-4efd-b5d3-96950687d291',
      call_number: 'DC 20/797',
      title: 'Test Title',
      summary: 'Test Summary',
      language_code: 'ger',
      source_date_start: Date.iso8601('1961-01-01'),
      source_date_end: Date.iso8601('1963-12-31'),
      source_date_text: '1961 - 1963'
    }.merge(overrides))
  end
end

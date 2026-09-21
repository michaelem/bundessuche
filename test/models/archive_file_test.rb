# frozen_string_literal: true

require 'test_helper'

class ArchiveFileTest < ActiveSupport::TestCase
  test 'source_dates' do
    archive_file = ArchiveFile.new(source_date_start: Date.new(1984, 1, 24))
    assert_equal ['1984-01-24'], archive_file.source_dates

    archive_file.source_date_end = Date.new(1985, 10, 1)
    assert_equal %w[1984-01-24 1985-10-01], archive_file.source_dates
  end

  test 'source_id round trips through the stored uuid bytes' do
    source_id = 'DE-1958_2a467dae-3487-4666-b4ab-9c0b4a6ac790'
    archive_file = ArchiveFile.new(source_id: source_id)

    assert_equal 16, archive_file.source_uuid.bytesize
    assert_equal source_id, archive_file.source_id
  end

  test 'link is rebuilt from the template and the uuid' do
    archive_file = ArchiveFile.new(source_id: 'DE-1958_2a467dae-3487-4666-b4ab-9c0b4a6ac790')

    archive_file.link = 'https://invenio.bundesarchiv.de/invenio/direktlink/2a467dae-3487-4666-b4ab-9c0b4a6ac790/'
    assert_equal 0, archive_file.link_variant
    assert_equal 'https://invenio.bundesarchiv.de/invenio/direktlink/2a467dae-3487-4666-b4ab-9c0b4a6ac790/',
                 archive_file.link

    archive_file.link = 'https://invenio.bundesarchiv.de/basys2-invenio/direktlink/2a467dae-3487-4666-b4ab-9c0b4a6ac790/'
    assert_equal 1, archive_file.link_variant
    assert_equal 'https://invenio.bundesarchiv.de/basys2-invenio/direktlink/2a467dae-3487-4666-b4ab-9c0b4a6ac790/',
                 archive_file.link
  end

  test 'a file without a link has none' do
    archive_file = ArchiveFile.new(source_id: 'DE-1958_2a467dae-3487-4666-b4ab-9c0b4a6ac790')
    archive_file.link = nil

    assert_nil archive_file.link_variant
    assert_nil archive_file.link
  end

  test 'SQLite rebuilds source_id and link for saved rows' do
    BundesarchivImporter.new('test/fixtures/files/dataset-tiny').run
    source_id = 'DE-1958_8a0ff3f6-46b3-443a-9e48-946e790301e0'

    # Read straight back out of the database rather than from memory.
    archive_file = ArchiveFile.find_by(source_id: source_id)

    assert_not_nil archive_file
    assert_equal source_id, archive_file.reload[:source_id]
    assert_match %r{\Ahttps://invenio\.bundesarchiv\.de/\S+/direktlink/\S+/\z}, archive_file[:link]
  end

  test 'an unexpected id or link stops the import instead of being stored' do
    assert_raises(ArchiveFile::UnexpectedSourceFormat) do
      ArchiveFile.pack_source_id('something-else-entirely')
    end
    assert_raises(ArchiveFile::UnexpectedSourceFormat) do
      ArchiveFile.link_variant_for('https://example.com/some/other/place/')
    end
  end

  test "parents walks the node tree root first, ending at the file's own node" do
    BundesarchivImporter.new('test/fixtures/files/dataset-tiny').run
    archive_file = ArchiveFile.find_by(source_id: 'DE-1958_8a0ff3f6-46b3-443a-9e48-946e790301e0')

    chain = archive_file.parents

    assert_operator chain.size, :>, 1, 'the fixture file is expected to sit below the root'
    assert_equal archive_file.archive_node, chain.last
    assert_nil chain.first.parent_node_id
    # Every step is the parent of the one after it.
    chain.each_cons(2) { |parent, child| assert_equal parent.id, child.parent_node_id }
  end

  test 'parents is empty without a node' do
    assert_equal [], ArchiveFile.new.parents
  end

  test 'preload_parents fills the same chains in one go' do
    BundesarchivImporter.new('test/fixtures/files/dataset-tiny').run
    expected = ArchiveFile.all.to_h { |file| [file.id, file.parents.map(&:id)] }

    files = ArchiveFile.preload_parents(ArchiveFile.all)

    assert_equal expected.size, files.size
    # No further queries: the chains are already in memory.
    assert_no_queries do
      files.each { |file| assert_equal expected[file.id], file.parents.map(&:id) }
    end
  end

  test 'effective_source_dates prefers the parsed date over the imported one' do
    archive_file =
      ArchiveFile.new(
        source_date_start: Date.new(2020, 1, 1),
        source_date_end: Date.new(2021, 12, 31),
        source_date_text: '1943'
      )
    assert_equal [Date.new(2020, 1, 1), Date.new(2021, 12, 31)],
                 archive_file.effective_source_dates

    archive_file.parsed_source_date =
      ParsedSourceDate.new(source_text: '1943', start_date: Date.new(1943, 1, 1))
    assert_equal [Date.new(1943, 1, 1), Date.new(1943, 1, 1)],
                 archive_file.effective_source_dates

    archive_file.parsed_source_date.end_date = Date.new(1943, 12, 31)
    assert_equal [Date.new(1943, 1, 1), Date.new(1943, 12, 31)],
                 archive_file.effective_source_dates
  end

  test 'effective_source_dates is empty without any date' do
    assert_empty ArchiveFile.new.effective_source_dates
  end

  test 'folded_call_number keeps only letters, digits and underscores' do
    assert_equal 'DC_20_797', ArchiveFile.new(call_number: 'DC 20/797').folded_call_number
    assert_equal 'B_106_1234', ArchiveFile.new(call_number: ' B 106/1234 ').folded_call_number
    assert_equal '', ArchiveFile.new.folded_call_number
  end

  test 'source_date_years' do
    archive_file = ArchiveFile.new(source_date_start: Date.new(2020, 1, 1))
    assert_equal ['2020'], archive_file.source_date_years

    archive_file.source_date_end = Date.new(2020, 12, 31)
    assert_equal ['2020'], archive_file.source_date_years

    archive_file.source_date_end = Date.new(2021, 12, 31)
    assert_equal %w[2020 2021], archive_file.source_date_years
  end
end

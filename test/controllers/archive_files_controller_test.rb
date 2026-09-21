require 'test_helper'

class ArchiveFilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @archive_node = ArchiveNode.create!(name: 'Bundesrechnungshof')
    @archive_file = ArchiveFile.create!(
      archive_node: @archive_node,
      call_number: 'B 112/386',
      title: 'Haushaltsrechnung des Bundes',
      summary: 'Prüfung der Haushaltsrechnung',
      language_code: 'ger',
      source_date_start: Date.new(1958, 1, 1),
      source_date_end: Date.new(1958, 12, 31),
      source_id: 'DE-1958_33333333-3333-4333-8333-333333333333',
      link: 'https://invenio.bundesarchiv.de/invenio/direktlink/33333333-3333-4333-8333-333333333333/'
    )
  end

  test 'an archive file is offered as a RIS citation' do
    get archive_file_path(@archive_file, format: :ris)

    assert_response :success
    assert_includes response.body, 'TY  - MANSCPT'
    assert_includes response.body, "AN  - #{@archive_file.call_number}"
    assert_includes response.body, "TI  - #{@archive_file.title}"
    assert_includes response.body, "AU  - #{@archive_node.name}"
    assert_includes response.body, "UR  - #{@archive_file.link}"
  end

  test 'an archive file is offered as a BibTeX citation' do
    get archive_file_path(@archive_file, format: :bib)

    assert_response :success
    assert_includes response.body, '@unpublished'
    assert_includes response.body, @archive_file.title
    assert_includes response.body, @archive_node.name
    assert_includes response.body, 'issued:1958'
  end
end

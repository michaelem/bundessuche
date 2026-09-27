# frozen_string_literal: true

require 'application_system_test_case'

class SearchTest < ApplicationSystemTestCase
  def setup
    BundesarchivImporter.new('test/fixtures/files/dataset-tiny').run
    ArchiveFile.reindex

    @archive_file = ArchiveFile.find_by(source_id: 'DE-1958_a3f843cb-07dd-4d39-a8a3-fa5ede2f69ab')
    ParsedSourceDate.create!(
      source_text: @archive_file.source_date_text,
      start_date: Date.new(1958, 1, 1),
      end_date: Date.new(1958, 12, 31)
    )
  end

  test 'searching for a title lists the matching file' do
    visit root_path

    fill_in 'q', with: @archive_file.title
    click_on 'Suchen'

    assert_selector '.result__title', text: @archive_file.call_number
    assert_text(/\d+ Objekte? gefunden\./)
  end

  test 'a date range from the folded filters narrows the results' do
    visit root_path

    fill_in 'q', with: @archive_file.title
    click_on 'Laufzeit einschränken'
    fill_in 'from_year', with: '1959'
    fill_in 'to_year', with: '1960'
    click_on 'Suchen'

    assert_text 'Keine Akten gefunden.'
    assert_no_selector '.result'

    fill_in 'from_year', with: '1950'
    fill_in 'to_year', with: '1958'
    click_on 'Suchen'

    assert_selector '.result__title', text: @archive_file.call_number
  end
end

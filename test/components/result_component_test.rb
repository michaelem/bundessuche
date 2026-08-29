require "test_helper"

class ResultComponentTest < ViewComponent::TestCase
  setup do
    @archive_file = Minitest::Mock.new
  end

  def test_title_highlight
    @archive_file.expect(:title, "Rechenzentrum Duisburg")

    component =
      ResultComponent.new(
        query: "rechenzentrum",
        archive_file: @archive_file
      )

    assert_equal %(<span class="result__highlight">Rechenzentrum</span> Duisburg),
                 component.title
    @archive_file.verify
  end

  def test_date
    @archive_file.expect(:source_date_text, "1989")
    @archive_file.expect(:source_date_text, "1989")

    component =
      ResultComponent.new(
        query: "rechenzentrum",
        archive_file: @archive_file
      )

    assert_equal "1989", component.date
    @archive_file.verify
  end

  def test_parsed_date_range
    @archive_file.expect(:effective_source_dates,
                         [Date.new(1943, 5, 1), Date.new(1943, 12, 31)])

    component = ResultComponent.new(query: "", archive_file: @archive_file)

    assert_equal "01.05.1943\u2009\u2013\u200931.12.1943", component.parsed_date
    @archive_file.verify
  end

  def test_parsed_date_single_day
    @archive_file.expect(:effective_source_dates,
                         [Date.new(1943, 5, 1), Date.new(1943, 5, 1)])

    component = ResultComponent.new(query: "", archive_file: @archive_file)

    assert_equal "01.05.1943", component.parsed_date
    @archive_file.verify
  end

  def test_parsed_date_without_dates
    @archive_file.expect(:effective_source_dates, [])

    component = ResultComponent.new(query: "", archive_file: @archive_file)

    assert_nil component.parsed_date
    @archive_file.verify
  end

  def test_summary_highlight
    @archive_file.expect(:summary, "Das Rechenzentrum in Duisburg")

    component =
      ResultComponent.new(
        query: "rechenzentrum",
        archive_file: @archive_file
      )

    assert_equal %(Das <span class="result__highlight">Rechenzentrum</span> in Duisburg),
                 component.summary
    @archive_file.verify
  end

  def test_cite_filename_folds_the_call_number
    @archive_file.expect(:call_number, "DC 20/797")

    component = ResultComponent.new(query: "", archive_file: @archive_file)

    assert_equal "DC_20_797.ris", component.cite_filename(:ris)
    @archive_file.verify
  end

  def test_render_offers_a_copy_and_a_download_per_format
    render_inline(ResultComponent.new(archive_file: citable_archive_file))

    assert_selector ".cite__group", count: 2
    assert_selector %(button.cite__button[data-action="copy"][data-format="ris"]), count: 1
    assert_selector %(button.cite__button[data-action="copy"][data-format="bib"]), count: 1
    assert_selector %(a.cite__button[data-format="ris"][download$=".ris"]), count: 1
    assert_selector %(a.cite__button[data-format="bib"][download$=".bib"]), count: 1
  end

  def test_render_labels_every_icon_only_control
    render_inline(ResultComponent.new(archive_file: citable_archive_file))

    page.all(".cite__button").each do |button|
      assert button[:title].present?, "a cite button is missing its title"
      assert_equal button[:title], button["aria-label"]
    end
  end

  private

  def citable_archive_file
    ArchiveFile.create!(
      archive_node: ArchiveNode.create!(name: "Ministerrat"),
      call_number: "DC 20/797",
      title: "Sitzungen des Ministerrates",
      summary: "Protokolle"
    )
  end
end

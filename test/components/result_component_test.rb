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
end

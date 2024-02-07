require "test_helper"

class ResultComponentTest < ViewComponent::TestCase
  def test_title_highlight
    component =
      ResultComponent.new(
        query: "rechenzentrum",
        record: OpenStruct.new(title: "Rechenzentrum Duisburg")
      )
    assert_equal %(<span class="result__highlight">Rechenzentrum</span> Duisburg),
                 component.title
  end

  def test_date
    component =
      ResultComponent.new(
        query: "rechenzentrum",
        record: OpenStruct.new(source_date: "1989")
      )
    assert_equal "1989", component.date
  end

  def test_summary_highlight
    component =
      ResultComponent.new(
        query: "rechenzentrum",
        record: OpenStruct.new(summary: "Das Rechenzentrum in Duisburg")
      )
    assert_equal %(Das <span class="result__highlight">Rechenzentrum</span> in Duisburg),
                 component.summary
  end
end

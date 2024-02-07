class ResultComponent < ViewComponent::Base
  def initialize(query:, record:)
    @query = query
    @record = record
  end

  def title
    highlight_query(@record.title)
  end

  def date
    @record.source_date
  end

  def summary
    highlight_query(@record.summary)
  end

  private

  def highlight_query(text)
    return text if @query.blank? || text.blank?
    text.gsub(
      /(#{@query})/i,
      '<span class="result__highlight">\1</span>'
    ).html_safe
  end
end

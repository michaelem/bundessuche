class ResultComponent < ViewComponent::Base
  def initialize(query:, record:)
    @query = query
    @record = record
  end

  def parents
    @parents ||=
      @record.parents.map do |parent|
        '<div class="parents__item">' + CGI.escapeHTML(parent.strip) + "</div>"
      end.join '<div class="parents__separator">/</div>'

    @parents.html_safe
  end

  def title
    highlight_query(@record.title)
  end

  def date
    @record.source_date_text
  end

  def summary
    highlight_query(@record.summary)
  end

  private

  def highlight_query(text)
    return text if @query.blank? || text.blank?
    text.gsub(
      /(#{CGI.escapeHTML(@query)})/i,
      '<span class="result__highlight">\1</span>'
    ).html_safe
  end
end

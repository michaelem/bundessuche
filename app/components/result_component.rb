class ResultComponent < ViewComponent::Base
  def initialize(query:, record:)
    @query = query
    @record = record
  end

  def parents
    @parents ||=
      @record.parents.map do |parent|
        text = highlight_query(CGI.escapeHTML(parent.strip))
        "<div class=\"parents__item\">#{text}</div>"
      end.join '<div class="parents__separator">/</div>'

    @parents.html_safe
  end

  def title
    highlight_query(@record.title)
  end

  def date
    return @record.source_date_text if @record.source_date_text.present?

    @record.source_date_years
  end

  def summary
    highlight_query(@record.summary)
  end

  def ris_link
    link_to @record, format: :ris
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

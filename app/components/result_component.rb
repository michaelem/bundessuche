class ResultComponent < ViewComponent::Base
  def initialize(archive_file:, query: "")
    @query = query
    @archive_file = archive_file
  end

  def parents
    @parents ||=
      @archive_file.parents.map do |parent|
        text = highlight_query(CGI.escapeHTML(parent.strip))
        "<div class=\"parents__item\">#{text}</div>"
      end.join '<div class="parents__separator">/</div>'

    @parents.html_safe
  end

  def title
    highlight_query(@archive_file.title)
  end

  def date
    return @archive_file.source_date_text if @archive_file.source_date_text.present?

    @archive_file.source_date_years
  end

  def summary
    highlight_query(@archive_file.summary)
  end

  def ris_link
    link_to @archive_file, format: :ris
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

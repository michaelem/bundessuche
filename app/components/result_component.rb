class ResultComponent < ViewComponent::Base
  def initialize(archive_file:, query: "")
    @query = query
    @archive_file = archive_file
  end

  def parents
    @parents ||=
      @archive_file.parents.map do |parent|
        text = highlight_query(CGI.escapeHTML(parent.name.to_s.strip))
        text = link_to text, archive_node_path(parent), class: "parents__item__link"

        "<div class=\"parents__item\">#{text}</div>"
      end.join '<div class="parents__separator">/</div>'

    @parents.html_safe
  end

  def title
    highlight_query(@archive_file.title)
  end

  def date
    return @archive_file.source_date_text if @archive_file.source_date_text.present?

    @archive_file.source_date_years.join("-")
  end

  # The dates behind the date text, shown when the reader unfolds it. Nil when
  # nothing could be parsed, in which case there is nothing to unfold.
  def parsed_date
    start_date, end_date = @archive_file.effective_source_dates
    return nil if start_date.blank?
    return format_date(start_date) if end_date == start_date

    "#{format_date(start_date)}\u2009\u2013\u2009#{format_date(end_date)}"
  end

  def summary
    highlight_query(@archive_file.summary)
  end

  def ris_link
    link_to @archive_file, format: :ris
  end

  private

  def format_date(date)
    date.strftime("%d.%m.%Y")
  end

  def highlight_query(text)
    return text if @query.blank? || text.blank?
    text.gsub(
      /(#{CGI.escapeHTML(@query)})/i,
      '<span class="result__highlight">\1</span>'
    ).html_safe
  end
end

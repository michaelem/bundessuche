class ResultComponent < ViewComponent::Base
  # The citation formats offered on every result, in tab order, mapped to the
  # label the reader sees. The keys double as the request format.
  CITE_FORMATS = { ris: "RIS", bib: "BibTeX" }.freeze

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

  def cite_path(format)
    archive_file_path(@archive_file, format: format)
  end

  # The name the browser saves the citation under. Call numbers carry spaces
  # and slashes, so everything outside of a plain file name is folded away.
  def cite_filename(format)
    name = @archive_file.call_number.to_s.gsub(/[^A-Za-z0-9]+/, "_").delete_prefix("_").delete_suffix("_")
    "#{name}.#{format}"
  end

  def copy_icon
    cite_icon(
      %(<path d="M10.4 3.6a1.6 1.6 0 0 0-1.6-1.6H4.4a1.6 1.6 0 0 0-1.6 1.6v4.4a1.6 1.6 0 0 0 1.6 1.6"/>) +
      %(<rect x="5.6" y="5.6" width="7.6" height="7.6" rx="1.6"/>)
    )
  end

  def download_icon
    cite_icon(
      %(<path d="M8 2.6v7"/><path d="M5.2 6.9 8 9.7l2.8-2.8"/><path d="M3 12.6h10"/>)
    )
  end

  private

  def cite_icon(paths)
    <<~SVG
      <svg width="14" height="14" viewBox="0 0 16 16" fill="none"
           stroke="currentColor" stroke-width="1.4" stroke-linecap="round"
           stroke-linejoin="round" aria-hidden="true">#{paths}</svg>
    SVG
      .strip
      .html_safe
  end

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

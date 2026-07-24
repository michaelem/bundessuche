# Parses the unambiguous date captions ("1948", "28. Mai 1948", "Febr.-März 1948",
# "o. Dat.") without asking an LLM. Returns nil for everything else, which is what
# SourceDateBackfill hands to SourceDateParser.
#
# Captions carrying an estimate ("ca.", "um", "vor", "nach", "?") or listing several
# periods ("1907, 1944-1951") are deliberately not matched here: reading them is a
# judgement call, and that is what the LLM is for.
class SourceDateMatcher
  MONTHS = {
    "januar" => 1, "jan" => 1,
    "februar" => 2, "febr" => 2, "feb" => 2,
    "märz" => 3, "marz" => 3, "maerz" => 3, "mrz" => 3, "mär" => 3,
    "april" => 4, "apr" => 4,
    "mai" => 5,
    "juni" => 6, "jun" => 6,
    "juli" => 7, "jul" => 7,
    "august" => 8, "aug" => 8,
    "september" => 9, "sept" => 9, "sep" => 9,
    "oktober" => 10, "okt" => 10,
    "november" => 11, "nov" => 11,
    "dezember" => 12, "dez" => 12
  }.freeze

  MONTH = /(#{MONTHS.keys.sort_by { |name| -name.length }.join("|")})\.?/i
  YEAR = /(1\d{3}|20\d{2})/
  DAY = /(\d{1,2})\.\s?/
  DASH = /\s*-{1,2}\s*/

  UNDATABLE = Regexp.union(
    /\A(o\.?\s*dat\.?|o\.?\s*d\.?|o\.?\s*j\.?)\z/i,
    /\A(ohne\s+(datum|jahr)|undatiert|k\.?\s*a\.?)\z/i,
    /\Alaufzeit\s+(nicht\s+ermittelt|automatisch\s+generiert)\z/i,
    /\A-{1,3}\z/
  )

  # Brackets mark a date the archivist inferred, so it stays a little less certain.
  BRACKETED_CONFIDENCE = 0.9

  def call(text)
    caption = text.to_s.strip.gsub(/\s+/, " ")
    bracketed = caption.match?(/\A\[.*\]\z/)
    caption = caption[1..-2].strip if bracketed

    return attributes(text, nil, nil, 0.0) if caption.match?(UNDATABLE)

    start_date, end_date = match(caption)
    return nil if start_date.nil?

    attributes(text, start_date, end_date, bracketed ? BRACKETED_CONFIDENCE : 1.0)
  end

  private

  def match(caption)
    case caption
    when /\A#{YEAR}\z/ # 1948
      year_range($1, $1)
    when /\A#{YEAR}#{DASH}#{YEAR}\z/ # 1946-1958
      year_range($1, $2)
    when /\A#{DAY}#{MONTH}\s*#{YEAR}\z/ # 28. Mai 1948
      day($3, MONTHS[month_key($2)], $1)
    when /\A(\d{1,2})\.\s?(\d{1,2})\.\s?#{YEAR}\z/ # 1. 1. 1920
      day($3, $2, $1)
    when /\A#{MONTH}\s*#{YEAR}\z/ # Nov. 1949
      month_range($2, MONTHS[month_key($1)], $2, MONTHS[month_key($1)])
    when /\A#{MONTH}#{DASH}#{MONTH}\s*#{YEAR}\z/ # Febr.-März 1948
      month_range($3, MONTHS[month_key($1)], $3, MONTHS[month_key($2)])
    when /\A#{MONTH}\s*#{YEAR}#{DASH}#{MONTH}\s*#{YEAR}\z/ # Jan. 1950 - Juni 1950
      month_range($2, MONTHS[month_key($1)], $4, MONTHS[month_key($3)])
    when /\A#{DAY}#{MONTH}#{DASH}#{DAY}#{MONTH}\s*#{YEAR}\z/ # 1. Jan. - 30. Juni 1943
      day_range($5, MONTHS[month_key($2)], $1, $5, MONTHS[month_key($4)], $3)
    when /\A#{DAY}#{MONTH}\s*#{YEAR}#{DASH}#{DAY}#{MONTH}\s*#{YEAR}\z/ # 1. Jan. 1943 - 30. Juni 1944
      day_range($3, MONTHS[month_key($2)], $1, $6, MONTHS[month_key($5)], $4)
    end
  end

  def month_key(name)
    name.downcase.delete_suffix(".")
  end

  def year_range(start_year, end_year)
    [Date.new(start_year.to_i, 1, 1), Date.new(end_year.to_i, 12, 31)]
  end

  def month_range(start_year, start_month, end_year, end_month)
    [Date.new(start_year.to_i, start_month, 1), Date.new(end_year.to_i, end_month, -1)]
  end

  def day(year, month, day)
    date = Date.new(year.to_i, month.to_i, day.to_i)
    [date, date]
  rescue Date::Error # 31. Juni 1948
    nil
  end

  def day_range(start_year, start_month, start_day, end_year, end_month, end_day)
    range = [
      Date.new(start_year.to_i, start_month.to_i, start_day.to_i),
      Date.new(end_year.to_i, end_month.to_i, end_day.to_i)
    ]
    range if range.first <= range.last
  rescue Date::Error
    nil
  end

  def attributes(text, start_date, end_date, confidence)
    {
      source_text: text,
      start_date: start_date,
      end_date: end_date,
      confidence: confidence,
      llm_model: nil,
      raw_response: nil
    }
  end
end

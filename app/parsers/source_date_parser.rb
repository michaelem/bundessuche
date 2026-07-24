# Turns a free text date caption from a finding aid ("28. Mai 1948", "Febr.-März 1948",
# "o. Dat.") into an ISO 8601 date range, using a local LLM.
#
# Stateless and free of database access, so it can be unit tested with a stubbed chat.
class SourceDateParser
  DEFAULT_MODEL = "gemma4:26b-mxfp8"

  class Schema < RubyLLM::Schema
    string :start_date, description: "First day covered by the caption, as YYYY-MM-DD. Empty string if the caption names no date."
    string :end_date, description: "Last day covered by the caption, as YYYY-MM-DD. Empty string if the caption names no date."
    number :confidence, description: "Confidence in the extracted range, between 0.0 and 1.0."
  end

  # Not every Ollama model honours the JSON schema (gemma4:26b-mxfp8 ignores it and answers
  # with prose), so the prompt spells the format out and the examples are the answers we
  # want verbatim.
  SYSTEM_PROMPT = <<~PROMPT
    You extract date ranges from the date captions of German archival finding aids
    (Bundesarchiv). The caption is printed for humans and may be abbreviated, bracketed
    or approximate.

    Answer with a single JSON object and nothing else: no explanation, no markdown, no
    code fence. The object has exactly the keys "start_date" and "end_date" (days as
    YYYY-MM-DD) and "confidence" (a number between 0.0 and 1.0).

    Rules:
    - The dates are the first and the last day the caption covers.
    - Expand partial dates to the full period they name:
      "1948" covers 1948-01-01 to 1948-12-31, "Mai 1948" covers 1948-05-01 to 1948-05-31.
    - For several separate dates or periods use the earliest and the latest one.
    - A single day gets the same start and end date.
    - Brackets, "?", "ca.", "um", "vor", "nach" mean the date is uncertain. Still give
      your best range, but lower the confidence.
    - If the caption names no date at all ("o. Dat.", "o.D.", "ohne Datum", "k. A."),
      use empty strings for both dates and a confidence of 0.0.

    Examples:
    Caption: 28. Mai 1948
    {"start_date": "1948-05-28", "end_date": "1948-05-28", "confidence": 1.0}
    Caption: Febr.-März 1948
    {"start_date": "1948-02-01", "end_date": "1948-03-31", "confidence": 0.9}
    Caption: 30. Juni 1948 und 25. Jan. 1949
    {"start_date": "1948-06-30", "end_date": "1949-01-25", "confidence": 0.9}
    Caption: 1907, 1944-1951
    {"start_date": "1907-01-01", "end_date": "1951-12-31", "confidence": 0.9}
    Caption: [Mai 1948 ?]
    {"start_date": "1948-05-01", "end_date": "1948-05-31", "confidence": 0.5}
    Caption: nach Mai 1953
    {"start_date": "1953-05-01", "end_date": "1953-12-31", "confidence": 0.3}
    Caption: o. Dat.
    {"start_date": "", "end_date": "", "confidence": 0.0}
  PROMPT

  def initialize(model: ENV.fetch("OLLAMA_MODEL", DEFAULT_MODEL))
    @model = model
  end

  attr_reader :model

  # Returns attributes for a ParsedSourceDate. Raises whatever ruby_llm raises when the
  # server cannot be reached, so callers can tell a transport failure apart from a caption
  # the model considers undatable.
  def call(text)
    content = chat.ask("Caption: #{text}").content

    normalize(extract_result(content)).merge(
      source_text: text,
      llm_model: model,
      raw_response: content.is_a?(String) ? content : JSON.generate(content)
    )
  end

  private

  # Models that honour the schema answer with a hash. The others answer with JSON wrapped
  # in prose or a code fence, or, when they fall for the examples, with the three values on
  # their own. Anything else is treated as no answer.
  def extract_result(content)
    return content if content.is_a?(Hash)

    text = content.to_s

    if (object = text[/\{.*?\}/m])
      begin
        parsed = JSON.parse(object)
        return parsed if parsed.is_a?(Hash)
      rescue JSON::ParserError
        # Fall through to the loose format below.
      end
    end

    dates = text.scan(/\d{4}-\d{2}-\d{2}/)
    return {} if dates.empty?

    {"start_date" => dates.first, "end_date" => dates.last, "confidence" => text.scan(/\d*\.\d+/).last&.to_f}
  end

  def chat
    RubyLLM
      .chat(model: model, provider: :ollama, assume_model_exists: true)
      .with_temperature(0)
      .with_instructions(SYSTEM_PROMPT)
      .with_schema(Schema)
  end

  def normalize(result)
    start_date = parse_iso8601_string(result["start_date"])
    end_date = parse_iso8601_string(result["end_date"])
    start_date, end_date = end_date, start_date if start_date && end_date && start_date > end_date

    if start_date.nil?
      start_date = end_date
      end_date = nil
    end

    {
      start_date: start_date,
      end_date: start_date && (end_date || start_date),
      confidence: clamp_confidence(result["confidence"], start_date)
    }
  end

  def parse_iso8601_string(date_string)
    return nil unless date_string.present?

    begin
      Date.iso8601(date_string)
    rescue Date::Error
      nil
    end
  end

  def clamp_confidence(confidence, start_date)
    return 0.0 if start_date.nil?
    return 0.0 unless confidence.is_a?(Numeric)

    confidence.to_f.clamp(0.0, 1.0)
  end
end

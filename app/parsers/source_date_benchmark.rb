# frozen_string_literal: true

# Scores an Ollama model on the job SourceDateParser does, so the model can be picked with
# numbers instead of a hunch.
#
# Two sets of captions:
#
# * "matched" - captions SourceDateMatcher reads deterministically. Their ranges are the
#   ground truth, which makes a large, unbiased and free test set. These captions never
#   reach the LLM in production, so they measure basic competence, not the real workload.
# * "hedged" - captions taken from the corpus that the matcher refuses, with the range
#   the prompt rules ask for filled in by hand. This is the workload that actually reaches
#   the LLM.
class SourceDateBenchmark
  # Real captions from the corpus, with the answer SourceDateParser::SYSTEM_PROMPT asks for.
  # Captions used as examples in the prompt are left out: they would measure copying.
  HEDGED = {
    'ca. 1944' => %w[1944-01-01 1944-12-31],
    'ca. 1939-1945' => %w[1939-01-01 1945-12-31],
    'ca. 1936-1938' => %w[1936-01-01 1938-12-31],
    'ca. 1900-1945' => %w[1900-01-01 1945-12-31],
    'um 1900' => %w[1900-01-01 1900-12-31],
    '1942, 1944' => %w[1942-01-01 1944-12-31],
    '1939, 1941' => %w[1939-01-01 1941-12-31],
    '1940/1941' => %w[1940-01-01 1941-12-31],
    '1943/1944' => %w[1943-01-01 1944-12-31],
    '1. - 31. Dez. 1943' => %w[1943-12-01 1943-12-31],
    '1. - 30. Juni 1943' => %w[1943-06-01 1943-06-30],
    '1946 - [vor 1958]' => %w[1946-01-01 1957-12-31],
    '1948 (Abschrift)' => %w[1948-01-01 1948-12-31],
    '1. Hälfte 1944' => %w[1944-01-01 1944-06-30],
    'ohne Datum; 19. Jahrh.' => %w[1801-01-01 1900-12-31], # no day, but the century counts
    'Bd. 1' => [nil, nil]
  }.transform_values { |dates| dates.map { |date| date && Date.iso8601(date) } }.freeze

  # Captions the matcher reads, drawn from the corpus with a fixed seed so every model sees
  # the same test set.
  # Shuffles first and reads lazily, so only as many captions as the sample needs are run
  # through the matcher - running all 250k of them takes about a minute and buys nothing.
  def self.matched_captions(size:, seed: 42, matcher: SourceDateMatcher.new)
    ArchiveFile
      .where.not(source_date_text: [nil, ''])
      .distinct
      .pluck(:source_date_text)
      .shuffle(random: Random.new(seed))
      .lazy
      .filter_map do |text|
        attributes = matcher.call(text)
        [text, [attributes[:start_date], attributes[:end_date]]] if attributes
      end
      .first(size)
      .to_h
  end

  def initialize(model:, captions:, parser: SourceDateParser.new(model: model))
    @model = model
    @captions = captions
    @parser = parser
  end

  attr_reader :model, :captions, :parser

  # Returns one row per caption: the expected and the parsed range, plus how long the call
  # took.
  def run(show_progress: false)
    warm_up

    captions.map do |caption, (start_date, end_date)|
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      begin
        result = parser.call(caption)
      rescue StandardError => e
        result = { start_date: nil, end_date: nil, raw_response: "#{e.class}: #{e.message}" }
      end

      seconds = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
      correct = result[:start_date] == start_date && result[:end_date] == end_date
      Rails.logger.debug(correct ? '.' : 'x') if show_progress

      {
        caption: caption,
        expected: [start_date, end_date],
        actual: [result[:start_date], result[:end_date]],
        correct: correct,
        json: result[:raw_response].to_s.strip.start_with?('{'),
        seconds: seconds
      }
    end
  end

  # One throwaway call so that loading the model into memory is not charged to the first
  # caption, which would otherwise dominate its timing.
  def warm_up
    parser.call('1948')
  rescue StandardError
    nil
  end

  def self.summarize(rows)
    correct = rows.count { |row| row[:correct] }
    seconds = rows.sum { |row| row[:seconds] }

    {
      captions: rows.size,
      correct: correct,
      accuracy: rows.empty? ? 0.0 : (100.0 * correct / rows.size).round(1),
      json: rows.count { |row| row[:json] },
      seconds_per_caption: rows.empty? ? 0.0 : (seconds / rows.size).round(1),
      total_seconds: seconds.round(1)
    }
  end
end

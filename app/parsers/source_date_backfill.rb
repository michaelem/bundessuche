# frozen_string_literal: true

# Turns every distinct ArchiveFile#source_date_text into a ParsedSourceDate. Unambiguous
# captions are read by SourceDateMatcher, the rest goes to the much slower SourceDateParser.
# Texts are processed most frequently used first, so an interrupted run still covers the bulk
# of the archive files. Re-running picks up where the last run stopped.
class SourceDateBackfill
  def initialize(limit: nil, matcher: SourceDateMatcher.new, parser: SourceDateParser.new)
    @limit = limit
    @matcher = matcher
    @parser = parser
  end

  attr_reader :limit, :matcher, :parser

  def run(show_progress: false)
    texts = pending_texts

    if show_progress
      start = Time.zone.now

      progress_bar = ProgressBar.create(
        title: 'Parsing dates',
        total: texts.size,
        format: '%t %p%% %a %e |%B|',
        output: $stdout
      )
    end

    failures = 0
    matched = 0

    texts.each do |text|
      begin
        attributes = matcher.call(text)
        matched += 1 if attributes
        ParsedSourceDate.create!(attributes || parser.call(text))
      rescue StandardError => e
        # Leave the text unparsed so that the next run tries it again.
        failures += 1
        Rails.logger.error("SourceDateBackfill failed for #{text.inspect}: #{e.class}: #{e.message}")
      end

      progress_bar.increment if show_progress
    end

    if show_progress
      Rails.logger.debug "Parsed #{texts.size - failures} of #{texts.size} date texts in #{Time.zone.now - start} seconds"
      Rails.logger.debug "#{matched} of them without the LLM"
      Rails.logger.debug "#{failures} failed, see the log for details" if failures.positive?
    end

    texts.size - failures
  end

  # Distinct, non blank source date texts without a ParsedSourceDate, most used first.
  def pending_texts
    known = ParsedSourceDate.pluck(:source_text).to_set

    texts = ArchiveFile
            .where.not(source_date_text: [nil, ''])
            .group(:source_date_text)
            .order(Arel.sql('COUNT(*) DESC'))
            .pluck(:source_date_text)

    texts = texts.reject { |text| known.include?(text) }
    limit ? texts.first(limit) : texts
  end
end

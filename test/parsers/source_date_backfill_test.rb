# frozen_string_literal: true

require 'test_helper'

class SourceDateBackfillTest < ActiveSupport::TestCase
  # Records the texts it was asked for and answers with a fixed range.
  class FakeParser
    def initialize(&block)
      @block = block
      @calls = []
    end

    attr_reader :calls

    def call(text)
      @calls << text
      @block&.call(text)

      {
        source_text: text,
        start_date: Date.new(1948, 1, 1),
        end_date: Date.new(1948, 12, 31),
        confidence: 0.9,
        llm_model: 'test-model',
        raw_response: '{}'
      }
    end
  end

  # Matches nothing, so every text reaches the parser.
  class NullMatcher
    def call(_text) = nil
  end

  setup do
    @archive_node = ArchiveNode.create!(name: 'Bestand', source_id: 'node-1')
  end

  def create_archive_file(source_date_text, count: 1)
    count.times do |_i|
      ArchiveFile.create!(
        archive_node: @archive_node,
        source_id: "DE-1958_#{SecureRandom.uuid}",
        source_date_text: source_date_text
      )
    end
  end

  test 'parses the most used texts first' do
    create_archive_file('1948', count: 1)
    create_archive_file('o. Dat.', count: 3)
    create_archive_file('Mai 1950', count: 2)

    parser = FakeParser.new
    SourceDateBackfill.new(matcher: NullMatcher.new, parser: parser).run

    assert_equal ['o. Dat.', 'Mai 1950', '1948'], parser.calls
    assert_equal 3, ParsedSourceDate.count
  end

  test 'skips blank texts' do
    create_archive_file('1948')
    create_archive_file('')
    create_archive_file(nil)

    parser = FakeParser.new
    SourceDateBackfill.new(matcher: NullMatcher.new, parser: parser).run

    assert_equal ['1948'], parser.calls
  end

  test 'skips texts that were parsed before' do
    create_archive_file('1948')
    create_archive_file('Mai 1950')
    ParsedSourceDate.create!(source_text: '1948', confidence: 1.0)

    parser = FakeParser.new
    SourceDateBackfill.new(matcher: NullMatcher.new, parser: parser).run

    assert_equal ['Mai 1950'], parser.calls
  end

  test 'honours the limit' do
    create_archive_file('1948', count: 2)
    create_archive_file('Mai 1950')

    parser = FakeParser.new
    SourceDateBackfill.new(limit: 1, matcher: NullMatcher.new, parser: parser).run

    assert_equal ['1948'], parser.calls
  end

  test 'continues after a failure and leaves the text unparsed' do
    create_archive_file('1948', count: 2)
    create_archive_file('Mai 1950')

    parser = FakeParser.new { |text| raise Faraday::ConnectionFailed, 'boom' if text == '1948' }
    parsed = SourceDateBackfill.new(matcher: NullMatcher.new, parser: parser).run

    assert_equal ['1948', 'Mai 1950'], parser.calls
    assert_equal 1, parsed
    assert_equal ['Mai 1950'], ParsedSourceDate.pluck(:source_text)
  end

  test 'only sends the texts the matcher cannot read to the LLM' do
    create_archive_file('1948')
    create_archive_file('nach Mai 1953')

    parser = FakeParser.new
    SourceDateBackfill.new(parser: parser).run

    assert_equal ['nach Mai 1953'], parser.calls
    assert_equal ['1948'], ParsedSourceDate.matched.pluck(:source_text)
    assert_equal ['nach Mai 1953'], ParsedSourceDate.from_llm.pluck(:source_text)
    assert_equal Date.new(1948, 1, 1), ParsedSourceDate.find_by(source_text: '1948').start_date
  end
end

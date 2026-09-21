# frozen_string_literal: true

require 'test_helper'

class SourceDateParserTest < ActiveSupport::TestCase
  # Stands in for the RubyLLM chat, which returns the parsed JSON object as content.
  class FakeChat
    def initialize(content)
      @content = content
    end

    attr_reader :asked

    def with_temperature(_temperature) = self
    def with_instructions(_instructions) = self
    def with_schema(_schema) = self
    def with_provider_options(_options) = self

    def ask(text)
      @asked = text
      Struct.new(:content).new(@content)
    end
  end

  def parse(content, text: '1948')
    chat = FakeChat.new(content)
    result = nil

    RubyLLM.stub(:chat, ->(**) { chat }) do
      result = SourceDateParser.new(model: 'test-model').call(text)
    end

    result
  end

  test 'parses a date range' do
    result = parse({ 'start_date' => '1948-02-01', 'end_date' => '1948-03-31', 'confidence' => 0.9 })

    assert_equal Date.new(1948, 2, 1), result[:start_date]
    assert_equal Date.new(1948, 3, 31), result[:end_date]
    assert_equal 0.9, result[:confidence]
    assert_equal '1948', result[:source_text]
    assert_equal 'test-model', result[:llm_model]
  end

  test 'parses a single date into a range of one day' do
    result = parse({ 'start_date' => '1948-05-28', 'end_date' => '', 'confidence' => 1.0 })

    assert_equal Date.new(1948, 5, 28), result[:start_date]
    assert_equal Date.new(1948, 5, 28), result[:end_date]
  end

  test 'swaps an inverted range' do
    result = parse({ 'start_date' => '1951-12-31', 'end_date' => '1907-01-01', 'confidence' => 0.8 })

    assert_equal Date.new(1907, 1, 1), result[:start_date]
    assert_equal Date.new(1951, 12, 31), result[:end_date]
  end

  test 'uses the end date when only that one is given' do
    result = parse({ 'start_date' => '', 'end_date' => '1948-05-28', 'confidence' => 0.5 })

    assert_equal Date.new(1948, 5, 28), result[:start_date]
    assert_equal Date.new(1948, 5, 28), result[:end_date]
  end

  test 'keeps undatable texts without a range and without confidence' do
    result = parse({ 'start_date' => '', 'end_date' => '', 'confidence' => 0.4 }, text: 'o. Dat.')

    assert_nil result[:start_date]
    assert_nil result[:end_date]
    assert_equal 0.0, result[:confidence]
    assert_equal 'o. Dat.', result[:source_text]
  end

  test 'ignores dates that are not ISO 8601' do
    result = parse({ 'start_date' => '28. Mai 1948', 'end_date' => '1948-13-45', 'confidence' => 0.9 })

    assert_nil result[:start_date]
    assert_nil result[:end_date]
    assert_equal 0.0, result[:confidence]
  end

  test 'clamps the confidence into 0.0 to 1.0' do
    result = parse({ 'start_date' => '1948-01-01', 'end_date' => '1948-12-31', 'confidence' => 7 })

    assert_equal 1.0, result[:confidence]
  end

  test 'falls back to 0.0 when the confidence is missing' do
    result = parse({ 'start_date' => '1948-01-01', 'end_date' => '1948-12-31' })

    assert_equal 0.0, result[:confidence]
  end

  test 'parses a JSON string response' do
    result = parse('{"start_date": "1950-01-01", "end_date": "1950-06-30", "confidence": 0.95}')

    assert_equal Date.new(1950, 1, 1), result[:start_date]
    assert_equal Date.new(1950, 6, 30), result[:end_date]
    assert_equal 0.95, result[:confidence]
  end

  test 'picks the JSON object out of a response with prose around it' do
    result = parse(<<~ANSWER)
      Hier ist das Ergebnis:
      ```json
      {"start_date": "1953-05-01", "end_date": "1953-12-31", "confidence": 0.3}
      ```
    ANSWER

    assert_equal Date.new(1953, 5, 1), result[:start_date]
    assert_equal Date.new(1953, 12, 31), result[:end_date]
    assert_equal 0.3, result[:confidence]
  end

  test 'reads the three values when a model answers without JSON' do
    result = parse('1976-01-01, 1976-12-31, 1.0')

    assert_equal Date.new(1976, 1, 1), result[:start_date]
    assert_equal Date.new(1976, 12, 31), result[:end_date]
    assert_equal 1.0, result[:confidence]
  end

  test 'survives a response that is not JSON' do
    result = parse('Das kann ich nicht sagen.')

    assert_nil result[:start_date]
    assert_equal 0.0, result[:confidence]
    assert_equal 'Das kann ich nicht sagen.', result[:raw_response]
  end
end

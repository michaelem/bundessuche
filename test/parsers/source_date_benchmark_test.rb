require 'test_helper'

class SourceDateBenchmarkTest < ActiveSupport::TestCase
  # Answers with whatever the test tells it to, so scoring can be checked without a server.
  class FakeParser
    def initialize(answers)
      @answers = answers
    end

    def call(caption)
      answer = @answers.fetch(caption)
      raise Faraday::ConnectionFailed, 'boom' if answer == :raise

      { start_date: answer[0], end_date: answer[1], raw_response: answer[2] || '{}' }
    end
  end

  def benchmark(captions, answers)
    SourceDateBenchmark.new(model: 'test-model', captions: captions, parser: FakeParser.new(answers)).run
  end

  test 'scores a correct and a wrong answer' do
    rows = benchmark(
      { '1948' => [Date.new(1948, 1, 1), Date.new(1948, 12, 31)],
        'ca. 1944' => [Date.new(1944, 1, 1), Date.new(1944, 12, 31)] },
      { '1948' => [Date.new(1948, 1, 1), Date.new(1948, 12, 31)], 'ca. 1944' => [Date.new(1944, 1, 1), nil] }
    )

    assert rows.first[:correct]
    refute rows.second[:correct]

    summary = SourceDateBenchmark.summarize(rows)
    assert_equal 2, summary[:captions]
    assert_equal 1, summary[:correct]
    assert_equal 50.0, summary[:accuracy]
  end

  test 'counts an undatable caption as correct when no range comes back' do
    rows = benchmark({ 'o. Dat.' => [nil, nil] }, { 'o. Dat.' => [nil, nil] })

    assert rows.first[:correct]
  end

  test 'counts responses that are not JSON' do
    rows = benchmark(
      { '1948' => [Date.new(1948, 1, 1), Date.new(1948, 12, 31)] },
      { '1948' => [Date.new(1948, 1, 1), Date.new(1948, 12, 31), '1948-01-01, 1948-12-31, 1.0'] }
    )

    assert rows.first[:correct]
    refute rows.first[:json]
    assert_equal 0, SourceDateBenchmark.summarize(rows)[:json]
  end

  test 'a failing call counts as a wrong answer instead of aborting the run' do
    rows = benchmark({ '1948' => [Date.new(1948, 1, 1), Date.new(1948, 12, 31)] }, { '1948' => :raise })

    refute rows.first[:correct]
    assert_equal 0.0, SourceDateBenchmark.summarize(rows)[:accuracy]
  end
end

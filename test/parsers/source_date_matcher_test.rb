# frozen_string_literal: true

require 'test_helper'

class SourceDateMatcherTest < ActiveSupport::TestCase
  setup do
    @matcher = SourceDateMatcher.new
  end

  def assert_range(text, start_date, end_date, confidence: 1.0)
    result = @matcher.call(text)

    assert_not_nil result, "expected #{text.inspect} to be matched"
    assert_equal start_date, result[:start_date], text
    assert_equal end_date, result[:end_date], text
    assert_equal confidence, result[:confidence], text
    assert_equal text, result[:source_text]
    assert_nil result[:llm_model]
  end

  test 'a year' do
    assert_range '1948', Date.new(1948, 1, 1), Date.new(1948, 12, 31)
  end

  test 'a range of years' do
    assert_range '1946-1958', Date.new(1946, 1, 1), Date.new(1958, 12, 31)
    assert_range '1946 - 1958', Date.new(1946, 1, 1), Date.new(1958, 12, 31)
    assert_range '1940--1952', Date.new(1940, 1, 1), Date.new(1952, 12, 31)
  end

  test 'a day with a month name' do
    assert_range '28. Mai 1948', Date.new(1948, 5, 28), Date.new(1948, 5, 28)
    assert_range '25. Jan. 1949', Date.new(1949, 1, 25), Date.new(1949, 1, 25)
  end

  test 'a numeric day' do
    assert_range '1. 1. 1920', Date.new(1920, 1, 1), Date.new(1920, 1, 1)
    assert_range '01.01.1920', Date.new(1920, 1, 1), Date.new(1920, 1, 1)
  end

  test 'a month' do
    assert_range 'Nov. 1949', Date.new(1949, 11, 1), Date.new(1949, 11, 30)
    assert_range 'Februar 1948', Date.new(1948, 2, 1), Date.new(1948, 2, 29)
  end

  test 'a range of months in one year' do
    assert_range 'Febr.-März 1948', Date.new(1948, 2, 1), Date.new(1948, 3, 31)
  end

  test 'a range of months with both years' do
    assert_range 'Jan. 1950 - Juni 1950', Date.new(1950, 1, 1), Date.new(1950, 6, 30)
    assert_range 'Sept. 1949 - Dez. 1950', Date.new(1949, 9, 1), Date.new(1950, 12, 31)
  end

  test 'brackets lower the confidence' do
    assert_range '[1949]', Date.new(1949, 1, 1), Date.new(1949, 12, 31), confidence: 0.9
    assert_range '[Mai 1948]', Date.new(1948, 5, 1), Date.new(1948, 5, 31), confidence: 0.9
  end

  test 'a range of days' do
    assert_range '1. Jan. - 30. Juni 1943', Date.new(1943, 1, 1), Date.new(1943, 6, 30)
    assert_range '1. Okt. 1943 - 31. März 1944', Date.new(1943, 10, 1), Date.new(1944, 3, 31)
  end

  test 'captions without a date' do
    ['o. Dat.', 'o.D.', 'ohne Datum', 'undatiert', 'k. A.', '---',
     'Laufzeit nicht ermittelt', 'Laufzeit automatisch generiert'].each do |text|
      result = @matcher.call(text)

      assert_not_nil result, "expected #{text.inspect} to be matched"
      assert_nil result[:start_date]
      assert_nil result[:end_date]
      assert_equal 0.0, result[:confidence]
    end
  end

  test 'leaves everything it cannot read for the LLM' do
    [
      'nach Mai 1953',
      '1946- [vor 1958]',
      '[Mai 1948 ?]',
      '30. Juni 1948 und 25. Jan. 1949',
      '1907, 1944-1951',
      'ca. 1950',
      '1948 (Abschrift)',
      'Frühjahr 1948',
      '31. Juni 1948',
      ''
    ].each do |text|
      assert_nil @matcher.call(text), "expected #{text.inspect} to go to the LLM"
    end
  end
end

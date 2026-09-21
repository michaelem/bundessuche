# frozen_string_literal: true

require 'test_helper'

class UnitDateTest < ActiveSupport::TestCase
  test 'Parses a date range correctly' do
    date_parser = UnitDate.new('1959', '1959-01-01/1959-12-31')

    assert date_parser.range?
    assert_equal Date.new(1959, 1, 1), date_parser.start_date
    assert_equal Date.new(1959, 12, 31), date_parser.end_date
    assert_equal '1959', date_parser.text
  end

  test 'Parses a single date correctly' do
    date_parser = UnitDate.new('1. 1. 1920', '1920-01-01')

    refute date_parser.range?
    assert_equal Date.new(1920, 1, 1), date_parser.start_date
    assert_equal Date.new(1920, 1, 1), date_parser.end_date
  end

  test 'Fails gracefully when the date is not parseable' do
    date_parser = UnitDate.new('Kein Datum', '')

    refute date_parser.range?
    assert_nil date_parser.start_date
    assert_nil date_parser.end_date
  end

  test 'Fails gracefully when normal is not present' do
    date_parser = UnitDate.new('Kein Datum', nil)

    refute date_parser.range?
    assert_nil date_parser.start_date
    assert_nil date_parser.end_date
  end
end

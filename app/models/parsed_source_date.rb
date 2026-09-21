# frozen_string_literal: true

# == Schema Information
#
# Table name: parsed_source_dates
#
#  id           :integer          not null, primary key
#  confidence   :float
#  end_date     :date
#  llm_model    :string
#  raw_response :text
#  source_text  :string           not null
#  start_date   :date
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_parsed_source_dates_on_source_text  (source_text) UNIQUE
#
class ParsedSourceDate < ApplicationRecord
  has_many :archive_files,
           foreign_key: :source_date_text,
           primary_key: :source_text,
           inverse_of: :parsed_source_date

  validates :source_text, presence: true, uniqueness: true

  scope :confident, ->(threshold = 0.8) { where(confidence: threshold..) }
  scope :matched, -> { where(llm_model: nil) }
  scope :from_llm, -> { where.not(llm_model: nil) }

  # A date of any precision: a year ("1943"), a month ("1943-05") or a day
  # ("1943-05-01"). Years are CE only, matching both the holdings and the year
  # field of the search form.
  PARTIAL_DATE = /\A(\d{1,4})(?:-(\d{1,2})(?:-(\d{1,2}))?)?\z/

  # Joins the separate year, month and day fields of the search form into a
  # partial date. Precision ends at the first blank field, so a month without a
  # day stands for the whole month and a blank year for no filter at all.
  def self.compose(year: nil, month: nil, day: nil)
    year, month, day = [year, month, day].map { |part| part.to_s.strip }
    return '' if year.blank?
    return year if month.blank?
    return format('%s-%02d', year, month.to_i) if day.blank?

    format('%s-%02d-%02d', year, month.to_i, day.to_i)
  end

  # Accepts a date of any precision and returns the earliest date it can stand
  # for. Blank or unparsable input returns nil.
  def self.start_boundary(value)
    boundary(value) { |year, month, day| Date.new(year, month || 1, day || 1) }
  end

  # Same as start_boundary, but returns the latest date the input can stand for,
  # so that a year filters up to its 31st of December and a month up to its last
  # day.
  def self.end_boundary(value)
    boundary(value) do |year, month, day|
      next Date.new(year, month, day) if day
      next Date.new(year, month, -1) if month

      Date.new(year, 12, 31)
    end
  end

  def self.boundary(value)
    value = value.to_s.strip
    return nil if value.blank?

    if (match = value.match(PARTIAL_DATE))
      return yield(*match.captures.map { |part| part&.to_i })
    end

    # Date.parse is lenient enough to read "-01-01" as the first of January of
    # the current year, so anything that does not start with a digit is out.
    return nil unless value.start_with?(/\d/)

    date = Date.parse(value)
    yield(date.year, date.month, date.day)
  rescue Date::Error
    nil
  end
  private_class_method :boundary

  def parsed?
    start_date.present?
  end

  def range?
    end_date.present? && end_date != start_date
  end
end

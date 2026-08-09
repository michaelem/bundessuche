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

  # Accepts a year ("1943") or a date ("1943-05-01") and returns the earliest
  # date it can stand for. Blank or unparsable input returns nil.
  def self.start_boundary(value)
    boundary(value) { |year| Date.new(year, 1, 1) }
  end

  # Same as start_boundary, but returns the latest date the input can stand for,
  # so that a year filters up to its 31st of December.
  def self.end_boundary(value)
    boundary(value) { |year| Date.new(year, 12, 31) }
  end

  def self.boundary(value)
    value = value.to_s.strip
    return nil if value.blank?
    return yield(value.to_i) if value.match?(/\A-?\d{1,4}\z/)

    Date.parse(value)
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

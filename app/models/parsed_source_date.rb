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

  def parsed?
    start_date.present?
  end

  def range?
    end_date.present? && end_date != start_date
  end
end

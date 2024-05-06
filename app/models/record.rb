class Record < ApplicationRecord
  has_many :originations
  has_many :origins, through: :originations

  def self.update_cached_all_count
    count = self.all.count
    CachedCount.find_or_create_by(model: self.name, scope: :all).update(
      count: count
    )
  end

  def self.cached_all_count
    CachedCount.find_by(model: self.name, scope: :all)&.count
  end

  def self.ilike_search(query)
    return Record.none if query.blank?

    query = "%#{query}%"
    Record
      .left_outer_joins(:origins)
      .where("lower(records.title) LIKE lower(?)", query)
      .or(Record.where("lower(records.summary) LIKE lower(?)", query))
      .or(Record.where("lower(origins.name) LIKE lower(?)", query))
      .order(:call_number)
  end

  def source_date_years
    if source_date_end.blank? || source_date_start.year == source_date_end.year
      return source_date_start.year.to_s
    end

    "#{source_date_start.year} - #{source_date_end.year}"
  end
end

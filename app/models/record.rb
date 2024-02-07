class Record < ApplicationRecord
  def self.update_cached_all_count
    count = self.all.count
    CachedCount.find_or_create_by(model: self.name, scope: :all).update(
      count: count
    )
  end

  def self.cached_all_count
    CachedCount.find_by(model: self.name, scope: :all)&.count
  end

  def self.fulltext_search(query)
    return Record.none if query.blank?

    Record.where(
      "to_tsvector('german', title || ' ' || call_number || ' ' || summary) @@ plainto_tsquery(?)",
      query
    ).order(:parents, :call_number)
  end

  def self.ilike_search(query)
    return Record.none if query.blank?

    query = "%#{query}%"
    Record.where("title ILIKE ? OR summary ILIKE ?", query, query).order(
      :call_number
    )
  end
end

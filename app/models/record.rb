class Record < ApplicationRecord
  has_many :originations
  has_many :origins, through: :originations

  scope :search,
        ->(query) do
          return none if query.blank?

          sql = <<~SQL.strip
            SELECT record_id FROM records_trigram
            WHERE records_trigram = '#{query}';
          SQL
          ids = connection.execute(sql).map(&:values).flatten
          where(id: ids)
        end

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

  def update_trigram_index
    trigram_attrs = {
      record_id: attributes["id"],
      title: title,
      summary: summary,
      call_number: call_number,
      parents: parents.join(" "),
      origin_names: origins.pluck(:name).join(" ")
    }

    delete_statement =
      "DELETE FROM records_trigram WHERE record_id = #{attributes["id"]}"
    self.class.connection.execute(delete_statement)

    values = trigram_attrs.values.map { |v| Record.connection.quote(v) }
    sql_insert = <<~SQL.strip
      INSERT INTO records_trigram(#{trigram_attrs.keys.join(", ")}) VALUES(#{values.join(", ")});
    SQL
    self.class.connection.execute(sql_insert)
  end
end

class Record < ApplicationRecord
  has_many :originations
  has_many :origins, through: :originations

  has_one :record_trigram

  after_create :insert_trigram
  after_update :update_trigram
  after_destroy :delete_trigram

  def self.update_cached_all_count
    count = self.all.count
    CachedCount.find_or_create_by(model: self.name, scope: :all).update(
      count: count
    )
  end

  def self.cached_all_count
    CachedCount.find_by(model: self.name, scope: :all)&.count
  end

  def source_date_years
    if source_date_end.blank? || source_date_start.year == source_date_end.year
      return source_date_start.year.to_s
    end

    "#{source_date_start.year} - #{source_date_end.year}"
  end

  def insert_trigram
    trigram_attrs = {
      record_id: attributes["id"],
      title: title,
      summary: summary,
      call_number: call_number,
      parents: parents.join(" "),
      origin_names: origins.pluck(:name).join(" ")
    }

    values = trigram_attrs.values.map { |v| Record.connection.quote(v) }
    sql_insert = <<~SQL.strip
      INSERT INTO record_trigrams(#{trigram_attrs.keys.join(", ")}) VALUES(#{values.join(", ")});
    SQL
    self.class.connection.execute(sql_insert)
  end

  def delete_trigram
    delete_statement =
      "DELETE FROM record_trigrams WHERE record_id = #{attributes["id"]}"
    self.class.connection.execute(delete_statement)
  end

  def update_trigram
    # Not very efficient, but fine for now as this should basically never happen
    delete_trigram
    insert_trigram
  end
end

class Origin < ApplicationRecord
  enum :label, ["pre", "final", "organisational unit"]

  has_many :originations
  has_many :records, through: :originations
end

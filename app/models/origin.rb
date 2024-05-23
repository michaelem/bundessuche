# == Schema Information
#
# Table name: origins
#
#  id         :integer          not null, primary key
#  label      :integer          default("pre")
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_origins_on_label_and_name  (label,name) UNIQUE
#  index_origins_on_name            (name)
#
class Origin < ApplicationRecord
  enum :label, ["pre", "final", "organisational unit"]

  has_many :originations
  has_many :records, through: :originations
end

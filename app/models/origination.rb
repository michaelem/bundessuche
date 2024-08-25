# == Schema Information
#
# Table name: originations
#
#  origin_id :integer
#  record_id :integer
#
# Indexes
#
#  index_originations_on_origin_id                (origin_id)
#  index_originations_on_record_id                (record_id)
#  index_originations_on_record_id_and_origin_id  (record_id,origin_id) UNIQUE
#
class Origination < ApplicationRecord
  belongs_to :archive_file, foreign_key: :record_id
  belongs_to :origin
end

# == Schema Information
#
# Table name: originations
#
#  origin_id :bigint
#  record_id :bigint
#
# Indexes
#
#  index_originations_on_origin_id                (origin_id)
#  index_originations_on_record_id                (record_id)
#  index_originations_on_record_id_and_origin_id  (record_id,origin_id) UNIQUE
#
class Origination < ApplicationRecord
  belongs_to :record
  belongs_to :origin
end

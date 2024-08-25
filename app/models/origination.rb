# == Schema Information
#
# Table name: originations
#
#  archive_file_id :integer
#  origin_id       :integer
#
# Indexes
#
#  index_originations_on_archive_file_id                (archive_file_id)
#  index_originations_on_archive_file_id_and_origin_id  (archive_file_id,origin_id) UNIQUE
#  index_originations_on_origin_id                      (origin_id)
#
class Origination < ApplicationRecord
  belongs_to :archive_file
  belongs_to :origin
end

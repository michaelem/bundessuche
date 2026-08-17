# == Schema Information
#
# Table name: archive_locations
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_archive_locations_on_name  (name) UNIQUE
#
class ArchiveLocation < ApplicationRecord
  has_many :archive_files
end

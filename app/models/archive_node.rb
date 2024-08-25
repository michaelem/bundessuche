# == Schema Information
#
# Table name: archive_nodes
#
#  id             :integer          not null, primary key
#  name           :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  parent_node_id :integer
#  source_id      :string
#
# Indexes
#
#  index_archive_nodes_on_parent_node_id  (parent_node_id)
#  index_archive_nodes_on_source_id       (source_id)
#
class ArchiveNode < ApplicationRecord
  belongs_to :parent_node, class_name: 'ArchiveNode'

  has_many :child_nodes, class_name: 'ArchiveNode', foreign_key: 'parent_node_id'
  has_many :archive_files
end

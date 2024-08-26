# == Schema Information
#
# Table name: archive_nodes
#
#  id             :integer          not null, primary key
#  level          :string
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
  belongs_to :parent_node, class_name: 'ArchiveNode', optional: true

  has_many :child_nodes, class_name: 'ArchiveNode', foreign_key: 'parent_node_id'
  has_many :archive_files

  def parents
    next_node = self
    parents = []

    while next_node.parent_node.present?
      parents << next_node.parent_node
      next_node = next_node.parent_node
    end

    parents.reverse
  end

end

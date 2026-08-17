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
  include NameTrigramIndexed

  belongs_to :parent_node, class_name: 'ArchiveNode', optional: true

  has_many :child_nodes, class_name: 'ArchiveNode', foreign_key: 'parent_node_id'
  has_many :archive_files

  # The ancestor chain of every given node, root first and including the node
  # itself, as { node_id => [ArchiveNode, ...] }.
  #
  # This walks the whole tree in one recursive query rather than one query per
  # level, which matters because a page of search results asks for five hundred
  # chains at once.
  def self.ancestor_chains(node_ids)
    ids = Array(node_ids).compact.uniq
    return {} if ids.empty?

    rows =
      connection.select_all(
        sanitize_sql_array(
          [
            <<~SQL.squish,
              WITH RECURSIVE chain(start_id, id, depth) AS (
                SELECT id, id, 0 FROM archive_nodes WHERE id IN (?)
                UNION ALL
                SELECT c.start_id, n.parent_node_id, c.depth + 1
                FROM archive_nodes n JOIN chain c ON n.id = c.id
                WHERE n.parent_node_id IS NOT NULL
              )
              SELECT start_id, id, depth FROM chain
            SQL
            ids
          ]
        )
      )

    nodes = where(id: rows.map { |row| row["id"] }.uniq).index_by(&:id)

    rows
      .group_by { |row| row["start_id"] }
      .transform_values do |group|
        # Deepest last: depth counts upwards from the node, so reversing it puts
        # the root in front.
        group.sort_by { |row| -row["depth"] }.filter_map { |row| nodes[row["id"]] }
      end
  end

  def parents
    self.class.ancestor_chains(id).fetch(id, [])
  end

end

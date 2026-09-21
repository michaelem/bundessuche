# frozen_string_literal: true

require 'test_helper'

class ArchiveNodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @root = ArchiveNode.create!(name: 'Bundesrechnungshof')
    @archive_node = ArchiveNode.create!(name: 'Prüfungsakten', parent_node: @root)
    @sibling = ArchiveNode.create!(name: 'Organisation', parent_node: @root)
    @archive_file = ArchiveFile.create!(
      archive_node: @archive_node,
      call_number: 'B 112/386',
      title: 'Haushaltsrechnung des Bundes',
      summary: 'Prüfung der Haushaltsrechnung'
    )
  end

  test 'the node page lists the files it holds' do
    get archive_node_path(@archive_node)

    assert_response :success
    assert_select '.result__title', text: /#{@archive_file.call_number}.*#{@archive_file.title}/
    assert_includes response.body, @archive_file.summary
  end

  test 'the node page offers the way through the tree around it' do
    get archive_node_path(@archive_node)

    assert_response :success
    assert_select %(a[href="#{archive_node_path(@root)}"]), text: @root.name
    assert_select %(a[href="#{archive_node_path(@sibling)}"]), text: @sibling.name
    # The node being shown is the one marked as selected among its siblings.
    assert_select '.archive-node--selected a', text: @archive_node.name
  end
end

class ArchiveNodesController < ApplicationController
  def show
    @archive_node = ArchiveNode.find(params[:id])
  end
end

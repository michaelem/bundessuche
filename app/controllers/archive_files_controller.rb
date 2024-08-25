class ArchiveFilesController < ApplicationController
  def show
    @archive_file = ArchiveFile.find(params[:id])
    respond_to do |format|
      format.ris { render ris: @archive_file }
    end
  end
end

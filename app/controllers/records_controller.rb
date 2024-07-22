class RecordsController < ApplicationController
  def show
    @record = Record.find(params[:id])
    respond_to do |format|
      format.ris { render ris: @record }
    end
  end
end

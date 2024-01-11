class SearchController < ApplicationController
  def index
    @total = Record.cached_all_count
    @query = params[:q]

    @results = @query.present? ? lookup(@query) : Record.none
    @results_count = @results.count

    @results = @results.page(params[:page]).per(500)
  end

  private

  def lookup(query)
    Record.where(
      "to_tsvector('german', title || ' ' || call_number || ' ' || summary) @@ plainto_tsquery(?)",
      query
    ).order(:call_number)
  end
end

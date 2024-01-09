class SearchController < ApplicationController
  def index
    @total = Record.cached_all_count
    @query = params[:q]

    @results = @query.present? ? lookup(@query) : []
    logger.info @results.inspect
  end

  private

  def lookup(query)
    Record.where(
      "to_tsvector('german', title || ' ' || call_number || ' ' || summary) @@ plainto_tsquery(?)",
      query
    )
  end
end

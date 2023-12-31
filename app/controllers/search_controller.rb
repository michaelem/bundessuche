class SearchController < ApplicationController
  def index
    @query = params[:q]

    @results = @query.present? ? lookup(@query) : []
    logger.info @results.inspect
  end

  private

  def lookup(query)
    Record.where(
      "to_tsvector('german', title || ' ' || call_number) @@ to_tsquery(?)",
      query
    )
  end
end

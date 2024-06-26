class SearchController < ApplicationController
  helper SearchHelper

  def index
    @total = Record.cached_all_count
    @query = params[:q]

    @trigrams =
      RecordTrigram
        .search(@query)
        .page(params[:page])
        .per(500)
        .includes(:record)

    @pagination_cache =
      Rails
        .cache
        .fetch(
          "controllers/search/pagination_cache_#{helpers.query_cache_key @query}"
        ) do
          {
            total_count: @trigrams.total_count,
            total_pages: @trigrams.total_pages
          }
        end
  end
end

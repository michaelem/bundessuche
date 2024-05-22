class SearchController < ApplicationController
  helper SearchHelper

  def index
    @total = Record.cached_all_count
    @query = params[:q]

    @records = Record.search(@query).page(params[:page]).per(500)
    @pagination_cache =
      Rails
        .cache
        .fetch(
          "controllers/search/ilike/pagination_cache_#{helpers.query_cache_key @query}"
        ) do
          {
            total_count: @records.total_count,
            total_pages: @records.total_pages
          }
        end
  end
end

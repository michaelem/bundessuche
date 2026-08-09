class SearchController < ApplicationController
  helper SearchHelper

  def index
    @total = ArchiveFile.cached_all_count
    @query = params[:q]
    @from = params[:from]
    @to = params[:to]

    @trigrams =
      ArchiveFileTrigram
        .search(@query)
        .source_dated_between(
          ParsedSourceDate.start_boundary(@from),
          ParsedSourceDate.end_boundary(@to)
        )
        .page(params[:page])
        .per(500)
        .includes(:archive_file)

    @pagination_cache =
      Rails
        .cache
        .fetch(
          "controllers/search/pagination_cache_#{helpers.query_cache_key @query, @from, @to}"
        ) do
          {
            total_count: @trigrams.total_count,
            total_pages: @trigrams.total_pages
          }
        end
  end
end

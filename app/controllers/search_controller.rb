class SearchController < ApplicationController
  helper SearchHelper

  def index
    @total = ArchiveFile.cached_all_count
    @query = params[:q]
    @from = date_parts(:from)
    @to = date_parts(:to)
    @from_value = ParsedSourceDate.compose(**@from)
    @to_value = ParsedSourceDate.compose(**@to)

    @trigrams =
      ArchiveFileTrigram
        .search(@query)
        .source_dated_between(
          ParsedSourceDate.start_boundary(@from_value),
          ParsedSourceDate.end_boundary(@to_value)
        )
        .page(params[:page])
        .per(500)
        .includes(:archive_file)

    @pagination_cache =
      Rails
        .cache
        .fetch(
          "controllers/search/pagination_cache_#{helpers.query_cache_key @query, @from_value, @to_value}"
        ) do
          {
            total_count: @trigrams.total_count,
            total_pages: @trigrams.total_pages
          }
        end
  end

  private

  # The date filters are split into a day, a month and a year field, each
  # submitted on its own, for example as "from_day".
  def date_parts(prefix)
    %i[day month year].index_with { |part| params[:"#{prefix}_#{part}"].presence }
  end
end

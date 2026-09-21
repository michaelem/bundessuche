# frozen_string_literal: true

class SearchController < ApplicationController
  helper SearchHelper

  def index
    @total = ArchiveFile.cached_all_count
    @query = params[:q]
    # A query with no piece long enough for the trigram index finds nothing, and
    # says so in its own words rather than claiming the archive holds no match.
    @query_too_short = @query.present? && !SearchQuery.new(@query).indexable?
    @from = date_parts(:from)
    @to = date_parts(:to)
    @from_value = ParsedSourceDate.compose(**@from)
    @to_value = ParsedSourceDate.compose(**@to)

    @archive_files =
      ArchiveFile
      .search(@query)
      .preload(:parsed_source_date)
      .source_dated_between(
        ParsedSourceDate.start_boundary(@from_value),
        ParsedSourceDate.end_boundary(@to_value)
      )
      .page(params[:page])
      .per(500)

    @pagination_cache =
      Rails
      .cache
      .fetch(
        "controllers/search/pagination_cache_#{helpers.query_cache_key @query, @from_value, @to_value}"
      ) do
        {
          total_count: @archive_files.total_count,
          total_pages: @archive_files.total_pages
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

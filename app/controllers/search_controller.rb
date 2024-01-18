class SearchController < ApplicationController
  def fulltext
    @total = Record.cached_all_count
    @query = params[:q]

    @results = @query.present? ? fulltext_search(@query) : Record.none
    @results_count = @results.count

    @results = @results.page(params[:page]).per(500)

    render :index
  end

  def index
    @total = Record.cached_all_count
    @query = params[:q]
    clause = "%#{@query}%"

    @results = @query.present? ? ilike_search(@query) : Record.none
    @results_count = @results.count

    @results = @results.page(params[:page]).per(500)
  end

  private

  def fulltext_search(query)
    Record.where(
      "to_tsvector('german', title || ' ' || call_number || ' ' || summary) @@ plainto_tsquery(?)",
      query
    ).order(:call_number)
  end

  def ilike_search(query)
    query = "%#{query}%"
    Record.where("title ILIKE ? OR summary ILIKE ?", query, query).order(
      :call_number
    )
  end
end

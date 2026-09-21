# frozen_string_literal: true

module SearchHelper
  # Filters are part of the key so that two searches for the same query but
  # different date ranges do not share a cache entry.
  def query_cache_key(query, *filters)
    parts = [query, *filters].map(&:to_s).join("\u0000")
    Digest::SHA512.hexdigest parts + Rails.application.config.cache_key_salt
  end
end

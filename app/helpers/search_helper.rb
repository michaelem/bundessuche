module SearchHelper
  def query_cache_key(query)
    query ||= ""
    Digest::SHA512.hexdigest query + Rails.application.config.cache_key_salt
  end
end

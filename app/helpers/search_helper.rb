module SearchHelper
  def query_cache_key(query)
    query ||= ""
    Digest::SHA512.hexdigest query + Rails.application.config.cache_key_salt
  end

  def highlight(query, text)
    return text if query.blank? || text.blank?
    text.gsub(
      /(#{query})/i,
      '<span class="result__highlight">\1</span>'
    ).html_safe
  end
end

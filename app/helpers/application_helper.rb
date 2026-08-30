module ApplicationHelper
  # The current page in another language: same path, same search and filters,
  # only the locale swapped. Built from the path rather than from url_for, so
  # that a query string cannot smuggle in a "controller" of its own.
  def language_url(locale)
    query = request.query_parameters.except("locale")
    query["locale"] = locale.to_s unless locale.to_s == I18n.default_locale.to_s

    query.empty? ? request.path : "#{request.path}?#{query.to_query}"
  end

  # Every language except the one being read right now.
  def other_locales
    I18n.available_locales - [I18n.locale]
  end
end

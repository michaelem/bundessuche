# frozen_string_literal: true

class ApplicationController < ActionController::Base
  around_action :switch_locale

  private

  def switch_locale(&action)
    I18n.with_locale(requested_locale, &action)
  end

  # Anything that is not a language we actually have falls back to the default
  # rather than raising, so a hand-edited "?locale=" cannot break the page.
  def requested_locale
    locale = params[:locale].to_s
    I18n.available_locales.map(&:to_s).include?(locale) ? locale : I18n.default_locale
  end

  # Carries the chosen language through every link and form on the page. German
  # is the default, so its URLs stay free of the parameter.
  def default_url_options
    return {} if I18n.locale == I18n.default_locale

    { locale: I18n.locale }
  end
end

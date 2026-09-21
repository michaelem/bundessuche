# frozen_string_literal: true

require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  test 'the imprint page renders its headings and contact details' do
    get imprint_path

    assert_response :success
    assert_select 'h2', text: I18n.t('imprint_title')
    assert_select 'h3', text: I18n.t('imprint_contact')
    assert_select %(a[href="mailto:info@bundessuche.de"]), text: 'info@bundessuche.de'
    assert_includes response.body, '+49 30 33897051'
  end
end

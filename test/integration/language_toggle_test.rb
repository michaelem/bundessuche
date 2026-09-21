require 'test_helper'

class LanguageToggleTest < ActionDispatch::IntegrationTest
  test 'pages are German by default and offer English' do
    get root_path

    assert_response :success
    assert_select %(html[lang="de"])
    assert_select '.footer__languages a', text: 'English'
  end

  test 'the locale parameter switches the page over' do
    get root_path, params: { locale: 'en' }

    assert_response :success
    assert_select %(html[lang="en"])
    assert_select 'h2', text: I18n.t('search_intro_title', locale: :en)
    assert_select '.footer__languages a', text: 'Deutsch'
  end

  test 'a locale we do not have falls back to German instead of raising' do
    get root_path, params: { locale: 'fr' }

    assert_response :success
    assert_select %(html[lang="de"])
  end

  test 'switching language keeps the search and its filters' do
    get root_path, params: { q: 'Chaussee', from_year: '1958', page: '1' }

    assert_response :success
    link = css_select('.footer__languages a').first
    target = link['href']

    assert_equal root_path, target.split('?').first
    query = Rack::Utils.parse_query(target.split('?').last)
    assert_equal 'Chaussee', query['q']
    assert_equal '1958', query['from_year']
    assert_equal '1', query['page']
    assert_equal 'en', query['locale']
  end

  test 'switching back to German drops the locale from the URL' do
    get root_path, params: { q: 'Chaussee', locale: 'en' }

    assert_response :success
    target = css_select('.footer__languages a').first['href']

    assert_equal 'q=Chaussee', target.split('?').last
  end

  test 'English links keep carrying the language' do
    get root_path, params: { locale: 'en' }

    assert_response :success
    assert_select %(footer a[href="#{imprint_path(locale: 'en')}"])
  end

  test 'the imprint reads in English too' do
    get imprint_path, params: { locale: 'en' }

    assert_response :success
    assert_select 'h2', text: I18n.t('imprint_title', locale: :en)
  end
end

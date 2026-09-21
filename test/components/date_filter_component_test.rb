require 'test_helper'

class DateFilterComponentTest < ViewComponent::TestCase
  def test_render_names_every_field_after_its_half_of_the_filter
    render_inline(component(prefix: 'from'))

    assert_selector "input#from_day[name='from_day']"
    assert_selector "input#from_month[name='from_month']"
    assert_selector "input#from_year[name='from_year']"
  end

  def test_render_carries_the_values_the_reader_typed
    render_inline(component(parts: { day: 24, month: 1, year: 1984 }))

    assert_selector "input#to_day[value='24']"
    assert_selector "input#to_month[value='1']"
    assert_selector "input#to_year[value='1984']"
  end

  def test_render_gives_every_part_its_own_modifier_and_width
    render_inline(component)

    assert_selector "input.search__date-input.search__date-input--day[maxlength='2']"
    assert_selector "input.search__date-input.search__date-input--month[maxlength='2']"
    assert_selector "input.search__date-input.search__date-input--year[maxlength='4']"
  end

  def test_render_separates_the_parts_but_does_not_lead_with_a_separator
    render_inline(component)

    assert_selector '.search__date-separator', count: 2
  end

  def test_render_labels_every_part_for_a_screen_reader
    render_inline(component)

    assert_selector "label.visually-hidden[for='to_day']", text: 'Tag'
    assert_selector "input#to_day[title='Tag als Zahl von 1 bis 31']"
    assert_selector "input#to_day[placeholder='TT']"
  end

  private

  def component(prefix: 'to', legend: 'To:', parts: {})
    DateFilterComponent.new(prefix: prefix, legend: legend, parts: parts)
  end
end

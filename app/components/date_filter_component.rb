class DateFilterComponent < ViewComponent::Base
  # Every part of the date brings its own validation, its own width and its own
  # modifier. The modifiers are written out in full rather than built from the
  # part name, so that a class found in the stylesheet can be found here too.
  PARTS = [
    { name: :day, modifier: "search__date-input--day",
      pattern: "0?[1-9]|[12][0-9]|3[01]", maxlength: 2 },
    { name: :month, modifier: "search__date-input--month",
      pattern: "0?[1-9]|1[0-2]", maxlength: 2 },
    { name: :year, modifier: "search__date-input--year",
      pattern: "[0-9]{1,4}", maxlength: 4 }
  ].freeze

  # parts holds the values the reader typed, keyed the same way as PARTS.
  def initialize(prefix:, legend:, parts:)
    @prefix = prefix
    @legend = legend
    @parts = parts
  end

  # Both halves of the filter render at once, so every field is named after the
  # half it belongs to: from_day and to_day rather than two fields called day.
  def field_id(part)
    "#{@prefix}_#{part[:name]}"
  end

  def value(part)
    @parts[part[:name]]
  end

  def label(part)
    t("search_date_#{part[:name]}")
  end

  def placeholder(part)
    t("search_date_#{part[:name]}_placeholder")
  end

  def hint(part)
    t("search_date_#{part[:name]}_hint")
  end
end

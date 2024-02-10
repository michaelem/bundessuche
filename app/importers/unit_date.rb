class UnitDate
  def initialize(node)
    @normal = node.attr("normal")
    @start_string, @end_string = @normal.split("/")

    begin
      @start_date = Date.iso8601(@start_string)
      @end_date = Date.iso8601(@end_string) if @end_string.present?
    rescue Date::Error
      @start_date = nil
    end
  end

  attr_reader :start_date, :end_date

  def range?
    @end_date.present?
  end

  def end_date
    @end_date || @start_date
  end
end

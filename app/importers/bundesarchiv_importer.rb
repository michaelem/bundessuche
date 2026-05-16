class BundesarchivSaxHandler < Nokogiri::XML::SAX::Document
  BATCH_SIZE = 1000

  def initialize(origins_cache)
    @origins_cache = origins_cache
    @total_count = 0
    @element_stack = []
    @node_stack = []
    @skip = false
    @current_file = nil
    @text_buffer = ""
    @current_unitdate_normal = nil
    @current_origination_label = nil
    @in_summary_scopecontent = false
    @batch = []
  end

  attr_reader :total_count

  def start_element(name, attrs = [])
    name = strip_ns(name)
    attrs_hash = normalize_attrs(attrs)
    @element_stack.push([name, attrs_hash])
    @text_buffer = ""
    return if @skip

    case name
    when "archdesc"    then @skip = attrs_hash["type"] != "inventory"
    when "c"           then start_c(attrs_hash)
    when "origination" then @current_origination_label = attrs_hash["label"] if in_file?
    when "unitdate"    then @current_unitdate_normal = attrs_hash["normal"] if in_file?
    when "scopecontent" then @in_summary_scopecontent = attrs_hash["encodinganalog"] == "summary"
    when "language"
      @current_file[:language_code] = attrs_hash["langcode"] if in_file? && parent_element == "langmaterial"
    when "extref"
      if in_file? && parent_element == "p" && grandparent_element == "otherfindaid"
        @current_file[:link] = attrs_hash["href"]
      end
    end
  end

  def characters(string)
    @text_buffer += string unless @skip
  end

  def end_element(name)
    name = strip_ns(name)

    if @skip
      @element_stack.pop
      @text_buffer = ""
      @skip = false if name == "archdesc"
      return
    end

    case name
    when "archdesc"    then flush_batch
    when "c"           then end_c
    when "did"         then ensure_node_record if parent_element == "c" && !in_file?
    when "unittitle"   then end_unittitle if in_did?
    when "unitid"      then end_unitid if in_file? && in_did?
    when "unitdate"    then end_unitdate if in_file? && in_did?
    when "origination" then end_origination if in_file? && in_did?
    when "physloc"     then @current_file[:location] = @text_buffer if in_file? && in_did?
    when "p"           then @current_file[:summary] = (@current_file[:summary] || "") + @text_buffer if in_file? && @in_summary_scopecontent
    when "scopecontent" then @in_summary_scopecontent = false
    end

    @element_stack.pop
    @text_buffer = ""
  end

  private

  def strip_ns(name)
    name.split(":").last
  end

  def normalize_attrs(attrs)
    attrs.to_h.transform_keys { |k| k.split(":").last }
  end

  def in_file?
    !@current_file.nil?
  end

  def in_did?
    parent_element == "did"
  end

  def parent_element
    @element_stack[-2]&.[](0)
  end

  def grandparent_element
    @element_stack[-3]&.[](0)
  end

  def current_attrs
    @element_stack.last&.[](1) || {}
  end

  def start_c(attrs_hash)
    level = attrs_hash["level"]
    source_id = attrs_hash["id"]
    if level == "file"
      @current_file = new_file_entry(source_id, @node_stack.last&.dig(:record))
    else
      @node_stack.push({ source_id: source_id, level: level, record: nil })
    end
  end

  def new_file_entry(source_id, parent)
    {
      source_id: source_id,
      archive_node_id: parent&.id,
      parents: @node_stack.filter_map { |n| r = n[:record]; r && { name: r.name, id: r.id } },
      title: nil,
      call_number: nil,
      source_date_text: nil,
      source_date_start: nil,
      source_date_end: nil,
      link: nil,
      location: nil,
      language_code: nil,
      summary: nil,
      origins: []
    }
  end

  def end_c
    if in_file?
      @batch << @current_file
      @current_file = nil
      @in_summary_scopecontent = false
      flush_batch if @batch.size >= BATCH_SIZE
    else
      ensure_node_record
      @node_stack.pop
    end
  end

  def end_unittitle
    if in_file?
      @current_file[:title] = @text_buffer
    elsif (pending = @node_stack.last) && pending[:record].nil?
      pending[:record] = ArchiveNode.find_or_create_by(
        name: @text_buffer,
        source_id: pending[:source_id],
        level: pending[:level],
        parent_node: @node_stack[-2]&.dig(:record)
      )
    end
  end

  def end_unitid
    @current_file[:call_number] = @text_buffer.sub(/\ABArch /, "") if current_attrs["type"] == "call number"
  end

  def end_unitdate
    date = UnitDate.new(@text_buffer, @current_unitdate_normal)
    @current_file[:source_date_text] = date.text
    @current_file[:source_date_start] = date.start_date
    @current_file[:source_date_end] = date.end_date
    @current_unitdate_normal = nil
  end

  def end_origination
    label = @current_origination_label
    @current_file[:origins] << (
      @origins_cache[[@text_buffer, label]] ||=
        Origin.find_or_create_by(name: @text_buffer, label: label)
    )
    @current_origination_label = nil
  end

  def ensure_node_record
    pending = @node_stack.last
    return unless pending && pending[:record].nil?
    pending[:record] = ArchiveNode.find_or_create_by(
      name: "",
      source_id: pending[:source_id],
      level: pending[:level],
      parent_node: @node_stack[-2]&.dig(:record)
    )
  end

  def flush_batch
    return if @batch.empty?
    ActiveRecord::Base.transaction do
      archive_files =
        ArchiveFile.upsert_all(
          @batch.map { |d| d.except(:origins) },
          unique_by: :source_id,
          returning: :id
        )
      origination_data =
        @batch
          .zip(archive_files)
          .flat_map { |d, r| d[:origins].map { |o| { archive_file_id: r["id"], origin_id: o.id } } }
      Origination.upsert_all(origination_data, unique_by: %i[archive_file_id origin_id]) if origination_data.any?
    end
    @total_count += @batch.size
    @batch = []
  end
end

class BundesarchivImporter
  def initialize(dir)
    @dir = dir || "data"
  end

  def run(show_progress: false)
    puts "Importing data from XML files in #{@dir}..." if show_progress
    start = Time.now
    archive_file_count = 0
    origins_cache = {}

    xml_files = Dir.glob("*.xml", base: @dir).sort
    total = xml_files.count
    if show_progress
      progress_bar =
        ProgressBar.create(
          title: "Importing",
          total: total,
          format: "%t %p%% %a %e |%B|"
        )
    end

    xml_files.each_with_index do |filename, index|
      path = File.join(@dir, filename)
      progress_bar.log("Now reading: #{filename} (#{index + 1} of #{total})") if show_progress

      handler = BundesarchivSaxHandler.new(origins_cache)
      Nokogiri::XML::SAX::Parser.new(handler).parse_file(path)
      archive_file_count += handler.total_count

      progress_bar.increment if show_progress
    end

    ArchiveFile.update_cached_all_count

    if show_progress
      puts "Finished. Imported #{archive_file_count} archive files in #{Time.now - start} seconds."
    end
  end
end

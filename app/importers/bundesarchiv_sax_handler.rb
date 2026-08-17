class BundesarchivSaxHandler < Nokogiri::XML::SAX::Document
  BATCH_SIZE = 1000

  def initialize(origins_cache)
    @origins_cache = origins_cache
    @total_count = 0
    @element_stack = []
    @node_stack = []
    @skip = false
    @current_file = nil
    @text_stack = []
    @current_unitdate_normal = nil
    @current_unitid_type = nil
    @current_origination_label = nil
    @in_summary_scopecontent = false
    @batch = []
  end

  attr_reader :total_count

  def start_element_namespace(name, attrs = [], prefix = nil, uri = nil, ns = [])
    attrs_hash = attrs.to_h { |a| [a.localname, a.value] }
    @element_stack.push([name, attrs_hash])
    @text_stack.push(String.new)
    return if @skip

    case name
    when "archdesc"
      @skip = attrs_hash["type"] != "inventory"
    when "c"
      start_c(attrs_hash)
    when "origination"
      @current_origination_label = attrs_hash["label"] if in_file?
    when "unitdate"
      @current_unitdate_normal = attrs_hash["normal"] if in_file?
    when "unitid"
      @current_unitid_type = attrs_hash["type"] if in_file?
    when "scopecontent"
      @in_summary_scopecontent = attrs_hash["encodinganalog"] == "summary"
    when "language"
      @current_file[:language_code] = attrs_hash["langcode"] if in_file? &&
        parent_element == "langmaterial"
    when "extref"
      if in_file? && parent_element == "p" &&
           grandparent_element == "otherfindaid"
        @current_file[:link] = attrs_hash["href"]
      end
    end
  end

  def characters(string)
    @text_stack.last&.concat(string) unless @skip
  end

  def end_element_namespace(name, prefix = nil, uri = nil)
    if @skip
      @element_stack.pop
      @text_stack.pop
      @skip = false if name == "archdesc"
      return
    end

    text = @text_stack.pop || ""
    @text_stack.last&.concat(text)

    case name
    when "archdesc"
      flush_batch
    when "c"
      end_c
    when "did"
      ensure_node_record if parent_element == "c" && !in_file?
    when "unittitle"
      end_unittitle(text) if in_did?
    when "unitid"
      end_unitid(text) if in_file? && in_did?
    when "unitdate"
      end_unitdate(text) if in_file? && in_did?
    when "origination"
      end_origination(text) if in_file? && in_did?
    when "physloc"
      @current_file[:archive_location_id] = archive_location_id(text) if in_file? && in_did?
    when "p"
      @current_file[:summary] = (@current_file[:summary] || "") +
        text if in_file? && @in_summary_scopecontent
    when "scopecontent"
      @in_summary_scopecontent = false
    end

    @element_stack.pop
  end

  private

  # There are only a handful of archive locations across the whole dataset, so
  # they are looked up once and then served from memory.
  def archive_location_id(name)
    return nil if name.blank?

    @archive_locations_cache ||= {}
    @archive_locations_cache[name] ||=
      ArchiveLocation.find_or_create_by!(name: name).id
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
      title: nil,
      call_number: nil,
      source_date_text: nil,
      source_date_start: nil,
      source_date_end: nil,
      link: nil,
      archive_location_id: nil,
      language_code: nil,
      summary: nil,
      origins: []
    }
  end

  def end_c
    if in_file?
      @batch << @current_file
      @current_file = nil
      flush_batch if @batch.size >= BATCH_SIZE
    else
      ensure_node_record
      @node_stack.pop
    end
  end

  def end_unittitle(text)
    if in_file?
      @current_file[:title] = text
    elsif (pending = @node_stack.last) && pending[:record].nil?
      pending[:record] = ArchiveNode.find_or_create_by(
        name: text,
        source_id: pending[:source_id],
        level: pending[:level],
        parent_node: @node_stack[-2]&.dig(:record)
      )
    end
  end

  def end_unitid(text)
    @current_file[:call_number] = text.sub(
      /\ABArch /,
      ""
    ) if @current_unitid_type == "call number"
    @current_unitid_type = nil
  end

  def end_unitdate(text)
    date = UnitDate.new(text, @current_unitdate_normal)
    @current_file[:source_date_text] = date.text
    @current_file[:source_date_start] = date.start_date
    @current_file[:source_date_end] = date.end_date
    @current_unitdate_normal = nil
  end

  def end_origination(text)
    label = @current_origination_label
    @current_file[:origins] << (
      @origins_cache[[text, label]] ||= Origin.find_or_create_by(
        name: text,
        label: label
      )
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
          .flat_map do |d, r|
            d[:origins].map do |o|
              { archive_file_id: r["id"], origin_id: o.id }
            end
          end
      if origination_data.any?
        Origination.upsert_all(
          origination_data,
          unique_by: %i[archive_file_id origin_id]
        )
      end
    end
    @total_count += @batch.size
    @batch = []
  end
end

class ArchiveObject
  def initialize(parents, node)
    @parents = parents
    @node = node
  end

  def process_files
    record_count = 0

    @node
      .xpath("c[@level='file']")
      .each_slice(1000) do |slice|
        data =
          slice.map do |node|
            date = UnitDate.new(node.xpath("did/unitdate").first)
            {
              title: node.xpath("did/unittitle").text,
              parents: @parents,
              call_number: node.xpath('did/unitid[@type="call number"]').text,
              source_date_text: date.text,
              source_date_start: date.start_date,
              source_date_end: date.end_date,
              source_id: node.attr("id"),
              link: node.xpath("otherfindaid/p/extref")[0]&.attr("href"),
              location: node.xpath("did/physloc").text,
              language_code:
                node.xpath("did/langmaterial/language")[0]&.attr("langcode"),
              summary:
                node.xpath('scopecontent[@encodinganalog="summary"]/p').text
            }
          end
        Record.upsert_all(data, unique_by: :source_id)
        record_count += data.count
      end

    return record_count
  end

  def descend
    @node
      .xpath("c[@level!='file']")
      .map do |node|
        descendent =
          ArchiveObject.new(@parents + [node.xpath("did/unittitle").text], node)
        descendent.descend + descendent.process_files
      end
      .sum
  end
end

class BundesarchivImporter
  def initialize(dir)
    @dir = dir || "data"
  end

  def run(show_progress: false)
    puts "Importing data from XML files in #{@dir}..." if show_progress
    start = Time.now
    record_count = 0

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
      doc = File.open(path) { |file| Nokogiri.XML(file) }

      # I can't figure out how these work in the documents I have, so out they go:
      doc.remove_namespaces!

      if show_progress
        progress_bar.log "Now reading: #{filename} (#{index + 1} of #{total})"
      end

      archive_description = doc.xpath("/ead/archdesc")

      if (archive_description.attr("type").value != "inventory")
        if show_progress
          puts "Skipping #{filename} because it's not an inventory"
        end
        next
      end

      record_count +=
        archive_description
          .xpath("//c[@level='fonds']")
          .map do |fond|
            object = ArchiveObject.new([fond.xpath("did/unittitle").text], fond)
            object.descend + object.process_files
          end
          .sum

      progress_bar.increment if show_progress
    end

    Record.update_cached_all_count

    if show_progress
      puts "Finished. Imported #{record_count} records in #{Time.now - start} seconds."
    end
  end
end

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
            {
              title: node.xpath("did/unittitle").text,
              parents: @parents,
              call_number: node.xpath('did/unitid[@type="call number"]').text,
              source_date: node.xpath("did/unitdate").text,
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

  def run
    puts "Importing data from XML files in #{@dir}..."
    start = Time.now
    record_count = 0

    xml_files = Dir.glob("*.xml", base: @dir).sort
    total = xml_files.count
    progress_bar =
      ProgressBar.create(
        title: "Importing",
        total: total,
        format: "%t %p%% %a %e |%B|"
      )

    xml_files.each_with_index do |filename, index|
      path = File.join(@dir, filename)
      doc = File.open(path) { |file| Nokogiri.XML(file) }

      # I can't figure out how these work in the documents I have, so out they go:
      doc.remove_namespaces!

      progress_bar.log "Now reading: #{filename} (#{index + 1} of #{total})"

      record_count +=
        doc
          .xpath("//c[@level='fonds']")
          .map do |fond|
            object = ArchiveObject.new([fond.xpath("did/unittitle").text], fond)
            object.descend + object.process_files
          end
          .sum

      progress_bar.increment
    end

    Record.update_cached_all_count

    puts "Finished. Imported #{record_count} records in #{Time.now - start} seconds."
  end
end

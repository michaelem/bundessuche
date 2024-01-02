namespace :data do
  desc "Import data from XML files"
  task import: :environment do
    puts "Importing data from CSV files..."
    DIR = "data"
    start = Time.now
    record_count = 0

    xml_files = Dir.glob("*.xml", base: DIR).sort
    total = xml_files.count
    progress_bar =
      ProgressBar.create(
        title: "Importing",
        total: total,
        format: "%t %p%% %a %e |%B|"
      )

    xml_files.each_with_index do |filename, index|
      path = File.join(DIR, filename)
      doc = File.open(path) { |file| Nokogiri.XML(file) }

      # I can't figure out how these work in the documents I have, so out they go:
      doc.remove_namespaces!

      progress_bar.log "Now reading: #{filename} (#{index + 1} of #{total})"
      doc
        .xpath("//c[@level='file']")
        .each_slice(1000) do |slice|
          data =
            slice.map do |node|
              {
                title: node.xpath("did/unittitle").text,
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

      progress_bar.increment
    end

    puts "Finished. Imported #{record_count} records in #{Time.now - start} seconds."
  end
end

RecordData = Struct.new(:title, :call_number, :source_date, :source_id)

namespace :data do
  desc "Import data from XML files"
  task import: :environment do
    puts "Importing data from CSV files..."
    DIR = "data"
    start = Time.now
    record_count = 0

    xml_files = Dir.glob("*.xml", base: DIR)
    total = xml_files.count

    xml_files.each_with_index do |filename, index|
      path = File.join(DIR, filename)
      doc = File.open(path) { |file| Nokogiri.XML(file) }

      # I can't figure out how these work in the documents I have, so out they go:
      doc.remove_namespaces!

      puts "Now reading: #{filename} (#{index + 1} of #{total}))"
      doc
        .xpath("//c[@level='file']")
        .each do |node|
          data =
            RecordData.new(
              node.xpath("did/unittitle").text,
              node.xpath('did/unitid[@type="call number"]').text,
              node.xpath("did/unitdate").text,
              node.attr("id")
            )

          Record.upsert(
            {
              title: data.title,
              call_number: data.call_number,
              source_date: data.source_date,
              source_id: data.source_id
            },
            unique_by: :source_id
          )

          record_count += 1
        end
    end

    puts "Finished. Imported #{record_count} records in #{Time.now - start} seconds."
  end
end

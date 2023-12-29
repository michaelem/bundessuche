namespace :import_data do
  desc "Import data from XML files"
  task :run => :environment do
    puts "Importing data from CSV files..."
    DIR = "data"
    
    xml_files = Dir.glob('*.xml', base: DIR)
    total = xml_files.count

    xml_files.each_with_index do |filename, index|
      path = File.join(DIR, filename)
      doc = File.open(path) { |file| Nokogiri::XML(file) }
      
      # I can't figure out how these work in the documents I have, so out they go:
      doc.remove_namespaces!

      puts "Now processing: #{filename} (#{index} of #{total}))"
      doc.xpath("//c[@level='file']").each do |node|
        r = Record.create(
          title: node.xpath('did/unittitle').text,
          call_number: node.xpath('did/unitid[@type="call number"]').text,
          source_date: node.xpath('did/unitdate').text,
          source_id: node.attr('id')
        )
      end
    end

  end
end

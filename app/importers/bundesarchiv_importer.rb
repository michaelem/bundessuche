# frozen_string_literal: true

class BundesarchivImporter
  def initialize(dir)
    @dir = dir || 'data'
  end

  def run(show_progress: false)
    puts "Importing data from XML files in #{@dir}..." if show_progress
    start = Time.now
    archive_file_count = 0
    origins_cache = {}

    xml_files = Dir.glob('*.xml', base: @dir).sort
    total = xml_files.count
    if show_progress
      progress_bar =
        ProgressBar.create(
          title: 'Importing',
          total: total,
          format: '%t %p%% %a %e |%B|'
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

    return unless show_progress

    puts "Finished. Imported #{archive_file_count} archive files in #{Time.now - start} seconds."
  end
end

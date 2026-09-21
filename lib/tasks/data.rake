# frozen_string_literal: true

namespace :data do
  desc 'Import data from XML files'
  task :import, [:dir] => [:environment] do |_task, args|
    BundesarchivImporter.new(args[:dir]).run(show_progress: true)
  end

  desc 'Recreate search index'
  task reindex: [:environment] do
    ArchiveFile.reindex(show_progress: true)
  end
end

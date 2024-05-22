namespace :data do
  desc "Import data from XML files"
  task :import, [:dir] => [:environment] do |task, args|
    BundesarchivImporter.new(args[:dir]).run(show_progress: true)
  end

  desc "Recreate search index"
  task reindex: [:environment] do
    Record.reindex
  end
end

namespace :data do
  desc "Import data from XML files"
  task :import, [:dir] => [:environment] do |task, args|
    BundesarchivImporter.new(args[:dir]).run
  end
end

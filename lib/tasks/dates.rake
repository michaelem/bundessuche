namespace :dates do
  desc "Parse source_date_text into date ranges using a local LLM"
  task :parse, [:limit] => [:environment] do |task, args|
    SourceDateBackfill.new(limit: args[:limit]&.to_i).run(show_progress: true)
  end
end

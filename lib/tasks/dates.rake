# frozen_string_literal: true

namespace :dates do
  desc 'Parse source_date_text into date ranges using a local LLM'
  task :parse, [:limit] => [:environment] do |_task, args|
    SourceDateBackfill.new(limit: args[:limit]&.to_i).run(show_progress: true)
  end

  desc 'Score Ollama models on parsing source date texts, e.g. dates:benchmark[30] MODELS=a,b'
  task :benchmark, [:sample_size] => [:environment] do |_task, args|
    sample_size = (args[:sample_size] || 30).to_i
    models = ENV.fetch('MODELS', SourceDateParser::DEFAULT_MODEL).split(',')

    matched = SourceDateBenchmark.matched_captions(size: sample_size)
    hedged = SourceDateBenchmark::HEDGED
    summaries = {}

    models.each do |model|
      puts "\n#{model}"

      summaries[model] = { matched: matched, hedged: hedged }.transform_values do |captions|
        print "  #{captions.size} captions "
        rows = SourceDateBenchmark.new(model: model, captions: captions).run(show_progress: true)
        puts

        rows.reject { |row| row[:correct] }.each do |row|
          puts "    #{row[:caption].inspect}: expected #{row[:expected].join('..')}, got #{row[:actual].join('..')}"
        end

        SourceDateBenchmark.summarize(rows)
      end
    end

    puts format("\n%-28s %-8s %9s %9s %6s %9s", 'model', 'set', 'accuracy', 'correct', 'json', 's/caption')
    summaries.each do |model, sets|
      sets.each do |set, summary|
        puts format('%-28s %-8s %8.1f%% %5d/%-3d %3d/%-2d %9.1f', model, set, summary[:accuracy], summary[:correct],
                    summary[:captions], summary[:json], summary[:captions], summary[:seconds_per_caption])
      end
    end
  end
end

source "https://rubygems.org"

ruby file: ".ruby-version"

# Framework
gem "rails", "~> 8.1.0"
gem "puma", "~> 8.0"
gem "reactionview", "~> 0.4.1"

# Assets
gem "importmap-rails"
gem "propshaft"

# Database
gem "sqlite3" # Use SQLite for production

gem "ruby_llm" # Talk to the local Ollama server when parsing source date texts
gem "ruby_llm-schema" # Structured output schemas for ruby_llm
gem "bootsnap", require: false # Reduces boot times through caching; required in config/boot.rb
gem "kaminari" # Pagination
gem "progressbar" # Used in the import task
gem "view_component" # Reusable view components
gem "cgi"
gem "tsort"

group :development, :test do
  gem "debug", ">= 1.0.0"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  gem "rack-mini-profiler"
  gem "stackprof"
  gem "memory_profiler"

  # Linters and annotations
  gem "annotaterb"
  gem "syntax_tree"
  gem "htmlbeautifier"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "minitest-mock"
  gem "simplecov", require: false
end

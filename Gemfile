# frozen_string_literal: true

source 'https://rubygems.org'

ruby file: '.ruby-version'

# Framework
gem 'puma', '~> 8.0'
gem 'rails', '~> 8.1.0'
gem 'reactionview', '~> 0.4.1'

# Assets
gem 'importmap-rails'
gem 'propshaft'

# Database
gem 'sqlite3' # Use SQLite for production

gem 'bootsnap', require: false # Reduces boot times through caching; required in config/boot.rb
gem 'cgi'
gem 'kaminari' # Pagination
gem 'progressbar' # Used in the import task
gem 'ruby_llm' # Talk to the local Ollama server when parsing source date texts
gem 'ruby_llm-schema' # Structured output schemas for ruby_llm
gem 'view_component' # Reusable view components

group :development, :test do
  gem 'debug', '>= 1.0.0'
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  gem 'memory_profiler'
  gem 'rack-mini-profiler'
  gem 'stackprof'

  # Linters and annotations
  gem 'annotaterb'
  gem 'rubocop'
  gem 'rubocop-rails', require: false
  gem 'ruby-lsp'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'minitest-mock'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
end

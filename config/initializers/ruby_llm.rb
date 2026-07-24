RubyLLM.configure do |config|
  config.ollama_api_base = ENV.fetch("OLLAMA_API_BASE", "http://localhost:11434/v1")

  # We do not use the acts_as API, this only opts out of the deprecation warning for its
  # legacy version.
  config.use_new_acts_as = true
end

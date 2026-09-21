require 'net/http'

module Ngrok
  class Client
    def initialize(server_port)
      @tunnels = Client.tunnels
      @port = server_port
    end

    def public_urls
      @tunnels
        .select { |h| h.dig('config', 'addr') == "http://localhost:#{@port}" }
        .map { |h| URI(h['public_url']).hostname }
        .uniq
    end

    def self.tunnels
      response = Net::HTTP.get(URI('http://localhost:4040/api/tunnels'))
      JSON.parse(response).dig('tunnels')
    rescue Errno::ECONNREFUSED
      puts 'No Ngrok instance available on localhost:4040'
      []
    rescue JSON::ParserError
      puts 'Failed to parse reponse from Ngrok internal API.'
      []
    end
  end
end

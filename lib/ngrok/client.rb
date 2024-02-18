require "net/http"

module Ngrok
  class Client
    def initialize(server_port)
      @tunnels = Client.tunnels
      @port = server_port
    end

    def public_urls
      @tunnels
        .select { |h| h.dig("config", "addr") == "http://localhost:#{@port}" }
        .map { |h| URI(h["public_url"]).hostname }
        .uniq
    end

    private

    def self.tunnels
      begin
        response = Net::HTTP.get(URI("http://localhost:4040/api/tunnels"))
        JSON.parse(response).dig("tunnels")
      rescue Errno::ECONNREFUSED => e
        puts "No Ngrok instance available on localhost:4040"
        return []
      rescue JSON::ParserError => e
        puts "Failed to parse reponse from Ngrok internal API."
        return []
      end
    end
  end
end

require 'eventmachine'
require 'em-websocket'
require 'json'

require_relative 'GameManager'

module Handshake
  module Websocket
  
    class Server
      def self.run!(ip, port, debug)
        
        EventMachine::WebSocket.start(:host => ip, :port => port, :debug => debug) do |websocket|
          
          # handle connection requests
          websocket.onopen do
            request = websocket.request["Path"]
            
            # analyse request path to differentiate between games and controllers
            if(game = request.match(/game/))
              
            elsif(controller = request.match(/(\w*)\/connect\/([a-zA-Z0-9|-]*)/))
              game_id = connect[1]
              deviceType = connect[2]
              
              puts websocket.inspect()
            end
            
          end #end onopen
          
        end
        
        puts "Server started listening for connections on #{ip}:#{port}"
        
      end
    end
    
  end
end
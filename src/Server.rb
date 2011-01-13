require 'eventmachine'
require 'em-websocket'
require 'json'

require_relative 'GameManager'

module Handshake
  
  class Server
  
    @@domainKeys = { 'jf41j2k41adfae12j4o2j1p2' => 'localhost' }
    @@gameManager = Handshake::GameManager.new
    
    # starts the websocket server and forwards new connections
    # 
    
    def self.run!(ip, port, debug)
      EventMachine::WebSocket.start(:host => ip, :port => port, :debug => debug) do |websocket|
        websocket.onopen do
          handleConnect(websocket)
        end
      end
      puts "Server started listening for connections on #{ip}:#{port}"
    end
  
    def self.handleConnect(websocket)
      request = websocket.request
      if( (key = request["Path"].match(/(\w+)\//)[1]) && @@domainKeys[key] )
        if("http://#{@@domainKeys[key]}" == request["Origin"]) 
          @@gameManager.addGame(key, websocket)
        end
      end
    end
  
  end # end class

end

=begin      
      # analyse request path to differentiate between games and controllers
      if(game = request.match(/game/))
        puts "game connect"
      elsif(controller = request.match(/(\w*)\/connect\/([a-zA-Z0-9|-]*)/))
        game_id = connect[1]
        deviceType = connect[2]

        puts "controller connect"
        puts websocket.inspect()
      end
=end
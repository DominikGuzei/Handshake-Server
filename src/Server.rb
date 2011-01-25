require 'eventmachine'
require 'em-websocket'
require 'json'

require_relative 'GameManager'

module Handshake
  
  class Server
    
    public
    
    @@domainKeys = {}
    @@debug = false
    
    def self.enableLocalhostDebugging
      @@domainKeys[Handshake::Constants::LOCALHOST_DEBUG_KEY] = Handshake::Constants::LOCALHOST_DOMAIN
      @@debug = true
    end

    def self.run!(ip, port)
      EventMachine::WebSocket.start(:host => ip, :port => port, :debug => @@debug) do |websocket|
        websocket.onopen do
          handleConnect(websocket)
        end
      end
      puts "Server started listening for connections on #{ip}:#{port}"
    end
  
    def self.handleConnect(websocket)
      request = websocket.request
      begin
        key = getKeyForRequest(request)
        domain = getDomainForKey(key)
        if(domain != request["Origin"]) then raise ArgumentError.new "Wrong key for domain origin" end
          
        action = getActionForRequest(request)
        
        case action["name"]
          when Handshake::Constants::ACTION_NEW then
            handleGameConnect(domain, websocket)
          
          when Handshake::Constants::ACTION_CONNECT then
            if(!action["id"]) then raise ArgumentError.new "No game id specified" end
            handleControllerConnect(domain, websocket, action["id"])
            
          else
            raise ArgumentError.new
        end
        
      rescue ArgumentError
        websocket.close_connection
      end

    end
    
    def self.handleGameConnect(domain, websocket)
      Handshake::GameManager.get().addGame(domain, websocket)
    end
    
    def self.handleControllerConnect(domain, websocket, gameId)
      game = Handshake::GameManager.get().getGame(domain, gameId)
      game.addController("Browser", websocket)
    end
    
    def self.getKeyForRequest(request)
      keyMatch = request["Path"].match(/(\w+)\//)
      return keyMatch ? keyMatch[1] : (raise ArgumentError.new("No key found in request"))
    end
    
    def self.getDomainForKey(key)
      domain = @@domainKeys[ key ]
      return domain || (raise ArgumentError.new("Wrong domain in request"))
    end
    
    def self.getActionForRequest(request)
      actionMatch = request["Path"].match(/\w+\/(\w+)\/{0,1}(\d*)/)
      actionMatch || (raise ArgumentError.new("No action found in request"))
      return { "name" => actionMatch[1], "id" => actionMatch[2].to_i }
    end
  
  end

end
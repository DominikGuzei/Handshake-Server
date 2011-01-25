require_relative 'Game'

module Handshake
  class GameManager
    
    attr_reader :gameCount
    @@instance = nil
    
    def initialize
      @gameCount = 0
      @domains = {}
    end
    
    def self.get
      if(!@@instance) then
        @@instance = Handshake::GameManager.new
      end
      return @@instance
    end
    
    def addGame(domain, websocket)
      
      unless(@domains[domain])
        @domains[domain] = []
      end
      
      id = @domains[domain].size
      game = Game.new(domain, id, websocket)
      
      addEventdata = { id: id }.to_json
      game.receive("#{Handshake::Constants::SERVER_ID} #{Handshake::Constants::ADD_EVENT} #{addEventdata}")
      
      game.setDelegate(self)
      
      @domains[domain].push(game)
      @gameCount += 1
      
      return game
    end
    
    def getGame(domain, gameId)
      unless(@domains[domain])
        raise IndexError.new("Key #{domain} not found in GameManager")
      end
      unless(@domains[domain][gameId])
        raise IndexError.new("Game with #{gameId} not found in GameManager")
      end
      return @domains[domain][gameId]
    end
    
    def removeGame(domain, gameId)
      game = self.getGame(domain, gameId)
      game.removeAllControllers
      game.receive("#{Handshake::Constants::SERVER_ID} #{Handshake::Constants::REMOVE_EVENT}")
      game.close
      @domains[domain].delete_at(gameId)
      @gameCount -= 1
    end
    
    def onClose(game)
      removeGame(game.domain, game.gameId)
    end
    
    def onMessage(game, message)
      
      # message to all controllers
      if (toAll = message.match(/all (.*)/))
        message = toAll[1]
        game.sendToAllFrom(game, message)
            
      # message to individual controller
      elsif (toController = message.match(/(\w*) (.*)/) )
          controller_id = toController[1].to_i
          message = toController[2]
          
          if(controller = game.getControllerById(controller_id))
            controller.receiveFrom(game, message)
          end
      end
    end
    
  end
end


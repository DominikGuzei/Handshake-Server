require_relative 'Game'

module Handshake
  class GameManager
    
    attr_reader :gameCount
    
    def initialize
      @gameCount = 0
      @domainKeys = {}
    end
    
    def addGame(key, websocket)
      unless(@domainKeys[key])
        @domainKeys[key] = []
      end
      id = @domainKeys[key].size
      game = Game.new(key, id, websocket)
      addEventdata = { id: id }.to_json
      game.receive("#{Handshake::Constants::SERVER_ID} #{Handshake::Constants::ADD_EVENT} #{addEventdata}")
      game.setDelegate(self)
      @domainKeys[key].push(game)
      @gameCount += 1
      return game
    end
    
    def getGame(key, gameId)
      unless(@domainKeys[key])
        raise IndexError.new("Key #{key} not found in GameManager")
      end
      unless(@domainKeys[key][gameId])
        raise IndexError.new("Game with #{gameId} not found in GameManager")
      end
      return @domainKeys[key][gameId]
    end
    
    def removeGame(key, gameId)
      game = self.getGame(key, gameId)
      game.removeAllControllers
      game.receive("#{Handshake::Constants::SERVER_ID} #{Handshake::Constants::REMOVE_EVENT}")
      game.close
      @domainKeys[key].delete_at(gameId)
      @gameCount -= 1
    end
    
    def onClose(game)
      removeGame(game.domainKey, game.gameId)
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


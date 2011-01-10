require_relative 'Game'

module Handshake
  class GameManager
    
    attr_reader :gameCount
    
    def initialize
      @gameCount = 0
      @keys = {}
    end
    
    def addGame(key, websocket)
      unless(@keys[key])
        @keys[key] = []
      end
      id = @keys[key].size
      game = Game.new(id, websocket)
      data = { id: id }.to_json
      game.receive("#{Handshake::Constants::SERVER_ID} #{Handshake::Constants::ADD_EVENT} #{data}")
      @keys[key].push(game)
      @gameCount += 1
      return game
    end
    
    def getGame(key, gameId)
      unless(@keys[key])
        raise IndexError.new("Key #{key} not found in GameManager")
      end
      unless(@keys[key][gameId])
        raise IndexError.new("Game with #{gameId} not found in GameManager")
      end
      return @keys[key][gameId]
    end
    
    def removeGame(key, gameId)
      game = self.getGame(key, gameId)
      game.removeAllControllers
      game.receive("#{Handshake::Constants::SERVER_ID} #{Handshake::Constants::REMOVE_EVENT}")
      @keys[key].delete_at(gameId)
      @gameCount -= 1
    end
    
  end
end


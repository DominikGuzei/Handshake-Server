require_relative 'Controller'
require_relative 'Constants'

module Handshake
  class Game < Communicator
    
    attr_reader :controllerCount
    attr_reader :gameId
    attr_reader :domainKey
    
    def initialize(domainKey, gameId, websocket)
      super(Handshake::Constants::GAME_ID, websocket)
      @domainKey = domainKey
      @gameId = gameId
      @controllerCount = 0
      @controllers = []
    end
    
    def addController(type, websocket)
      controller = Controller.new(type, @controllerCount, websocket)
      @controllers.push(controller)
      @controllerCount += 1
      controller.receiveEventFrom(self, Handshake::Constants::ADD_EVENT, { id: controller.id })
      controller.setDelegate(self)
      self.receiveFrom(controller, Handshake::Constants::ADD_EVENT)
      return controller
    end
    
    def removeController(controller)
      unless(@controllers[controller.id] === controller)
        raise ArgumentError.new("Given controller is not connected to this game")
      end
      self.receiveFrom(controller, Handshake::Constants::REMOVE_EVENT)
      controller.receiveFrom(self, Handshake::Constants::REMOVE_EVENT)
      controller.close
      @controllers.delete_at(controller.id)
      
      @controllerCount -= 1
    end
    
    def removeAllControllers
      @controllers.each do |controller|
        controller.receiveFrom(self, Handshake::Constants::REMOVE_EVENT)
        controller.close
      end
      @controllers.clear
      @controllerCount = 0
    end
    
    def getControllerById(id)
      unless(@controllers[id])
        raise IndexError.new "Controller with id was not found"
      end
      @controllers[id]
    end
    
    def sendToAllFrom(communicator, message)
      @controllers.each do |controller|
        if(controller != communicator)
          controller.receiveFrom(communicator, message) 
        end
      end
    end
    
    def sendEventToAllFrom(communicator, eventName, data)
      @controllers.each do |controller|
        if(controller != communicator)
          controller.receiveEventFrom(communicator, eventName, data)
        end
      end
    end
    
    def onMessage(controller, message)
      # message to game
      if (toGame = message.match(/#{Handshake::Constants::GAME_ID} (.*)/) )
        message = toGame[1]
        self.receiveFrom(controller, "#{message}")
      
      # message ot all other controllers
      elsif (toOthers = message.match(/all (.*)/))
        message = toOthers[1]
        self.sendToAllFrom(controller, message)
            
      # message to individual controllers
      elsif (toController = message.match(/(\w*) (.*)/) )
          other_controller_id = toController[1].to_i
          message = toController[2]
          
          if(otherController = self.getControllerById(other_controller_id))
            otherController.receiveFrom(controller, message)
          end
      end
    end
    
    def onClose(controller)
      self.removeController(controller)
    end
    
  end
end
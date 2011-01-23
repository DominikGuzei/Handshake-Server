require 'json'

module Handshake
  class Communicator
    
    attr_reader :id
    attr_reader :websocket
    attr_reader :status
    
    CONNECTED = 0
    CLOSED = 1
    ERROR = 2
    
    def initialize(id, websocket)
      @id = id
      @websocket = websocket
      @status = Communicator::CONNECTED
      @delegate = nil
      self.setupDelegateCallbacks
    end
    
    def receive(message)
      unless(message.is_a?(String)) then
        raise TypeError.new("Argument message has to be of type String")
      end
      @websocket.send(message)
    end
    
    def receiveFrom(other, message)
      unless(other.respond_to?(:id)) then
        raise NoMethodError.new("The sender needs to have an 'id' getter")
      end
      @websocket.send("#{other.id} #{message}")
    end
    
    def receiveEventFrom(other, eventName, jsonDataHash)
      json = jsonDataHash.to_json
      self.receiveFrom(other, "#{eventName} #{json}")
    end
    
    def close
      @status = Communicator::CLOSED
      @websocket.close_websocket
    end
    
    def setDelegate(delegate)
      @delegate = delegate
    end

    protected 
    
    def setupDelegateCallbacks
      @websocket.onmessage do |message|
        if(@delegate) then
          @delegate.onMessage(self, message)
        end
      end
      
      @websocket.onerror do |message|
        if(@delegate) then
          @delegate.onError(self, message)
        end
      end
      
      @websocket.onclose do |message|
        if(@delegate) then
          @delegate.onClose(self)
        end
      end
    end
    
  end
end
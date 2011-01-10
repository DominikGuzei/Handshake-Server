require_relative 'Communicator'

module Handshake
  class Controller < Communicator
    
    attr_accessor :name
    attr_reader :type
    
    def initialize(type, id, websocket)
      super(id, websocket)
      @type = type
    end
    
  end
end
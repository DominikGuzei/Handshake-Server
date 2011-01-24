require 'rubygems'
require 'rspec'
require 'mocha'
require 'json'
require_relative '../src/Game'
require_relative 'stubs/Websocket'

RSpec.configure do |config|
  config.mock_with :mocha
end

domain = "example.com"

describe Handshake::Game do
  
  before do
    @gameSocket = Stubs::Websocket.new
    @game = Handshake::Game.new(domain, 0, @gameSocket)
  end
  
  describe ".initialize:" do

    it "extends Handshake::Communicator" do
      @game.should be_a_kind_of(Handshake::Communicator)
    end

    it "has a gameId of zero" do
      @game.gameId.should == 0
    end

    it "has a domain key attribute" do
      @game.domain.should == domain
    end
    
    it "has controllerCount set to zero" do
      @game.controllerCount.should == 0
    end

  end

  describe ".addController:" do

    before(:each) do
      @controllerSocket = Stubs::Websocket.new
    end

    it "creates a controller and returns it" do
      controller = @game.addController("Browser", @controllerSocket)
      controller.should be_a_kind_of(Handshake::Controller)
      controller.id.should == 0
      controller.type.should == "Browser"
    end

    it "sends the controller an add event with its id" do
      expectedMessage = "#{Handshake::Constants::GAME_ID} #{Handshake::Constants::ADD_EVENT} {\"id\":0}"
      @controllerSocket.expects(:send).with(expectedMessage).once
      @game.addController("Browser", @controllerSocket)
    end

    it "sends the game an add event from the controller" do
      @gameSocket.expects(:send).with("0 #{Handshake::Constants::ADD_EVENT}").once
      @game.addController("Browser", @controllerSocket)
    end

    it "increments the controller count by one" do
      @game.addController("Browser", @controllerSocket)
      @game.controllerCount.should == 1
    end

  end

  describe ".removeController:" do

    before do
      @controller = @game.addController("Browser", Stubs::Websocket.new)
    end

    it "removes the controller and sends it a remove event" do
      @controller.expects(:receiveFrom).with(@game, Handshake::Constants::REMOVE_EVENT).once
      @controller.expects(:close).once
      @game.removeController(@controller)
      @game.controllerCount.should == 0
    end

    it "only removes controllers that are connected to this game" do
      fake = Handshake::Controller.new("Browser", 2, Stubs::Websocket.new)
      expect{ @game.removeController(fake) }.to raise_error(ArgumentError)
    end

  end

  describe ".getControllerById:" do

    before do
      @controller = @game.addController("Browser", Stubs::Websocket.new)
    end

    it "returns the controller with given id" do
      @game.getControllerById(@controller.id).should == @controller
    end

    it "throws an IndexError if id is not available" do
      expect{ @game.getControllerById(2) }.to raise_error(IndexError)
    end

    it "just takes integers as id" do
      expect{ @game.getControllerById("test") }.to raise_error(TypeError)
    end

  end

  describe ".removeAllControllers:" do

    before do
      @controller1 = @game.addController("Browser", Stubs::Websocket.new)
      @controller2 = @game.addController("Browser", Stubs::Websocket.new)
    end

    it "deletes all controllers and closes them properly" do
      @controller1.expects(:receiveFrom).with(@game, Handshake::Constants::REMOVE_EVENT).once
      @controller2.expects(:receiveFrom).with(@game, Handshake::Constants::REMOVE_EVENT).once
      
      @controller1.expects(:close).once
      @controller2.expects(:close).once

      @game.removeAllControllers
      @game.controllerCount.should == 0
    end

  end

  describe ".sendToAllFrom:" do

    before do
      @controller1 = @game.addController("Browser", Stubs::Websocket.new)
      @controller2 = @game.addController("Browser", Stubs::Websocket.new)
    end

    it "sends the message from x to all connected controllers" do
      message = 'event {"data":"value"}'
      @controller1.expects(:receiveFrom).with(@game, message).once
      @controller2.expects(:receiveFrom).with(@game, message).once
      
      @game.sendToAllFrom(@game, message)
    end

  end

  describe ".sendEventToAllFrom:" do

    before do
      @controller1 = @game.addController("Browser", Stubs::Websocket.new)
      @controller2 = @game.addController("Browser", Stubs::Websocket.new)
    end

    it "sends the event from x to all connected controllers" do
      event = { data: "value" }
      eventName = "event"
      
      @controller1.expects(:receiveEventFrom).with(@game, eventName, event).once
      @controller2.expects(:receiveEventFrom).with(@game, eventName, event).once
      
      @game.sendEventToAllFrom(@game, eventName, event)
    end

  end

  describe "as message delegate of a controller" do

    before do
      @socket1 = Stubs::Websocket.new
      @socket2 = Stubs::Websocket.new
      @controller1 = @game.addController("Browser", @socket1)
      @controller2 = @game.addController("Browser", @socket2)
      @event = { data: "value" }.to_json
      @eventName = "event"
    end

    it "routes controller messages and sends them to game websocket" do
      expectedMessage = "#{@eventName} #{@event}"
      @game.expects(:receiveFrom).with(@controller1, expectedMessage).once
      
      message = "#{Handshake::Constants::GAME_ID} #{@eventName} #{@event}"
      @socket1.sendMessage(message)
    end

    it "routes controller messages to other individual controllers" do
      expectedMessage = "#{@eventName} #{@event}"
      @controller1.expects(:receiveFrom).with(@controller2, expectedMessage).once
      
      message = "#{@controller1.id} #{@eventName} #{@event}"
      @socket2.sendMessage(message)
    end

    it "routes a controller message to all other controllers" do
      controller3 = @game.addController("Browser", Stubs::Websocket.new)
      expectedMessage = "#{@eventName} #{@event}"
      
      @controller2.expects(:receiveFrom).with( @controller1, expectedMessage ).once
      controller3.expects(:receiveFrom).with( @controller1, expectedMessage ).once
      
      message = "#{Handshake::Constants::ALL_ID} #{@eventName} #{@event}"
      @socket1.sendMessage(message)
    end
  end

  describe "as close delegate of controller" do

    before(:each) do
      @controlSocket = Stubs::Websocket.new
      @controller = @game.addController("Browser", @controlSocket)
    end

    it "removes the controller that sent the close event" do
      @controlSocket.sendClose()
      @game.controllerCount.should == 0
    end

    it "sends a remove event to the game from the closed controller" do
      @gameSocket.expects(:send).with("#{@controller.id} #{Handshake::Constants::REMOVE_EVENT}")
      @controlSocket.sendClose()
    end

  end
  
end
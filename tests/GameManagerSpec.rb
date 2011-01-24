require 'rubygems'
require 'rspec'
require 'mocha'
require_relative '../src/GameManager'
require_relative 'stubs/Websocket'

RSpec.configure do |config|
  config.mock_with :mocha
end

describe Handshake::GameManager do

  before do
    @manager = Handshake::GameManager.new
    @domain = "papercraft.heroku.com"
  end

  describe ".initialize:" do
    
    it "has a gameCount of zero" do
      @manager.gameCount.should == 0
    end
    
  end

  describe ".addGame:" do
    
    it "adds a game with given websocket to manager" do
      websocket = Stubs::Websocket.new
      expectedMessage = "#{Handshake::Constants::SERVER_ID} #{Handshake::Constants::ADD_EVENT} {\"id\":0}"
      websocket.expects(:send).with(expectedMessage).once
      
      @game = @manager.addGame(@domain, websocket)
      @game.should be_an_instance_of(Handshake::Game)
      @game.gameId.should == 0
      @manager.gameCount.should == 1
    end
    
  end
  
  describe ".getGame:" do
    
    before do
      @game = @manager.addGame(@domain, Stubs::Websocket.new)
    end
    
    it "returns the game with given id on the specified domain" do
      @manager.getGame(@domain, @game.gameId).should == @game
    end
    
  end
  
  describe ".removeGame:" do
    
    before do
      @game = @manager.addGame(@domain, Stubs::Websocket.new)
      
      @controller1 = @game.addController("Browser", Stubs::Websocket.new)
      @controller2 = @game.addController("Browser", Stubs::Websocket.new)
    end
    
    it "removes the game from the domain array and closes all its controllers" do
      expectedControllerMessage = "#{Handshake::Constants::REMOVE_EVENT}"
      @controller1.expects(:receiveFrom).with( @game, expectedControllerMessage ).once
      @controller2.expects(:receiveFrom).with( @game, expectedControllerMessage ).once
      
      @controller1.expects(:close).once
      @controller2.expects(:close).once
      
      expectedGameMessage = "#{Handshake::Constants::SERVER_ID} #{Handshake::Constants::REMOVE_EVENT}"
      @game.expects(:receive).with( expectedGameMessage ).once
      @game.expects(:close).once

      @manager.removeGame(@domain, @game.gameId)
      @manager.gameCount.should == 0
      expect{ @manager.getGame(@domain, @game.gameId) }.to raise_error(IndexError)
    end
    
  end
  
  describe "as close delegate of a game:" do
    
    before(:each) do
      @gameSocket = Stubs::Websocket.new
      @game = @manager.addGame(@domain, @gameSocket)
    end
    
    it "removes the game and all its controllers" do
      @game.expects(:removeAllControllers).once
      @game.expects(:close).once

      @gameSocket.sendClose
      @manager.gameCount.should == 0
    end
    
  end
  
  describe "as message delegate of a game:" do
    
    before(:each) do
      @gameSocket = Stubs::Websocket.new
      @game = @manager.addGame(@key, @gameSocket)
      
      @controller1 = @game.addController("Browser", Stubs::Websocket.new)
      @controller2 = @game.addController("Browser", Stubs::Websocket.new)
      @message = "test {'data':0}"
    end
    
    it "routes a direct message from the game to a controller" do
      @controller1.expects(:receiveFrom).with( @game, @message).once
      @gameSocket.sendMessage("#{@controller1.id} #{@message}")
    end
    
    it "routes a message to all controllers" do
      @controller1.expects(:receiveFrom).with( @game, @message ).once
      @controller2.expects(:receiveFrom).with( @game, @message ).once
      
      @gameSocket.sendMessage("#{Handshake::Constants::ALL_ID} #{@message}")
    end
    
  end

end
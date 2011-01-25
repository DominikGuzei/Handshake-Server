require 'rubygems'
require 'rspec'
require 'mocha'
require_relative '../src/Server'
require_relative 'stubs/Websocket'

RSpec.configure do |config|
  config.mock_with :mocha
end

describe Handshake::Server do
  
  before(:each) do
    @localhostDomain = Handshake::Constants::LOCALHOST_DOMAIN
    @manager = Handshake::GameManager.get()
  end

  describe ".self.enableLocalhostDebugging" do
    
    it "adds a debug domain-key mapping for localhost" do
      Handshake::Server.enableLocalhostDebugging
      domain = Handshake::Server.getDomainForKey(Handshake::Constants::LOCALHOST_DEBUG_KEY)
      domain.should == @localhostDomain
    end
    
  end

  describe ".self.getKeyForRequest:" do
    
    it "returns the key in the request path" do
      key = Handshake::Server.getKeyForRequest( { "Path" => "/key/" } )
      key.should == "key"
    end
    
    it "raises error when key not found" do
      expect{ Handshake::Server.getKeyForRequest({ "Path" => "/" }) }.to raise_error ArgumentError
    end
    
  end
  
  describe ".self.getDomainForKey" do
    
    it "returns the domain for corresponding key" do
      domain = Handshake::Server.getDomainForKey( Handshake::Constants::LOCALHOST_DEBUG_KEY )
      domain.should == @localhostDomain
    end
    
    it "raises an ArgumentError when no domain was found for key" do
      expect{ Handshake::Server.getDomainForKey("wrongkey") }.to raise_error ArgumentError
    end
    
  end
  
  describe ".self.getActionForRequest" do
    
    it "returns an action hash with a name" do
      action = Handshake::Server.getActionForRequest({ "Path" => "/key/myAction" })
      action["name"].should == "myAction"
    end
    
    it "returns the action hash with name and id" do
      action = Handshake::Server.getActionForRequest({ "Path" => "/key/myAction/1" })
      action["name"].should == "myAction"
      action["id"].should == 1
    end
    
  end
  
  describe ".self.handleGameConnect" do
    
    it "adds the game to the domain in the game manager" do
      Handshake::Server.handleGameConnect(@localhostDomain, Stubs::Websocket.new)
      @manager.gameCount.should == 1
      
      @manager.removeGame(@localhostDomain, 0)
    end
    
  end
  
  describe ".self.handleControllerConnect" do

    it "adds the controller to the game on domain with id" do
      Handshake::Server.handleGameConnect(@localhostDomain, Stubs::Websocket.new)
      Handshake::Server.handleControllerConnect(@localhostDomain, Stubs::Websocket.new, 0)
      game = @manager.getGame(@localhostDomain, 0)
      
      game.controllerCount.should == 1
      
      @manager.removeGame(@localhostDomain, 0)
    end
    
  end
  
  describe ".self.handleConnect" do
    
    before(:each) do
      @gameSocket = Stubs::Websocket.new
      path = "/#{Handshake::Constants::LOCALHOST_DEBUG_KEY}/#{Handshake::Constants::ACTION_NEW}"
      @gameSocket.request = { "Path" =>  path, "Origin" => @localhostDomain }
      
      Handshake::Server::handleConnect(@gameSocket)
    end
    
    after(:each) do
      @manager.removeGame(@localhostDomain, 0)
    end
    
    it "creates a new game" do
      @manager.gameCount.should == 1
    end
    
    it "adds the controller to the game" do
      game = @manager.getGame(@localhostDomain, 0)
      
      controllerSocket = Stubs::Websocket.new
      path = "/#{Handshake::Constants::LOCALHOST_DEBUG_KEY}/#{Handshake::Constants::ACTION_CONNECT}/0"
      controllerSocket.request = { "Path" =>  path, "Origin" => @localhostDomain }
      
      Handshake::Server::handleConnect(controllerSocket)
      
      game.controllerCount.should == 1
    end
    
  end

end
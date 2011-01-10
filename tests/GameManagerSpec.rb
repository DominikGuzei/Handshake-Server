require 'rubygems'
require 'rspec'
require 'mocha'
require_relative '../GameManager'
require_relative 'stubs/Websocket'

RSpec.configure do |config|
  config.mock_with :mocha
end

describe "GameManager" do

  describe "gameCount" do
    before do
      @manager = Handshake::GameManager.new
    end
    
    it "should give back the number of open games" do
      @manager.gameCount.should == 0
    end
  end

  describe "addGame" do
    before do
      @manager = Handshake::GameManager.new
      @websocket = Stubs::Websocket.new
    end
    
    it "should add the game to manager" do
      @websocket.expects(:send).with(equals("#{Handshake::Constants::SERVER_ID} #{Handshake::Constants::ADD_EVENT} {\"id\":0}")).once
      @game = @manager.addGame("papercraft.heroku.com", @websocket)
      @game.should be_an_instance_of(Handshake::Game)
      @game.gameId.should == 0
      @manager.gameCount.should == 1
    end
  end
  
  describe "getGame" do
    
    before do
      @manager = Handshake::GameManager.new
      @websocket = Stubs::Websocket.new
      @key = "fawep125l1j35jk3235jl2"
      @game = @manager.addGame(@key, @websocket)
    end
    
    it "should return the game with given id on the specified domain" do
      @manager.getGame(@key, @game.gameId).should equal(@game)
    end
    
  end
  
  describe "removeGame" do
    
    before do
      @manager = Handshake::GameManager.new
      @gameSocket = Stubs::Websocket.new
      @key = "fawep125l1j35jk3235jl2"
      @game = @manager.addGame(@key, @gameSocket)
      @cSocket = Stubs::Websocket.new
      @game.addController("Browser", @cSocket)
      @game.addController("Browser", @cSocket)
    end
    
    it "should remove the game and all its controllers from the domain array" do
      @cSocket.expects(:send).with( equals("#{Handshake::Constants::GAME_ID} #{Handshake::Constants::REMOVE_EVENT}") ).twice
      @gameSocket.expects(:send).with( equals("#{Handshake::Constants::SERVER_ID} #{Handshake::Constants::REMOVE_EVENT}") ).once
      @manager.removeGame(@key, @game.gameId)
      @manager.gameCount.should == 0
      expect{ @manager.getGame(@key, @game.gameId) }.to raise_error(IndexError)
    end
    
  end

end
require 'rubygems'
require 'rspec'
require 'mocha'
require_relative '../src/Game'
require_relative 'stubs/Websocket'

RSpec.configure do |config|
  config.mock_with :mocha
end

describe "Game.new:" do
  
  before do
    @websocket = Stubs::Websocket.new
    @game = Handshake::Game.new(0, @websocket)
  end
  
  it "should extend Handshake::Communicator" do
    @game.should be_a_kind_of(Handshake::Communicator)
  end
  
  it "should have attribute gameId" do
    @game.gameId.should == 0
  end
  
end

describe "Game.controllerCount" do
  
  it "should return the number of controllers connected to the game" do
    @game = Handshake::Game.new(0, Stubs::Websocket.new)
    @game.controllerCount.should == 0
  end
  
end

describe "Game.addController:" do
  
  before do
    @controllerSocket = Stubs::Websocket.new
    @gameSocket = Stubs::Websocket.new
    @game = Handshake::Game.new(0, Stubs::Websocket.new) 
  end
  
  it "should create, add and return the controller and send it an add event" do
    @controllerSocket.expects(:send).with('game added {"id":0}').once
    @controller = @game.addController("Browser", @controllerSocket)
    @controller.should be_a_kind_of(Handshake::Controller)
    @controller.id.should == 0
    @controller.type.should == "Browser"
    @game.controllerCount.should == 1
  end
  
end

describe "Game.removeController:" do

  before do
    @controllerSocket = Stubs::Websocket.new
    @game = Handshake::Game.new(0, Stubs::Websocket.new)
    @controller = @game.addController("Browser", @controllerSocket)
  end
  
  it "should remove the controller and send a remove event" do
    @controllerSocket.expects(:send).with('game removed').once
    @controllerSocket.expects(:close_websocket).once
    @game.removeController(@controller)
    @game.controllerCount.should == 0
    @controller.status.should == Handshake::Communicator::CLOSED
  end
  
  it "should only remove controllers that are connected to this game" do
    fake = Handshake::Controller.new("Browser", 2, Stubs::Websocket.new)
    expect{ @game.removeController(fake) }.to raise_error(ArgumentError)
  end
  
end

describe "Game.getControllerById" do
  
  before do
    @controllerSocket = Stubs::Websocket.new
    @game = Handshake::Game.new(0, Stubs::Websocket.new)
    @controller = @game.addController("Browser", @controllerSocket)
  end
  
  it "should return the controller with given id" do
    @game.getControllerById(@controller.id).should equal(@controller)
  end
  
  it "should throw an IndexError if id is not available" do
    expect{ @game.getControllerById(2) }.to raise_error(IndexError)
  end
  
  it "should just take integer values" do
    expect{ @game.getControllerById("test") }.to raise_error(TypeError)
  end
  
end

describe "Game.removeAllControllers:" do
  
  before do
    @controllerSocket = Stubs::Websocket.new
    @game = Handshake::Game.new(0, Stubs::Websocket.new)
    @controller1 = @game.addController("Browser", @controllerSocket)
    @controller2 = @game.addController("Browser", @controllerSocket)
  end
  
  it "should delete all controllers and close them properly" do
    @controllerSocket.expects(:send).with('game removed').twice
    @controllerSocket.expects(:close_websocket).twice
    @game.removeAllControllers
    @game.controllerCount.should == 0
    @controller1.status.should == Handshake::Communicator::CLOSED
    @controller2.status.should == Handshake::Communicator::CLOSED
  end
  
end

describe "Game.sendToAllFrom:" do
  
  before do
    @controllerSocket = Stubs::Websocket.new
    @game = Handshake::Game.new(0, Stubs::Websocket.new)
    @controller1 = @game.addController("Browser", @controllerSocket)
    @controller2 = @game.addController("Browser", @controllerSocket)
  end
  
  it "should send the message to all connected controllers" do
    @controllerSocket.expects(:send).with('game event {"data":"value"}').twice
    @game.sendToAllFrom(@game, 'event {"data":"value"}')
  end
  
end

describe "Game.sendEventToAllFrom:" do
  
  before do
    @controllerSocket = Stubs::Websocket.new
    @game = Handshake::Game.new(0, Stubs::Websocket.new)
    @controller1 = @game.addController("Browser", @controllerSocket)
    @controller2 = @game.addController("Browser", @controllerSocket)
  end
  
  it "should send the event to all connected controllers" do
    @controllerSocket.expects(:send).with('game event {"data":"value"}').twice
    @game.sendEventToAllFrom(@game, "event", { data: "value" })
  end
  
end

describe "Game as controller delegate" do
  
  before do
    @firstSocket = Stubs::Websocket.new
    @othersSocket = Stubs::Websocket.new
    
    @gameSocket = Stubs::Websocket.new
    @game = Handshake::Game.new(0, @gameSocket)
    
    @controller = @game.addController("Browser", @firstSocket)
    @otherController = @game.addController("Browser", @othersSocket)
  end
  
  it "should route controller messages and send to game websocket" do
    @gameSocket.expects(:send).with(equals('0 event {"data":"value"}')).once
    @firstSocket.sendMessage('game event {"data":"value"}')
  end
  
  it "should route controller messages to individual controllers" do
    @othersSocket.expects(:send).with(equals('0 event {"data":"value"}')).once
    @firstSocket.sendMessage('1 event {"data":"value"}')
  end
  
  it "should rout controller messages to all other controllers" do
    @game.addController("Browser", @othersSocket)
    
    @othersSocket.expects(:send).with(equals('0 event {"data":"value"}')).twice
    @firstSocket.sendMessage('all event {"data":"value"}')
  end
  
end
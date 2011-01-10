require 'rubygems'
require 'rspec'
require 'mocha'
require_relative '../src/Communicator'
require_relative 'stubs/Websocket'

RSpec.configure do |config|
  config.mock_with :mocha
end

describe "Communicator.new:" do
  
  before do
    @websocket = Stubs::Websocket.new
    @id = "test"
    @communicator = Handshake::Communicator.new(@id, @websocket)
  end
  
  it "should be instance of Communicator" do
    @communicator.should be_an_instance_of(Handshake::Communicator)
  end
  
  it "should have the id assigned" do
    @communicator.id.should eql(@id)
  end
  
  it "should have websocket assigned" do
    @communicator.websocket.should eql(@websocket)
  end
  
  it "should have a status of connected" do
    @communicator.status.should == Handshake::Communicator::CONNECTED
  end
  
end

describe "Communicator.setDelegate" do
  
  before do
    @websocket = Stubs::Websocket.new
    @communicator = Handshake::Communicator.new(1, @websocket)
    @delegate = mock()
  end
  
  it "should be able to set a delegate for websocket messages" do
    @communicator.setDelegate(@delegate)
    @delegate.expects(:onMessage).with(@communicator, "test").once
    @websocket.sendMessage("test")
  end
  
  it "should be able to set a delegate for websocket errors" do
    @communicator.setDelegate(@delegate)
    @delegate.expects(:onError).with(@communicator, "test").once
    @websocket.sendError("test")
  end
  
  it "should be able to set a delegate for websocket close" do
    @communicator.setDelegate(@delegate)
    @delegate.expects(:onClose).with(@communicator).once
    @websocket.sendClose()
  end
  
end

describe "Communicator.receive:" do
  
  before do
    @websocket = Stubs::Websocket.new
    @communicator = Handshake::Communicator.new("test", @websocket)
  end
  
  it "should send strings" do
    @websocket.expects(:send).never
    expect{@communicator.receive(0)}.to raise_error(TypeError)
    expect{@communicator.receive({})}.to raise_error(TypeError)
    expect{@communicator.receive([])}.to raise_error(TypeError)
  end
  
  it "should send message via websocket" do
    @websocket.expects(:send).with("message").at_least_once
    @communicator.receive("message")
  end
  
end

describe "Communicator.receiveFrom:" do
  
  before do
    @websocket1 = Stubs::Websocket.new
    @websocket2 = Stubs::Websocket.new
    @communicator1 = Handshake::Communicator.new("1", @websocket1)
    @communicator2 = Handshake::Communicator.new("2", @websocket2)
  end
  
  it "should receive the message from other communicator with its id" do
    @websocket1.expects(:send).with("2 message").once
    @websocket2.expects(:send).never
    @communicator1.receiveFrom(@communicator2, "message")
  end
  
end

describe "Communicator.receiveEventFrom:" do
  
  before do
    @websocket1 = Stubs::Websocket.new
    @websocket2 = Stubs::Websocket.new
    @communicator1 = Handshake::Communicator.new("1", @websocket1)
    @communicator2 = Handshake::Communicator.new("2", @websocket2)
  end
  
  it "should receive event and json data with others id" do
    @websocket1.expects(:send).with('2 event {"data":"value"}')
    expect{ @communicator1.receiveEventFrom(@communicator2, "event", { data: "value" }) }.to_not raise_error()
  end

end

describe "Communicator.close:" do
  
  before do
    @websocket = Stubs::Websocket.new
    @communicator = Handshake::Communicator.new("test", @websocket)
  end
  
  it "should close the websocket and change status to closed" do
    @websocket.expects(:close_websocket).once
    @communicator.close
    @communicator.status.should == Handshake::Communicator::CLOSED
  end
  
end
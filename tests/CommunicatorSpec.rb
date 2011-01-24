require 'rubygems'
require 'rspec'
require 'mocha'
require_relative '../src/Communicator'
require_relative 'stubs/Websocket'

RSpec.configure do |config|
  config.mock_with :mocha
end

describe Handshake::Communicator do
  
  before do
    @websocket = Stubs::Websocket.new
    @id = 1
    @communicator = Handshake::Communicator.new(@id, @websocket)
  end
  
  describe ".initialize:" do

    it "has the given id assigned" do
      @communicator.id.should == @id
    end

    it "has the given websocket assigned" do
      @communicator.websocket.should == @websocket
    end

    it "has a status of connected" do
      @communicator.status.should == Handshake::Communicator::CONNECTED
    end

  end

  describe ".setDelegate:" do

    before do
      @delegate = mock()
      @message = "test"
    end

    it "sets up the delegate to receive its websocket messages" do
      @communicator.setDelegate(@delegate)
      @delegate.expects(:onMessage).with(@communicator, @message).once
      @websocket.sendMessage(@message)
    end

    it "sets up the delegate to receive its websocket errors" do
      @communicator.setDelegate(@delegate)
      @delegate.expects(:onError).with(@communicator, @message).once
      @websocket.sendError(@message)
    end

    it "sets up the delegate to receive its websocket close" do
      @communicator.setDelegate(@delegate)
      @delegate.expects(:onClose).with(@communicator).once
      @websocket.sendClose()
    end

  end

  describe ".receive:" do

    it "only allows strings to be sent to the websocket" do
      @websocket.expects(:send).never
      expect{@communicator.receive(0)}.to raise_error(TypeError)
      expect{@communicator.receive({})}.to raise_error(TypeError)
      expect{@communicator.receive([])}.to raise_error(TypeError)
    end

    it "sends the message to the websocket" do
      @message = "message"
      @websocket.expects(:send).with(@message).at_least_once
      @communicator.receive(@message)
    end

  end

  describe ".receiveFrom:" do

    before do
      @websocket2 = Stubs::Websocket.new
      @communicator2 = Handshake::Communicator.new(2, @websocket2)
    end

    it "receives the message from other communicator with its id" do
      @websocket.expects(:send).with("2 message").once
      @websocket2.expects(:send).never
      @communicator.receiveFrom(@communicator2, "message")
    end

  end

  describe ".receiveEventFrom:" do

    before do
      @websocket2 = Stubs::Websocket.new
      @communicator2 = Handshake::Communicator.new(2, @websocket2)
    end

    it "receives event and json data with other communicator's id" do
      @websocket.expects(:send).with('2 event {"data":"value"}')
      expect{ @communicator.receiveEventFrom(@communicator2, "event", { data: "value" }) }.to_not raise_error()
    end

  end

  describe ".close:" do

    it "closes the websocket and changes its status to closed" do
      @websocket.expects(:close_connection_after_writing).once
      @communicator.close
      @communicator.status.should == Handshake::Communicator::CLOSED
    end

  end
  
end
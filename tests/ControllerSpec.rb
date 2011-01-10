require 'rubygems'
require 'rspec'
require 'mocha'
require_relative '../src/Controller'
require_relative 'stubs/Websocket'

RSpec.configure do |config|
  config.mock_with :mocha
end

describe "Controller.new:" do
  
  before do
    @type = "Webclient"
    @websocket = Stubs::Websocket.new
    @controller = Handshake::Controller.new(@type, "test", @websocket)
  end
  
  it "should extend Handshake::Communicator" do
    @controller.should be_a_kind_of(Handshake::Communicator)
  end
  
  it "should have a type applied" do
    @controller.type.should equal(@type)
  end
  
  it "should not be possible to change the type" do
    expect{@controller.type = "Test"}.to raise_error()
  end
  
end


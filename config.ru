require 'rubygems'
require 'eventmachine'

#require './web/Application.rb'
require_relative 'websocket/Server'

EM.run {
  
  #Handshake::Web::Application.run!({ :port => 3000 })
  Handshake::Websocket::Server.run!("0.0.0.0", 10000, false);
}
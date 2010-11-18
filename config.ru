require 'rubygems'
require 'eventmachine'

#require './web/Application.rb'
require './websocket/Server.rb'


  #Handshake::Web::Application.run!({ :port => 3000 })
Handshake::Websocket::Server.run!("0.0.0.0", 10000, false);

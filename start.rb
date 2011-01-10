require 'rubygems'
require 'eventmachine'

require_relative 'Server'

EM.run {
  Handshake::Websocket::Server.run!("127.0.0.1", 8008, true)
}
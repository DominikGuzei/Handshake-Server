require 'rubygems'
require 'cramp/controller'

Cramp::Controller::Websocket.backend = :thin

class WelcomeController < Cramp::Controller::Websocket
  on_data :received_data

  def received_data(data)
    render "Got your #{data}"
  end
end


Rack::Handler::Thin.run WelcomeController, :Port => 3000
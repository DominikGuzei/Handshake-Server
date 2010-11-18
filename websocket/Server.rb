require 'eventmachine'
require 'em-websocket'
require 'json'
require_relative 'HostManager'

module Handshake
  module Websocket
  
    class Server
      
      def self.run!(host, port, debug)
        
        EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 10_000, :debug => true) do |websocket|

          # handle connection requests
          websocket.onopen {
            # analyse request path to differentiate between clients and hosts
            host = websocket.request["Path"].match /host/
            if(host)
              host = HandShake::HostManager.add_host(websocket)

              # HOST MESSAGES
              host.websocket.onmessage do |msg|
                # message to all clients
                if(all = msg.match /all (.*)/)
                  message = all[1] # extracted message
                  host.to_all("host #{message}")

                # message to individual client
                elsif(client = msg.match /(\w*) (.*)/)
                  client_id = client[1]
                  message = client[2]
                  begin
                    host.to_client(client_id, "host #{message}")
                  rescue HandShake::ClientNotFoundException => exception
                    exceptionJson = { 
                      :type => "clientNotFound",
                      :clientNotFound => exception.client_id 
                    }.to_json
                    host.websocket.send("server exception #{exceptionJson}")
                  end # rescue
                end
              end # block

              host.websocket.onclose do
                HandShake::HostManager.remove_host(host.id)
              end

              connectJson = { :id => host.id }.to_json
              host.websocket.send("server connect #{connectJson}")

            else
              # connecting route - /host_id/connect 
              connect = websocket.request["Path"].match /(\w*)\/connect\/([a-zA-Z0-9|-]*)/

              if(connect)
                host_id = connect[1]
                deviceType = connect[2]
                host = HandShake::HostManager.get_host(host_id)
                client = host.add_client(websocket, deviceType)

                connectJson = { 
                  :id => client.id, 
                  :deviceType => deviceType
                }.to_json
                host.websocket.send("#{client.id} connect #{connectJson}")
                client.websocket.send("server connect #{connectJson}")

                # CLIENT MESSAGES

                client.websocket.onmessage do |msg|
                  # message to host
                  if(toHost = msg.match /host (.*)/)
                    message = toHost[1] # extracted message
                    host.websocket.send("#{client.id} #{message}")

                  # message to all clients
                  elsif(toAll = msg.match /all (.*)/)
                    message = toAll[1] # extracted message
                    host.to_all("#{client.id} #{message}")

                  # message to individual client
                  elsif(toClient = msg.match /(\w*) (.*)/)
                      other_client_id = toClient[1]
                      message = toClient[2]
                      begin
                        host.to_client(other_client_id, "#{client.id} #{message}")
                      rescue HandShake::ClientNotFoundException => exception
                        exceptionJson = {
                          :type => "clientNotFound",
                          :clientId => exception.client_id 
                        }.to_json
                        client.websocket.send("server exception #{exceptionJson}")
                      end # rescue
                  end # if (host) 
                end # client.onmessage

                client.websocket.onclose do
                  client.websocket.send("server disconnect")
                  host.websocket.send("#{client.id} disconnect")
                end

              else
                websocket.close_with_error("connect to host like this: /*i/connect")
              end
            end
          }

        end

        puts "Server started"
      end # self.run!
    end # class
    
  end
end
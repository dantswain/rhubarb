#!/usr/bin/ruby

# Copyright (c) 2011 Daniel T. Swain
# See the file license.txt for copying permissions

require 'socket'

socket = TCPSocket.open('127.0.0.1',1234)

loop do
  resp = socket.gets

  if(!resp)
    puts "Server has shut down"
    break
  end

  if(resp.strip == "Goodbye")
    puts resp
    break
  end
      

  puts resp

  cmd = gets

  socket.puts cmd

end  

socket.close


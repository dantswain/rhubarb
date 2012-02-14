# Copyright (c) 2011 Daniel T. Swain
# See the file license.txt for copying permissions

$: << File.expand_path('lib', File.dirname(__FILE__))
require 'rhubarb'

class SampleServer < Rhubarb

  add_command :name => "hi"
  add_get_set_command :name => "ultimateAnswer", :setArgs => 1
  add_indexed_get_set_command :name => "arrayData", :setArgs => 3, :maxIndex => 1

  def self.reset_data
    @@ultimate_answer = 42
    @@array_data = [[1, 2, 3],[4, 5, 6]]
  end

  reset_data

  def welcomeMessage(args)
    "Welcome, client #{@@client_id}!"
  end

  def respondToHi(words)
    "HO!"
  end

  def getUltimateAnswer(args, cmd_def)
    "The ultimate answer is #{@@ultimate_answer}"
  end

  def setUltimateAnswer(args, cmd_def)
    @@ultimate_answer = args[2]
    getUltimateAnswer(args, cmd_def)
  end

  def getArrayData(i)
    "#{@@array_data[i][0]} #{@@array_data[i][1]} #{@@array_data[i][2]}"
  end
  
  def setArrayData(i, args)
    @@array_data[i][0] = args[0].to_f
    @@array_data[i][1] = args[1].to_f
    @@array_data[i][2] = args[2].to_f
    getArrayData(i)
  end    
  
end

server = SampleServer.new(1234, '127.0.0.1')

server.audit = true
server.start

server.join

puts "Server has been terminated"


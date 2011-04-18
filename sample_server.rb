# Copyright (c) 2011 Daniel T. Swain
# See the file license.txt for copying permissions

$: << File.expand_path(File.dirname(__FILE__))
require 'rhubarb.rb'

class SampleServer < Rhubarb

  def initialize(*args)
    super(*args)

    @ultimateAnswer = 42
    @arrayData = [[1, 2, 3],[4, 5, 6]];
    
    get_set_ultimateanswer = {:name => "ultimateAnswer", :setArgs => 1}
    get_set_arraydata = {:name => "arrayData", :setArgs => 3, :maxIndex => 1}
    
    @commands << {:name => "hi"};

    @get_commands << get_set_ultimateanswer
    @set_commands << get_set_ultimateanswer

    @indexed_get_commands << get_set_arraydata
    @indexed_set_commands << get_set_arraydata    

  end

  def welcomeMessage(args)
    "Welcome, client #{@@client_id}!"
  end

  def respondToHi(words)
    "HO!"
  end

  def getUltimateAnswer(args, cmd_def)
    "The ultimate answer is #{@ultimateAnswer}"
  end

  def setUltimateAnswer(args, cmd_def)
    @ultimateAnswer = args[2]
    getUltimateAnswer(args, cmd_def)
  end

  def getArrayData(i)
    "#{@arrayData[i][0]} #{@arrayData[i][1]} #{@arrayData[i][2]}"
  end
  
  def setArrayData(i, args)
    @arrayData[i][0] = args[0].to_f
    @arrayData[i][1] = args[1].to_f
    @arrayData[i][2] = args[2].to_f
    getArrayData(i)
  end    
  
end

server = SampleServer.new(1234, '127.0.0.1')

server.audit = true
server.start

server.join

puts "Server has been terminated"


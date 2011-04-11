require 'rhubarb.rb'

class SampleServer < Rhubarb

  def initialize(*args)
    super(*args)

    @ultimateAnswer = 42
    
    get_set_cmd = {:name => "ultimateAnswer", :setArgs => 1}
    
    @commands << {:name => "hi"};

    @get_commands << get_set_cmd
    @set_commands << get_set_cmd    

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

end

server = SampleServer.new(1234, '127.0.0.1')

server.audit = true
server.start

server.join

puts "Server has been terminated"


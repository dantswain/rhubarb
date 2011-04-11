require 'rhubarb.rb'

class SampleServer < Rhubarb

  def initialize(*args)
    super(*args)

    @commands << {:name => "hi"};
    
  end

  def respondToHi(words)
    "HO!"
  end

end

server = SampleServer.new(1234, '127.0.0.1')

server.audit = true
server.start

server.join

puts "Server has been terminated"


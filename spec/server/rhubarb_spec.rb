require 'spec_helper'

class TestServer < Rhubarb
  
  add_get_set_command :name => "foo", :setArgs => 1
  add_indexed_get_set_command :name => "arrayData", :setArgs => 3, :maxIndex => 1 
  add_command :name => "fee"

  @@foo = 42
  @@arrayData = [[1, 2, 3],[4, 5, 6]]
  
  def welcomeMessage(args)
    "Hi, client #{client_id}!"
  end

  def getFoo(args, cmd_def)
    "#{@@foo}"
  end

  def setFoo(args, cmd_def)
    @@foo = args[2]
    getFoo(args, cmd_def)
  end

  def getArrayData(i)
    "#{@@arrayData[i][0]} #{@@arrayData[i][1]} #{@@arrayData[i][2]}"
  end

  def setArrayData(i, args)
    @@arrayData[i][0] = args[0].to_f
    @@arrayData[i][1] = args[1].to_f
    @@arrayData[i][2] = args[2].to_f
    getArrayData(i)
  end

  def respondToFee(words)
    "Fi!"
  end

end

describe Rhubarb do

  before(:all) do
    @server = TestServer.new(1234, '127.0.0.1')
    @server.start

    @sock = TCPSocket.open('127.0.0.1', 1234)
    @welcome = @sock.gets
  end

  it "should give the right welcome message" do
    @welcome.should match "Hi, client 1!\n"
  end

  it "should respond to get foo" do
    @sock.puts "get foo"
    @sock.gets.to_i.should == 42 
  end

  it "should set foo" do
    @sock.puts "set foo 10.0"
    @sock.gets
    @sock.puts "get foo"
    @sock.gets.to_i.should == 10
  end

  it "should get arrayData" do
    @sock.puts "get arrayData 0"
    a = @sock.gets.split.collect{ |i| i.to_i }
    a[0].should == 1
    a[1].should == 2
    a[2].should == 3
  end

  it "should set arrayData" do
    @sock.puts "set arrayData 0 5.0 6.0 7.0"
    @sock.gets
    @sock.puts "get arrayData 0"
    a = @sock.gets.split.collect{ |i| i.to_i }
    a[0].should == 5
    a[1].should == 6
    a[2].should == 7
  end

  it "should respond to fee" do
    @sock.puts "fee"
    @sock.gets.should match "Fi!"
  end

  after(:all) do
    @sock.puts "S"
    @sock.gets
    @sock.close
    @server.join
  end
  
end

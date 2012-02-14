require 'spec_helper'

class TestServer < Rhubarb::Server
  
  add_get_set_command :name => "foo", :setArgs => 1
  add_indexed_get_set_command :name => "arrayData", :setArgs => 3, :maxIndex => 1
  add_command :name => "fee"

  @@mode_cmd_def = ({ :name => "modeData", :modes => {
                             :mode2 => { :setArgs => 2 },
                             :mode3 => { :setArgs => 3 }
                           },
                           :maxIndex => 1
                         })

  # set modeData mode2 0 1.0 2.0
  # get modeData 0 -> mode2 1.0 2.0
  # set modeData mode3 0 1.0 2.0 3.0
  # get modeData 0 -> mode3 1.0 2.0 3.0


  add_indexed_get_set_command @@mode_cmd_def

  def self.reset_data
    @@foo = 42
    @@arrayData = [[1, 2, 3],[4, 5, 6]]

    @@mode_data = {
      :mode2 => [["w", "x"], ["y", "z"]],
      :mode3 => [["a", "b", "c"], ["d", "e", "f"]]
    }

    @@mode = :mode2
  end

  reset_data
    
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
    @@arrayData[i].join(" ")
  end

  def setArrayData(i, args)
    @@arrayData[i][0] = args[0].to_f
    @@arrayData[i][1] = args[1].to_f
    @@arrayData[i][2] = args[2].to_f
    getArrayData(i)
  end

  def getModeDataMode
    @@mode
  end

  def setModeDataMode mode
    return false unless @@mode_cmd_def[:modes].has_key?(mode.to_sym)
    @@mode = mode.to_sym
    return true
  end

  def respondToFee(words)
    "Fi!"
  end

  def getModeData(i)
    @@mode_data[@@mode][i].join(" ")
  end

  def setModeData(i, args)
    @@mode_data[@@mode][i] = args
    getModeData(i)
  end

end

describe Rhubarb::Server do

  before(:each) do
    TestServer.reset_data    
    @server = TestServer.new(1234, '127.0.0.1')
    @server.start

    @sock = TCPSocket.open('127.0.0.1', 1234)
    @welcome = @sock.gets
  end

  it "should give the right welcome message" do
    @welcome.should match "Hi, client 1!\n"
  end

  describe "for a custom command" do
    
    it "should respond to fee" do
      response_to("fee").should match "Fi!"
    end

  end
  
  describe "for simple data" do
    
    it "should respond to get foo" do
      response_to("get foo").to_i.should == 42
    end

    it "should set foo" do
      response_to("set foo 10.0").should match "10.0"
      response_to("get foo").to_i.should == 10
    end
    
  end

  describe "for array data" do
    
    it "should get" do
      a = response_to("get arrayData 0").split.collect{ |i| i.to_i }
      a[0].should == 1
      a[1].should == 2
      a[2].should == 3
      a = response_to("get arrayData 1").split.collect{ |i| i.to_i }
      a[0].should == 4
      a[1].should == 5
      a[2].should == 6
    end

    it "should set data" do
      response_to("set arrayData 0 5.0 6.0 7.0").should match "5.0 6.0 7.0"
      a = response_to("get arrayData 0").split.collect{ |i| i.to_i }
      a[0].should == 5
      a[1].should == 6
      a[2].should == 7
      response_to("set arrayData 1 7.0 8.0 9.0").should match "7.0 8.0 9.0"
      a = response_to("get arrayData 1").split.collect{ |i| i.to_i }
      a[0].should == 7
      a[1].should == 8
      a[2].should == 9
    end

    it "should get all array data" do
      response_to("get arrayData *").should match "1 2 3 4 5 6"
    end

    it "should allow to set all of the data" do
      response_to("set arrayData 0 -1 -2 -3 1 -4 -5 -6").
        should match "-1.0 -2.0 -3.0 -4.0 -5.0 -6.0"
      response_to("get arrayData *").
        should match "-1.0 -2.0 -3.0 -4.0 -5.0 -6.0"        
    end

    it "should get array data in the order in which it was requested" do
      response_to("set arrayData 1 1 1 1 0 0 0 0").should match "1.0 1.0 1.0 0.0 0.0 0.0"
      response_to("get arrayData 1 0").should match "1.0 1.0 1.0 0.0 0.0 0.0"
    end
    
  end

  describe "for moded data" do
    
    it "should get data" do
      response_to("get modeData 0").should match "mode2 w x"
    end

    it "should set data" do
      response_to("set modeData mode2 0 1.0 2.0").should match "mode2 1.0 2.0"
    end

    it "should set data with a new mode" do
      response_to("set modeData mode3 0 p q r").should match "mode3 p q r"
    end

    it "should set the mode" do
      response_to("set modeData mode3").should match "mode3"
      response_to("get modeData 0").should match "mode3 a b c"
    end

    it "should get all of the data" do
      response_to("get modeData *").should match "mode2 w x y z"
    end

    it "should get all of the data after switching modes" do
      response_to("set modeData mode3").should match "mode3"
      response_to("get modeData *").should match "mode3 a b c d e f"
    end

    it "should allow to set all data with the mode" do
      response_to("set modeData mode3 0 l m n 1 g h i").
        should match "l m n g h i"
      response_to("get modeData *").
        should match "l m n g h i"        
    end

    it "should get data in the order in which it was requested" do
      response_to("set modeData mode2 0 a a 1 b b").should match "a a b b"
      response_to("get modeData 1 0").should match "b b a a"
    end
    
  end

  it "should not time out" do
    1000.times do
      response_to("get arrayData 1").should match "4 5 6"
    end
  end

  it "should not time out with two clients" do
    sock2 = TCPSocket.open('127.0.0.1', 1234)
    sock2.gets # dump welcome message

    1000.times do
      p = Array.new(3).collect{ 3.0*(rand()-0.5) }
      p_as_str = p.join(" ")
      i = rand(1)
      response_to("set arrayData #{i} #{p_as_str}").should match p_as_str
      response_to("get arrayData #{i}", sock2).should match p_as_str
    end
    
  end

  after(:each) do
    @sock.puts "S"
    @sock.gets
    @sock.close
    @server.join
  end

  def response_to(send_string, sock = @sock)
    sock.puts send_string
    return sock.gets
  end
  
end

rhubarb
==================

rhubarb is Copyright (c) 2012 by Daniel Swain, dan.t.swain at gmail.com.

What is rhubarb?
------------------

rhubarb is a lightweight and extensible inter-process communication (IPC) server.  rhubarb is a base class, written in ruby, with the intention that you add your own functionality by subclassing it.  

Communication with rhubarb is via lines of text and therefore clients can be written in any language with socket support.  The `sample_server.rb` file should give you an idea of what's possible.

How do I use it?
------------------

This is a very simple example, see `sample_server.rb` for a more involved example.  Suppose that you want the value of a variable, let's call it `ultimateAnswer`, to be available for several different programs to get and set.

The first step is to subclass `Rhubarb::Server`, add a class variable to store the value of `ultimateAnswer`, and add the command definition

```ruby
class LUEServer < Rhubarb::Server
 
  # recommended so that the dat is reset whenever
  #  we fire up the server
  def self.reset_data
    @@ultimateAnswer = 42
  end
  reset_data

  # setArgs is the number of arguments required to set the variable
  add_get_set_command :name => "ultimateAnswer", :setArgs => 1

end
```
     
The next step is to add methods telling rhubarb how to respond to get and set commands for ultimateAnswer.  The method name is automatically determined by camel-casing the name of the command and adding the appropriate prefix.  In this case, we need setUltimateAnswer and getUltimateAnswer.  The functions should return a line of text that the server will send back to the user.

```ruby
class LUEServer < Rhubarb::Server
  def getUltimateAnswer(args, cmd_def)
    "The ultimate answer is #{@@ultimateAnswer}"
  end

  def setUltimateAnswer(args, cmd_def)
    # args[0] is "set" and args[1] is "ultimateAnswer"
    @@ultimateAnswer = args[2]
    # delegate to getUltimateAnswer so that the response is standardized
    getUltimateAnswer(args, cmd_def)
  end
end # finish the class definition
```

These methods need to have two arguments.  The first is the arguments, which is an arry of words from the line that was sent to the server.  In this case, the first two words will be "get ultimateAnswer" or "set ultimateAnswer" - hence the third argument is used to actually set the value.  The second argument is the command definition hash, i.e. {:name => "ultimateAnswer", :setArgs => 1}.

To launch the server, create a new object (the initialization arguments set the port and hostname) and call the start method on it.  The join method will wait for the server to shut down gracefully.

```ruby
server = LUEServer.new(1234, '127.0.0.1')
server.start

server.join
```

The simplest way to test the server is to run the ruby client in the clients folder.  Each line typed in the client gets sent to the server and the response is reported.

In one terminal:

    $ ruby sample_server.rb
    [Thu Feb 16 12:15:36 2012] SampleServer 127.0.0.1:1234 start
    
In another terminal:

    $ ruby clients/client.rb
    Welcome, client 1!             # welcome message from the server
    get ultimateanswer
    The ultimate answer is 42      # response
    set ultimateanswer 54
    The ultimate answer is 54      # response
    S                              # sending "S" tells the server to shutdown
    Goodbye                        # response

